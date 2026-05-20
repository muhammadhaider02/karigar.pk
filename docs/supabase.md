# Karigar-PK: Supabase Schema Reference

> Single source of truth for all persistent data. Backend (FastAPI) and mobile (Flutter)
> both read/write here. SQLite is not used.

## Overview

| Layer | Connection |
|-------|-----------|
| FastAPI backend | `supabase-py` async client with `service_role` key (bypasses RLS) |
| Flutter mobile | `supabase_flutter` SDK with `anon` key (subject to RLS) |

---

## Enums

| Enum | Values |
|------|--------|
| `app_language` | `english`, `urdu`, `roman_urdu` |
| `service_category` | `plumber`, `electrician`, `ac_technician`, `carpenter`, `painter`, `cleaner`, `mason`, `welder`, `pest_control`, `appliance_repair`, `tutor`, `beautician` |
| `verification_status` | `pending`, `under_review`, `verified`, `rejected` |
| `booking_status` | `searching`, `worker_assigned`, `worker_accepted`, `en_route`, `arrived`, `in_progress`, `completed`, `cancelled`, `no_show`, `disputed`, `resolved` |
| `urgency_level` | `low`, `medium`, `high` |
| `dispute_reason` | `no_show`, `quality_issue`, `overcharged`, `rude_behavior`, `property_damage`, `other` |
| `dispute_decision` | `full_refund`, `partial_refund`, `no_refund`, `escalated` |
| `notification_type` | `booking_confirmed`, `worker_en_route`, `worker_arrived`, `service_complete`, `review_request`, `dispute_update`, `payment_received`, `new_job_request`, `reminder` |

---

## Tables

### `customers`
Registered app users who book services. Auto-created by auth trigger on signup.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | = `auth.users.id` |
| `full_name` | TEXT | |
| `phone_number` | TEXT UNIQUE | |
| `profile_photo_url` | TEXT | Supabase Storage URL |
| `language` | app_language | Default: `roman_urdu` |
| `district` | TEXT | |
| `city` | TEXT | |
| `current_lat` / `current_lng` | FLOAT | Live GPS from app |
| `fcm_token` | TEXT | Firebase push token |
| `is_onboarded` | BOOL | |
| `is_active` | BOOL | |
| `last_seen_at` | TIMESTAMPTZ | |

**RLS**: User reads/writes own row only.

---

### `workers`
All workers — both 25 mock seed workers (from providers.json) and real registered users.
Differentiated by `is_seed_data`. Remove mock workers later: `DELETE FROM workers WHERE is_seed_data = true`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | Auto-generated |
| `auth_user_id` | UUID | FK → `auth.users`; NULL for seed workers |
| `full_name` | TEXT NOT NULL | |
| `phone_number` | TEXT | |
| `profile_photo_url` | TEXT | |
| `bio` | TEXT | |
| `skills` | service_category[] | GIN-indexed |
| `rate_per_hour` | INT | PKR |
| `minimum_charge` | INT | PKR |
| `experience_years` | INT | |
| `district` | TEXT NOT NULL | |
| `area` | TEXT NOT NULL | Primary service area |
| `home_lat` / `home_lng` | FLOAT | Worker's base location |
| `coverage_radius_km` | FLOAT | Default 10.0 |
| `verification_status` | verification_status | Seed workers: `verified` |
| `cnic_number` | TEXT UNIQUE | Real workers only |
| `cnic_front_url` / `cnic_back_url` | TEXT | Supabase Storage |
| `proof_of_skill_urls` | TEXT[] | |
| `is_online` | BOOL | Toggle from WorkerHubScreen |
| `is_available` | BOOL | |
| `working_hours` | JSONB | `{"start":"08:00","end":"20:00"}` |
| `busy_slots` | JSONB | ISO datetime array; seed data only |
| `rating` | FLOAT | Updated by trigger on reviews INSERT |
| `total_reviews` | INT | Updated by trigger |
| `jobs_completed` | INT | Incremented by trigger |
| `response_rate` / `on_time_rate` | FLOAT | |
| `is_seed_data` | BOOL | true = mock provider from providers.json |
| `legacy_id` | TEXT UNIQUE | Original "provider_01" id; debug only |

