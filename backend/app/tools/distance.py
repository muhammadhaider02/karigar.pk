"""HaversineDistance: pure-Python distance calculation."""

from __future__ import annotations

import math

from app.graph.state import GeoPoint


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class HaversineDistance:
    async def km(self, a: GeoPoint, b: GeoPoint) -> float:
        return haversine_km(a.lat, a.lng, b.lat, b.lng)


class GoogleDistanceMatrix:
    """Distance matrix backed by Google API with Haversine fallback."""

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key
        self._haversine = HaversineDistance()

    async def km(self, a: GeoPoint, b: GeoPoint) -> float:
        try:
            import httpx
            url = "https://maps.googleapis.com/maps/api/distancematrix/json"
            params = {
                "origins": f"{a.lat},{a.lng}",
                "destinations": f"{b.lat},{b.lng}",
                "mode": "driving",
                "key": self.api_key,
            }
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(url, params=params)
                data = resp.json()
            row = data.get("rows", [{}])[0]
            elem = row.get("elements", [{}])[0]
            if elem.get("status") == "OK":
                return elem["distance"]["value"] / 1000.0
        except Exception:
            pass
        return await self._haversine.km(a, b)
