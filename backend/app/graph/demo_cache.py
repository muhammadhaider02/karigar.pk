"""DEMO_MODE: deterministic cached Gemini responses for the 5 canonical demo inputs.

Activated by ``DEMO_MODE=true`` in ``.env``. When on, the IntentAgent /
DecisionAgent / ConflictResolverAgent skip the Gemini API and return a
pre-baked answer for any prompt that matches one of the 5 canonical demo
inputs (matched on a normalised substring). Any unmatched prompt still
falls through to the live Gemini call, so the demo doesn't silently
return stale data for new inputs.

Why this exists: free-tier Gemini quota is 20 requests / day on
gemini-2.5-flash and lower on Pro. A 4-minute live demo easily fires
8-12 LLM calls (Intent + Decision per session × 3 languages, plus the
recovery flow). The cache makes the demo reproducible and quota-proof.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from app.graph.state import (
    Language,
    ParsedIntent,
    ServiceType,
    TimeWindow,
)

_TZ = ZoneInfo("Asia/Karachi")


def _tomorrow_morning() -> TimeWindow:
    """Stable label/time pair for the canonical 'kal subah' demo input."""
    tomorrow = (datetime.now(_TZ) + timedelta(days=1)).replace(
        hour=6, minute=0, second=0, microsecond=0
    )
    return TimeWindow(
        start=tomorrow,
        end=tomorrow.replace(hour=12),
        label="kal subah",
    )


# Substring keys are normalised (lowercased, whitespace-collapsed) before lookup.
# Order matters only for the human reader; we match on whichever entry the
# normalised prompt contains.
_CANONICAL_INTENTS: dict[str, dict[str, Any]] = {
    # Roman Urdu — the headline demo query
    "mujhe kal subah g-13 mein ac technician chahiye": {
        "language": Language.ROMAN_URDU,
        "service_type": ServiceType.AC_TECHNICIAN,
        "location_hint": "G-13",
        "urgency": "normal",
        "use_tomorrow_morning": True,
        "notes": "",
    },
    # Urdu (Nastaliq) — proves multilingual claim
    "کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے": {
        "language": Language.URDU,
        "service_type": ServiceType.AC_TECHNICIAN,
        "location_hint": "G-13",
        "urgency": "normal",
        "use_tomorrow_morning": True,
        "notes": "",
    },
    # English — third language variant
    "i need an ac technician in g-13 tomorrow morning": {
        "language": Language.ENGLISH,
        "service_type": ServiceType.AC_TECHNICIAN,
        "location_hint": "G-13",
        "urgency": "normal",
        "use_tomorrow_morning": True,
        "notes": "",
    },
    # Roman Urdu — urgent plumber, F-7 (used to demo `urgency=high` branch)
    "f-7 mein abhi plumber bhejo, paani leak ho raha hai": {
        "language": Language.ROMAN_URDU,
        "service_type": ServiceType.PLUMBER,
        "location_hint": "F-7",
        "urgency": "high",
        "use_tomorrow_morning": False,
        "notes": "paani leak ho raha hai",
    },
    # English — electrician, I-8 (used as the second multilingual proof)
    "send a carpenter to i-8 today afternoon": {
        "language": Language.ENGLISH,
        "service_type": ServiceType.CARPENTER,
        "location_hint": "I-8",
        "urgency": "normal",
        "use_tomorrow_morning": False,
        "notes": "",
    },
}


# ── Decision justifications (cached per (provider_name, language)) ────────────

_DECISION_JUSTIFICATIONS: dict[tuple[str, Language], str] = {
    ("Ali AC Services", Language.ROMAN_URDU): (
        "Ali AC Services ko chuna gaya kyunki yeh sabse qareeb hai, "
        "rating 4.7 hai, aur aap ke pasandeeda slot par bilkul free hai."
    ),
    ("Ali AC Services", Language.URDU): (
        "علی اے سی سروسز کو چنا گیا کیونکہ یہ سب سے قریب ہے، "
        "ریٹنگ 4.7 ہے، اور آپ کے پسندیدہ سلاٹ پر بالکل دستیاب ہے۔"
    ),
    ("Ali AC Services", Language.ENGLISH): (
        "Picked Ali AC Services because it's the nearest provider, rated 4.7, "
        "and exactly free in your preferred slot."
    ),
    ("Hassan Cooling Experts", Language.ROMAN_URDU): (
        "Hassan Cooling Experts ko chuna gaya, woh nazdeek hain aur "
        "aap ke time slot par dastiyab hain."
    ),
    ("Hassan Cooling Experts", Language.URDU): (
        "حسن کولنگ ایکسپرٹس کو چنا گیا، یہ قریب ہیں اور آپ کے ٹائم سلاٹ پر دستیاب ہیں۔"
    ),
    ("Hassan Cooling Experts", Language.ENGLISH): (
        "Picked Hassan Cooling Experts — close by and available in your time slot."
    ),
    ("Karim Cool Air", Language.ROMAN_URDU): (
        "Karim Cool Air ko chuna gaya kyunki price kam hai aur "
        "yeh aap ke time par available hain."
    ),
    ("Karim Cool Air", Language.URDU): (
        "کریم کول ایئر کو چنا گیا کیونکہ قیمت کم ہے اور یہ آپ کے وقت پر دستیاب ہیں۔"
    ),
    ("Karim Cool Air", Language.ENGLISH): (
        "Picked Karim Cool Air — best price and available at your preferred time."
    ),
}


# ── Conflict resolver decisions ──────────────────────────────────────────────

_CONFLICT_DECISIONS: list[dict[str, Any]] = [
    {  # attempt 1: just exclude + retry
        "exclude_provider": True,
        "widen_hours": 0,
        "reasoning": "Excluding the failed provider; retrying with the original window.",
    },
    {  # attempt 2: widen ±1h
        "exclude_provider": True,
        "widen_hours": 1,
        "reasoning": "Excluding the failed provider and widening the window by 1 hour each side.",
    },
    {  # attempt 3: widen ±2h (last chance before hand-off)
        "exclude_provider": True,
        "widen_hours": 2,
        "reasoning": "Last attempt — widening the window by 2 hours each side.",
    },
]


# ── Public API ───────────────────────────────────────────────────────────────


def _normalise(text: str) -> str:
    return " ".join(text.lower().split())


def lookup_intent(raw_text: str) -> ParsedIntent | None:
    """Return a cached ParsedIntent if the input matches a canonical demo prompt.

    Returns None to signal "fall through to the live LLM call".
    """
    if not raw_text:
        return None
    needle = _normalise(raw_text)
    for key, spec in _CANONICAL_INTENTS.items():
        if _normalise(key) in needle or needle in _normalise(key):
            time_window = _tomorrow_morning() if spec["use_tomorrow_morning"] else None
            return ParsedIntent(
                language=spec["language"],
                service_type=spec["service_type"],
                location_hint=spec["location_hint"],
                time_window=time_window,
                urgency=spec["urgency"],
                notes=spec["notes"],
            )
    return None


def lookup_decision(provider_name: str, language: Language) -> str | None:
    """Return a cached one-sentence justification, or None."""
    return _DECISION_JUSTIFICATIONS.get((provider_name, language))


def lookup_conflict_decision(attempt_number: int) -> dict[str, Any] | None:
    """Return the deterministic resolver decision for attempt N (1-indexed)."""
    if attempt_number < 1:
        return None
    idx = min(attempt_number, len(_CONFLICT_DECISIONS)) - 1
    return dict(_CONFLICT_DECISIONS[idx])
