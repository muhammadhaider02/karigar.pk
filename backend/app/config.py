from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict

# .env lives at repo root (one level above backend/)
_ENV_FILE = Path(__file__).parent.parent.parent / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── LLM ────────────────────────────────────────────────────────────────
    google_api_key: str = Field(..., description="Google AI Studio key (Gemini)")

    # ── Maps (optional) ────────────────────────────────────────────────────
    google_maps_key: str = Field(default="", description="Google Maps Platform key")

    @computed_field  # type: ignore[misc]
    @property
    def use_real_maps(self) -> bool:
        return bool(self.google_maps_key)

    # ── Demo behaviour ─────────────────────────────────────────────────────
    demo_mode: bool = Field(
        default=False,
        description="Cache 5 canonical Gemini responses to avoid quota issues",
    )
    demo_time_scale: int = Field(
        default=1,
        ge=1,
        description="1 real-second = N simulated-minutes. 60 for live no-show demo.",
    )
    demo_trace_pace_ms: int = Field(
        default=0,
        description="Artificial delay (ms) between trace events in demo mode.",
    )

    # ── Server ─────────────────────────────────────────────────────────────
    host: str = "0.0.0.0"
    port: int = 8000
    log_level: str = "info"

    # ── Database ───────────────────────────────────────────────────────────
    db_path: str = Field(
        default="runtime/karigar.db",
        description=(
            "SQLite path relative to backend/. "
            "Lives under backend/runtime/ (gitignored runtime output) "
            "to keep it separate from backend/app/data/ (versioned source data)."
        ),
    )

    @computed_field  # type: ignore[misc]
    @property
    def database_url(self) -> str:
        # aiosqlite needs three slashes for relative paths
        return f"sqlite+aiosqlite:///{self.db_path}"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
