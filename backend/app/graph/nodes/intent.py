"""IntentAgent: parse raw text → ParsedIntent using Gemini structured output."""

from __future__ import annotations

import time
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from langchain_google_genai import ChatGoogleGenerativeAI

from app.config import get_settings
from app.graph import demo_cache
from app.graph.state import (
    Language,
    ParsedIntent,
    RequestSession,
    ServiceType,
    TimeWindow,
)
from app.graph.trace import emit_trace

_TZ = ZoneInfo("Asia/Karachi")

# Few-shot system prompt
_SYSTEM_PROMPT = """You are an intent parser for Karigar, a service-booking app in Pakistan.

Extract a structured ParsedIntent from the user's message which may be in:
- Roman Urdu (Latin script Urdu): e.g. "Mujhe kal subah G-13 mein AC technician chahiye"
- Urdu (Nastaliq script): e.g. "کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے"
- English: e.g. "I need an AC technician in G-13 tomorrow morning"

Language detection rules:
- If ANY Urdu/Arabic script characters are present → language = "ur"
- Else if ANY of these words present (case-insensitive): chahiye, hai, mein, ko, abhi, kal, subah, raat, bhejo, aaj, jaldi, zaroor → language = "roman_ur"
- Else → language = "en"

Service type mapping:
- AC technician / AC tech / AC wala / اے سی → ac_technician
- Plumber / naai / nal wala / نلکہ → plumber
- Electrician / bijli wala / بجلی → electrician
- Tutor / teacher / ustaz / استاد → tutor
- Beautician / parlor / beauty / makeup → beautician
- Carpenter / badhai / لکڑی → carpenter
- Anything unclear → unknown

Time resolution (use current server time as "now"):
- "abhi" / "ابھی" / "right now" / "urgent" → start=now, end=now+2h
- "kal subah" / "کل صبح" / "tomorrow morning" → start=tomorrow 06:00, end=tomorrow 12:00
- "kal" / "tomorrow" (no time) → start=tomorrow 09:00, end=tomorrow 18:00
- "aaj" / "today" (no time) → start=now, end=today 20:00
- "agle hafte" / "next week" → start=next Monday 09:00, end=next Sunday 21:00
- If no time mentioned → time_window=null

Urgency:
- "abhi" / "urgent" / "jaldi" / "leak" / "short circuit" → high
- "agle hafte" / "next week" / "kabhi bhi" → low
- Default → normal

Always use Asia/Karachi timezone (UTC+5).
location_hint: copy the raw location phrase from the user, do NOT geocode.
notes: anything that doesn't fit other fields (e.g. "for kids", "math subject", "ceiling fan").

Few-shot examples:
1. "Mujhe kal subah G-13 mein AC technician chahiye"
   → language=roman_ur, service_type=ac_technician, location_hint="G-13", urgency=normal, time_window.label="kal subah"

2. "F-7 mein abhi plumber bhejo, paani leak ho raha hai"
   → language=roman_ur, service_type=plumber, location_hint="F-7", urgency=high, notes="paani leak ho raha hai", time_window.label="abhi"

3. "Bahria Phase 4 mein agle hafte beautician chahiye home service"
   → language=roman_ur, service_type=beautician, location_hint="Bahria Phase 4", urgency=low, notes="home service", time_window.label="agle hafte"

4. "کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے"
   → language=ur, service_type=ac_technician, location_hint="G-13"

5. "ابھی ایف-۱۰ میں الیکٹریشن بھیجو"
   → language=ur, service_type=electrician, location_hint="F-10", urgency=high

6. "بچوں کے لیے ریاضی کا ٹیوٹر چاہیے"
   → language=ur, service_type=tutor, notes="ریاضی - بچوں کے لیے"

7. "I need an AC technician in G-13 tomorrow morning"
   → language=en, service_type=ac_technician, location_hint="G-13"

8. "Send a carpenter to I-8 today afternoon, urgent"
   → language=en, service_type=carpenter, location_hint="I-8", urgency=high

9. "Looking for a math tutor for my kids in F-7"
   → language=en, service_type=tutor, location_hint="F-7", notes="math, for kids"
"""


