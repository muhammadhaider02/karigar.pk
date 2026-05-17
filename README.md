<div align="center">

# Karigar: AI Service Orchestrator for Pakistan's Informal Economy

**Agentic AI system automating service requests from intent to booking, follow-up and autonomous recovery**

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.136.1-005571?logo=fastapi)](https://fastapi.tiangolo.com/)
[![LangGraph](https://img.shields.io/badge/LangGraph-1.2.0-000000?logo=langchain&logoColor=white)](https://langchain-ai.github.io/langgraph/)
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75B2?logo=googlegemini&logoColor=white)](https://gemini.google.com/)
[![SQLite](https://img.shields.io/badge/SQLite-07405E?logo=sqlite&logoColor=white)](https://sqlite.org/)
[![uv](https://img.shields.io/badge/uv-package%20manager-7C3AED)](https://github.com/astral-sh/uv)

> **Karigar** (کاریگر): Urdu for *artisan / craftsman*.  
> Submission for the Google Antigravity Hackathon.

An agentic AI system that automates the full lifecycle of a service request, from natural-language intent (Urdu / Roman Urdu / English) to provider matching, simulated booking, follow-up and autonomous recovery from real-world failures like no-shows and double-bookings.

</div>

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
- **LLM**: Gemini 2.5 Flash via Google AI Studio
- **Build platform**: [Google Antigravity](https://antigravity.google/)

## License

MIT. See [LICENSE](LICENSE).
