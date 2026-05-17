"""Happy-path tests: 3 languages × canonical query.

Tests run without hitting Gemini by patching intent.run with a deterministic mock.
"""

from __future__ import annotations

import asyncio
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
from zoneinfo import ZoneInfo

from app.graph.state import (
    Language,
    ParsedIntent,
    RequestSession,
    ServiceType,
    TimeWindow,
)

_TZ = ZoneInfo("Asia/Karachi")


def _tomorrow_morning() -> TimeWindow:
    tomorrow = (datetime.now(_TZ) + timedelta(days=1)).replace(
        hour=6, minute=0, second=0, microsecond=0
    )
    return TimeWindow(start=tomorrow, end=tomorrow.replace(hour=12), label="kal subah")


def _mock_intent(language: Language) -> ParsedIntent:
    return ParsedIntent(
        language=language,
        service_type=ServiceType.AC_TECHNICIAN,
        location_hint="G-13",
        time_window=_tomorrow_morning(),
        urgency="normal",
    )


async def _make_session(lang: Language) -> RequestSession:
    state = RequestSession(
        id=f"test-{lang.value}",
        user_id="test_user",
        raw_text="Mujhe kal subah G-13 mein AC technician chahiye",
    )
    state.parsed_intent = _mock_intent(lang)
    return state


# ── Unit tests for individual nodes ───────────────────────────────────────────


@pytest.mark.asyncio
async def test_geocoder_g13():
    from app.tools.geocoder import MockGeocoder
    geo = await MockGeocoder().resolve("G-13")
    assert abs(geo.lat - 33.651) < 0.01
    assert abs(geo.lng - 72.940) < 0.01


@pytest.mark.asyncio
async def test_provider_store_g13_ac():
    from app.tools.geocoder import MockGeocoder
    from app.tools.providers import JsonProviderStore

    geo = await MockGeocoder().resolve("G-13")
    candidates = await JsonProviderStore().search(
        service=ServiceType.AC_TECHNICIAN,
        lat=geo.lat, lng=geo.lng,
        radius_km=5.0,
        exclude=[],
    )
    names = [c.name for c in candidates]
    assert len(candidates) > 0
    assert "Ali AC Services" in names, f"Expected Ali AC Services in {names}"


@pytest.mark.asyncio
async def test_ranking_ali_is_top():
    """Ali AC Services must rank #1 for the canonical query."""
    from app.tools.geocoder import MockGeocoder
    from app.tools.providers import JsonProviderStore
    from app.graph.nodes import ranking

    state = await _make_session(Language.ROMAN_URDU)
    geo = await MockGeocoder().resolve("G-13")
    candidates = await JsonProviderStore().search(
        service=ServiceType.AC_TECHNICIAN,
        lat=geo.lat, lng=geo.lng,
        radius_km=5.0,
        exclude=[],
    )
    state.candidates = candidates

    # Patch emit_trace to avoid SSE/DB side effects.
    # NOTE: the trace context's add_tool_call / set_output / set_reasoning are
    # *synchronous* methods, so we yield a MagicMock (not AsyncMock) to avoid
    # "coroutine never awaited" RuntimeWarnings.
    with patch("app.graph.nodes.ranking.emit_trace") as mock_trace:
        mock_trace.return_value.__aenter__ = AsyncMock(return_value=MagicMock())
        mock_trace.return_value.__aexit__ = AsyncMock(return_value=False)
        # Use real ranking logic directly
        from app.graph.nodes.ranking import (
            _proximity_score, _rating_score, _availability_score, _price_score,
            _availability_label, haversine_km
        )
        from app.graph.state import GeoPoint, RankedCandidate

        origin = GeoPoint(lat=geo.lat, lng=geo.lng)
        prices = [c.price_per_visit for c in candidates]
        tw = state.parsed_intent.time_window

        ranked = []
        for p in candidates:
            dist_km = haversine_km(origin.lat, origin.lng, p.lat, p.lng)
            score = (
                0.4 * _proximity_score(dist_km)
                + 0.3 * _rating_score(p.rating)
                + 0.2 * _availability_score(p, tw)
                + 0.1 * _price_score(p.price_per_visit, prices)
            )
            ranked.append((p, score, dist_km))

        ranked.sort(key=lambda x: -x[1])
        top = ranked[0]
        assert top[0].name == "Ali AC Services", (
            f"Expected Ali AC Services to rank #1 but got {top[0].name} (score={top[1]:.3f})"
        )


