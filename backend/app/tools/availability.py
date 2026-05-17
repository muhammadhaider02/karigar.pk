"""SqliteAvailability: atomic slot-hold via UNIQUE constraint on bookings table."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from app.db.models import BookingModel
from app.db.session import get_raw_session
from app.graph.errors import SlotConflict
from app.graph.state import BookingRecord, BookingStatus


class SqliteAvailability:
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
        """Atomically inserts a PENDING booking.

        Raises SlotConflict if the UNIQUE(provider_id, slot_start) constraint fires.
        """
        booking_id = str(uuid.uuid4())
        row = BookingModel(
            id=booking_id,
            session_id=session_id,
            user_id=user_id,
            provider_id=provider_id,
            provider_name=provider_name,
            service_type=service_type,
            slot_start=slot_start,
            slot_end=slot_end,
            status="PENDING",
            price_estimate=price_estimate,
        )

        async with await get_raw_session() as db:
            async with db.begin():
                db.add(row)
                try:
                    await db.flush()
                except IntegrityError as exc:
                    raise SlotConflict(provider_id, slot_start.isoformat()) from exc

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
        async with await get_raw_session() as db:
            async with db.begin():
                await db.execute(
                    update(BookingModel)
                    .where(BookingModel.id == booking_id)
                    .values(status="CANCELLED")
                )

    async def get_booking(self, booking_id: str) -> BookingRecord | None:
        async with await get_raw_session() as db:
            result = await db.execute(
                select(BookingModel).where(BookingModel.id == booking_id)
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return _row_to_record(row)

    async def update_status(self, booking_id: str, status: str) -> None:
        async with await get_raw_session() as db:
            async with db.begin():
                await db.execute(
                    update(BookingModel)
                    .where(BookingModel.id == booking_id)
                    .values(status=status)
                )


def _row_to_record(row: BookingModel) -> BookingRecord:
    return BookingRecord(
        id=row.id,
        session_id=row.session_id,
        user_id=row.user_id,
        provider_id=row.provider_id,
        provider_name=row.provider_name,
        service_type=row.service_type,
        slot_start=row.slot_start,
        slot_end=row.slot_end,
        status=BookingStatus(row.status),
        price_estimate=row.price_estimate,
        receipt_png_path=row.receipt_png_path,
        created_at=row.created_at,
    )
