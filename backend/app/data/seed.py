"""Seed mock workers from providers.json into Supabase workers table.

Idempotent: upserts on legacy_id so re-running is safe.
Run standalone with: uv run python -m app.data.seed
"""

from __future__ import annotations

import asyncio
import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

_DATA_FILE = Path(__file__).parent / "providers.json"


def _infer_district(lat: float, lng: float) -> tuple[str, str]:
    """Best-effort district/area from Islamabad-area coordinates."""
    if lng < 73.0:
        district = "Rawalpindi"
        area = "Saddar" if lat < 33.67 else "Chaklala"
    elif lng < 73.05:
        district = "Islamabad"
        area = "G-7" if lat < 33.71 else "G-11"
    else:
        district = "Islamabad"
        area = "I-8" if lat < 33.71 else "F-7"
    return district, area


def _map_provider_to_worker(p: dict) -> dict:
    if "area" in p:
        district = "Islamabad"
        area = p["area"]
    else:
        district, area = _infer_district(p["lat"], p["lng"])
    return {
        "full_name": p["name"],
        "phone_number": p.get("phone", ""),
        "skills": p.get("services", []),
        "rate_per_hour": p.get("price_per_visit", 500),
        "minimum_charge": p.get("price_per_visit", 500),
        "home_lat": p["lat"],
        "home_lng": p["lng"],
        "district": district,
        "area": area,
        "rating": float(p.get("rating", 0.0)),
        "working_hours": p.get("working_hours", {"start": "08:00", "end": "20:00"}),
        "busy_slots": p.get("busy_slots", []),
        "verification_status": "verified",
        "is_online": True,
        "is_available": True,
        "is_seed_data": True,
        "legacy_id": p["id"],
    }


async def seed_workers() -> None:
    """Upsert all providers.json entries into Supabase workers table."""
    from app.db.supabase_client import get_supabase

    providers = json.loads(_DATA_FILE.read_text(encoding="utf-8"))
    rows = [_map_provider_to_worker(p) for p in providers]

    supabase = await get_supabase()
    result = await supabase.table("workers").upsert(
        rows,
        on_conflict="legacy_id",
    ).execute()

    count = len(result.data) if result.data else 0
    logger.info("Seeded %d workers from providers.json", count)


async def main() -> None:
    logging.basicConfig(level=logging.INFO)
    await seed_workers()
    print("Seed complete.")


if __name__ == "__main__":
    asyncio.run(main())
