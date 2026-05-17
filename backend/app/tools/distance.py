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
    """Drop-in replacement backed by Google Distance Matrix API.

    Stub — see `GoogleGeocoder` for the wiring pattern. Until implemented,
    `build_tools()` will only instantiate it when `GOOGLE_MAPS_KEY` is set,
    and the first call surfaces a clear NotImplementedError.
    """

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key

    async def km(self, a: GeoPoint, b: GeoPoint) -> float:  # pragma: no cover
        raise NotImplementedError(
            "GoogleDistanceMatrix is a stub. Implement it or unset "
            "GOOGLE_MAPS_KEY to use HaversineDistance."
        )
