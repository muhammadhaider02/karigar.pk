"""Event handlers: wire the bus to the conflict resolver at startup."""

from __future__ import annotations

from app.events.bus import get_bus
from app.graph import conflict_resolver


def register_handlers() -> None:
    """Subscribe the conflict resolver to all 5 event types."""
    bus = get_bus()
    for key in (
        "no_show_detected",
        "user_cancellation",
        "provider_unavailable",
        "slot_conflict",
        "reschedule_requested",
    ):
        bus.subscribe(key, conflict_resolver.handle)
