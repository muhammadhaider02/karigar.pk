"""Search tool: Antigravity Browser subagent wrapper.

When running inside Antigravity the browser subagent performs the search.
Outside Antigravity (tests / local dev) we fall back to a Gemini grounded
search or a simple mock.
"""

from __future__ import annotations

import os


class AntigravityBrowserSearch:
    """Wraps the Antigravity Browser subagent for reputation enrichment."""

    async def lookup(self, query: str) -> list[dict]:
        """Return a list of snippet dicts: [{title, snippet, url}]."""
        if _running_inside_antigravity():
            return await _antigravity_search(query)
        return await _gemini_fallback(query)


def _running_inside_antigravity() -> bool:
    """Heuristic: Antigravity sets ANTIGRAVITY_RUNTIME env var."""
    return bool(os.environ.get("ANTIGRAVITY_RUNTIME"))


async def _antigravity_search(query: str) -> list[dict]:
    """Placeholder: replaced at runtime by Antigravity's Browser subagent API."""
    # In a real Antigravity environment this would call the subagent.
    # For now return empty so tests don't hang.
    return []


async def _gemini_fallback(query: str) -> list[dict]:
    """Fallback: use Gemini to generate plausible reputation snippets."""
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI
        from app.config import get_settings

        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=get_settings().google_api_key,
            temperature=0.2,
        )
        prompt = (
            f"You are a search engine. For the query '{query}', return a JSON array "
            "of 3 objects with keys: title, snippet, url. "
            "These should be realistic but clearly fictional review snippets for a "
            "service provider in Islamabad, Pakistan. Return only the JSON array."
        )
        response = await llm.ainvoke(prompt)
        import json
        import re
        text = response.content if hasattr(response, "content") else str(response)
        match = re.search(r"\[.*\]", text, re.DOTALL)
        if match:
            return json.loads(match.group())
    except Exception:
        pass
    return []