def _resolve_time_window(label: str, now: datetime) -> TimeWindow | None:
    """Resolve a time label to absolute datetimes."""
    label_lower = label.lower()
    tomorrow = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)

    if any(w in label_lower for w in ["abhi", "ابھی", "right now", "urgent", "jaldi"]):
        return TimeWindow(start=now, end=now + timedelta(hours=2), label=label)

    if any(w in label_lower for w in ["kal subah", "کل صبح", "tomorrow morning"]):
        return TimeWindow(
            start=tomorrow.replace(hour=6),
            end=tomorrow.replace(hour=12),
            label=label,
        )

    if any(w in label_lower for w in ["kal", "tomorrow"]):
        return TimeWindow(
            start=tomorrow.replace(hour=9),
            end=tomorrow.replace(hour=18),
            label=label,
        )

    if any(w in label_lower for w in ["aaj", "today", "آج"]):
        return TimeWindow(
            start=now,
            end=now.replace(hour=20, minute=0, second=0),
            label=label,
        )

    if any(w in label_lower for w in ["agle hafte", "next week", "اگلے ہفتے"]):
        days_until_monday = (7 - now.weekday()) % 7 or 7
        monday = (now + timedelta(days=days_until_monday)).replace(
            hour=9, minute=0, second=0, microsecond=0
        )
        sunday = monday + timedelta(days=6, hours=12)
        return TimeWindow(start=monday, end=sunday, label=label)

    return None


