"""SQLAlchemy async models for Karigar.

Tables:
- providers          (seeded from providers.json)
- bookings           (UNIQUE provider_id+slot_start for atomic-hold)
- agent_traces       (one row per TraceEvent)
- conflict_events    (one row per bus event)
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class ProviderModel(Base):
    __tablename__ = "providers"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    services: Mapped[str] = mapped_column(Text, nullable=False)  # JSON array
    lat: Mapped[float]
    lng: Mapped[float]
    rating: Mapped[float]
    price_per_visit: Mapped[int]
    phone: Mapped[str] = mapped_column(String, nullable=False)
    working_hours: Mapped[str] = mapped_column(Text, nullable=False)  # JSON
    busy_slots: Mapped[str] = mapped_column(Text, default="[]")  # JSON array

    bookings: Mapped[list["BookingModel"]] = relationship(
        back_populates="provider", lazy="select"
    )


class BookingModel(Base):
    __tablename__ = "bookings"

    id: Mapped[str] = mapped_column(String, primary_key=True)  # ulid
    session_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String, nullable=False)
    provider_id: Mapped[str] = mapped_column(
        ForeignKey("providers.id"), nullable=False
    )
    provider_name: Mapped[str] = mapped_column(String, nullable=False)
    service_type: Mapped[str] = mapped_column(String, nullable=False)
    slot_start: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    slot_end: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    status: Mapped[str] = mapped_column(String, default="PENDING")
    price_estimate: Mapped[int] = mapped_column(Integer, nullable=False)
    receipt_png_path: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    provider: Mapped["ProviderModel"] = relationship(back_populates="bookings")
    traces: Mapped[list["AgentTraceModel"]] = relationship(
        back_populates="booking",
        primaryjoin="BookingModel.session_id == foreign(AgentTraceModel.session_id)",
        lazy="select",
        viewonly=True,
        # Both sides of this logical join are viewonly; declare the overlap
        # to silence the SAWarning about column copy conflicts.
        overlaps="booking",
    )

    __table_args__ = (
        UniqueConstraint("provider_id", "slot_start", name="uq_provider_slot"),
    )


class AgentTraceModel(Base):
    __tablename__ = "agent_traces"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    step: Mapped[int] = mapped_column(Integer, nullable=False)
    agent: Mapped[str] = mapped_column(String, nullable=False)
    phase: Mapped[str] = mapped_column(String, nullable=False)
    input_data: Mapped[str] = mapped_column(Text, default="{}")   # JSON
    output_data: Mapped[str] = mapped_column(Text, default="{}")  # JSON
    tool_calls: Mapped[str] = mapped_column(Text, default="[]")   # JSON
    latency_ms: Mapped[int] = mapped_column(Integer, default=0)
    reasoning: Mapped[str] = mapped_column(Text, default="")
    triggered_by: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    booking: Mapped[Optional["BookingModel"]] = relationship(
        back_populates="traces",
        primaryjoin="foreign(AgentTraceModel.session_id) == BookingModel.session_id",
        lazy="select",
        viewonly=True,
        overlaps="traces",
    )


class ConflictEventModel(Base):
    __tablename__ = "conflict_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    key: Mapped[str] = mapped_column(String, nullable=False)
    session_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    failed_provider_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    payload: Mapped[str] = mapped_column(Text, default="{}")  # JSON
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