@pytest.mark.asyncio
async def test_discovery_node():
    from app.graph.nodes import discovery
    state = await _make_session(Language.ROMAN_URDU)

    with patch("app.graph.nodes.discovery.emit_trace") as mock_trace:
        ctx = MagicMock()  # sync .add_tool_call / .set_output / .set_reasoning
        mock_trace.return_value.__aenter__ = AsyncMock(return_value=ctx)
        mock_trace.return_value.__aexit__ = AsyncMock(return_value=False)

        result = await discovery.run(state)

    assert len(result.candidates) > 0
    names = [c.name for c in result.candidates]
    assert "Ali AC Services" in names


@pytest.mark.asyncio
@pytest.mark.parametrize("lang", [Language.ROMAN_URDU, Language.URDU, Language.ENGLISH])
async def test_happy_path_ranking_per_language(lang: Language):
    """Ranking is deterministic regardless of language."""
    from app.graph.nodes import ranking
    from app.tools.geocoder import MockGeocoder
    from app.tools.providers import JsonProviderStore

    state = await _make_session(lang)
    geo = await MockGeocoder().resolve("G-13")
    state.candidates = await JsonProviderStore().search(
        service=ServiceType.AC_TECHNICIAN,
        lat=geo.lat, lng=geo.lng, radius_km=5.0, exclude=[],
    )

    with patch("app.graph.nodes.ranking.emit_trace") as mock_trace:
        ctx = MagicMock()  # sync trace-context methods
        mock_trace.return_value.__aenter__ = AsyncMock(return_value=ctx)
        mock_trace.return_value.__aexit__ = AsyncMock(return_value=False)
        result = await ranking.run(state)

    assert len(result.ranked) > 0
    assert result.ranked[0].provider.name == "Ali AC Services"
    # Verify trace event shape through mock
    ctx.set_output.assert_called_once()
    ctx.set_reasoning.assert_called_once()


@pytest.mark.asyncio
async def test_trace_event_shape():
    """Each trace event must have the required fields per plan.md §3."""
    from app.graph.nodes import discovery
    from app.graph.state import TraceEvent

    state = await _make_session(Language.ENGLISH)

    with patch("app.graph.nodes.discovery.emit_trace") as mock_trace:
        ctx = MagicMock()
        mock_trace.return_value.__aenter__ = AsyncMock(return_value=ctx)
        mock_trace.return_value.__aexit__ = AsyncMock(return_value=False)
        await discovery.run(state)

    # Verify emit_trace was called with correct arguments
    call_kwargs = mock_trace.call_args
    assert call_kwargs is not None
    kwargs = call_kwargs.kwargs if call_kwargs.kwargs else {}
    args = call_kwargs.args if call_kwargs.args else ()
    # agent and phase must be present
    all_args = list(args) + list(kwargs.values())
    assert "DiscoveryAgent" in str(all_args)
    assert "act" in str(all_args)


@pytest.mark.asyncio
async def test_exclusion_list_filters_providers():
    """Excluded providers must not appear in Discovery results."""
    from app.graph.nodes import discovery

    state = await _make_session(Language.ENGLISH)
    state.excluded_provider_ids = ["provider_01"]  # Ali AC Services

    with patch("app.graph.nodes.discovery.emit_trace") as mock_trace:
        ctx = MagicMock()
        mock_trace.return_value.__aenter__ = AsyncMock(return_value=ctx)
        mock_trace.return_value.__aexit__ = AsyncMock(return_value=False)
        result = await discovery.run(state)

    ids = [c.id for c in result.candidates]
    assert "provider_01" not in ids, "Excluded provider appeared in candidates"
