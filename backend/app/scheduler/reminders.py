"""APScheduler jobs: reminder, no-show watchdog, and completion check."""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from typing import TYPE_CHECKING

from apscheduler.schedulers.asyncio import AsyncIOScheduler

if TYPE_CHECKING:
    from app.graph.state import BookingRecord

logger = logging.getLogger(__name__)

_scheduler: AsyncIOScheduler | None = None


def get_scheduler() -> AsyncIOScheduler:
    global _scheduler
    if _scheduler is None:
        _scheduler = AsyncIOScheduler()
    return _scheduler


def _scaled_timedelta(real_seconds: int) -> timedelta:
    from app.config import get_settings
    scale = get_settings().demo_time_scale
    return timedelta(seconds=real_seconds / max(scale, 1))


async def schedule_booking_jobs(booking: "BookingRecord") -> list[str]:
    """Register reminder, watchdog, and completion jobs. Returns job IDs."""
    scheduler = get_scheduler()
    job_ids: list[str] = []

    slot_start = booking.slot_start
    booking_id = booking.id

    # slot_start is tz-aware (Asia/Karachi). Compare against a tz-aware "now"
    # so we never raise `TypeError: can't compare offset-naive and offset-aware`.
    now_aware = (
        datetime.now(slot_start.tzinfo)
        if slot_start.tzinfo is not None
        else datetime.now()
    )

    # T-1h reminder
    reminder_time = slot_start - _scaled_timedelta(3600)
    if reminder_time > now_aware:
        job = scheduler.add_job(
            _emit_reminder,
            "date",
            run_date=reminder_time,
            args=[booking_id],
            id=f"reminder:{booking_id}",
            replace_existing=True,
        )
        job_ids.append(job.id)

    # T+15min no-show watchdog
    watchdog_time = slot_start + _scaled_timedelta(900)
    job = scheduler.add_job(
        _noshow_watchdog,
        "date",
        run_date=watchdog_time,
        args=[booking_id],
        id=f"noshow:{booking_id}",
        replace_existing=True,
    )
    job_ids.append(job.id)

    # T+2h completion check
    completion_time = slot_start + _scaled_timedelta(7200)
    job = scheduler.add_job(
        _completion_check,
        "date",
        run_date=completion_time,
        args=[booking_id],
        id=f"complete:{booking_id}",
        replace_existing=True,
    )
    job_ids.append(job.id)

    logger.info("Scheduled %d jobs for booking %s", len(job_ids), booking_id[:8])
    return job_ids


def cancel_booking_jobs(booking_id: str) -> None:
    scheduler = get_scheduler()
    for prefix in ("reminder", "noshow", "complete"):
        job_id = f"{prefix}:{booking_id}"
        try:
            scheduler.remove_job(job_id)
        except Exception:
            pass


async def _emit_reminder(booking_id: str) -> None:
    logger.info("Reminder: booking %s is coming up in 1 hour", booking_id[:8])
    from app.events.bus import get_bus
    await get_bus().publish("reminder", {"booking_id": booking_id})


async def _noshow_watchdog(booking_id: str) -> None:
    """Fire if provider hasn't arrived 15 min after slot start."""
    from app.events.bus import get_bus
    from app.tools import get_tools

    avail = get_tools().availability
    booking = await avail.get_booking(booking_id)
    if booking is None:
        return

    if booking.status.value == "CONFIRMED":
        logger.info("No-show detected for booking %s", booking_id[:8])
        await avail.update_status(booking_id, "NO_SHOW")
        await get_bus().publish(
            "no_show_detected",
            {
                "session_id": booking.session_id,
                "booking_id": booking_id,
                "failed_provider_id": booking.provider_id,
            },
        )


async def _completion_check(booking_id: str) -> None:
    from app.tools import get_tools

    avail = get_tools().availability
    booking = await avail.get_booking(booking_id)
    if booking and booking.status.value == "CONFIRMED":
        await avail.update_status(booking_id, "COMPLETED")
        logger.info("Auto-completed booking %s", booking_id[:8])
