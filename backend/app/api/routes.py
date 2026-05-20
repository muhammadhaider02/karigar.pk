"""FastAPI routes — the HTTP/SSE contract for the Flutter app.

Contract (source of truth for flutter-engineer):

POST   /sessions                        → {session_id, status}
GET    /sessions/{id}                   → full session snapshot (trace[])
GET    /sessions/{id}/stream            → SSE stream of TraceEvent until done
GET    /sessions/{id}/trace             → polling: list of trace events
GET    /sessions/{id}/trace.md          → Markdown export of the trace
GET    /bookings                        → list bookings for user_id query param
POST   /bookings/{id}/cancel            → cancel (and optionally rebook)
POST   /bookings/{id}/arrived           → mark provider arrived (cancels watchdog)
POST   /bookings/{id}/complete          → mark COMPLETED
POST   /providers/{id}/unavailable      → proactive conflict trigger
POST   /sessions/{id}/reschedule        → reschedule with new time_window
GET    /notifier-log                    → mock WhatsApp message log
GET    /health                          → {"status": "ok"}
GET    /roles                           → [{id, display_name, worker_count}] all service categories
GET    /workers?role=                   → [{id, name, rating, area, price_per_visit, phone}]
POST   /transcribe                      → {text} transcribe base64 audio via Gemini multimodal
"""

from __future__ import annotations

import asyncio
import json
import logging
import uuid
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from sse_starlette.sse import EventSourceResponse

from langchain_core.messages import HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI

from app.config import get_settings
from app.events.bus import get_bus
from app.graph import conflict_resolver, orchestrator
from app.graph.state import BookingStatus, RequestSession
from app.tools import get_tools
from app.tools import bookings as bookings_crud
from app.scheduler.reminders import cancel_booking_jobs

router = APIRouter()
logger = logging.getLogger(__name__)

# In-memory session store (keyed by session_id)
_sessions = conflict_resolver._sessions


# ── Request / Response models ──────────────────────────────────────────────────

class StartSessionRequest(BaseModel):
    user_id: str
    raw_text: str
    user_phone: str = "0300-0000000"
    language: str = "english"
    lat: Optional[float] = None  # device GPS latitude
    lng: Optional[float] = None  # device GPS longitude


class StartSessionResponse(BaseModel):
    session_id: str
    status: str = "started"


class CancelRequest(BaseModel):
    rebook: bool = False


class RescheduleRequest(BaseModel):
    new_time_window: dict  # {start, end, label}


class ProviderUnavailableRequest(BaseModel):
    session_id: str


class TranscribeRequest(BaseModel):
    audio_data: str          # base64-encoded audio bytes
    mime_type: str = "audio/wav"  # audio/wav | audio/mp3 | audio/ogg


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


@router.post("/transcribe")
async def transcribe_audio(req: TranscribeRequest):
    """Transcribe base64-encoded audio to text using Gemini 2.5 Flash multimodal.
    When DEMO_MODE=true returns a canned plumber query so the full flow can be
    tested without spending Gemini API credits."""
    settings = get_settings()
    if settings.demo_mode:
        return {"text": "G-13 mein plumber chahiye"}
    try:
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=settings.google_api_key,
            temperature=0.0,
        )
        message = HumanMessage(content=[
            {
                "type": "media",
                "data": req.audio_data,
                "mime_type": req.mime_type,
            },
            {
                "type": "text",
                "text": (
                    "Transcribe this audio exactly as spoken. "
                    "The speaker may use Urdu (Nastaliq or Roman script), English, or mix them. "
                    "Return ONLY the transcription — no explanation, no labels."
                ),
            },
        ])
        response = await llm.ainvoke([message])
        return {"text": response.content.strip()}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@router.post("/sessions", response_model=StartSessionResponse)
