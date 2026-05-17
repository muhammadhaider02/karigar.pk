"""FollowupAgent: schedules APScheduler reminder and watchdog jobs."""

from __future__ import annotations

from app.graph.state import RequestSession
from app.graph.trace import emit_trace


async def run(state: RequestSession) -> RequestSession:
    booking = state.booking
    assert booking is not None, "FollowupAgent requires a booking"

    async with emit_trace(
        state,
        agent="FollowupAgent",
        phase="follow_up",
        input={"booking_id": booking.id, "slot_start": booking.slot_start.isoformat()},
    ) as t:
        from app.scheduler.reminders import schedule_booking_jobs

        job_ids = await schedule_booking_jobs(booking)

        t.add_tool_call(
            "APScheduler.schedule",
            {
                "booking_id": booking.id,
                "slot_start": booking.slot_start.isoformat(),
            },
            {"job_ids": job_ids},
        )
        t.set_output({"scheduled_jobs": job_ids})
        t.set_reasoning(
            f"Scheduled T-1h reminder, T+15min no-show watchdog, "
            f"T+2h completion check for booking #{booking.id[:8]}"
        )

    return state
