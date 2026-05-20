"""BookingAgent: atomic slot-hold → persist → receipt → notify."""

from __future__ import annotations

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from app.graph.errors import SlotConflict
from app.graph.state import BookingStatus, RequestSession
from app.graph.trace import emit_trace
from app.tools import get_tools
from app.tools import bookings as bookings_crud
from app.tools.notifier import build_confirmation_message

_TZ = ZoneInfo("Asia/Karachi")


async def run(state: RequestSession) -> RequestSession:
    tools = get_tools()
    chosen = state.chosen
    intent = state.parsed_intent
    assert chosen is not None, "BookingAgent requires chosen provider"

    # Determine slot times
    if chosen.slot_start and chosen.slot_end:
        slot_start = chosen.slot_start
        slot_end = chosen.slot_end
    elif intent and intent.time_window:
        slot_start = intent.time_window.start
        slot_end = slot_start + timedelta(hours=2)
    else:
        now = datetime.now(_TZ)
        slot_start = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)
        slot_end = slot_start + timedelta(hours=2)

    async with emit_trace(
        state,
        agent="BookingAgent",
        phase="act",
        input={
            "provider_id": chosen.provider.id,
            "provider_name": chosen.provider.name,
            "slot_start": slot_start.isoformat(),
            "slot_end": slot_end.isoformat(),
        },
    ) as t:
        # Step 1: Atomic hold
        try:
            booking = await tools.availability.check_and_hold(
                provider_id=chosen.provider.id,
                slot_start=slot_start,
                slot_end=slot_end,
                session_id=state.id,
                user_id=state.user_id,
                provider_name=chosen.provider.name,
                service_type=intent.service_type.value if intent else "unknown",
                price_estimate=chosen.provider.price_per_visit,
            )
            t.add_tool_call(
                "Availability.check_and_hold",
                {"provider_id": chosen.provider.id, "slot_start": slot_start.isoformat()},
                {"booking_id": booking.id, "status": "PENDING"},
            )
        except SlotConflict as exc:
            t.add_tool_call(
                "Availability.check_and_hold",
                {"provider_id": chosen.provider.id, "slot_start": slot_start.isoformat()},
                {"error": "SlotConflict"},
            )
            t.set_output({"error": "SlotConflict", "provider_id": exc.provider_id})
            t.set_reasoning(
                f"Slot conflict on {exc.provider_id} at {exc.slot_start}; "
                "routing to Conflict Resolver"
            )
            # NOTE: deliberately do NOT publish the "slot_conflict" bus event here.
            # The caller (orchestrator on happy path, or conflict_resolver itself)
            # owns conflict dispatch. Publishing here used to spawn a *parallel*
            # conflict_resolver.handle() task that raced with the recursive call
            # inside conflict_resolver, producing duplicate bookings.
            raise

        # Step 2: Confirm + receipt
        booking.status = BookingStatus.CONFIRMED
        location_hint = intent.location_hint if intent else ""
        receipt_url = await bookings_crud.render_and_upload_receipt(booking, chosen.provider, location_hint)
        booking.receipt_url = receipt_url
        await bookings_crud.persist(booking)
        t.add_tool_call(
            "Bookings.create",
            {"booking_id": booking.id},
            {"status": "CONFIRMED", "receipt_url": receipt_url},
        )

        # Step 3: WhatsApp notification
        language = intent.language if intent else None
        from app.graph.state import Language
        lang = language if language else Language.ENGLISH
        message = build_confirmation_message(booking, chosen.provider, lang, location_hint)
        await tools.notifier.send(
            channel="whatsapp_mock",
            to=state.user_phone,
            message=message,
        )
        t.add_tool_call(
            "Notifier.send",
            {"channel": "whatsapp_mock", "to": state.user_phone},
            {"sent": True},
        )

        state.booking = booking
        t.set_output(
            {
                "booking_id": booking.id,
                "slot": slot_start.isoformat(),
                "status": "CONFIRMED",
            }
        )
        t.set_reasoning(
            f"Booked {chosen.provider.name} for "
            f"{slot_start.strftime('%H:%M')}; receipt #{booking.id[:8]}"
        )

    return state
