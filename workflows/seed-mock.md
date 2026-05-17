# Workflow: `/seed-mock`

> Antigravity slash command. Regenerates the synthetic provider dataset and primes the SQLite DB.
> Idempotent: safe to run any number of times.

## When to run

- First time setting up the project on a new machine.
- After editing `backend/app/data/seed.py` (e.g. adding new providers / categories).
- Before recording the demo, to guarantee deterministic data.

## What it does

1. Wipes any existing `backend/runtime/karigar.db` (runtime DB; `backend/app/data/providers.json` is source data and is NOT touched).
2. Calls `seed.py` to:
   - Read the 25 hand-tuned providers from `backend/app/data/providers.json` (source).
   - Create all tables defined in `backend/app/db/models.py`.
   - Insert each provider into the `providers` table in `backend/runtime/karigar.db`.
   - Print a verification summary (count per category, count per sector).
3. Verifies that the canonical demo query (`G-13` + `AC technician` + tomorrow morning) returns **Ali AC Services** as the top candidate.

## Steps (the agent executes these in order)

1. **Pre-check**: confirm we're inside `backend/` and `uv` is available:
   ```bash
   cd backend
   uv --version
   ```

2. **Reset runtime DB**:
   ```bash
   rm -f runtime/karigar.db
   ```

3. **Run the seed script**:
   ```bash
   uv run python -m app.data.seed
   ```

4. **Verify** (the seed script runs `verify_canonical()` at the end of `main()`,
   but you can also re-run it standalone; note it is `async`, so wrap it in
   `asyncio.run` if calling from a one-liner):
   ```bash
   uv run python -c "import asyncio; from app.data.seed import verify_canonical; asyncio.run(verify_canonical())"
   ```
   Expected output:
   ```
   [OK] 25 providers loaded into SQLite
   [OK] Seed report written to runtime/seed-report.md
   [OK] Canonical query G-13 + AC technician + tomorrow morning -> top match: Ali AC Services
   [OK] 6 categories represented
   ```

## Output artifact

A short markdown report at `backend/runtime/seed-report.md` listing:
- Provider count per category
- Provider count per sector
- The top-3 results for each canonical demo query (used by `demo/script.md`)

## Failure modes

| Symptom | Fix |
|---|---|
| `uv: command not found` | Install uv: see `https://docs.astral.sh/uv/getting-started/installation/` |
| `ModuleNotFoundError: app` | Make sure CWD is `backend/`, not repo root |
| Canonical query doesn't return Ali AC Services | Inspect `seed.py` to ensure Ali AC Services is in G-13 with the right `busy_slots` and the highest combined rank for the canonical query (see `skills/provider-ranking-rules.md`) |
| `IntegrityError: UNIQUE constraint failed` | DB wasn't wiped; re-run step 2 |

## Acceptance criteria

- `backend/runtime/karigar.db` exists and contains exactly 25 providers.
- `verify_canonical()` prints all 3 checkmarks.
- `runtime/seed-report.md` was rewritten with the current timestamp.
