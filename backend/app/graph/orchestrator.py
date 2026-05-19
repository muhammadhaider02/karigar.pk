"""Happy-path LangGraph orchestrator.

Graph:  Intent → PlanningStep → Discovery → Ranking → Decision → Booking → Followup

The PlanningStep is owned by the Orchestrator (not a separate node) and emits a
single 'plan' trace event listing the upcoming 5 steps.
"""

from __future__ import annotations

from app.graph.errors import ProviderNotFound
from app.graph.state import RequestSession
from app.graph.trace import emit_trace

MAX_RESOLUTION_ATTEMPTS = 3


async def _planning_step(state: RequestSession) -> RequestSession:
    """Emit the Plan trace event — makes the planning phase visible in the trace."""
    intent = state.parsed_intent
    service = intent.service_type.pretty_name if intent else "service"
    location = intent.location_hint if intent else "your location"
    time_label = (
        intent.time_window.label if (intent and intent.time_window) else "at your convenience"
    )

    plan_steps = [
        f"1. Resolve '{location}' to coordinates",
        f"2. Find {service} providers within 5km",
        f"3. Rank by distance + rating + availability + price",
        f"4. Select best match and justify in {intent.language.value if intent else 'en'}",
        f"5. Book slot for {time_label}, send confirmation, schedule reminders",
    ]

    async with emit_trace(
        state,
        agent="Orchestrator",
        phase="plan",
        input={"parsed_intent": intent.model_dump(mode="json") if intent else {}},
    ) as t:
        t.set_output({"plan": plan_steps})
        t.set_reasoning(" | ".join(plan_steps))

    return state


async def run_session(
    session_id: str,
    user_id: str,
    raw_text: str,
    user_phone: str = "0300-000-0000",
) -> RequestSession:
    """Run the full happy-path graph for a new session."""
    from app.graph import conflict_resolver as cr
    from app.api import routes as _routes

    # Reuse the placeholder session registered by POST /sessions so that
    # /sessions/{id}/trace can stream partial progress while the graph runs.
    state = _routes._sessions.get(session_id)
    if state is None:
        state = RequestSession(
            id=session_id,
            user_id=user_id,
            raw_text=raw_text,
            user_phone=user_phone,
        )
        _routes._sessions[session_id] = state
    else:
        state.user_phone = user_phone

    from app.graph.nodes import intent, discovery, ranking, decision, booking, followup

    # Step 1: Intent parsing
    state = await intent.run(state)
    # Register AFTER intent so parsed_intent is available to conflict resolver
    cr.register_session(state)

    # Step 2: Planning step (orchestrator-owned)
    state = await _planning_step(state)
    cr.register_session(state)

    # Step 3: Discovery
    state = await discovery.run(state)
    cr.register_session(state)

    # Guard: no candidates
    if not state.candidates:
        pi = state.parsed_intent
        raise ProviderNotFound(
            service=pi.service_type.value if pi else "unknown",
            location=pi.location_hint if pi else "unknown",
        )

    # Step 4: Ranking
    state = await ranking.run(state)
    cr.register_session(state)

    # Step 5: Decision
    state = await decision.run(state)
    cr.register_session(state)

    if not state.chosen:
        raise ProviderNotFound(service="", location="")

    # Step 6: Booking (may raise SlotConflict — caught by caller / conflict resolver)
    state = await booking.run(state)
    cr.register_session(state)

    # Step 7: Follow-up
    state = await followup.run(state)
    cr.register_session(state)

    return state

