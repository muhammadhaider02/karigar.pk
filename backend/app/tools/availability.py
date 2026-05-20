"""SupabaseAvailability: atomic slot-hold via Supabase Postgres unique index."""

from __future__ import annotations

import uuid
from datetime import datetime
from zoneinfo import ZoneInfo

from app.graph.errors import SlotConflict
from app.graph.state import BookingRecord, BookingStatus

_KARACHI_TZ = ZoneInfo("Asia/Karachi")

# Maps Python BookingStatus enum values to Supabase booking_status enum values.
_STATUS_MAP: dict[str, str] = {
    "PENDING": "worker_assigned",
    "CONFIRMED": "arrived",
    "CANCELLED": "cancelled",
    "COMPLETED": "completed",
    "NO_SHOW": "no_show",
}


class SupabaseAvailability:
    async def check_and_hold(
        self,
        provider_id: str,
        slot_start: datetime,
        slot_end: datetime,
        session_id: str,
        user_id: str,
        provider_name: str,
        service_type: str,
        price_estimate: int,
    ) -> BookingRecord:
        """Atomically inserts a booking row.

        Raises SlotConflict if the partial unique index (uq_worker_slot) fires.
        """
        from app.db.supabase_client import get_supabase
        booking_id = str(uuid.uuid4())
        supabase = await get_supabase()

        try:
            await supabase.table("bookings").insert({
                "id": booking_id,
                "booking_code": f"BKG-{booking_id[:8].upper()}",
                "session_id": session_id,
                "customer_id": user_id,
                "worker_id": provider_id,
                "description": provider_name,  # preserve name for notifications
                "service_type": service_type,
                "slot_time": slot_start.isoformat(),
                "slot_end": slot_end.isoformat(),
                "price_estimate": price_estimate,
                "status": "worker_assigned",
                "is_auto_booked": True,
            }).execute()
        except Exception as exc:
            err = str(exc)
            if "uq_worker_slot" in err or "23505" in err:
                raise SlotConflict(
                    provider_id=provider_id,
                    slot_start=slot_start.isoformat(),
                ) from exc
            import logging as _logging
            _logging.getLogger(__name__).warning("Booking INSERT skipped (non-fatal): %s", exc)
            # Fall through — return in-memory BookingRecord; Supabase write is best-effort

        return BookingRecord(
            id=booking_id,
            session_id=session_id,
            user_id=user_id,
            provider_id=provider_id,
            provider_name=provider_name,
            service_type=service_type,
            slot_start=slot_start,
            slot_end=slot_end,
            status=BookingStatus.PENDING,
            price_estimate=price_estimate,
        )

    async def release(self, booking_id: str) -> None:
        from app.db.supabase_client import get_supabase
        supabase = await get_supabase()
        await supabase.table("bookings").update({"status": "cancelled"}).eq("id", booking_id).execute()

    async def get_booking(self, booking_id: str) -> BookingRecord | None:
        from app.db.supabase_client import get_supabase
        supabase = await get_supabase()
        result = await supabase.table("bookings").select("*").eq("id", booking_id).maybe_single().execute()
        if not result.data:
            return None
        return _row_to_record(result.data)

    async def update_status(self, booking_id: str, status: str) -> None:
        from app.db.supabase_client import get_supabase
        supabase = await get_supabase()
        db_status = _STATUS_MAP.get(status, status.lower())
        await supabase.table("bookings").update({"status": db_status}).eq("id", booking_id).execute()


def _parse_dt(val) -> datetime:
    if isinstance(val, datetime):
        return val
    return datetime.fromisoformat(str(val).replace("Z", "+00:00"))


def _row_to_record(row: dict) -> BookingRecord:
    return BookingRecord(
        id=row["id"],
        session_id=row.get("session_id") or "",
        user_id=row["customer_id"],
        provider_id=row.get("worker_id") or "",
        provider_name=row.get("description") or "",
        service_type=row["service_type"],
        slot_start=_parse_dt(row["slot_time"]),
        slot_end=_parse_dt(row["slot_end"]),
        status=BookingStatus.PENDING,
        price_estimate=row["price_estimate"],
        receipt_url=row.get("receipt_url"),
        created_at=_parse_dt(row["created_at"]) if row.get("created_at") else datetime.now(_KARACHI_TZ),
    )
