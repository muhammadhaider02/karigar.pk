"""FastAPI routes — the HTTP/SSE contract for the Flutter app.

Contract (source of truth for flutter-engineer):

POST   /sessions                        → {session_id, status}
GET    /sessions/{id}                   → full session snapshot (trace[])
GET    /sessions/{id}/stream            → SSE stream of TraceEvent until done
GET    /sessions/{id}/trace.md          → Markdown export of the trace
GET    /bookings                        → list bookings for user_id query param
POST   /bookings/{id}/cancel            → cancel (and optionally rebook)
POST   /bookings/{id}/arrived           → mark provider arrived (cancels watchdog)
POST   /bookings/{id}/complete          → mark COMPLETED
POST   /providers/{id}/unavailable      → proactive conflict trigger
POST   /sessions/{id}/reschedule        → reschedule with new time_window
GET    /receipts/{booking_id}.png       → serve the PNG receipt for a booking
GET    /notifier-log                    → mock WhatsApp message log
GET    /health                          → {"status": "ok"}
"""

from __future__ import annotations

import asyncio
import json
import logging
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from fastapi.responses import FileResponse, PlainTextResponse
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

from app.events.bus import get_bus
from app.graph import conflict_resolver, orchestrator
from app.graph.state import BookingStatus, RequestSession, TraceEvent
from app.tools import get_tools
from app.tools import bookings as bookings_crud
from app.scheduler.reminders import cancel_booking_jobs

router = APIRouter()
logger = logging.getLogger(__name__)

# ── In-memory session store (keyed by session_id) ─────────────────────────────
# Shared with conflict_resolver so it can reload state on events.
_sessions = conflict_resolver._sessions


# ── Request / Response models ──────────────────────────────────────────────────

class StartSessionRequest(BaseModel):
    user_id: str
    raw_text: str
    user_phone: str = "0300-000-0000"


class StartSessionResponse(BaseModel):
    session_id: str
    status: str = "started"


class CancelRequest(BaseModel):
    rebook: bool = False


class RescheduleRequest(BaseModel):
    new_time_window: dict  # {start, end, label}


class ProviderUnavailableRequest(BaseModel):
    session_id: str


# ── Helpers ────────────────────────────────────────────────────────────────────

def _session_or_404(session_id: str) -> RequestSession:
    state = _sessions.get(session_id)
    if state is None:
        raise HTTPException(status_code=404, detail=f"Session {session_id} not found")
    return state


# ── Routes ────────────────────────────────────────────────────────────────────


@router.get("/health")
async def health():
    return {"status": "ok"}


@router.post("/sessions", response_model=StartSessionResponse)
async def start_session(req: StartSessionRequest, background_tasks: BackgroundTasks):
    import uuid
    session_id = str(uuid.uuid4())

    # Register the SSE queue BEFORE we hand work off to the background task,
    # otherwise a fast client that calls GET /sessions/{id}/stream immediately
    # would race with the background task and get a 404.
    get_bus().register_session(session_id)

    background_tasks.add_task(_run_graph_in_background, session_id, req)

    return StartSessionResponse(session_id=session_id)


async def _run_graph_in_background(session_id: str, req: StartSessionRequest) -> None:
    from app.graph.errors import SlotConflict

    bus = get_bus()
    try:
        updated_state = await orchestrator.run_session(
            session_id=session_id,
            user_id=req.user_id,
            raw_text=req.raw_text,
            user_phone=req.user_phone,
        )
        _sessions[session_id] = updated_state
        conflict_resolver.register_session(updated_state)
        await bus.publish_done(session_id, "completed")
    except SlotConflict as exc:
        # Happy path failed at the booking step → hand off to the conflict
        # resolver via the event bus. Publishing here (rather than from
        # booking.py) guarantees exactly one resolver flow per failure.
        logger.info(
            "SlotConflict on session %s (provider=%s); dispatching to resolver",
            session_id[:8],
            exc.provider_id,
        )
        partial = conflict_resolver.get_session(session_id)
        if partial:
            _sessions[session_id] = partial
        await bus.publish(
            "slot_conflict",
            {"session_id": session_id, "failed_provider_id": exc.provider_id},
        )
        # Do not publish_done here — the resolver will when it finishes.
    except Exception as exc:
        logger.error("Graph error for session %s: %s", session_id[:8], exc)
        partial = conflict_resolver.get_session(session_id)
        if partial:
            _sessions[session_id] = partial
        await bus.publish_done(session_id, f"error: {exc}")


@router.get("/sessions/{session_id}")
async def get_session(session_id: str):
    state = _session_or_404(session_id)
    return {
        "session_id": state.id,
        "user_id": state.user_id,
        "raw_text": state.raw_text,
        "parsed_intent": state.parsed_intent.model_dump(mode="json") if state.parsed_intent else None,
        "candidates_count": len(state.candidates),
        "ranked_count": len(state.ranked),
        "chosen": state.chosen.model_dump(mode="json") if state.chosen else None,
        "booking": state.booking.model_dump(mode="json") if state.booking else None,
        "trace_count": len(state.trace),
        "resolution_attempts": state.resolution_attempts,
    }


