# Skill: Authoring LangGraph Nodes

> Load this skill any time you write or edit a file under `backend/app/graph/nodes/` or `backend/app/graph/orchestrator.py`.
> Owner: `backend-engineer`.

## Purpose

Every LangGraph node in Karigar follows the same contract so the trace stays consistent and the conflict resolver can re-invoke any node safely.

## Node signature

```python
# backend/app/graph/nodes/<name>.py
from app.graph.state import RequestSession
from app.graph.trace import emit_trace  # helper that times + appends

async def run(state: RequestSession) -> RequestSession:
    ...
    return state
```

Rules:
- Nodes are `async`. Even purely computational nodes (Ranking): keeps the graph uniform.
- Nodes **mutate and return** the shared `RequestSession`. Never return a new object.
- Nodes **must not** call other nodes. Only the Orchestrator wires nodes together.
- Nodes **must** emit exactly one trace event per invocation (except the Planning step, which is the only multi-event step and is owned by the Orchestrator).

## Trace event helper

Always use `emit_trace` (lives in `backend/app/graph/trace.py`). It auto-times, auto-numbers the step and writes to both the state's in-memory `trace[]` and the SSE event bus.

```python
async with emit_trace(
    state,
    agent="DiscoveryAgent",
    phase="act",
    input={"location_hint": state.parsed_intent.location_hint, "service": state.parsed_intent.service_type.value},
    triggered_by=state.triggered_by,
) as trace_ctx:
    geo = await geocoder.resolve(state.parsed_intent.location_hint)
    trace_ctx.add_tool_call("Geocoder.resolve", {"hint": state.parsed_intent.location_hint}, geo)

    candidates = await provider_store.search(
        service=state.parsed_intent.service_type,
        lat=geo.lat, lng=geo.lng, radius_km=5,
        exclude=state.excluded_provider_ids,
    )
    trace_ctx.add_tool_call("ProviderStore.search", {"radius_km": 5, "exclude": state.excluded_provider_ids}, {"count": len(candidates)})

    state.candidates = candidates
    trace_ctx.set_output({"candidate_count": len(candidates)})
    trace_ctx.set_reasoning(f"Found {len(candidates)} candidates within 5km of {geo.label}")

return state
```

`emit_trace` is responsible for:
- Capturing `latency_ms` (from `__aenter__` to `__aexit__`).
- Setting `step` (monotonic counter on `state`).
- Publishing the event to SSE subscribers.
- Persisting to the `agent_traces` table.

## Phase values (mirrors brief language)

| Phase | Use for |
|---|---|
| `plan` | IntentAgent + the Orchestrator's Planning step |
| `decide` | DecisionAgent, RankingAgent, ConflictResolverAgent's routing decision |
| `act` | DiscoveryAgent, BookingAgent (anything that calls external tools or mutates DB) |
| `follow_up` | FollowupAgent (scheduling reminders, watchdogs) |
| `recover` | ConflictResolverAgent's sub-invocations of Discovery/Ranking/Decision/Booking |

When the Conflict Resolver re-invokes a happy-path node, pass `phase_override="recover"` to `emit_trace`. The same node code runs but the trace card is rendered with the amber "Recover" badge.

## Error handling

- Domain errors (`SlotConflict`, `ProviderNotFound`, `LanguageNotSupported`) are defined in `backend/app/graph/errors.py`. Raise them, don't swallow.
- The Orchestrator catches them and routes:
  - `SlotConflict` → publish `slot_conflict` event → Conflict Resolver
  - `ProviderNotFound` → emit an `act` trace with `output={"empty": true}` and short-circuit to a "no providers" response
- Network / API errors (`httpx.HTTPError`, `google.api_core.exceptions.*`): retry once with exponential backoff (helper in `app/graph/retry.py`); if still failing, emit a trace event with the error in `output` and re-raise.

## State mutation rules

`RequestSession` is **append-only** for the trace and `excluded_provider_ids`. Replacing those lists in a node will lose data from earlier nodes, so don't do it.

Allowed mutations per node:
| Node | Reads | Writes |
|---|---|---|
| Intent | `raw_text` | `parsed_intent`, `language` |
| Planning step | `parsed_intent` | appends one `plan` trace event |
| Discovery | `parsed_intent`, `excluded_provider_ids` | `candidates` |
| Ranking | `candidates` | `ranked` (list of `(provider, score, reasoning)`) |
| Decision | `ranked`, `parsed_intent.language` | `chosen` |
| Booking | `chosen`, `parsed_intent.time_window` | `booking` |
| Follow-up | `booking` | schedules jobs (no state write) |
| Conflict | `booking`, `excluded_provider_ids` | appends to `excluded_provider_ids`, increments `resolution_attempts`, sets `triggered_by` for downstream re-runs |

## Testing pattern

Every node has a test in `backend/tests/test_<node>.py` that:
1. Constructs a `RequestSession` fixture.
2. Calls `await run(state)`.
3. Asserts on the resulting state fields **and** the last trace event's shape.

Example:
```python
async def test_intent_parses_roman_urdu():
    state = RequestSession(raw_text="Mujhe kal subah G-13 mein AC technician chahiye")
    new_state = await intent.run(state)
    assert new_state.parsed_intent.language == Language.ROMAN_URDU
    assert new_state.parsed_intent.service_type == ServiceType.AC_TECHNICIAN
    last = new_state.trace[-1]
    assert last["agent"] == "IntentAgent"
    assert last["phase"] == "decide"
    assert last["tool_calls"][0]["name"].startswith("Gemini")
```
