"""JsonProviderStore: reads providers from data/providers.json.

Filters by service type, radius and excluded provider IDs.
"""

from __future__ import annotations

import json
import math
from functools import lru_cache
from pathlib import Path

from app.graph.state import GeoPoint, Provider, ServiceType

_DATA_FILE = Path(__file__).parent.parent / "data" / "providers.json"


@lru_cache(maxsize=1)
def _load_providers() -> list[Provider]:
    with open(_DATA_FILE, encoding="utf-8") as f:
        raw = json.load(f)
    return [Provider(**p) for p in raw]


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class JsonProviderStore:
    """Searches providers.json for nearby providers matching the requested service."""

    async def search(
        self,
        service: ServiceType,
        lat: float,
        lng: float,
        radius_km: float,
        exclude: list[str],
    ) -> list[Provider]:
        all_providers = _load_providers()
        results: list[Provider] = []

        for p in all_providers:
            if p.id in exclude:
                continue
            if service.value not in p.services and service != ServiceType.UNKNOWN:
                continue
            dist = _haversine_km(lat, lng, p.lat, p.lng)
            if dist <= radius_km:
                results.append(p)

        return results


class GooglePlacesStore:
    """Drop-in replacement backed by Google Places Nearby Search API.

    Stub — see `GoogleGeocoder`. Implement against
    `https://maps.googleapis.com/maps/api/place/nearbysearch/json` with
    `keyword=<service>` and convert the response to `Provider`.
    """

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key

    async def search(
        self,
        service: ServiceType,
        lat: float,
        lng: float,
        radius_km: float,
        exclude: list[str],
    ) -> list[Provider]:  # pragma: no cover
        raise NotImplementedError(
            "GooglePlacesStore is a stub. Implement it or unset "
            "GOOGLE_MAPS_KEY to use JsonProviderStore."
        )
