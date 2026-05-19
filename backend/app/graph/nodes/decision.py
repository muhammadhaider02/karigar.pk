"""DecisionAgent: Gemini 2.5 Flash picks the top provider and justifies in user's language."""

from __future__ import annotations

import json

from langchain_google_genai import ChatGoogleGenerativeAI

from app.config import get_settings
from app.graph import demo_cache
from app.graph.state import Language, RankedCandidate, RequestSession
from app.graph.trace import emit_trace


_DECISION_PROMPT = """You are the decision agent for Karigar, a service-booking app.

Given a ranked list of service providers, you must:
1. Pick the BEST single provider (first in the list unless there is a strong reason not to).
2. Write a concise 1-sentence justification in the user's language: {language}.

Language instructions:
- "ur" → write in Urdu script
- "roman_ur" → write in Roman Urdu (e.g. "Ali AC Services choose kiya kyunki...")
- "en" → write in English

If there are 0 candidates, say so in the user's language and set chosen_index = -1.
If there is only 1 candidate, choose it.

Respond with a JSON object ONLY:
{{
  "chosen_index": 0,
  "justification": "..."
}}

Ranked providers (index 0 is best):
{ranked_json}
"""


async def run(state: RequestSession) -> RequestSession:
    settings = get_settings()
    ranked = state.ranked
    intent = state.parsed_intent
    language = intent.language if intent else Language.ENGLISH

    async with emit_trace(
        state,
        agent="DecisionAgent",
        phase="decide",
        input={"ranked_count": len(ranked), "language": language.value},
    ) as t:
        if not ranked:
            t.set_output({"chosen": None})
            t.set_reasoning("No ranked candidates — cannot decide")
            return state

        # DEMO_MODE: pick top-1 deterministically, no Gemini call needed.
        if settings.demo_mode:
            top = ranked[0]
            cached_just = demo_cache.lookup_decision(top.provider.name, language)
            if cached_just is None:
                # Generate a simple justification without LLM
                if language == Language.ROMAN_URDU:
                    cached_just = (
                        f"{top.provider.name} ko chuna gaya kyunki yeh sabse qareeb hai, "
                        f"rating {top.provider.rating} hai, aur aap ke slot par available hai."
                    )
                elif language == Language.URDU:
                    cached_just = (
                        f"{top.provider.name} کو چنا گیا کیونکہ یہ سب سے قریب ہے، "
                        f"ریٹنگ {top.provider.rating} ہے، اور آپ کے وقت پر دستیاب ہے۔"
                    )
                else:
                    cached_just = (
                        f"Selected {top.provider.name} — nearest provider, "
                        f"rated {top.provider.rating}, available in your time slot."
                    )
            state.chosen = top
            t.add_tool_call(
                "DemoCache.decision",
                {"provider": top.provider.name, "language": language.value},
                {"chosen_index": 0, "justification": cached_just},
            )
            t.set_output(
                {
                    "chosen_id": top.provider.id,
                    "chosen_name": top.provider.name,
                    "justification": cached_just,
                }
            )
            t.set_reasoning(f"[DEMO_MODE] {cached_just}")
            return state

        ranked_summary = [
            {
                "index": i,
                "name": r.provider.name,
                "score": round(r.score, 3),
                "reasoning": r.reasoning,
            }
            for i, r in enumerate(ranked[:5])
        ]

        # Using Gemini 2.5 Flash — the task is simple slot-filling:
        # pick index 0 from a pre-ranked list and write one justification sentence.
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=settings.google_api_key,
            temperature=0.2,
        )

        prompt = _DECISION_PROMPT.format(
            language=language.value,
            ranked_json=json.dumps(ranked_summary, ensure_ascii=False, indent=2),
        )

        try:
            response = await llm.ainvoke(prompt)
            content = response.content if hasattr(response, "content") else str(response)

            # Parse JSON from response
            import re
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                data = json.loads(match.group())
                chosen_index = int(data.get("chosen_index", 0))
                justification = data.get("justification", "")
            else:
                chosen_index = 0
                justification = content.strip()

            if chosen_index < 0 or chosen_index >= len(ranked):
                chosen_index = 0

            state.chosen = ranked[chosen_index]

            t.add_tool_call(
                "Gemini.flash.decision",
                {"model": "gemini-2.5-flash", "candidates": len(ranked), "language": language.value},
                {"chosen_index": chosen_index, "justification": justification},
            )
            t.set_output(
                {
                    "chosen_id": state.chosen.provider.id,
                    "chosen_name": state.chosen.provider.name,
                    "justification": justification,
                }
            )
            t.set_reasoning(justification)

        except Exception as exc:
            # Fallback: pick top-ranked
            state.chosen = ranked[0]
            t.set_output(
                {
                    "chosen_id": ranked[0].provider.id,
                    "error": str(exc),
                    "fallback": True,
                }
            )
            t.set_reasoning(
                f"LLM decision failed ({exc}); defaulted to top-ranked: {ranked[0].provider.name}"
            )

    return state
