"""Conflict scenario tests: 5 scenarios from plan.md §9b."""

from __future__ import annotations

import asyncio
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
from zoneinfo import ZoneInfo

from app.graph.state import (
    BookingRecord,
    BookingStatus,
    Language,
    ParsedIntent,
    RequestSession,
    ServiceType,
    TimeWindow,
)

_TZ = ZoneInfo("Asia/Karachi")


def _make_state(session_id: str = "test-conflict") -> RequestSession:
    tomorrow = (datetime.now(_TZ) + timedelta(days=1)).replace(
        hour=10, minute=0, second=0, microsecond=0
    )
    state = RequestSession(
        id=session_id,
        user_id="test_user",
        raw_text="G-13 mein AC technician chahiye",
    )
    state.parsed_intent = ParsedIntent(
        language=Language.ROMAN_URDU,
        service_type=ServiceType.AC_TECHNICIAN,
        location_hint="G-13",
        time_window=TimeWindow(
            start=tomorrow,
            end=tomorrow.replace(hour=12),
            label="kal subah",
        ),
    )
    return state


def _make_booking(session_id: str, provider_id: str = "provider_01") -> BookingRecord:
    slot = datetime.now(_TZ) + timedelta(hours=1)
    return BookingRecord(
        id="booking-test-001",
        session_id=session_id,
        user_id="test_user",
        provider_id=provider_id,
        provider_name="Ali AC Services",
        service_type="ac_technician",
        slot_start=slot,
        slot_end=slot + timedelta(hours=2),
        status=BookingStatus.CONFIRMED,
        price_estimate=1500,
    )


# ── Scenario 1: No-show detection ─────────────────────────────────────────────


@pytest.mark.asyncio
async def test_noshow_watchdog_publishes_event():
    """_noshow_watchdog should mark CONFIRMED booking as NO_SHOW and publish event."""
    booking = _make_booking("session-noshow")

    mock_avail = AsyncMock()
    mock_avail.get_booking.return_value = booking

    published: list[tuple] = []

    async def capture_publish(key, payload):
        published.append((key, payload))

    # get_bus is imported lazily inside _noshow_watchdog; patch at source module
    mock_bus_instance = MagicMock()
    mock_bus_instance.publish = capture_publish

    # The scheduler now resolves Availability via get_tools().availability
    # (so the same singleton instance is used everywhere). We patch the
    # Tools container so the test stays decoupled from the real DB.
    mock_tools = MagicMock()
    mock_tools.availability = mock_avail

    with (
        patch("app.tools.get_tools", return_value=mock_tools),
        patch("app.events.bus.get_bus", return_value=mock_bus_instance),
    ):
        from app.scheduler.reminders import _noshow_watchdog
        await _noshow_watchdog(booking.id)

    mock_avail.update_status.assert_called_once_with(booking.id, "NO_SHOW")
    assert len(published) == 1
    key, payload = published[0]
    assert key == "no_show_detected"
    assert payload["failed_provider_id"] == booking.provider_id


# ── Scenario 2: User cancellation ─────────────────────────────────────────────


@pytest.mark.asyncio
async def test_user_cancellation_event_structure():
    """Cancellation with rebook=True should publish user_cancellation event."""
    state = _make_state("session-cancel")
    state.booking = _make_booking("session-cancel")

    from app.graph import conflict_resolver
    conflict_resolver.register_session(state)

    published_events = []

    # EventBus.publish is an instance method: self, key, payload
    async def mock_publish(self, key, payload):
        published_events.append((key, payload))

    with patch("app.events.bus.EventBus.publish", new=mock_publish):
        from app.events.bus import get_bus
        await get_bus().publish(
            "user_cancellation",
            {
                "session_id": state.id,
                "booking_id": state.booking.id,
                "failed_provider_id": state.booking.provider_id,
                "rebook": True,
            },
        )

    assert any(k == "user_cancellation" for k, _ in published_events)


# ── Scenario 3: Provider unavailable (proactive) ───────────────────────────────


@pytest.mark.asyncio
async def test_provider_unavailable_event():
    """provider_unavailable event should contain session_id and failed_provider_id."""
    state = _make_state("session-unavail")
    state.booking = _make_booking("session-unavail", "provider_01")

    from app.graph import conflict_resolver
    conflict_resolver.register_session(state)

    received = {}

    async def capture_handler(event: dict):
        received.update(event)

    from app.events.bus import get_bus
    get_bus().subscribe("provider_unavailable", capture_handler)

    await get_bus().publish(
        "provider_unavailable",
        {
            "session_id": state.id,
            "failed_provider_id": "provider_01",
            "booking_id": state.booking.id,
        },
    )

    # Give background task time to run
    await asyncio.sleep(0.05)
    assert received.get("failed_provider_id") == "provider_01"
    assert received.get("session_id") == state.id


