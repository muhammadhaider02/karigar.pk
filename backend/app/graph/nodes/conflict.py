"""ConflictResolverAgent node: Gemini 2.5 Flash decides recovery strategy."""

from __future__ import annotations

import json

from langchain_google_genai import ChatGoogleGenerativeAI

from app.config import get_settings
from app.graph import demo_cache
from app.graph.state import RequestSession
from app.graph.trace import emit_trace

_RESOLVER_PROMPT = """You are the Conflict Resolver for Karigar, a service-booking app.

A booking has failed. Based on the conflict event and current session state, decide the recovery strategy.

Event: {event_key}
Failed provider: {failed_provider}
Resolution attempt: {attempt} of 3
Current excluded providers: {excluded}
Time window: {time_window}

Your job:
1. Confirm that excluding the failed provider is the right move (it always is for no-show/unavailable).
2. Decide if the time window should be widened:
   - Attempt 1: no widening
   - Attempt 2: widen by 1h each side
   - Attempt 3: widen by 2h each side
3. Write a brief reasoning string (1 sentence) explaining what you are doing.

Respond ONLY with JSON:
{{
  "exclude_provider": true,
  "widen_hours": 0,
  "reasoning": "..."
}}
"""


async def run(state: RequestSession, event: dict) -> RequestSession:
    """Called by the conflict resolver subgraph with the triggering event."""
    settings = get_settings()
    intent = state.parsed_intent

    # Snapshot the user's ORIGINAL time_window the very first time the resolver
    # touches this session. All subsequent widenings are computed relative to
    # this snapshot, not relative to the previously-widened window — otherwise
    # attempt 3's "widen by 2h" stacks on top of attempt 2's "widen by 1h" and
    # the search window grows unboundedly.
    if state.original_time_window is None and intent and intent.time_window:
        state.original_time_window = intent.time_window.model_copy(deep=True)

    async with emit_trace(
        state,
        agent="ConflictResolverAgent",
        phase="recover",
        input={
            "event": event.get("key", "unknown"),
            "attempt": state.resolution_attempts,
            "excluded": state.excluded_provider_ids,
        },
        triggered_by=state.triggered_by,
    ) as t:
        # Using Gemini 2.5 Flash — the recovery rules are explicit in the prompt;
        # no deep reasoning is needed beyond following the 3-attempt rule table.
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=settings.google_api_key,
            temperature=0.1,
        )

        failed_provider = event.get("failed_provider_id", "unknown")
        time_window_str = (
            f"{intent.time_window.label}" if (intent and intent.time_window) else "any time"
        )

        prompt = _RESOLVER_PROMPT.format(
            event_key=event.get("key", "unknown"),
            failed_provider=failed_provider,
            attempt=state.resolution_attempts,
            excluded=state.excluded_provider_ids,
            time_window=time_window_str,
        )

        try:
            # DEMO_MODE: skip Gemini, use the deterministic per-attempt policy.
            if settings.demo_mode:
                cached = demo_cache.lookup_conflict_decision(state.resolution_attempts)
                if cached is not None:
                    data = cached
                else:
                    response = await llm.ainvoke(prompt)
                    content = response.content if hasattr(response, "content") else str(response)
                    import re
                    match = re.search(r"\{.*\}", content, re.DOTALL)
                    data = json.loads(match.group()) if match else {
                        "exclude_provider": True, "widen_hours": 0, "reasoning": content,
                    }
            else:
                response = await llm.ainvoke(prompt)
                content = response.content if hasattr(response, "content") else str(response)
                import re
                match = re.search(r"\{.*\}", content, re.DOTALL)
                if match:
                    data = json.loads(match.group())
                else:
                    data = {"exclude_provider": True, "widen_hours": 0, "reasoning": content}

            widen_hours = int(data.get("widen_hours", 0))
            reasoning = data.get("reasoning", f"Excluding {failed_provider} and retrying")

            # Apply time-window widening RELATIVE TO THE ORIGINAL window
            # (never relative to the already-widened current window).
            if intent and state.original_time_window is not None:
                from datetime import timedelta
                orig = state.original_time_window
                if widen_hours > 0:
                    intent.time_window = orig.model_copy(
                        update={
                            "start": orig.start - timedelta(hours=widen_hours),
                            "end": orig.end + timedelta(hours=widen_hours),
                            "label": f"{orig.label} (±{widen_hours}h)",
                        }
                    )
                else:
                    # Make sure we don't keep a previous attempt's widened window.
                    intent.time_window = orig.model_copy(deep=True)
                state.parsed_intent = intent

            t.add_tool_call(
                "Gemini.flash.conflict_decision",
                {"model": "gemini-2.5-flash", "event": event.get("key")},
                data,
            )
            t.set_output(
                {
                    "action": "re-run discovery",
                    "excluded_count": len(state.excluded_provider_ids),
                    "widen_hours": widen_hours,
                }
            )
            t.set_reasoning(reasoning)

        except Exception as exc:
            t.set_output({"error": str(exc)})
            t.set_reasoning(
                f"LLM decision failed ({exc}); defaulting to exclude+retry with no widening"
            )

    return state
