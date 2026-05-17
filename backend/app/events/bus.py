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
        # Conflict event subscribers: key → list of handlers
        self._subscribers: dict[str, list[Callable[[dict], Awaitable[None]]]] = defaultdict(list)
        # SSE queues: session_id → asyncio.Queue of serialised events
        self._sse_queues: dict[str, asyncio.Queue] = {}

    def subscribe(self, key: str, handler: Callable[[dict], Awaitable[None]]) -> None:
        self._subscribers[key].append(handler)

    async def publish(self, key: str, payload: dict) -> None:
        """Publish a conflict event to all subscribers."""
        # Persist to DB
        try:
            await _persist_event(key, payload)
        except Exception:
            pass
        # Notify subscribers
        for handler in self._subscribers.get(key, []):
            asyncio.create_task(handler(payload))

    # ── SSE / Trace streaming ──────────────────────────────────────────────

    def register_session(self, session_id: str) -> asyncio.Queue:
        """Create an SSE queue for a session. Returns the queue."""
        q: asyncio.Queue = asyncio.Queue(maxsize=200)
        self._sse_queues[session_id] = q
        return q

    def get_session_queue(self, session_id: str) -> asyncio.Queue | None:
        return self._sse_queues.get(session_id)

    async def publish_trace(self, session_id: str, event: TraceEvent) -> None:
        """Push a serialised trace event to the SSE queue for this session."""
        q = self._sse_queues.get(session_id)
        if q is not None:
            data = event.model_dump_json()
            try:
                q.put_nowait(("trace", data))
            except asyncio.QueueFull:
                pass  # Drop if queue is full — client will poll fallback

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
    import json as _json
    from app.db.models import ConflictEventModel
    from app.db.session import get_raw_session

    row = ConflictEventModel(
        key=key,
        session_id=payload.get("session_id", ""),
        failed_provider_id=payload.get("failed_provider_id"),
        payload=_json.dumps(payload, ensure_ascii=False, default=str),
    )
    async with await get_raw_session() as db:
        async with db.begin():
            db.add(row)