def _rule_based_parse(raw_text: str, now: datetime) -> ParsedIntent:
    """Fast keyword-based intent parser — used in DEMO_MODE for any query."""
    text = raw_text.lower()

    # Language detection
    if any(ord(c) > 0x0600 for c in raw_text):
        lang = Language.URDU
    elif any(w in text for w in ["chahiye", "hai", "mein", "ko", "abhi", "kal", "subah", "bhejo", "aaj"]):
        lang = Language.ROMAN_URDU
    else:
        lang = Language.ENGLISH

    # Service type
    svc = ServiceType.UNKNOWN
    if any(w in text for w in ["ac", "cooling", "air condition", "اے سی"]):
        svc = ServiceType.AC_TECHNICIAN
    elif any(w in text for w in ["plumb", "pipe", "nal", "paani", "نلکہ", "leak"]):
        svc = ServiceType.PLUMBER
    elif any(w in text for w in ["electric", "bijli", "wire", "بجلی", "short"]):
        svc = ServiceType.ELECTRICIAN
    elif any(w in text for w in ["tutor", "teacher", "math", "science", "ustaz", "استاد"]):
        svc = ServiceType.TUTOR
    elif any(w in text for w in ["beauty", "parlor", "makeup", "hair", "wax"]):
        svc = ServiceType.BEAUTICIAN
    elif any(w in text for w in ["carpenter", "badhai", "wood", "لکڑی", "furniture"]):
        svc = ServiceType.CARPENTER
    elif any(w in text for w in ["paint", "rang", "رنگ"]):
        svc = ServiceType.PAINTER

    # Urgency
    urgency = "normal"
    if any(w in text for w in ["abhi", "urgent", "jaldi", "leak", "short circuit", "ابھی"]):
        urgency = "high"
    elif any(w in text for w in ["agle hafte", "next week", "whenever", "اگلے"]):
        urgency = "low"

    # Location hint — prefer sector codes (G-13, F-10, I-8 etc.) then first
    # meaningful capitalized token, skipping Urdu/Roman-Urdu filler words.
    _URDU_STOP = {
        "mujhe", "mujah", "mein", "main", "mai", "chahiye", "caiyah", "ciayah",
        "chayie", "chaiye", "karein", "karo", "hai", "hain",
        "aur", "ya", "ke", "ki", "ka", "ko", "se", "par", "kal", "subah",
        "raat", "shaam", "abhi", "aj", "aaj", "please", "plz", "thoda",
        "bahut", "shukriya", "bhi", "bhai", "ap", "aap", "yahan", "wahan",
        "i", "a", "ac", "ok", "hi",
    }
    import re as _re
    location_hint = ""
    # Case-insensitive sector match: g-13, G-13, g 13, f-7, F-10, i-8, etc.
    # Accepts dash OR space between letter and digits ("g 13" → "G-13")
    _sector = _re.search(r'\b([A-Za-z]{1,2}[-\s]\d{1,2}(?:/\d+)?)\b', raw_text, _re.IGNORECASE)
    if _sector:
        # Normalise to uppercase dash format: "g 13" → "G-13"
        location_hint = _re.sub(r'\s+', '-', _sector.group(1).upper())
    else:
        for word in raw_text.split():
            stripped = word.strip(".,!?")
            if len(stripped) >= 2 and (stripped[0].isupper() or stripped.upper() == stripped):
                if stripped.lower() not in _URDU_STOP:
                    location_hint = stripped
                    break

    # Time window
    time_window: TimeWindow | None = None
    if any(w in text for w in ["abhi", "ابھی", "right now", "urgent"]):
        time_window = TimeWindow(start=now, end=now + timedelta(hours=2), label="abhi")
    elif any(w in text for w in ["kal subah", "کل صبح", "tomorrow morning"]):
        tomorrow = (now + timedelta(days=1)).replace(hour=6, minute=0, second=0, microsecond=0)
        time_window = TimeWindow(start=tomorrow, end=tomorrow.replace(hour=12), label="kal subah")
    elif any(w in text for w in ["kal", "tomorrow"]):
        tomorrow = (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
        time_window = TimeWindow(start=tomorrow, end=tomorrow.replace(hour=18), label="kal")

    return ParsedIntent(
        language=lang,
        service_type=svc,
        location_hint=location_hint,
        time_window=time_window,
        urgency=urgency,
        notes="",
    )


async def run(state: RequestSession) -> RequestSession:
    settings = get_settings()
    now = datetime.now(_TZ)

    t0 = time.perf_counter_ns()

    llm = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=settings.google_api_key,
        temperature=0.1,
    )

    structured_llm = llm.with_structured_output(ParsedIntent)

    async with emit_trace(
        state,
        agent="IntentAgent",
        phase="decide",
        input={"raw_text": state.raw_text},
    ) as t:
        try:
            # DEMO_MODE short-circuit: serve a deterministic ParsedIntent for
            # known prompts without burning Gemini quota. For unrecognized input
            # we do a fast rule-based parse so the full demo works offline.
            if settings.demo_mode:
                cached = demo_cache.lookup_intent(state.raw_text)
                if cached is None:
                    cached = _rule_based_parse(state.raw_text, now)
                state.parsed_intent = cached
                latency_ms = int((time.perf_counter_ns() - t0) / 1_000_000)
                t.add_tool_call(
                    "DemoCache.intent",
                    {"raw_text": state.raw_text},
                    cached.model_dump(mode="json"),
                    latency_ms=latency_ms,
                )
                t.set_output(cached.model_dump(mode="json"))
                t.set_reasoning(
                    f"[DEMO_MODE] Detected {cached.language.value}; "
                    f"service={cached.service_type.pretty_name}, "
                    f"location='{cached.location_hint}', urgency={cached.urgency}"
                )
                return state

            messages = [
                ("system", _SYSTEM_PROMPT + f"\n\nCurrent server time (Asia/Karachi): {now.isoformat()}"),
                ("human", state.raw_text),
            ]
            parsed: ParsedIntent = await structured_llm.ainvoke(messages)

            # Post-process: resolve time_window label to absolute datetimes
            if parsed.time_window and parsed.time_window.label:
                resolved = _resolve_time_window(parsed.time_window.label, now)
                if resolved:
                    parsed.time_window = resolved

            state.parsed_intent = parsed
            latency_ms = int((time.perf_counter_ns() - t0) / 1_000_000)

            t.add_tool_call(
                "Gemini.flash.structured_output",
                {"model": "gemini-2.5-flash", "schema": "ParsedIntent"},
                parsed.model_dump(mode="json"),
                latency_ms=latency_ms,
            )
            t.set_output(parsed.model_dump(mode="json"))
            t.set_reasoning(
                f"Detected {parsed.language.value}; "
                f"service={parsed.service_type.pretty_name}, "
                f"location='{parsed.location_hint}', "
                f"urgency={parsed.urgency}"
            )

        except Exception as exc:
            # Fallback: unknown intent rather than crashing
            state.parsed_intent = ParsedIntent(
                language=Language.ENGLISH,
                service_type=ServiceType.UNKNOWN,
                location_hint="",
                notes=f"parse_error: {exc}",
            )
            t.set_output({"error": str(exc)})
            t.set_reasoning(f"IntentAgent failed: {exc}; defaulting to UNKNOWN")

    return state