async def start_session(req: StartSessionRequest, background_tasks: BackgroundTasks):
    session_id = str(uuid.uuid4())

    # Register SSE queue before handing off
    get_bus().register_session(session_id)

    # Register placeholder session so trace polling works immediately
    _sessions[session_id] = RequestSession(
        id=session_id,
        user_id=req.user_id,
        raw_text=req.raw_text,
        override_lat=req.lat,
        override_lng=req.lng,
    )

    # Persist session row in Supabase so agent_traces FK is valid
    try:
        from app.db.supabase_client import get_supabase
        supabase = await get_supabase()
        await supabase.table("sessions").insert({
            "id": session_id,
            "customer_id": req.user_id,
            "raw_text": req.raw_text,
            "user_phone": req.user_phone,
            "status": "running",
        }).execute()
    except Exception as exc:
        # FK violation (test user without a customer row) or network error.
        # In-memory pipeline still works; traces just won't persist.
        logger.warning("Could not persist session row to Supabase: %s", exc)

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

        # Mark session completed in Supabase
        try:
            from app.db.supabase_client import get_supabase
            from datetime import datetime
            supabase = await get_supabase()
            await supabase.table("sessions").update({
                "status": "completed",
                "completed_at": datetime.utcnow().isoformat(),
            }).eq("id", session_id).execute()
        except Exception:
            pass

        await bus.publish_done(session_id, "completed")
    except SlotConflict as exc:
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
    except Exception as exc:
        logger.error("Graph error for session %s: %s", session_id[:8], exc)
        partial = conflict_resolver.get_session(session_id)
        if partial:
            _sessions[session_id] = partial

        try:
            from app.db.supabase_client import get_supabase
            supabase = await get_supabase()
            await supabase.table("sessions").update({"status": "failed"}).eq("id", session_id).execute()
        except Exception:
            pass

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


@router.get("/sessions/{session_id}/trace")
async def get_session_trace(session_id: str):
    state = _session_or_404(session_id)
    return [evt.model_dump(mode="json") for evt in state.trace]


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


@router.get("/notifier-log")
async def get_notifier_log():
    tools = get_tools()
    return await tools.notifier.get_log()


@router.get("/roles")
async def list_roles():
    """Return all service categories with display names and live worker counts."""
    from app.db.supabase_client import get_supabase
    from app.graph.state import ServiceType, _SERVICE_DISPLAY

    supabase = await get_supabase()
    result = await supabase.rpc("get_role_counts").execute()

    # Build a count map from the RPC result; fall back to 0 for any missing role.
    count_map: dict[str, int] = {}
    if result.data:
        for row in result.data:
            count_map[row["role"]] = row["worker_count"]

    roles = []
    for service_type in ServiceType:
        if service_type == ServiceType.UNKNOWN:
            continue
        roles.append({
            "id": service_type.value,
            "display_name": _SERVICE_DISPLAY.get(service_type, service_type.value.replace("_", " ").title()),
            "worker_count": count_map.get(service_type.value, 0),
        })

    # Sort by worker_count desc so most-available categories appear first.
    roles.sort(key=lambda r: r["worker_count"], reverse=True)
    return roles


@router.get("/workers")
async def list_workers_by_role(role: str = Query(..., description="ServiceType value, e.g. ac_technician")):
    """Return workers for a given role ordered by rating descending."""
    from app.db.supabase_client import get_supabase

    supabase = await get_supabase()
    result = (
        await supabase.table("workers")
        .select("id, full_name, rating, area, rate_per_hour, phone_number, home_lat, home_lng, skills, working_hours, busy_slots")
        .contains("skills", [role])
        .eq("verification_status", "verified")
        .eq("is_available", True)
        .order("rating", desc=True)
        .execute()
    )

    workers = []
    for row in (result.data or []):
        workers.append({
            "id": str(row["id"]),
            "name": row.get("full_name", ""),
            "rating": float(row.get("rating") or 0),
            "area": row.get("area", ""),
            "price_per_visit": int(row.get("rate_per_hour") or 0),
            "phone": row.get("phone_number", ""),
            "home_lat": float(row.get("home_lat") or 0),
            "home_lng": float(row.get("home_lng") or 0),
            "skills": row.get("skills") or [],
            "working_hours": row.get("working_hours") or {},
            "busy_slots": row.get("busy_slots") or [],
        })

    return workers
