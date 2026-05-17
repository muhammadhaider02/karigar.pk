"""MockGeocoder: Islamabad sector → lat/lng lookup table.

Covers G-13, F-7, F-10, I-8, G-9, Bahria and common alternate spellings.

`GoogleGeocoder` is the swap-in production class. It is intentionally a
stub that raises NotImplementedError at call-time: `build_tools()` lazy-
imports it only when `GOOGLE_MAPS_KEY` is set, which keeps the protocol
boundary in place (zero refactor when a real implementation lands).
"""

from __future__ import annotations

import re

from app.graph.state import GeoPoint

# Sector centroid coordinates (Islamabad)
_SECTOR_TABLE: dict[str, tuple[float, float]] = {
    "g-13": (33.6510, 72.9400),
    "g13":  (33.6510, 72.9400),
    "g 13": (33.6510, 72.9400),
    "f-7":  (33.7200, 73.0420),
    "f7":   (33.7200, 73.0420),
    "f 7":  (33.7200, 73.0420),
    "f-10": (33.6960, 73.0150),
    "f10":  (33.6960, 73.0150),
    "f 10": (33.6960, 73.0150),
    "i-8":  (33.6750, 73.0720),
    "i8":   (33.6750, 73.0720),
    "i 8":  (33.6750, 73.0720),
    "g-9":  (33.7050, 73.0500),
    "g9":   (33.7050, 73.0500),
    "g 9":  (33.7050, 73.0500),
    "bahria": (33.5380, 72.9050),
    "bahria phase 4": (33.5300, 72.9100),
    "bahria phase4":  (33.5300, 72.9100),
    "e-11": (33.7280, 73.0250),
    "e11":  (33.7280, 73.0250),
    "d-12": (33.7350, 73.0100),
    "h-8":  (33.6680, 73.0580),
    "islamabad": (33.6938, 73.0652),
}

# Urdu/Roman Urdu sector aliases
_URDU_ALIASES: dict[str, str] = {
    "جی-۱۳": "g-13",
    "جی ۱۳": "g-13",
    "ایف-۷": "f-7",
    "ایف ۷": "f-7",
    "ایف-۱۰": "f-10",
    "آئی-۸": "i-8",
    "جی-۹": "g-9",
    "بحریہ": "bahria",
}


def _normalise(hint: str) -> str:
    """Lower-case and strip extra whitespace."""
    return re.sub(r"\s+", " ", hint.lower().strip())


class MockGeocoder:
    """Resolve a location hint to a lat/lng using a lookup table."""

    async def resolve(self, hint: str) -> GeoPoint:
        # Try Urdu alias first
        for urdu_key, eng_key in _URDU_ALIASES.items():
            if urdu_key in hint:
                hint = eng_key
                break

        normalised = _normalise(hint)

        # Exact match
        if normalised in _SECTOR_TABLE:
            lat, lng = _SECTOR_TABLE[normalised]
            return GeoPoint(lat=lat, lng=lng, label=hint)

        # Substring match (e.g. "near G-13" or "G-13 area")
        for key, (lat, lng) in _SECTOR_TABLE.items():
            if key in normalised:
                return GeoPoint(lat=lat, lng=lng, label=key)

        # Default to Islamabad centre
        return GeoPoint(lat=33.6938, lng=73.0652, label=f"{hint} (approx)")


class GoogleGeocoder:
    """Drop-in replacement for `MockGeocoder` backed by Google Geocoding API.

    Not implemented yet — the class is present so `build_tools()` can
    `from app.tools.geocoder import GoogleGeocoder` without raising
    `ImportError` when `GOOGLE_MAPS_KEY` is set. Wire `httpx.AsyncClient`
    + `https://maps.googleapis.com/maps/api/geocode/json` to finish.
    """

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key

    async def resolve(self, hint: str) -> GeoPoint:  # pragma: no cover
        raise NotImplementedError(
            "GoogleGeocoder is a stub. Either implement it (see app/tools/"
            "geocoder.py) or unset GOOGLE_MAPS_KEY to use MockGeocoder."
        )