**RLS**: Anyone can SELECT (needed for discovery). Only owner (`auth_user_id = auth.uid()`) can UPDATE. Service role inserts seed data.

---

### `worker_service_areas`
Additional districts/areas a worker covers beyond their primary `area`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `worker_id` | UUID FK workers | Cascade delete |
| `district` | TEXT | |
| `area` | TEXT | |
| `is_primary` | BOOL | |
| UNIQUE | `(worker_id, district, area)` | No duplicates |

---

### `sessions`
One row per AI pipeline invocation. Anchor table for `agent_traces` and `conflict_events`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | UUID from backend |
| `customer_id` | UUID FK customers | |
| `raw_text` | TEXT | Original user query |
| `user_phone` | TEXT | For mock WhatsApp notifications |
| `language` | app_language | Detected by IntentAgent |
| `parsed_intent` | JSONB | `{service_type, location_hint, time_window, urgency, notes}` |
| `excluded_worker_ids` | UUID[] | Workers tried and failed (conflict resolution) |
| `resolution_attempts` | INT | Max 3 before handoff |
| `triggered_by` | TEXT | e.g. `"no_show_detected:worker-uuid"` |
| `original_time_window` | JSONB | Snapshot for relative time widening |
| `status` | TEXT | `running` → `completed` / `failed` / `handoff` |

**RLS**: Customer reads own sessions. Backend writes with service role.

---

### `agent_traces`
Append-only log of every LangGraph node execution. One row per node per session.

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `session_id` | TEXT FK sessions | |
| `step` | INT | Sequential within session |
| `agent` | TEXT | `IntentAgent`, `DiscoveryAgent`, etc. |
| `phase` | TEXT | `plan`, `decide`, `act`, `follow_up`, `recover` |
| `input_data` | JSONB | Context passed to node |
| `output_data` | JSONB | Node result |
| `tool_calls` | JSONB | `[{name, args, result, latency_ms}]` |
| `latency_ms` | INT | Wall-clock node execution time |
| `reasoning` | TEXT | Human-readable explanation |
| `triggered_by` | TEXT | Set for conflict-resolver nodes only |

**RLS**: Customer reads traces from their own sessions. Service role inserts.

---

### `conflict_events`
Audit log of conflict triggers. Fire-and-forget from backend; never queried by mobile.

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGSERIAL PK | |
| `session_id` | TEXT FK sessions | |
| `event_type` | TEXT | One of 5 conflict types |
| `failed_worker_id` | UUID FK workers | Worker that caused the conflict |
| `payload` | JSONB | Full event payload |

**RLS**: Service role only (no user access).

---

### `bookings`
Core transaction table. Written by both backend (AI flow) and Flutter (direct booking).

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `booking_code` | TEXT UNIQUE | Human-readable, e.g. `BKG-A3F8B2C1` |
| `session_id` | TEXT FK sessions | NULL for direct (non-AI) bookings |
| `customer_id` | UUID FK customers | |
| `worker_id` | UUID FK workers | NULL during `searching` phase |
| `service_type` | service_category | |
| `raw_input` | TEXT | Original customer query |
| `description` | TEXT | Provider name (stored for notifications) |
| `urgency` | urgency_level | |
| `job_address/district/area/lat/lng` | — | Job location |
| `slot_time` | TIMESTAMPTZ | Scheduled start |
| `slot_end` | TIMESTAMPTZ | Auto-set to `slot_time + 2h` by trigger |
| `price_estimate` | INT | PKR, locked at booking time |
| `final_price` | INT | Set on completion |
| `status` | booking_status | Full lifecycle |
| `ranked_providers` | JSONB | AI-ranked candidates snapshot |
| `is_auto_booked` | BOOL | AI selected without user confirmation |
| `is_rebook` | BOOL | Created by conflict resolver |
| `original_booking_id` | UUID FK bookings | Self-reference for rebooking chain |
| `receipt_url` | TEXT | Supabase Storage public URL |
| `confirmed_at/arrived_at/completed_at/cancelled_at` | TIMESTAMPTZ | Lifecycle timestamps |

**Key constraint**: `UNIQUE(worker_id, slot_time)` partial index excludes `cancelled`/`no_show` rows — freed slots are re-bookable.

