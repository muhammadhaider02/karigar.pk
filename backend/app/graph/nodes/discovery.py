"""DiscoveryAgent: geocode location + search providers + optional reputation enrichment."""

from __future__ import annotations

from app.graph.state import GeoPoint, RequestSession, ServiceType
from app.graph.trace import emit_trace
from app.tools import get_tools


async def run(state: RequestSession) -> RequestSession:
    tools = get_tools()
    intent = state.parsed_intent
    assert intent is not None, "DiscoveryAgent requires parsed_intent"

    async with emit_trace(
        state,
        agent="DiscoveryAgent",
        phase="act",
        input={
            "location_hint": intent.location_hint,
            "service": intent.service_type.pretty_name,
            "exclude": state.excluded_worker_ids,
        },
    ) as t:
        # Step 1: Resolve location — GPS override > geocoded hint > Islamabad default
        if state.override_lat is not None and state.override_lng is not None:
            geo = GeoPoint(lat=state.override_lat, lng=state.override_lng, label="Your location")
            t.add_tool_call("GPS.override", {"lat": geo.lat, "lng": geo.lng}, {"label": geo.label})
        elif intent.location_hint:
            geo = await tools.geocoder.resolve(intent.location_hint)
            t.add_tool_call(
                "Geocoder.resolve",
                {"hint": intent.location_hint},
                {"lat": geo.lat, "lng": geo.lng, "label": geo.label},
            )
        else:
            geo = GeoPoint(lat=33.6938, lng=73.0652, label="Islamabad")
            t.add_tool_call("GPS.default", {}, {"label": geo.label})

        # Step 2: Search providers
        candidates = await tools.provider_store.search(
            service=intent.service_type,
            lat=geo.lat,
            lng=geo.lng,
            radius_km=5.0,
            exclude=state.excluded_worker_ids,
        )
        t.add_tool_call(
            "ProviderStore.search",
            {
                "service": intent.service_type.pretty_name,
                "lat": geo.lat,
                "lng": geo.lng,
                "radius_km": 5.0,
                "exclude": state.excluded_worker_ids,
            },
            {"count": len(candidates), "ids": [c.id for c in candidates]},
        )

        # Step 3: Optional reputation enrichment (top-3 low-confidence candidates)
        uncertain = [c for c in candidates if c.rating < 4.0][:3]
        for provider in uncertain:
            try:
                snippets = await tools.search.lookup(
                    f"{provider.name} Islamabad reviews"
                )
                if snippets:
                    t.add_tool_call(
                        "Search.lookup",
                        {"query": f"{provider.name} Islamabad reviews"},
                        {"snippets": snippets[:2]},
                    )
            except Exception:
                pass

        state.candidates = candidates

        t.set_output(
            {
                "candidate_count": len(candidates),
                "geo_label": geo.label,
            }
        )
        t.set_reasoning(
            f"Found {len(candidates)} candidates within 5km of {geo.label}"
            + (f"; enriched {len(uncertain)} low-confidence providers via Search" if uncertain else "")
        )

    return state
