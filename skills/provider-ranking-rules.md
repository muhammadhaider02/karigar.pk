# Skill: Provider Ranking Rules

> Load this skill when working on `backend/app/graph/nodes/ranking.py` or its tests.
> Owner: `backend-engineer`.

## Purpose

Deterministically rank candidate providers so the same query always returns the same ordering. Pure function: no LLM. The DecisionAgent (next node) is the one that adds language-aware nuance on top.

## The formula

```
score = 0.40 * proximity_score
      + 0.30 * rating_score
      + 0.20 * availability_score
      + 0.10 * price_score
```

All sub-scores are in `[0.0, 1.0]`. Final `score` is in `[0.0, 1.0]`.

### `proximity_score`

```python
proximity_score = max(0.0, 1.0 - (distance_km / 5.0))
```

- Distance is computed by the active `Distance` tool (haversine for mock, Distance Matrix for real).
- Providers > 5 km away get `0.0` (and should be filtered out by Discovery's radius, so this is a safety net).
- The 5 km cap matches DiscoveryAgent's default search radius.

### `rating_score`

```python
rating_score = max(0.0, (rating - 3.0) / 2.0)
```

- Maps 3.0 → 0.0 and 5.0 → 1.0 linearly.
- Anything below 3.0 is clamped to 0.0. (We don't show < 3.0 providers anyway, but this keeps the formula safe.)

### `availability_score`

```python
if exact slot inside time_window is free:
    availability_score = 1.0
elif provider is free anywhere inside time_window:
    availability_score = 0.7
elif provider is free on the same calendar day:
    availability_score = 0.4
else:
    availability_score = 0.0
```

When `parsed_intent.time_window is None`, treat it as "any time today": use the second branch.

### `price_score`

Normalised across the *current candidate set* (not globally), so cheaper-within-cohort wins:
```python
prices = [c.price_per_visit for c in candidates]
pmin, pmax = min(prices), max(prices)
if pmax == pmin:
    price_score = 0.5    # all equal -> neutral
else:
    price_score = 1.0 - ((price - pmin) / (pmax - pmin))
```

## Output shape

`RankingAgent` writes to `state.ranked`:

```python
ranked: list[RankedCandidate]

class RankedCandidate(BaseModel):
    provider: Provider
    score: float           # final 0.0-1.0
    sub_scores: dict[str, float]   # {"proximity": 0.8, "rating": 0.95, "availability": 1.0, "price": 0.6}
    reasoning: str         # human-readable, see template below
    distance_km: float
```

### Reasoning string template

Must be one sentence, in **English** (the DecisionAgent will translate for the user-facing message; here we just need it for the trace).

> `f"{provider.name}: {distance_km:.1f} km away, rating {provider.rating}, {availability_label}, Rs. {provider.price_per_visit} - final score {score:.2f}"`

Where `availability_label` is one of `"exact slot free"`, `"available in window"`, `"available same day"`, `"unavailable today"`.

Example:
> "Ali AC Services: 2.1 km away, rating 4.7, exact slot free, Rs. 1500 - final score 0.89"

## Ordering

Sort `ranked` by `score` descending. On ties (score within 0.02), break by:
1. Higher rating
2. Smaller distance
3. Earlier `provider.id` (stable)

## Edge cases

- **Empty `state.candidates`** → set `state.ranked = []` and emit a trace event with `reasoning="no candidates to rank"`. DecisionAgent will handle the empty case.
- **Single candidate** → `price_score = 0.5` (neutral, see formula); still emit a one-element `ranked`.
- **All candidates have `availability_score = 0.0`** → still rank them; the DecisionAgent will tell the user "no one is available in your window, try later".
- **Distance unavailable** (real Distance Matrix failed) → fall back to haversine. Tool layer handles this internally; the ranking node doesn't see the failure.

## Trace event

```python
async with emit_trace(state, agent="RankingAgent", phase="decide", input={"candidate_count": len(state.candidates)}) as t:
    state.ranked = sorted([_score(c, ctx) for c in state.candidates], key=lambda r: r.score, reverse=True)
    t.set_output({"ranked": [{"id": r.provider.id, "score": r.score} for r in state.ranked]})
    t.set_reasoning(f"Ranked {len(state.ranked)} candidates by weighted score (0.4 proximity, 0.3 rating, 0.2 availability, 0.1 price)")
    # no external tool calls
```

## Why no LLM here

Determinism + speed + cost. Judges can read the formula and verify the math. The LLM (DecisionAgent) is *not* re-ranking: it's just choosing the top-N and writing the user-facing justification.