**Trigger**: `fill_slot_end` auto-sets `slot_end = slot_time + 2 hours` when omitted.

**RLS**: Customer and assigned worker read/update own bookings. Customer inserts.

---

### `reviews`
One review per booking. Stars 1–5.

| Column | Type | Notes |
|--------|------|-------|
| `booking_id` | UUID UNIQUE FK | One review per booking |
| `customer_id` | UUID FK customers | |
| `worker_id` | UUID FK workers | |
| `stars` | INT CHECK 1–5 | |
| `review_text` | TEXT | |
| `tags` | TEXT[] | `['Punctual','Skilled','Affordable','Polite','Clean Work','Fast']` |
| `sentiment` / `sentiment_score` | TEXT / FLOAT | Optional AI sentiment |
| `dispute_triggered` | BOOL | |

**Trigger**: `sync_worker_rating` updates `workers.rating`, `total_reviews`, `jobs_completed` on every INSERT.

---

### `disputes`
One dispute per booking.

| Column | Type | Notes |
|--------|------|-------|
| `dispute_code` | TEXT UNIQUE | Human-readable `DSP-XXXXXXXX` |
| `booking_id` | UUID UNIQUE FK | One dispute per booking |
| `reason` | dispute_reason | Enum |
| `evidence_urls` | TEXT[] | Supabase Storage URLs |
| `status` | TEXT | `open` → `under_review` → `resolved` / `closed` |
| `decision` | dispute_decision | Set by admin |
| `refund_amount` | INT | PKR |

---

### `notifications`
Push notifications for both customers and workers. References `auth.users` directly.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | UUID FK auth.users | Covers customers and workers |
| `type` | notification_type | Enum |
| `title` / `body` | TEXT | English |
| `title_urdu` / `body_urdu` | TEXT | Urdu translation |
| `deep_link` | TEXT | In-app navigation target |
| `data` | JSONB | Additional payload (booking_id etc.) |
| `is_read` | BOOL | |

**Index**: Partial index on `(user_id, is_read) WHERE is_read = false` for fast unread count.

---

### `saved_workers`
Customer's saved/favourite workers.

| Column | Type | Notes |
|--------|------|-------|
| `customer_id` | UUID FK customers | Cascade delete |
| `worker_id` | UUID FK workers | Cascade delete |
| UNIQUE | `(customer_id, worker_id)` | No duplicates |

---

## Storage Buckets

| Bucket | Access | Contents |
|--------|--------|---------|
| `avatars` | Public | Worker profile photos |
| `cnic-documents` | Private (signed URLs) | CNIC front/back scans |
| `skill-proofs` | Private (signed URLs) | Skill certificates |
| `receipts` | Public | Booking receipt PNGs |

---

## Auth Trigger

On every new `auth.users` INSERT:
- If `role = 'customer'` (or unset): auto-creates row in `customers`
- If `role = 'worker'`: no auto-create (worker does their own INSERT into `workers`)

Role is stored in `auth.users.user_metadata` at signup:
- Customer: `supabase.auth.signUp(data: {'role': 'customer'})`
- Worker registration: `supabase.auth.updateUser(data: {'role': 'worker'})`

---

## Screen → Table Map

| Screen | Tables Used |
|--------|-------------|
| SplashScreen | `auth.users` (user_metadata for role) |
| PhoneAuthScreen | `auth.users` |
| LanguageSelectScreen | `customers` |
| HomeScreen | `bookings`, `workers` |
| AgentTraceScreen | `sessions`, `agent_traces` |
| ProviderSelectionScreen | in-memory from session |
| ProviderProfileScreen | `workers` |
| BookingConfirmedScreen | `bookings` |
| BookingHistoryScreen | `bookings` |
| LiveTrackingScreen | `bookings`, `workers` |
| ReviewScreen | `reviews` → trigger → `workers` |
| DisputeScreen | `disputes` |
| MessagesScreen | `bookings` |
| WorkerProfileSetupScreen | `workers`, `worker_service_areas` |
| WorkerSkillSelectionScreen | `workers` |
| WorkerAreaScreen | `worker_service_areas` |
| WorkerHubScreen | `workers`, `bookings` |
| WorkerJobRequestScreen | `bookings` |
