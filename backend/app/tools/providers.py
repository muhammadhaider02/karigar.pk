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


_SERVICE_KEYWORDS = {
    "plumber": "plumber",
    "electrician": "electrician",
    "ac_technician": "air conditioning repair",
    "carpenter": "carpenter",
    "painter": "painter",
    "cleaner": "house cleaning",
    "handyman": "handyman",
    "appliance_repair": "appliance repair",
    "locksmith": "locksmith",
}


class GooglePlacesStore:
    """Provider store backed by Google Places Nearby Search with JsonProviderStore fallback."""

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key
        self._json_store = JsonProviderStore()

    async def search(
        self,
        service: ServiceType,
        lat: float,
        lng: float,
        radius_km: float,
        exclude: list[str],
    ) -> list[Provider]:
        if not self.api_key:
            return await self._json_store.search(service, lat, lng, radius_km, exclude)
        try:
            import httpx
            keyword = _SERVICE_KEYWORDS.get(service.value, service.value.replace("_", " "))
            url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            params = {
                "location": f"{lat},{lng}",
                "radius": int(radius_km * 1000),
                "keyword": keyword,
                "key": self.api_key,
            }
            async with httpx.AsyncClient(timeout=8.0) as client:
                r = await client.get(url, params=params)
                data = r.json()
            if data.get("status") not in ("OK", "ZERO_RESULTS"):
                return await self._json_store.search(service, lat, lng, radius_km, exclude)
            results: list[Provider] = []
            for idx, place in enumerate(data.get("results", [])[:10]):
                pid = f"gplace_{place.get('place_id', idx)}"
                if pid in exclude:
                    continue
                loc = place.get("geometry", {}).get("location", {})
                results.append(Provider(
                    id=pid,
                    name=place.get("name", "Unknown"),
                    services=[service.value],
                    lat=loc.get("lat", lat),
                    lng=loc.get("lng", lng),
                    rating=float(place.get("rating", 4.0)),
                    price_per_visit=800 + (idx * 50),
                    phone=place.get("formatted_phone_number", "N/A"),
                    working_hours={"start": "08:00", "end": "20:00"},
                    busy_slots=[],
                ))
            if not results:
                return await self._json_store.search(service, lat, lng, radius_km, exclude)
            return results
        except Exception:
            return await self._json_store.search(service, lat, lng, radius_km, exclude)
