"""emit_trace: async context manager used by every LangGraph node.

Usage:
    async with emit_trace(state, agent="DiscoveryAgent", phase="act", input={...}) as t:
        result = await some_tool()
        t.add_tool_call("ToolName", args, result)
        t.set_output({"key": "value"})
        t.set_reasoning("Found 6 candidates within 5km")

The context manager:
  - Records wall-clock latency
  - Auto-increments the step counter on state
  - Appends a TraceEvent to state.trace
  - Publishes the event to the SSE bus for live streaming
  - Persists the event to agent_traces table in Supabase
"""

from __future__ import annotations

import asyncio
import time
from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator

from app.graph.state import RequestSession, ToolCall, TraceEvent


class _TraceContext:
    def __init__(
        self,
        state: RequestSession,
        agent: str,
        phase: str,
        input_data: dict,
        triggered_by: str | None,
        step: int,
        start_ns: int,
    ) -> None:
        self._state = state
        self._agent = agent
        self._phase = phase
        self._input = input_data
        self._triggered_by = triggered_by
        self._step = step
        self._start_ns = start_ns
        self._tool_calls: list[ToolCall] = []
        self._output: dict[str, Any] = {}
        self._reasoning: str = ""

    def add_tool_call(self, name: str, args: dict, result: Any, latency_ms: int = 0) -> None:
        self._tool_calls.append(ToolCall(name=name, args=args, result=result, latency_ms=latency_ms))

    def set_output(self, output: dict) -> None:
        self._output = output

    def set_reasoning(self, reasoning: str) -> None:
        self._reasoning = reasoning

    def _build_event(self) -> TraceEvent:
        elapsed_ms = int((time.perf_counter_ns() - self._start_ns) / 1_000_000)
        return TraceEvent(
            step=self._step,
            agent=self._agent,
            phase=self._phase,  # type: ignore[arg-type]
            input=self._input,
            output=self._output,
            tool_calls=self._tool_calls,
            latency_ms=elapsed_ms,
            reasoning=self._reasoning,
            triggered_by=self._triggered_by,
        )


@asynccontextmanager
async def emit_trace(
    state: RequestSession,
    agent: str,
    phase: str,
    input: dict | None = None,  # noqa: A002
    triggered_by: str | None = None,
) -> AsyncGenerator[_TraceContext, None]:
    """Async context manager that auto-times and records a trace event."""
    step = state.next_step()
    start_ns = time.perf_counter_ns()
    ctx = _TraceContext(
        state=state,
        agent=agent,
        phase=phase,
        input_data=input or {},
        triggered_by=triggered_by or state.triggered_by,
        step=step,
        start_ns=start_ns,
    )
    try:
        yield ctx
    finally:
        event = ctx._build_event()
        state.trace.append(event)

        # Publish to SSE bus (non-blocking)
        try:
            from app.events.bus import get_bus
            await get_bus().publish_trace(state.id, event)
        except Exception:
            pass

        # Persist to Supabase (non-blocking)
        try:
            await _persist_trace(state.id, event)
        except Exception:
            pass

        # Demo pacing
        try:
            from app.config import get_settings
            pace_ms = get_settings().demo_trace_pace_ms
            if pace_ms > 0:
                await asyncio.sleep(pace_ms / 1000)
        except Exception:
            pass


async def _persist_trace(session_id: str, event: TraceEvent) -> None:
    from app.db.supabase_client import get_supabase
    import json

    supabase = await get_supabase()
    await supabase.table("agent_traces").insert({
        "session_id": session_id,
        "step": event.step,
        "agent": event.agent,
        "phase": event.phase,
        "input_data": event.input,
        "output_data": event.output,
        "tool_calls": [tc.model_dump() for tc in event.tool_calls],
        "latency_ms": event.latency_ms,
        "reasoning": event.reasoning,
        "triggered_by": event.triggered_by,
    }).execute()
