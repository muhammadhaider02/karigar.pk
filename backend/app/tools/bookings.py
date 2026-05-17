"""BookingsCRUD: persist/update bookings and render receipts."""

from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from sqlalchemy import select, update

from app.db.models import BookingModel
from app.db.session import get_raw_session
from app.graph.state import BookingRecord, BookingStatus, Provider, ServiceType

logger = logging.getLogger(__name__)

_RECEIPTS_DIR = Path(__file__).parent.parent.parent / "runtime" / "receipts"


async def persist(booking: BookingRecord) -> None:
    """Update the DB row status + receipt path for an existing booking."""
    async with await get_raw_session() as db:
        async with db.begin():
            await db.execute(
                update(BookingModel)
                .where(BookingModel.id == booking.id)
                .values(
                    status=booking.status.value,
                    receipt_png_path=booking.receipt_png_path,
                )
            )


async def get(booking_id: str) -> BookingRecord | None:
    async with await get_raw_session() as db:
        result = await db.execute(
            select(BookingModel).where(BookingModel.id == booking_id)
        )
        row = result.scalar_one_or_none()
        if row is None:
            return None
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


async def list_for_user(user_id: str) -> list[BookingRecord]:
    async with await get_raw_session() as db:
        result = await db.execute(
            select(BookingModel).where(BookingModel.user_id == user_id)
        )
        rows = result.scalars().all()
        return [
            BookingRecord(
                id=r.id,
                session_id=r.session_id,
                user_id=r.user_id,
                provider_id=r.provider_id,
                provider_name=r.provider_name,
                service_type=r.service_type,
                slot_start=r.slot_start,
                slot_end=r.slot_end,
                status=BookingStatus(r.status),
                price_estimate=r.price_estimate,
                receipt_png_path=r.receipt_png_path,
                created_at=r.created_at,
            )
            for r in rows
        ]


async def transition(booking_id: str, new_status: BookingStatus) -> None:
    async with await get_raw_session() as db:
        async with db.begin():
            await db.execute(
                update(BookingModel)
                .where(BookingModel.id == booking_id)
                .values(status=new_status.value)
            )


def _load_font(size: int) -> ImageFont.ImageFont:
    """Try a few common system fonts; fall back to PIL's bitmap default.

    PIL's default font ignores `size`, so receipts on a font-less machine
    will look small but will not crash.
    """
    for candidate in ("arial.ttf", "DejaVuSans.ttf", "Helvetica.ttf", "LiberationSans-Regular.ttf"):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def render_receipt(booking: BookingRecord, provider: Provider, location_hint: str) -> str:
    """Render a PNG receipt and save to `runtime/receipts/<booking_id>.png`.

    Returns the absolute filesystem path of the generated PNG, which is
    stored on `BookingRecord.receipt_png_path` and served by
    `GET /receipts/{booking_id}.png`.
    """
    _RECEIPTS_DIR.mkdir(parents=True, exist_ok=True)
    receipt_path = _RECEIPTS_DIR / f"{booking.id}.png"

    width, height = 640, 520
    bg_color = "#FFFFFF"
    header_color = "#0F9D58"  # Karigar green
    footer_bg = "#F1F3F4"
    label_color = "#5F6368"
    value_color = "#202124"

    img = Image.new("RGB", (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)

    title_font = _load_font(24)
    body_font = _load_font(16)
    small_font = _load_font(13)

    # Header bar
    draw.rectangle([(0, 0), (width, 70)], fill=header_color)
    draw.text((24, 22), "KARIGAR  ·  Booking Confirmation", fill="white", font=title_font)

    # Body rows
    rows = [
        ("Booking ID", booking.id[:8]),
        ("Service", ServiceType.pretty(booking.service_type)),
        ("Provider", provider.name),
        ("Phone", provider.phone),
        ("Date", booking.slot_start.strftime("%a, %d %b %Y")),
        (
            "Time",
            f"{booking.slot_start.strftime('%H:%M')} – {booking.slot_end.strftime('%H:%M')}",
        ),
        ("Location", location_hint or "—"),
        ("Price (est.)", f"Rs. {booking.price_estimate:,}"),
    ]

    y = 110
    for label, value in rows:
        draw.text((30, y), label, fill=label_color, font=body_font)
        draw.text((200, y), str(value), fill=value_color, font=body_font)
        y += 36

    # Footer bar
    draw.rectangle([(0, height - 60), (width, height)], fill=footer_bg)
    draw.text((24, height - 42), "Status: CONFIRMED", fill=header_color, font=body_font)
    issued = datetime.now().strftime("%H:%M, %d %b %Y")
    draw.text((width - 260, height - 38), f"Issued at: {issued}", fill=label_color, font=small_font)

    try:
        img.save(receipt_path, "PNG")
    except Exception:
        logger.exception("Failed to render PNG receipt for booking %s", booking.id[:8])
        raise

    return str(receipt_path)
