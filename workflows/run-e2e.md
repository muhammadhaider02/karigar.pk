# Workflow: `/run-e2e`

> Antigravity slash command. Boots the backend, runs the full pytest suite (happy path in 3 languages + 5 conflict scenarios) and exports a trace artifact.
> Use before every commit on Day 2+ and before recording the demo.

## When to run

- After implementing any new node, tool or scheduler change.
- Before pushing to `main`.
- Before recording the demo (catches regressions that would embarrass us on camera).

## What it does

1. Ensures the DB is freshly seeded (calls `/seed-mock` if needed).
2. Runs `pytest` with the `tests/` directory.
3. For each test, captures the agent trace and writes it to `backend/runtime/traces/<test_name>.md`.
4. Asserts the **happy-path acceptance criteria** (below) and the **conflict-recovery criteria**.
5. Exports a single combined `backend/runtime/traces/e2e-report.md` summarising pass/fail per test.

## Test matrix

### Happy-path tests (3)

| Test | Input | Asserts |
|---|---|---|
| `test_happy_path_roman_urdu` | `"Mujhe kal subah G-13 mein AC technician chahiye"` | top provider = Ali AC Services; booking created with status worker_accepted; faux-WhatsApp message in Roman Urdu |
| `test_happy_path_urdu` | `"کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے"` | same as above; faux-WhatsApp in Urdu |
| `test_happy_path_english` | `"I need an AC technician in G-13 tomorrow morning"` | same as above; faux-WhatsApp in English |

### Conflict tests (5)

| Test | Setup | Asserts |
|---|---|---|
| `test_no_show_auto_rebook` | Create booking, fast-forward time past `T+15min` watchdog | Original booking marked `no_show`; a new booking exists with a different worker; trace contains a `recover` phase event |
| `test_user_cancellation_with_rebook` | Create booking, call `POST /bookings/{id}/cancel?rebook=true` | Original `cancelled`; new booking exists with `triggered_by="user_cancellation"` in its trace |
| `test_provider_unavailable_proactive` | Create booking, call `POST /providers/{id}/unavailable` | Original `cancelled`; new booking with different worker; user notification sent |
| `test_double_booking_race` | Spawn 2 concurrent BookingAgent calls for the same slot | Exactly 1 booking succeeds; loser's session has a `slot_conflict` trace event followed by a `recover`-phase rebook |
| `test_resolution_attempts_cap` | Force 3 sequential no-shows on the same session | After attempt 3: no further auto-rebook; user is shown top-3 alternatives; `resolution_attempts == 3` |

## Steps (the agent executes these in order)

1. **Ensure clean state**:
   ```bash
   cd backend
   uv run python -m app.data.seed    # upserts workers into Supabase (idempotent)
   ```

2. **Run tests**:
   ```bash
   uv run python -m pytest -v --tb=short
   ```

3. **Collect traces**:
   Each test fixture writes its trace to `backend/runtime/traces/<test_name>.md`. The aggregator at the end of the test run combines them into `e2e-report.md`.

4. **Print summary**:
   ```
   Karigar E2E Report
   ==================
   Happy path (3 / 3): PASS
     test_happy_path_roman_urdu     0.62 s
     test_happy_path_urdu           0.71 s
     test_happy_path_english        0.55 s

   Conflicts (5 / 5): PASS
     test_no_show_auto_rebook       1.34 s
     test_user_cancellation_*       0.87 s
     test_provider_unavailable_*    0.91 s
     test_double_booking_race       0.78 s
     test_resolution_attempts_cap   2.10 s

   Total: 8 / 8 PASS in 7.88 s
   Traces written to: backend/runtime/traces/
   ```

## Demo time-scale mode

For tests that exercise the scheduler, set `DEMO_TIME_SCALE=600` (1 real-second = 10 simulated-minutes) in the test fixture. This makes the `T+15min` watchdog fire in ~1.5 s of real time, keeping the suite under 10 s.

## Failure modes

| Symptom | Likely cause |
|---|---|
| `GOOGLE_API_KEY not set` | Either set the env var or run tests with `DEMO_MODE=true` to use cached responses |
| Test hangs on scheduler | `DEMO_TIME_SCALE` not set in fixture: APScheduler is waiting real time |
| `SlotConflict` test always passes both sides | Partial unique index `uq_worker_slot` missing from Supabase `bookings` table; apply the missing migration |
| Roman Urdu test asserts on Urdu | The language detection heuristic regressed (see `skills/multilingual-intent.md`) |

## Acceptance criteria

- All 8 tests pass.
- `backend/runtime/traces/e2e-report.md` exists and shows `8 / 8 PASS`.
- Each individual trace file contains at least one event per agent that participated.
- The conflict tests' traces include at least one `recover`-phase event.
