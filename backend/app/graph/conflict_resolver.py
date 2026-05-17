"""Conflict Resolver subgraph.

Subscribes to 5 event types and re-runs Discovery → Ranking → Decision → Booking.
"""

from __future__ import annotations

import asyncio
import logging

from app.graph.errors import SlotConflict
from app.graph.nodes import conflict as conflict_node
from app.graph.nodes import booking, decision, discovery, ranking
from app.graph.state import RequestSession

logger = logging.getLogger(__name__)

MAX_RESOLUTION_ATTEMPTS = 3

# In-memory session store (for the conflict resolver to reload state).
# In production this would be a Redis/DB-backed store.
_sessions: dict[str, RequestSession] = {}

# Per-session lock so two events for the same session are serialised.
# Without this, a SlotConflict from a re-booking attempt could spawn a
# second handle() task that races with the recursive call below, producing
# duplicate bookings for the same user (we hit this in live testing).
_session_locks: dict[str, asyncio.Lock] = {}


def _get_lock(session_id: str) -> asyncio.Lock:
    lock = _session_locks.get(session_id)
    if lock is None:
        lock = asyncio.Lock()
        _session_locks[session_id] = lock
    return lock


def register_session(state: RequestSession) -> None:
    _sessions[state.id] = state


def get_session(session_id: str) -> RequestSession | None:
    return _sessions.get(session_id)


async def handle(event: dict) -> None:
    """Entry point for all conflict events. Serialised per session."""
    session_id = event.get("session_id", "")
    state = get_session(session_id)
    if state is None:
        logger.warning("Conflict event for unknown session %s", session_id)
        return

    async with _get_lock(session_id):
        await _handle_locked(state, event)


async def _handle_locked(state: RequestSession, event: dict) -> None:
    session_id = state.id

    if state.resolution_attempts >= MAX_RESOLUTION_ATTEMPTS:
        await _hand_off_to_user(state, event)
        await _publish_resolver_done(session_id, status="handoff")
        return

    # Update state for this resolution attempt
    state.resolution_attempts += 1
    event_key = event.get("key", "unknown")
    failed_provider_id = event.get("failed_provider_id")
    state.triggered_by = f"{event_key}:{failed_provider_id}" if failed_provider_id else event_key

    if failed_provider_id and failed_provider_id not in state.excluded_provider_ids:
        state.excluded_provider_ids.append(failed_provider_id)

    logger.info(
        "Conflict resolution attempt %d/%d for session %s (event=%s)",
        state.resolution_attempts,
        MAX_RESOLUTION_ATTEMPTS,
        session_id[:8],
        event_key,
    )

    try:
        # ConflictResolverAgent decides strategy (widening etc.)
        state = await conflict_node.run(state, event)

        # Re-run the discovery → booking pipeline with phase_override=recover
        state = await discovery.run(state)

        if not state.candidates:
            await _hand_off_to_user(state, event)
            await _publish_resolver_done(session_id, status="handoff")
            return

        state = await ranking.run(state)
        state = await decision.run(state)

        if not state.chosen:
            await _hand_off_to_user(state, event)
            await _publish_resolver_done(session_id, status="handoff")
            return

        state = await booking.run(state)

        # Notify user of successful rebook
        await _notify_rebooked(state, event)
        await _publish_resolver_done(session_id, status="rebooked")

    except SlotConflict as exc:
        # The retry also conflicted. Recurse *inside* the current lock so we
        # don't deadlock and don't spawn a parallel resolver task. The recursive
        # call re-enters _handle_locked directly (already-acquired lock).
        await _handle_locked(
            state,
            {
                "key": "slot_conflict",
                "session_id": session_id,
                "failed_provider_id": exc.provider_id,
            },
        )
    except Exception as exc:
        logger.error("Conflict resolution failed for session %s: %s", session_id[:8], exc)
        await _hand_off_to_user(state, event)
        await _publish_resolver_done(session_id, status=f"error: {exc}")


async def _publish_resolver_done(session_id: str, status: str) -> None:
    """Signal the SSE stream that the resolver run is complete."""
    try:
        from app.events.bus import get_bus
        await get_bus().publish_done(session_id, f"resolver:{status}")
    except Exception:
        logger.exception("Failed to publish resolver-done for %s", session_id[:8])


async def _notify_rebooked(state: RequestSession, event: dict) -> None:
    from app.tools import get_tools
    from app.tools.notifier import REBOOK_TEMPLATES
    from app.graph.state import Language

    tools = get_tools()
    intent = state.parsed_intent
    lang = intent.language if intent else Language.ENGLISH
    lang_key = lang.value

    # Resolve the failed provider's friendly name from the provider store so
    # the WhatsApp message reads "Ali AC Services ne confirm nahi kiya"
    # instead of the raw id "provider_01".
    failed_id = event.get("failed_provider_id", "")
    old_provider = await _resolve_provider_name(failed_id) or "previous provider"

    new_provider = state.booking.provider_name if state.booking else "new provider"
    time_str = (
        state.booking.slot_start.strftime("%H:%M")
        if state.booking
        else "the original time"
    )

    template = REBOOK_TEMPLATES.get(lang_key, REBOOK_TEMPLATES["en"])
    message = template.format(old=old_provider, new=new_provider, time=time_str)

    await tools.notifier.send(
        channel="whatsapp_mock",
        to=state.user_phone,
        message=message,
    )


async def _resolve_provider_name(provider_id: str) -> str | None:
    """Look up a provider's display name from the active ProviderStore.

    Returns ``None`` if the id is unknown or the lookup fails. Implemented
    on top of the existing `ProviderStore.search` protocol so it works
    with both `JsonProviderStore` and the (future) `GooglePlacesStore`.
    """
    if not provider_id:
        return None
    try:
        from app.graph.state import ServiceType
        from app.tools import get_tools
        store = get_tools().provider_store
        # Search a large radius around Islamabad centre with service=UNKNOWN
        # (which skips the service filter) and no exclusions.
        candidates = await store.search(
            service=ServiceType.UNKNOWN,
            lat=33.6938,
            lng=73.0652,
            radius_km=50.0,
            exclude=[],
        )
        for c in candidates:
            if c.id == provider_id:
                return c.name
    except Exception:
        logger.exception("Failed to resolve provider name for %s", provider_id)
    return None


async def _hand_off_to_user(state: RequestSession, event: dict) -> None:
    from app.tools import get_tools
    from app.tools.notifier import HANDOFF_TEMPLATES
    from app.graph.state import Language
    from app.graph.trace import emit_trace

    tools = get_tools()
    intent = state.parsed_intent
    lang = intent.language if intent else Language.ENGLISH

    async with emit_trace(
        state,
        agent="ConflictResolverAgent",
        phase="recover",
        triggered_by=state.triggered_by,
        input={"event": event.get("key"), "attempt": state.resolution_attempts},
    ) as t:
        top3 = [r.provider.name for r in state.ranked[:3]]
        t.set_output({"action": "hand_off", "alternatives": top3})
        t.set_reasoning("Exhausted auto-rebook attempts; handing off to user with top-3 alternatives")

    message = HANDOFF_TEMPLATES.get(lang.value, HANDOFF_TEMPLATES["en"])
    await tools.notifier.send(
        channel="whatsapp_mock",
        to=state.user_phone,
        message=message,
    )
