# Workflow: `/seed-mock`

> Antigravity slash command. Upserts the synthetic provider dataset into Supabase and verifies the canonical demo query.
> Idempotent: safe to run any number of times.

## When to run

- First time setting up the project on a new machine.
- After editing `backend/app/data/seed.py` (adding new providers or categories).
- Before recording the demo, to guarantee deterministic data.

## What it does

1. Reads the 25 hand-tuned providers from `backend/app/data/providers.json` (source data; never modified by this script).
2. Calls `seed.py` to upsert each provider into the `workers` table in Supabase using `legacy_id` as the conflict key. Existing rows are updated; new rows are inserted. No data is deleted.
3. Verifies that the canonical demo query (G-13 + AC technician + tomorrow morning) returns Ali AC Services as the top candidate.

## Steps (the agent executes these in order)

1. **Pre-check**: confirm we're inside `backend/`, `uv` is available and Supabase env vars are set:
   ```bash
   cd backend
   uv --version
   echo $SUPABASE_URL   # must be non-empty
   ```

2. **Run the seed script**:
   ```bash
   uv run python -m app.data.seed
   ```

3. **Verify** (the seed script runs `verify_canonical()` at the end of `main()`, but you can also re-run it standalone):
   ```bash
   uv run python -c "import asyncio; from app.data.seed import verify_canonical; asyncio.run(verify_canonical())"
   ```
   Expected output:
   ```
   [OK] 25 workers upserted into Supabase
   [OK] Seed report written to runtime/seed-report.md
   [OK] Canonical query G-13 + AC technician + tomorrow morning -> top match: Ali AC Services
   [OK] 6 categories represented
   ```

## Output artifact

A short markdown report at `backend/runtime/seed-report.md` listing:
- Worker count per category
- Worker count per sector
- The top-3 results for each canonical demo query (used by `demo/script.md`)

## Failure modes

| Symptom | Fix |
|---|---|
| `uv: command not found` | Install uv: see https://docs.astral.sh/uv/getting-started/installation/ |
| `ModuleNotFoundError: app` | Make sure CWD is `backend/`, not repo root |
| `SUPABASE_URL not set` | Copy `.env.example` to `.env` and fill in Supabase credentials |
| Canonical query does not return Ali AC Services | Inspect `seed.py` to ensure Ali AC Services is in G-13 with the right `busy_slots` and the highest combined rank for the canonical query (see `skills/provider-ranking-rules.md`) |
| Upsert silently skips a row | Check the `legacy_id` column exists on the `workers` table; apply the migration if missing |

## Acceptance criteria

- Supabase `workers` table contains at least 25 rows with `is_seed_data=true`.
- `verify_canonical()` prints all 3 checkmarks.
- `runtime/seed-report.md` was rewritten with the current timestamp.
