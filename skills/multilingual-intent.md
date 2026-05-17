# Skill: Multilingual Intent Parsing

> Load this skill when working on `backend/app/graph/nodes/intent.py`, its prompt, or its tests.
> Owner: `backend-engineer`.

## Purpose

Convert a raw user message (Urdu / Roman Urdu / English) into a strict Pydantic object so every downstream agent can rely on typed fields.

## Pydantic schema (source of truth)

```python
# backend/app/graph/state.py
from enum import Enum
from typing import Literal, Optional
from datetime import datetime
from pydantic import BaseModel, Field

class Language(str, Enum):
    URDU = "ur"
    ROMAN_URDU = "roman_ur"
    ENGLISH = "en"

class ServiceType(str, Enum):
    AC_TECHNICIAN = "ac_technician"
    PLUMBER = "plumber"
    ELECTRICIAN = "electrician"
    TUTOR = "tutor"
    BEAUTICIAN = "beautician"
    CARPENTER = "carpenter"
    UNKNOWN = "unknown"

class TimeWindow(BaseModel):
    start: datetime          # earliest acceptable start
    end: datetime            # latest acceptable end
    label: str               # human-readable, e.g. "tomorrow morning"

class ParsedIntent(BaseModel):
    language: Language
    service_type: ServiceType
    location_hint: str       # raw user phrase, e.g. "G-13", "near F-7 Markaz"
    time_window: Optional[TimeWindow]
    urgency: Literal["low", "normal", "high"] = "normal"
    notes: str = Field(default="", description="anything that doesn't fit other fields")
```

## Implementation rules

1. Use `langchain-google-genai` with `model="gemini-2.5-flash"` and `with_structured_output(ParsedIntent)`. Never use free-form completions for this node.
2. Resolve relative time phrases (*"kal subah"*, *"tonight"*, *"abhi"*) using the current server time. Always emit absolute `datetime` in `Asia/Karachi` (UTC+5).
3. If `service_type` cannot be confidently determined, set it to `UNKNOWN` and put the raw service phrase in `notes`. Do **not** guess: the DiscoveryAgent will surface "please clarify what service you need".
4. `location_hint` is intentionally a free-text string. Do **not** geocode here. The Geocoder tool does that in the next node.
5. Always set `language` based on the **input** language, even if the user mixes (e.g. Urdu script with English words → still `URDU`).

## Few-shot examples (include all 9 in the prompt)

### Roman Urdu
- `"Mujhe kal subah G-13 mein AC technician chahiye"` →
  `language=ROMAN_URDU, service_type=AC_TECHNICIAN, location_hint="G-13", time_window={start: tomorrow 06:00, end: tomorrow 12:00, label: "kal subah"}, urgency="normal"`
- `"F-7 mein abhi plumber bhejo, paani leak ho raha hai"` →
  `language=ROMAN_URDU, service_type=PLUMBER, location_hint="F-7", time_window={start: now, end: now+2h, label: "abhi"}, urgency="high", notes="paani leak ho raha hai"`
- `"Bahria Phase 4 mein agle hafte beautician chahiye home service"` →
  `language=ROMAN_URDU, service_type=BEAUTICIAN, location_hint="Bahria Phase 4", time_window={start: next monday 09:00, end: next sunday 21:00, label: "agle hafte"}, urgency="low", notes="home service"`

### Urdu (script)
- `"کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے"` →
  `language=URDU, service_type=AC_TECHNICIAN, location_hint="G-13", time_window={..., label: "کل صبح"}`
- `"ابھی ایف-۱۰ میں الیکٹریشن بھیجو"` →
  `language=URDU, service_type=ELECTRICIAN, location_hint="F-10", urgency="high", time_window={start: now, end: now+2h, label: "ابھی"}`
- `"بچوں کے لیے ریاضی کا ٹیوٹر چاہیے"` →
  `language=URDU, service_type=TUTOR, location_hint="", time_window=None, notes="ریاضی - بچوں کے لیے"`

### English
- `"I need an AC technician in G-13 tomorrow morning"` →
  `language=ENGLISH, service_type=AC_TECHNICIAN, location_hint="G-13", time_window={start: tomorrow 06:00, end: tomorrow 12:00, label: "tomorrow morning"}`
- `"Send a carpenter to I-8 today afternoon, urgent"` →
  `language=ENGLISH, service_type=CARPENTER, location_hint="I-8", time_window={start: today 12:00, end: today 18:00, label: "today afternoon"}, urgency="high"`
- `"Looking for a math tutor for my kids in F-7"` →
  `language=ENGLISH, service_type=TUTOR, location_hint="F-7", time_window=None, notes="math, for kids"`

## Trace event (required output)

Before returning, append:

```python
trace.append({
    "step": next_step,
    "agent": "IntentAgent",
    "phase": "decide",       # parsing IS a decision
    "input": {"raw_text": state.raw_text},
    "output": parsed_intent.model_dump(),
    "tool_calls": [{"name": "Gemini.flash.structured_output", "args": {...}, "result": "...", "latency_ms": 247}],
    "latency_ms": 247,
    "reasoning": f"Detected {parsed_intent.language.value}; extracted service={parsed_intent.service_type.value}, location='{parsed_intent.location_hint}'",
    "triggered_by": None,
})
```

## Edge cases

- **Empty `service_type`** → return `UNKNOWN`, let DiscoveryAgent route to a "please clarify" branch.
- **Missing `time_window`** → leave `None`. RankingAgent will treat it as "any time today".
- **Mixed language** → classify by script if any Urdu script chars are present; otherwise English vs Roman Urdu by a simple heuristic (presence of any of `chahiye, hai, mein, ko, abhi, kal, subah, raat, bhejo, dho`).
- **Profanity / unrelated text** → return `UNKNOWN` with `notes="off_topic"`.
