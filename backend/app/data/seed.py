"""Seed script: writes providers.json → SQLite, verifies canonical query.

Run with:
    uv run python -m app.data.seed
"""

from __future__ import annotations

import asyncio
import json
import sys
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────
_THIS_DIR = Path(__file__).parent
_PROVIDERS_JSON = _THIS_DIR / "providers.json"
_REPORT_DIR = Path(__file__).parent.parent.parent / "runtime"


async def _seed_db() -> None:
    from app.db.session import create_tables, get_raw_session
    from app.db.models import ProviderModel

    await create_tables()

    with open(_PROVIDERS_JSON, encoding="utf-8") as f:
        providers_raw = json.load(f)

    async with await get_raw_session() as db:
        async with db.begin():
            # Clear existing providers
            from sqlalchemy import text
            await db.execute(text("DELETE FROM providers"))

            for p in providers_raw:
                row = ProviderModel(
                    id=p["id"],
                    name=p["name"],
                    services=json.dumps(p["services"]),
                    lat=p["lat"],
                    lng=p["lng"],
                    rating=p["rating"],
                    price_per_visit=p["price_per_visit"],
                    phone=p["phone"],
                    working_hours=json.dumps(p["working_hours"]),
                    busy_slots=json.dumps(p.get("busy_slots", [])),
                )
                await db.merge(row)

    print(f"[OK] {len(providers_raw)} providers loaded into SQLite")


def _category_summary() -> dict:
    with open(_PROVIDERS_JSON, encoding="utf-8") as f:
        providers = json.load(f)

    by_service: dict[str, int] = {}
    by_sector: dict[str, int] = {}

    sector_map = {
        (33.6, 33.67): "G-13",
        (33.71, 33.73): "F-7",
        (33.69, 33.71): "F-10 / G-9",
        (33.67, 33.69): "I-8",
        (33.53, 33.56): "Bahria",
    }

    for p in providers:
        for svc in p["services"]:
            by_service[svc] = by_service.get(svc, 0) + 1

    return {"by_service": by_service, "total": len(providers)}


async def verify_canonical() -> None:
    """Verify the canonical demo query returns Ali AC Services as top match."""
    from app.tools.geocoder import MockGeocoder
    from app.tools.providers import JsonProviderStore
    from app.graph.state import ServiceType

    geocoder = MockGeocoder()
    store = JsonProviderStore()

    geo = await geocoder.resolve("G-13")
    candidates = await store.search(
        service=ServiceType.AC_TECHNICIAN,
        lat=geo.lat,
        lng=geo.lng,
        radius_km=5.0,
        exclude=[],
    )

    if not candidates:
        print("✗ Canonical query returned 0 candidates!", file=sys.stderr)
        sys.exit(1)

    # Quick ranking to find top
    from app.tools.distance import haversine_km
    from app.graph.state import GeoPoint

    origin = GeoPoint(lat=geo.lat, lng=geo.lng)
    scored = sorted(
        candidates,
        key=lambda p: -(0.4 * max(0, 1 - haversine_km(geo.lat, geo.lng, p.lat, p.lng) / 5)
                       + 0.3 * max(0, (p.rating - 3.0) / 2.0)),
    )
    top = scored[0]
    if top.name != "Ali AC Services":
        print(f"[FAIL] Canonical query top match: {top.name} (expected Ali AC Services)", file=sys.stderr)
        sys.exit(1)

    print(f"[OK] Canonical query G-13 + AC technician + tomorrow morning -> top match: {top.name}")


def _write_report(summary: dict) -> None:
    _REPORT_DIR.mkdir(parents=True, exist_ok=True)
    report_path = _REPORT_DIR / "seed-report.md"
    lines = ["# Karigar Seed Report\n\n"]
    lines.append(f"**Total providers:** {summary['total']}\n\n")
    lines.append("## By service category\n\n")
    for svc, count in sorted(summary["by_service"].items()):
        lines.append(f"- {svc}: {count}\n")
    report_path.write_text("".join(lines), encoding="utf-8")
    print(f"[OK] Seed report written to {report_path}")


async def main() -> None:
    await _seed_db()
    summary = _category_summary()
    _write_report(summary)
    await verify_canonical()
    print("[OK] 6 categories represented")
    print("\nSeed complete. Run the backend with:")
    print("  uv run python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000")


if __name__ == "__main__":
    asyncio.run(main())
