"""Tool Protocols and build_tools factory.

Every tool implements a Protocol so implementations are swappable via env vars.
Import ``build_tools`` to get the active set of tool implementations.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Protocol, runtime_checkable

if TYPE_CHECKING:
    from datetime import datetime

    from app.graph.state import (
        BookingRecord,
        GeoPoint,
        Provider,
        RankedCandidate,
        ServiceType,
    )


# ── Protocols ─────────────────────────────────────────────────────────────────


@runtime_checkable
class Geocoder(Protocol):
    async def resolve(self, hint: str) -> "GeoPoint": ...


@runtime_checkable
class ProviderStore(Protocol):
    async def search(
        self,
        service: "ServiceType",
        lat: float,
        lng: float,
        radius_km: float,
        exclude: list[str],
    ) -> list["Provider"]: ...


@runtime_checkable
class Distance(Protocol):
    async def km(self, a: "GeoPoint", b: "GeoPoint") -> float: ...


@runtime_checkable
class Availability(Protocol):
    async def check_and_hold(
        self,
        provider_id: str,
        slot_start: "datetime",
        slot_end: "datetime",
        session_id: str,
        user_id: str,
        provider_name: str,
        service_type: str,
        price_estimate: int,
    ) -> "BookingRecord": ...

    async def release(self, booking_id: str) -> None: ...

    async def get_booking(self, booking_id: str) -> "BookingRecord | None": ...

    async def update_status(self, booking_id: str, status: str) -> None: ...


@runtime_checkable
class Notifier(Protocol):
    async def send(self, channel: str, to: str, message: str) -> None: ...

    async def get_log(self) -> list[dict]: ...


@runtime_checkable
class SearchTool(Protocol):
    async def lookup(self, query: str) -> list[dict]: ...


# ── Tools container ───────────────────────────────────────────────────────────


@dataclass
class Tools:
    geocoder: Geocoder
    provider_store: ProviderStore
    distance: Distance
    availability: Availability
    notifier: Notifier
    search: SearchTool


# ── Factory ───────────────────────────────────────────────────────────────────


def build_tools() -> Tools:
    """Return the active tool implementations based on env settings."""
    from app.config import get_settings
    from app.tools.availability import SqliteAvailability
    from app.tools.distance import HaversineDistance
    from app.tools.geocoder import MockGeocoder
    from app.tools.notifier import MockNotifier
    from app.tools.providers import JsonProviderStore
    from app.tools.search import AntigravityBrowserSearch

    settings = get_settings()

    geocoder: Geocoder
    provider_store: ProviderStore
    distance: Distance

    if settings.use_real_maps:
        # Real Google APIs — imported lazily to avoid hard dependency
        from app.tools.geocoder import GoogleGeocoder  # type: ignore
        from app.tools.distance import GoogleDistanceMatrix  # type: ignore
        from app.tools.providers import GooglePlacesStore  # type: ignore

        geocoder = GoogleGeocoder(api_key=settings.google_maps_key)
        provider_store = GooglePlacesStore(api_key=settings.google_maps_key)
        distance = GoogleDistanceMatrix(api_key=settings.google_maps_key)
    else:
        geocoder = MockGeocoder()
        provider_store = JsonProviderStore()
        distance = HaversineDistance()

    return Tools(
        geocoder=geocoder,
        provider_store=provider_store,
        distance=distance,
        availability=SqliteAvailability(),
        notifier=MockNotifier(),
        search=AntigravityBrowserSearch(),
    )


# Singleton tools instance (initialised once at startup)
_tools: Tools | None = None


def get_tools() -> Tools:
    global _tools
    if _tools is None:
        _tools = build_tools()
    return _tools
