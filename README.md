# Karigar: AI Service Orchestrator for Pakistan's Informal Economy

> **Karigar** (کاریگر): Urdu for *artisan / craftsman*.
> Submission for the Google Antigravity Hackathon.

An agentic AI system that automates the full lifecycle of a service request, from natural-language intent (Urdu / Roman Urdu / English) to provider matching, simulated booking, follow-up, and autonomous recovery from real-world failures like no-shows and double-bookings.

Built around **7 specialised agents** orchestrated through a LangGraph state machine, with Google Antigravity at the core of both development and runtime (Search tool powered by the Antigravity Browser subagent).

## The pitch

> "Mujhe kal subah G-13 mein AC technician chahiye"

Karigar understands. Plans. Searches. Ranks. Decides. Books. Follows up. And if Ali AC Services doesn't show up, it autonomously rebooks Hassan Cooling Experts and tells you in your own language.

## Quick links

- **[Project Plan](plan.md)**: full specification: architecture, agents, tools, timeline, scoring map.
- **[Architecture Deep-Dive](docs/architecture.md)**: system diagram, state contracts, swap-to-real-APIs guide.
- **[Detailed README](docs/README.md)**: setup, run instructions, assumptions, limitations.
- **[Agent Team](agents.md)**: Antigravity AI dev team definition.
- **[Skills](skills/)**: modular capability files loaded on-demand by Antigravity.
- **[Workflows](workflows/)**: Antigravity slash commands.
- **[Demo Script](demo/script.md)**: minute-by-minute demo plan.
- **[Hackathon Brief](karigar.md)**: the original problem statement.

## Stack

- **Mobile**: Flutter 3.x
- **Backend**: Python 3.11, FastAPI, LangGraph, SQLite, APScheduler (managed with [`uv`](https://docs.astral.sh/uv/))
- **LLM**: Gemini 2.5 Flash + Pro via Google AI Studio
- **Build platform**: [Google Antigravity](https://antigravity.google/)

## Status

Work in progress. See [`plan.md`](plan.md) for the day-by-day execution timeline.

## License

MIT. See [LICENSE](LICENSE).
