"""Supabase async client singleton (service_role — bypasses RLS)."""
from __future__ import annotations

import asyncio

_client = None
_lock = asyncio.Lock()


async def get_supabase():
    global _client
    async with _lock:
        if _client is None:
            from supabase._async.client import create_client
            from app.config import get_settings
            s = get_settings()
            _client = await create_client(s.supabase_url, s.supabase_service_key)
    return _client
