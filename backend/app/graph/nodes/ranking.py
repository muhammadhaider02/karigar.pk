"""RankingAgent: deterministic weighted scorer — no LLM.

Formula: score = 0.4*proximity + 0.3*rating + 0.2*availability + 0.1*price
"""

from __future__ import annotations

import math
from datetime import datetime

from app.graph.state import GeoPoint, Provider, RankedCandidate, RequestSession
from app.graph.trace import emit_trace
from app.tools import get_tools
from app.tools.distance import haversine_km

_SEARCH_LAT = 33.6938  # default (Islamabad centre) — overridden by geo
_SEARCH_LNG = 73.0652


def _proximity_score(distance_km: float) -> float:
    return max(0.0, 1.0 - distance_km / 5.0)


def _rating_score(rating: float) -> float:
    return max(0.0, (rating - 3.0) / 2.0)


def _availability_score(provider: Provider, time_window) -> float:
    if time_window is None:
        return 0.7  # treat as "available in window"

    # Normalise to naive UTC for comparison (busy_slots are stored as naive)
    def _naive(dt: datetime) -> datetime:
        return dt.replace(tzinfo=None) if dt.tzinfo else dt

    win_start = _naive(time_window.start)
    win_end = _naive(time_window.end)

    busy_datetimes: list[datetime] = []
    for s in provider.busy_slots:
        try:
            busy_datetimes.append(_naive(datetime.fromisoformat(s)))
        except ValueError:
            pass

    # 1.0: the exact requested slot (= window start) is free (no busy_slot
    # within ±1h of it).
    slot_occupied = any(abs((b - win_start).total_seconds()) < 3600 for b in busy_datetimes)
    if not slot_occupied:
        return 1.0

    # 0.7: provider has at least one free moment anywhere inside the window
    window_occupied = any(win_start <= b <= win_end for b in busy_datetimes)
    if not window_occupied:
        return 0.7

    # 0.4: provider is free somewhere on the same calendar day
    if not any(b.date() == win_start.date() for b in busy_datetimes):
        return 0.4

    return 0.0


def _price_score(price: int, prices: list[int]) -> float:
    pmin, pmax = min(prices), max(prices)
    if pmax == pmin:
        return 0.5
    return 1.0 - (price - pmin) / (pmax - pmin)


def _availability_label(score: float) -> str:
    if score >= 1.0:
        return "exact slot free"
    if score >= 0.7:
        return "available in window"
    if score >= 0.4:
        return "available same day"
    return "unavailable today"


async def run(state: RequestSession) -> RequestSession:
    tools = get_tools()
    candidates = state.candidates
    intent = state.parsed_intent

    async with emit_trace(
        state,
        agent="RankingAgent",
        phase="decide",
        input={"candidate_count": len(candidates)},
    ) as t:
        if not candidates:
            state.ranked = []
            t.set_output({"ranked_count": 0})
            t.set_reasoning("No candidates to rank")
            return state

        # Get the search origin from geocoder (re-resolve cheaply from intent)
        try:
            geo = await tools.geocoder.resolve(
                intent.location_hint if intent else "Islamabad"
            )
            origin = GeoPoint(lat=geo.lat, lng=geo.lng)
        except Exception:
            origin = GeoPoint(lat=_SEARCH_LAT, lng=_SEARCH_LNG)

        prices = [c.price_per_visit for c in candidates]
        time_window = intent.time_window if intent else None

        ranked: list[RankedCandidate] = []
        for provider in candidates:
            dist_km = haversine_km(origin.lat, origin.lng, provider.lat, provider.lng)
            prox = _proximity_score(dist_km)
            rat = _rating_score(provider.rating)
            avail = _availability_score(provider, time_window)
            price = _price_score(provider.price_per_visit, prices)

            score = 0.4 * prox + 0.3 * rat + 0.2 * avail + 0.1 * price

            avail_label = _availability_label(avail)
            reasoning = (
                f"{provider.name}: {dist_km:.1f} km away, "
                f"rating {provider.rating}, {avail_label}, "
                f"Rs. {provider.price_per_visit} — final score {score:.2f}"
            )

            slot_start = time_window.start if time_window else None
            slot_end = time_window.end if time_window else None

            ranked.append(
                RankedCandidate(
                    provider=provider,
                    score=score,
                    sub_scores={
                        "proximity": round(prox, 3),
                        "rating": round(rat, 3),
                        "availability": round(avail, 3),
                        "price": round(price, 3),
                    },
                    reasoning=reasoning,
                    distance_km=round(dist_km, 2),
                    slot_start=slot_start,
                    slot_end=slot_end,
                )
            )

        # Sort: score desc, then rating desc, then distance asc, then id asc
        ranked.sort(
            key=lambda r: (-r.score, -r.provider.rating, r.distance_km, r.provider.id)
        )
        state.ranked = ranked

        t.set_output(
            {
                "ranked": [
                    {"id": r.provider.id, "name": r.provider.name, "score": round(r.score, 3)}
                    for r in ranked[:5]
                ]
            }
        )
        t.set_reasoning(
            f"Ranked {len(ranked)} candidates by weighted score "
            f"(0.4 proximity, 0.3 rating, 0.2 availability, 0.1 price); "
            f"top: {ranked[0].provider.name} (score={ranked[0].score:.2f})"
        )

    return state
