"""BookingsCRUD: persist/update bookings and upload receipts to Supabase Storage."""

from __future__ import annotations

import io
import logging
from datetime import datetime

from PIL import Image, ImageDraw, ImageFont

from app.graph.state import BookingRecord, BookingStatus, Provider, ServiceType

logger = logging.getLogger(__name__)

# Maps Python BookingStatus → Supabase booking_status enum
_STATUS_MAP: dict[str, str] = {
    "PENDING": "worker_assigned",
    "CONFIRMED": "arrived",      # routes.mark_arrived uses BookingStatus.CONFIRMED
    "CANCELLED": "cancelled",
    "COMPLETED": "completed",
    "NO_SHOW": "no_show",
}


async def persist(booking: BookingRecord) -> None:
    """Update the Supabase booking row: status to 'worker_accepted' + receipt_url."""
    from app.db.supabase_client import get_supabase
    supabase = await get_supabase()
    await supabase.table("bookings").update({
        "status": "worker_accepted",
        "receipt_url": booking.receipt_url,
        "confirmed_at": datetime.utcnow().isoformat(),
    }).eq("id", booking.id).execute()


async def get(booking_id: str) -> BookingRecord | None:
    from app.db.supabase_client import get_supabase
    from app.tools.availability import _row_to_record
    supabase = await get_supabase()
    result = await supabase.table("bookings").select("*").eq("id", booking_id).maybe_single().execute()
    if not result.data:
        return None
    return _row_to_record(result.data)


async def list_for_user(user_id: str) -> list[BookingRecord]:
    from app.db.supabase_client import get_supabase
    from app.tools.availability import _row_to_record
    supabase = await get_supabase()
    result = await supabase.table("bookings").select("*").eq("customer_id", user_id).execute()
    rows = result.data or []
    return [_row_to_record(r) for r in rows]


async def transition(booking_id: str, new_status: BookingStatus) -> None:
    from app.db.supabase_client import get_supabase
    supabase = await get_supabase()
    db_status = _STATUS_MAP.get(new_status.value, new_status.value.lower())
    await supabase.table("bookings").update({
        "status": db_status,
        "updated_at": datetime.utcnow().isoformat(),
    }).eq("id", booking_id).execute()


def _load_font(size: int) -> ImageFont.ImageFont:
    for candidate in ("arial.ttf", "DejaVuSans.ttf", "Helvetica.ttf", "LiberationSans-Regular.ttf"):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _render_receipt_bytes(booking: BookingRecord, provider: Provider, location_hint: str) -> bytes:
    """Render a PNG receipt and return the bytes."""
    width, height = 640, 520
    img = Image.new("RGB", (width, height), color="#FFFFFF")
    draw = ImageDraw.Draw(img)

    header_color = "#0F9D58"
    label_color = "#5F6368"
    value_color = "#202124"
    footer_bg = "#F1F3F4"

    title_font = _load_font(24)
    body_font = _load_font(16)
    small_font = _load_font(13)

    draw.rectangle([(0, 0), (width, 70)], fill=header_color)
    draw.text((24, 22), "KARIGAR  ·  Booking Confirmation", fill="white", font=title_font)

    rows = [
        ("Booking ID", booking.id[:8]),
        ("Service", ServiceType.pretty(booking.service_type)),
        ("Provider", provider.name),
    ]
    if provider.phone and provider.phone not in ("N/A", ""):
        rows.append(("Phone", provider.phone))
    rows += [
        ("Date", booking.slot_start.strftime("%a, %d %b %Y")),
        ("Time", f"{booking.slot_start.strftime('%H:%M')} – {booking.slot_end.strftime('%H:%M')}"),
        ("Location", location_hint or "—"),
        ("Price (est.)", f"Rs. {booking.price_estimate:,}"),
    ]

    y = 110
    for label, value in rows:
        draw.text((30, y), label, fill=label_color, font=body_font)
        draw.text((200, y), str(value), fill=value_color, font=body_font)
        y += 36

    draw.rectangle([(0, height - 60), (width, height)], fill=footer_bg)
    draw.text((24, height - 42), "Status: CONFIRMED", fill=header_color, font=body_font)
    issued = datetime.now().strftime("%H:%M, %d %b %Y")
    draw.text((width - 260, height - 38), f"Issued at: {issued}", fill=label_color, font=small_font)

    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


async def render_and_upload_receipt(
    booking: BookingRecord,
    provider: Provider,
    location_hint: str,
) -> str | None:
    """Render receipt PNG and upload to Supabase Storage. Returns public URL."""
    try:
        png_bytes = _render_receipt_bytes(booking, provider, location_hint)
    except Exception:
        logger.exception("Failed to render receipt for booking %s", booking.id[:8])
        return None

    try:
        from app.db.supabase_client import get_supabase
        supabase = await get_supabase()
        path = f"{booking.id}.png"
        await supabase.storage.from_("receipts").upload(
            path,
            png_bytes,
            {"content-type": "image/png", "upsert": "true"},
        )
        return await supabase.storage.from_("receipts").get_public_url(path)
    except Exception:
        logger.exception("Failed to upload receipt for booking %s", booking.id[:8])
        return None
