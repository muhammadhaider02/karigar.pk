"""FastAPI app entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router
from app.config import get_settings
from app.db.session import create_tables
from app.events.handlers import register_handlers
from app.scheduler.reminders import get_scheduler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    logger.info("Karigar backend starting (demo_mode=%s, time_scale=%dx)", settings.demo_mode, settings.demo_time_scale)

    # Create DB tables
    await create_tables()
    logger.info("Database tables ready")

    # Register conflict event handlers
    register_handlers()
    logger.info("Event handlers registered")

    # Start APScheduler
    scheduler = get_scheduler()
    scheduler.start()
    logger.info("APScheduler started")

    yield

    # Shutdown
    scheduler.shutdown(wait=False)
    logger.info("APScheduler stopped")


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Karigar API",
        description="AI Service Orchestrator for Pakistan's Informal Economy",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # tighten in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(router)
    return app


app = create_app()
