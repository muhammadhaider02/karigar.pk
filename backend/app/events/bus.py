"""In-process event bus for conflict events.

Subscribers register async handlers keyed by event type.
Trace events are published to per-session SSE queues.
"""

from __future__ import annotations

import asyncio
import json
from collections import defaultdict
from typing import Awaitable, Callable

from app.graph.state import TraceEvent


class EventBus:
    def __init__(self) -> None:
        self._subscribers: dict[str, list[Callable[[dict], Awaitable[None]]]] = defaultdict(list)
        self._sse_queues: dict[str, asyncio.Queue] = {}

    def subscribe(self, key: str, handler: Callable[[dict], Awaitable[None]]) -> None:
        self._subscribers[key].append(handler)

    async def publish(self, key: str, payload: dict) -> None:
        """Publish a conflict event to all subscribers."""
        try:
            await _persist_event(key, payload)
        except Exception:
            pass
        for handler in self._subscribers.get(key, []):
            asyncio.create_task(handler(payload))

    # ── SSE / Trace streaming ──────────────────────────────────────────────

    def register_session(self, session_id: str) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue(maxsize=200)
        self._sse_queues[session_id] = q
        return q

    def get_session_queue(self, session_id: str) -> asyncio.Queue | None:
        return self._sse_queues.get(session_id)

    async def publish_trace(self, session_id: str, event: TraceEvent) -> None:
        q = self._sse_queues.get(session_id)
        if q is not None:
            data = event.model_dump_json()
            try:
                q.put_nowait(("trace", data))
            except asyncio.QueueFull:
                pass

    async def publish_done(self, session_id: str, status: str = "completed") -> None:
        q = self._sse_queues.get(session_id)
        if q is not None:
            data = json.dumps({"session_id": session_id, "status": status})
            try:
                q.put_nowait(("done", data))
            except asyncio.QueueFull:
                pass

    def deregister_session(self, session_id: str) -> None:
        self._sse_queues.pop(session_id, None)


# ── Singleton ─────────────────────────────────────────────────────────────────

_bus: EventBus | None = None


def get_bus() -> EventBus:
    global _bus
    if _bus is None:
        _bus = EventBus()
    return _bus


# ── DB persistence ────────────────────────────────────────────────────────────

async def _persist_event(key: str, payload: dict) -> None:
    from app.db.supabase_client import get_supabase
    supabase = await get_supabase()
    await supabase.table("conflict_events").insert({
        "session_id": payload.get("session_id", ""),
        "event_type": key,
        "failed_worker_id": payload.get("failed_provider_id"),
        "payload": payload,
    }).execute()
