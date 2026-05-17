"""MockNotifier: logs messages to a JSONL file and exposes them via GET /notifier-log.

Templates for booking confirmation and rebook notifications in all 3 languages.
"""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from app.graph.state import BookingRecord, Language, Provider, ServiceType

_TZ = ZoneInfo("Asia/Karachi")

_LOG_FILE = Path(__file__).parent.parent.parent / "runtime" / "notifier-log.jsonl"

# ── Confirmation templates ─────────────────────────────────────────────────────

_CONFIRM_TEMPLATES: dict[str, str] = {
    "roman_ur": (
        "*Karigar Booking Confirmed* ✅\n\n"
        "Aap ka {service_type} {provider_name} ke saath book ho gaya hai.\n\n"
        "🗓 *Date:* {date}\n"
        "⏰ *Time:* {time}\n"
        "📍 *Location:* {location}\n"
        "💰 *Price (est):* Rs. {price}\n"
        "📞 *Provider:* {phone}\n\n"
        "Booking ID: {booking_id}\n\n"
        "Reply *CANCEL {booking_id}* to cancel."
    ),
    "ur": (
        "*کریگر بکنگ تصدیق شدہ* ✅\n\n"
        "آپ کا {service_type} {provider_name} کے ساتھ بُک ہو گیا ہے۔\n\n"
        "🗓 *تاریخ:* {date}\n"
        "⏰ *وقت:* {time}\n"
        "📍 *مقام:* {location}\n"
        "💰 *قیمت (تخمینہ):* Rs. {price}\n"
        "📞 *فراہم کنندہ:* {phone}\n\n"
        "بکنگ ID: {booking_id}\n\n"
        "منسوخی کے لیے لکھیں: *CANCEL {booking_id}*"
    ),
    "en": (
        "*Karigar Booking Confirmed* ✅\n\n"
        "Your {service_type} has been booked with {provider_name}.\n\n"
        "🗓 *Date:* {date}\n"
        "⏰ *Time:* {time}\n"
        "📍 *Location:* {location}\n"
        "💰 *Price (est):* Rs. {price}\n"
        "📞 *Provider:* {phone}\n\n"
        "Booking ID: {booking_id}\n\n"
        "Reply *CANCEL {booking_id}* to cancel."
    ),
}

# ── Rebook templates ───────────────────────────────────────────────────────────

REBOOK_TEMPLATES: dict[str, str] = {
    "roman_ur": "{old} ne confirm nahi kiya. Hum ne {new} ko {time} ke liye book kar diya hai.",
    "ur": "{old} نے کنفرم نہیں کیا۔ ہم نے {new} کو {time} کے لیے بک کر دیا ہے۔",
    "en": "{old} didn't confirm, we auto-booked {new} at {time} instead.",
}

HANDOFF_TEMPLATES: dict[str, str] = {
    "roman_ur": "Hum auto-rebook nahi kar paaye. 3 alternatives diye hain, please apni pasand chunein.",
    "ur": "ہم آٹو ری بک نہیں کر سکے۔ ۳ متبادل دیے ہیں، براہ کرم اپنی پسند چنیں۔",
    "en": "We couldn't auto-rebook. 3 alternatives are available: please pick one.",
}


def build_confirmation_message(
    booking: BookingRecord,
    provider: Provider,
    language: Language,
    location_hint: str,
) -> str:
    lang_key = language.value.replace("-", "_")  # roman_ur, ur, en
    if lang_key not in _CONFIRM_TEMPLATES:
        lang_key = "en"
    template = _CONFIRM_TEMPLATES[lang_key]
    return template.format(
        service_type=ServiceType.pretty(booking.service_type),
        provider_name=provider.name,
        date=booking.slot_start.strftime("%a, %d %b %Y"),
        time=f"{booking.slot_start.strftime('%H:%M')} – {booking.slot_end.strftime('%H:%M')}",
        location=location_hint,
        price=booking.price_estimate,
        phone=provider.phone,
        booking_id=booking.id[:8],
    )


class MockNotifier:
    """Appends messages to a JSONL log file instead of sending real WhatsApp messages."""

    def _ensure_log_dir(self) -> None:
        _LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

    async def send(self, channel: str, to: str, message: str) -> None:
        self._ensure_log_dir()
        entry = {
            # tz-aware Asia/Karachi timestamp to match the rest of the app
            # (datetime.utcnow() is naive + deprecated in Python 3.12).
            "ts": datetime.now(_TZ).isoformat(),
            "channel": channel,
            "to": to,
            "message": message,
        }
        with open(_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    async def get_log(self) -> list[dict]:
        if not _LOG_FILE.exists():
            return []
        lines = _LOG_FILE.read_text(encoding="utf-8").strip().splitlines()
        return [json.loads(line) for line in lines if line.strip()]
