"""Karigar shared graph state.

Every LangGraph node reads from and writes to a single ``RequestSession``
instance. Fields are append-only for ``trace`` and ``excluded_worker_ids``.
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
    PAINTER = "painter"
    CLEANER = "cleaner"
    SOLAR_TECHNICIAN = "solar_technician"
    PEST_CONTROL = "pest_control"
    DRIVER = "driver"
    WELDER = "welder"
    UNKNOWN = "unknown"

    @property
    def pretty_name(self) -> str:
        """Human-readable name for receipts, WhatsApp, trace UI etc."""
        return _SERVICE_DISPLAY.get(self, self.value.replace("_", " ").title())

    @classmethod
    def pretty(cls, raw: str) -> str:
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
    ServiceType.PAINTER: "Painter",
    ServiceType.CLEANER: "Cleaner",
    ServiceType.SOLAR_TECHNICIAN: "Solar Technician",
    ServiceType.PEST_CONTROL: "Pest Control",
    ServiceType.DRIVER: "Driver",
    ServiceType.WELDER: "Welder",
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
    id: str          # UUID string from workers.id
    name: str
    services: list[str]
    lat: float
    lng: float
    rating: float
    price_per_visit: int  # PKR — maps to workers.rate_per_hour
    phone: str
    working_hours: WorkingHours
    busy_slots: list[str] = []  # ISO datetime strings

    @classmethod
    def from_worker_row(cls, row: dict) -> "Provider":
        wh = row.get("working_hours") or {"start": "08:00", "end": "20:00"}
        if isinstance(wh, dict):
            working_hours = WorkingHours(start=wh.get("start", "08:00"), end=wh.get("end", "20:00"))
        else:
            working_hours = WorkingHours(start="08:00", end="20:00")
        busy = row.get("busy_slots") or []
        return cls(
            id=str(row["id"]),
            name=row.get("full_name", "Unknown"),
            services=list(row.get("skills") or []),
            lat=float(row.get("home_lat") or 33.6938),
            lng=float(row.get("home_lng") or 73.0652),
            rating=float(row.get("rating") or 0.0),
            price_per_visit=int(row.get("rate_per_hour") or 500),
            phone=row.get("phone_number") or "N/A",
            working_hours=working_hours,
            busy_slots=list(busy) if isinstance(busy, list) else [],
        )


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
    """In-memory booking representation (mirrors Supabase bookings row)."""

    id: str
    session_id: str
    user_id: str
    provider_id: str    # UUID string (workers.id)
    provider_name: str
    service_type: str
    slot_start: datetime
    slot_end: datetime
    status: BookingStatus = BookingStatus.PENDING
    price_estimate: int
    receipt_url: Optional[str] = None   # Supabase Storage public URL
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

    id: str  # UUID
    user_id: str
    user_phone: str = "0300-0000000"
    raw_text: str

    # GPS coordinates from the client device — when set, DiscoveryAgent skips geocoding
    override_lat: Optional[float] = None
    override_lng: Optional[float] = None

    parsed_intent: Optional[ParsedIntent] = None

    candidates: list[Provider] = []
    ranked: list[RankedCandidate] = []
    chosen: Optional[RankedCandidate] = None
    booking: Optional[BookingRecord] = None

    trace: list[TraceEvent] = []  # append-only

    # Conflict-resolution state
    excluded_worker_ids: list[str] = []  # UUID strings — append-only
    resolution_attempts: int = 0
    triggered_by: Optional[str] = None  # e.g. "no_show_detected:<worker-uuid>"

    # Snapshot of the user's ORIGINAL time_window at the moment of the first
    # conflict, so the resolver can apply widening relative to it.
    original_time_window: Optional[TimeWindow] = None

    created_at: datetime = Field(default_factory=lambda: datetime.now(KARACHI_TZ))

    _step_counter: int = PrivateAttr(default=0)

    def next_step(self) -> int:
        self._step_counter += 1
        return self._step_counter