@router.get("/sessions/{session_id}/stream")
async def stream_session(session_id: str):
    """SSE stream of TraceEvent objects until a 'done' event."""
    q = get_bus().get_session_queue(session_id)
    if q is None:
        raise HTTPException(status_code=404, detail="Session SSE queue not found")

    async def event_generator():
        while True:
            try:
                event_type, data = await asyncio.wait_for(q.get(), timeout=30.0)
                yield {"event": event_type, "data": data}
                if event_type == "done":
                    break
            except asyncio.TimeoutError:
                yield {"event": "ping", "data": "{}"}

    return EventSourceResponse(event_generator())


@router.get("/sessions/{session_id}/trace.md")
async def export_trace(session_id: str):
    """Export the agent trace as a Markdown artifact."""
    state = _session_or_404(session_id)
    lines = [f"# Karigar Agent Trace — Session {session_id[:8]}\n"]
    lines.append(f"**Query:** {state.raw_text}\n")
    if state.parsed_intent:
        pi = state.parsed_intent
        lines.append(
            f"**Intent:** {pi.service_type.value} · {pi.location_hint} · "
            f"{pi.language.value} · urgency={pi.urgency}\n"
        )
    lines.append("\n---\n")
    for evt in state.trace:
        lines.append(f"## Step {evt.step}: {evt.agent} [{evt.phase.upper()}] ({evt.latency_ms}ms)\n")
        lines.append(f"**Reasoning:** {evt.reasoning}\n")
        if evt.tool_calls:
            lines.append("**Tool calls:**\n")
            for tc in evt.tool_calls:
                lines.append(f"- `{tc.name}` → `{json.dumps(tc.result, default=str)[:120]}`\n")
        lines.append(f"**Output:** `{json.dumps(evt.output, default=str)[:200]}`\n\n")

    return PlainTextResponse("".join(lines), media_type="text/markdown")


@router.get("/bookings")
async def list_bookings(user_id: str = Query(...)):
    records = await bookings_crud.list_for_user(user_id)
    return [r.model_dump(mode="json") for r in records]


@router.post("/bookings/{booking_id}/cancel")
async def cancel_booking(booking_id: str, req: CancelRequest):
    booking = await bookings_crud.get(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    cancel_booking_jobs(booking_id)
    await bookings_crud.transition(booking_id, BookingStatus.CANCELLED)

    if req.rebook:
        await get_bus().publish(
            "user_cancellation",
            {
                "session_id": booking.session_id,
                "booking_id": booking_id,
                "failed_provider_id": booking.provider_id,
                "rebook": True,
            },
        )

    return {"status": "cancelled", "rebook": req.rebook}


@router.post("/bookings/{booking_id}/arrived")
async def mark_arrived(booking_id: str):
    cancel_booking_jobs(booking_id)
    await bookings_crud.transition(booking_id, BookingStatus.CONFIRMED)
    return {"status": "arrived"}


@router.post("/bookings/{booking_id}/complete")
async def mark_complete(booking_id: str):
    await bookings_crud.transition(booking_id, BookingStatus.COMPLETED)
    return {"status": "completed"}


@router.post("/providers/{provider_id}/unavailable")
async def provider_unavailable(provider_id: str, req: ProviderUnavailableRequest):
    state = _sessions.get(req.session_id)
    if not state or not state.booking:
        raise HTTPException(status_code=404, detail="Session or booking not found")

    # Cancel the pending no-show watchdog + reminder so we don't double-fire
    # a conflict event once the resolver has already kicked off.
    cancel_booking_jobs(state.booking.id)
    await bookings_crud.transition(state.booking.id, BookingStatus.CANCELLED)
    await get_bus().publish(
        "provider_unavailable",
        {
            "session_id": req.session_id,
            "failed_provider_id": provider_id,
            "booking_id": state.booking.id,
        },
    )
    return {"status": "conflict_triggered"}


@router.post("/sessions/{session_id}/reschedule")
async def reschedule(session_id: str, req: RescheduleRequest):
    await get_bus().publish(
        "reschedule_requested",
        {"session_id": session_id, "new_time_window": req.new_time_window},
    )
    return {"status": "reschedule_queued"}


@router.get("/receipts/{booking_id}.png")
async def get_receipt(booking_id: str):
    """Serve the PNG receipt for a booking by looking up its stored path.

    This avoids the previous bug where the route guessed the filename
    (full id + `.txt`) while the renderer wrote `<id[:8]>.txt`, and
    avoids depending on the process's current working directory.
    """
    booking = await bookings_crud.get(booking_id)
    if booking is None or not booking.receipt_png_path:
        raise HTTPException(status_code=404, detail="Receipt not found")

    receipt_path = Path(booking.receipt_png_path)
    if not receipt_path.exists():
        raise HTTPException(status_code=404, detail="Receipt file missing on disk")

    return FileResponse(str(receipt_path), media_type="image/png")


@router.get("/notifier-log")
async def get_notifier_log():
    tools = get_tools()
    return await tools.notifier.get_log()
