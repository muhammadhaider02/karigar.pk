<div align="center">

# Karigar Pakistan

**FROM WHATSAPP STYLE MESSAGE TO BOOKING IN SECONDS**

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://python.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.136.1-005571?logo=fastapi)](https://fastapi.tiangolo.com/)
[![LangGraph](https://img.shields.io/badge/LangGraph-1.2.0-000000?logo=langchain&logoColor=white)](https://langchain-ai.github.io/langgraph/)
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75B2?logo=googlegemini&logoColor=white)](https://gemini.google.com/)
[![SQLite](https://img.shields.io/badge/SQLite-07405E?logo=sqlite&logoColor=white)](https://sqlite.org/)
[![uv](https://img.shields.io/badge/uv-package%20manager-7C3AED)](https://github.com/astral-sh/uv)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Karigar** (کاریگر): Urdu for *artisan / craftsman*.

An agentic AI system that automates the full lifecycle of a service request, from natural-language intent (Urdu / Roman Urdu / English) to provider matching, simulated booking, follow-up and autonomous recovery from real-world failures like no-shows and double-bookings.

[Project Plan](plan.md) · [Architecture](docs/architecture.md) · [Detailed Docs](docs/README.md) · [Getting Started](#getting-started)

</div>

---

## How It Works

> "Mujhe kal subah G-13 mein AC technician chahiye"

Karigar understands. Plans. Searches. Ranks. Decides. Books. Follows up. And if Ali AC Services doesn't show up, it autonomously rebooks Hassan Cooling Experts and tells you in your own language.

1. **Send a message** - Natural language in Urdu, Roman Urdu or English
2. **Intent is parsed** - The IntentAgent extracts service type, location, time window and urgency
3. **Providers are discovered** - The DiscoveryAgent geocodes the location and finds nearby providers
4. **Candidates are ranked** - The RankingAgent scores by proximity, rating, availability and price
5. **Best provider is chosen** - The DecisionAgent picks the top match and justifies in your language
6. **Booking is confirmed** - The BookingAgent holds the slot and sends a faux-WhatsApp confirmation
7. **Follow-up is scheduled** - The FollowupAgent sets reminders, no-show watchdogs and completion checks
8. **Failures are recovered** - The ConflictResolverAgent autonomously rebooks on no-shows, cancellations or double-bookings

---

## The Seven Agents

| Agent | Model | Role |
|:---|:---|:---|
| **IntentAgent** | Gemini 2.5 Flash | Detects language, extracts service type, location, time window, urgency and notes |
| **DiscoveryAgent** | No LLM | Geocodes location and queries the provider store with exclusion filters |
| **RankingAgent** | No LLM | Scores candidates: 0.4×proximity + 0.3×rating + 0.2×availability + 0.1×price |
| **DecisionAgent** | Gemini 2.5 Flash | Picks the top provider and writes a 1-sentence justification in the user's language |
| **BookingAgent** | No LLM | Atomic slot hold, booking creation, receipt generation and WhatsApp notification |
| **FollowupAgent** | No LLM | Schedules reminder, no-show watchdog, status check and completion request |
| **ConflictResolverAgent** | Gemini 2.5 Flash | Decides recovery strategy on no-shows, cancellations and double-bookings |

---

## Architecture

| Component | Stack | Description |
|:---|:---|:---|
| **Backend** | Python 3.11, FastAPI, LangGraph, Pydantic v2 | 7-agent state machine with SSE streaming and event bus |
| **Mobile** | Flutter 3.38+, Provider, http | WhatsApp-style chat, live agent-trace timeline, booking management |
| **LLM** | Gemini 2.5 Flash (Google AI Studio) | Intent parsing, decision justification, conflict resolution |
| **Database** | SQLite (aiosqlite), SQLAlchemy | Providers, bookings, session state |
| **Scheduler** | APScheduler | Reminders, no-show watchdogs, completion checks |
| **Search** | Antigravity Browser subagent | Runtime reputation enrichment via web search |

---

## Getting Started

### Prerequisites

- Python 3.11+ and [uv](https://docs.astral.sh/uv/)
- Flutter 3.10+ (for mobile; run `flutter doctor` to verify)
- A [Google AI Studio](https://aistudio.google.com/) API key

### Quick Start

```bash
git clone https://github.com/muhammadhaider02/karigar.pk.git
cd karigar.pk
```

**Backend:**

```bash
cd backend
cp ../.env.example ../.env           # fill in GOOGLE_API_KEY
uv sync                              # install dependencies
uv run python -m app.data.seed       # seed providers + SQLite
uv run python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

**Verify:**

```bash
curl http://127.0.0.1:8000/health    # {"status": "ok"}
```

**Mobile (Flutter):**

```bash
cd mobile
flutter pub get

# Android emulator (backend must be running)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

**Run tests:**

```bash
# Backend
uv run python -m pytest -v --tb=short

# Mobile
cd mobile && flutter test
```

---

## Documentation

- **[Project Plan](plan.md)** - Full specification: architecture, agents, tools, timeline, scoring map
- **[Architecture Deep-Dive](docs/architecture.md)** - System diagram, state contracts, swap-to-real-APIs guide
- **[Detailed README](docs/README.md)** - Setup, run instructions, assumptions, limitations

---

## License

MIT. See [LICENSE](LICENSE).
