"""Karigar shared graph state.

Every LangGraph node reads from and writes to a single ``RequestSession``
instance. Fields are append-only for ``trace`` and ``excluded_provider_ids``.
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Literal, Optional
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field, PrivateAttr

KARACHI_TZ = ZoneInfo("Asia/Karachi")


# ── Enums ─────────────────────────────────────────────────────────────────────


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

    @property
    def pretty_name(self) -> str:
        """Human-readable name for receipts, WhatsApp, trace UI etc.

        Stored values are kept as lower_snake_case identifiers so they
        round-trip cleanly through JSON/DB. This property is the only
        approved way to render a ServiceType to a user.
        """
        return _SERVICE_DISPLAY.get(self, self.value.replace("_", " ").title())

    @classmethod
    def pretty(cls, raw: str) -> str:
        """Look up the pretty name from a raw enum-value string (e.g.
        from ``BookingRecord.service_type``). Falls back to a Title-Cased
        version of the raw string if unknown.
        """
        try:
            return cls(raw).pretty_name
        except ValueError:
            return raw.replace("_", " ").title()


_SERVICE_DISPLAY: dict[ServiceType, str] = {
    ServiceType.AC_TECHNICIAN: "AC Technician",
    ServiceType.PLUMBER: "Plumber",
    ServiceType.ELECTRICIAN: "Electrician",
    ServiceType.TUTOR: "Tutor",
    ServiceType.BEAUTICIAN: "Beautician",
    ServiceType.CARPENTER: "Carpenter",
    ServiceType.UNKNOWN: "Service",
}


# ── Intent ────────────────────────────────────────────────────────────────────


class TimeWindow(BaseModel):
    start: datetime
    end: datetime
    label: str  # human-readable, e.g. "tomorrow morning"


class ParsedIntent(BaseModel):
    language: Language
    service_type: ServiceType
    location_hint: str = ""  # raw user phrase, NOT geocoded
    time_window: Optional[TimeWindow] = None
    urgency: Literal["low", "normal", "high"] = "normal"
    notes: str = Field(default="", description="anything that doesn't fit other fields")


# ── Providers ─────────────────────────────────────────────────────────────────


class WorkingHours(BaseModel):
    start: str  # "HH:MM"
    end: str    # "HH:MM"


class Provider(BaseModel):
    id: str
    name: str
    services: list[str]
    lat: float
    lng: float
    rating: float  # 3.5 – 4.9
    price_per_visit: int  # PKR
    phone: str
    working_hours: WorkingHours
    busy_slots: list[str] = []  # ISO datetime strings


class GeoPoint(BaseModel):
    lat: float
    lng: float
    label: str = ""  # resolved sector name


# ── Ranking ───────────────────────────────────────────────────────────────────


class RankedCandidate(BaseModel):
    provider: Provider
    score: float
    sub_scores: dict[str, float]  # proximity, rating, availability, price
    reasoning: str
    distance_km: float
    slot_start: Optional[datetime] = None
    slot_end: Optional[datetime] = None


# ── Booking ───────────────────────────────────────────────────────────────────


class BookingStatus(str, Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"
    NO_SHOW = "NO_SHOW"


class BookingRecord(BaseModel):
    """In-memory booking representation (mirrors DB row)."""

    id: str
    session_id: str
    user_id: str
    provider_id: str
    provider_name: str
    service_type: str
    slot_start: datetime
    slot_end: datetime
    status: BookingStatus = BookingStatus.PENDING
    price_estimate: int
    receipt_png_path: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(KARACHI_TZ))


# ── Trace ─────────────────────────────────────────────────────────────────────


class ToolCall(BaseModel):
    name: str
    args: dict[str, Any] = {}
    result: Any = None
    latency_ms: int = 0


class TraceEvent(BaseModel):
    step: int
    agent: str
    phase: Literal["plan", "decide", "act", "follow_up", "recover"]
    input: dict[str, Any] = {}
    output: dict[str, Any] = {}
    tool_calls: list[ToolCall] = []
    latency_ms: int = 0
    reasoning: str = ""
    triggered_by: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(KARACHI_TZ))


# ── Session ───────────────────────────────────────────────────────────────────


class RequestSession(BaseModel):
    """The single shared state object that every LangGraph node reads/writes."""

    id: str  # ulid
    user_id: str
    user_phone: str = "0300-000-0000"
    raw_text: str

    parsed_intent: Optional[ParsedIntent] = None

    candidates: list[Provider] = []
    ranked: list[RankedCandidate] = []
    chosen: Optional[RankedCandidate] = None
    booking: Optional[BookingRecord] = None

    trace: list[TraceEvent] = []  # append-only

    # Conflict-resolution state
    excluded_provider_ids: list[str] = []  # append-only
    resolution_attempts: int = 0
    triggered_by: Optional[str] = None  # e.g. "no_show_detected:provider_42"

    # Snapshot of the user's ORIGINAL time_window at the moment of the first
    # conflict, so the resolver can apply widening relative to it (rather than
    # cumulatively widening an already-widened window each retry).
    original_time_window: Optional[TimeWindow] = None

    created_at: datetime = Field(default_factory=lambda: datetime.now(KARACHI_TZ))

    # Internal: step counter incremented by emit_trace.
    # Pydantic v2 requires PrivateAttr for mutable instance-level private state;
    # a plain `_step_counter: int = 0` is treated as a class attribute and would
    # raise on assignment.
    _step_counter: int = PrivateAttr(default=0)

    def next_step(self) -> int:
        self._step_counter += 1
        return self._step_counter