# ── Scenario 4: Double-booking race (SlotConflict) ────────────────────────────


@pytest.mark.asyncio
async def test_slot_conflict_raises():
    """check_and_hold must raise SlotConflict on UNIQUE constraint violation."""
    from app.graph.errors import SlotConflict as SlotConflictError
    from sqlalchemy.exc import IntegrityError

    # Build a proper async context manager chain that simulates the DB session.
    # `db.add` is synchronous in SQLAlchemy so use a plain MagicMock for it
    # (AsyncMock would return a coroutine that is never awaited).
    mock_db = AsyncMock()
    mock_db.add = MagicMock(return_value=None)
    mock_db.flush = AsyncMock(side_effect=IntegrityError("UNIQUE", None, None))

    # begin() returns an async context manager that yields mock_db
    begin_ctx = AsyncMock()
    begin_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    begin_ctx.__aexit__ = AsyncMock(return_value=False)
    mock_db.begin = MagicMock(return_value=begin_ctx)

    # get_raw_session() is an async function that returns an async context manager
    session_ctx = AsyncMock()
    session_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    session_ctx.__aexit__ = AsyncMock(return_value=False)

    async def fake_get_raw_session():
        return session_ctx

    with patch("app.tools.availability.get_raw_session", side_effect=fake_get_raw_session):
        from app.tools.availability import SqliteAvailability
        avail = SqliteAvailability()
        slot = datetime.now(_TZ) + timedelta(hours=2)

        with pytest.raises(SlotConflictError) as exc_info:
            await avail.check_and_hold(
                provider_id="provider_01",
                slot_start=slot,
                slot_end=slot + timedelta(hours=2),
                session_id="test-race",
                user_id="user1",
                provider_name="Ali AC Services",
                service_type="ac_technician",
                price_estimate=1500,
            )

        assert exc_info.value.provider_id == "provider_01"


# ── Scenario 5: Resolution attempts cap ────────────────────────────────────────


@pytest.mark.asyncio
async def test_resolution_cap():
    """After 3 attempts, handle() should call _hand_off_to_user and NOT retry."""
    state = _make_state("session-cap")
    state.resolution_attempts = 3  # already at cap

    from app.graph import conflict_resolver
    conflict_resolver.register_session(state)

    with patch("app.graph.conflict_resolver._hand_off_to_user", new_callable=AsyncMock) as mock_handoff:
        with patch("app.graph.conflict_resolver.conflict_node") as mock_node:
            await conflict_resolver.handle(
                {
                    "key": "no_show_detected",
                    "session_id": state.id,
                    "failed_provider_id": "provider_01",
                }
            )
            # Should NOT enter conflict_node.run
            mock_node.run.assert_not_called()
            # Should hand off to user
            mock_handoff.assert_called_once()

    assert state.resolution_attempts == 3  # unchanged


@pytest.mark.asyncio
async def test_resolution_increments_attempts():
    """Each handle() call should increment resolution_attempts, hit the
    conflict + discovery nodes once, push the failed provider onto the
    exclude list, and hand off when discovery returns no candidates."""
    state = _make_state("session-inc")
    state.resolution_attempts = 0

    from app.graph import conflict_resolver
    conflict_resolver.register_session(state)

    mock_conflict = AsyncMock(return_value=state)
    mock_discovery = AsyncMock(return_value=state)
    mock_handoff = AsyncMock()

    with (
        patch("app.graph.conflict_resolver.conflict_node.run", mock_conflict),
        patch("app.graph.conflict_resolver.discovery.run", mock_discovery),
        patch("app.graph.conflict_resolver._hand_off_to_user", mock_handoff),
    ):
        state.candidates = []  # Force hand-off after increment
        await conflict_resolver.handle(
            {"key": "no_show_detected", "session_id": state.id, "failed_provider_id": "provider_01"}
        )

    assert state.resolution_attempts == 1
    assert "provider_01" in state.excluded_provider_ids
    assert state.triggered_by == "no_show_detected:provider_01"
    assert mock_conflict.await_count == 1
    assert mock_discovery.await_count == 1
    assert mock_handoff.await_count == 1, "should have handed off (no candidates)"
