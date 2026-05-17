# Karigar — Demo Script

> Minute-by-minute plan for the 3–5 minute submission video.
> Target length: **4 minutes**. Hard cap: **5 minutes**.

## Goals (in priority order)

1. Show every brief-required deliverable beat: user input → understanding → matching → booking → follow-up.
2. Land the **auto-rebook recovery moment** — the differentiator.
3. Make Antigravity visible (Mission Control window, Browser subagent recording badge, Artifacts panel).
4. Show all 3 languages (or at least 2 to prove the claim).

## Setup before recording

- [ ] `/seed-mock` ran successfully; `Ali AC Services` is in G-13.
- [ ] `/run-e2e` shows 8/8 PASS.
- [ ] Backend running with `DEMO_MODE=true` (cached LLM responses) and `DEMO_TIME_SCALE=60` (1 sec = 1 min).
- [ ] Flutter app open on Android emulator (Pixel 7, dark mode, system locale `en_PK`).
- [ ] Antigravity open in the second monitor showing the Agent Manager view.
- [ ] Browser subagent extension enabled in Chrome.
- [ ] Microphone tested; pre-recorded Urdu voice clip ready as a fallback for the live mic.
- [ ] Screen recording set to 1920×1080 @ 30 fps; record both monitors (Antigravity left, Flutter right).
- [ ] No browser tabs, no notifications visible, do-not-disturb enabled.

## Storyboard

### 0:00 – 0:20 — Title + the problem (20 s)

**Visual**: Title card → cut to a quick montage of WhatsApp chats / a missed-call screenshot / a confused user.

**Voice-over**:
> "Pakistan's informal economy (plumbers, electricians, AC technicians) runs on WhatsApp messages, phone calls and word-of-mouth. Finding a reliable karigar for what you need, when you need it, is harder than it should be. We built **Karigar**: an agentic AI orchestrator that turns one natural-language sentence into a confirmed booking, and rebooks you autonomously if anything goes wrong."

### 0:20 – 0:35 — Open Antigravity Mission Control (15 s)

**Visual**: Cut to the Antigravity Agent Manager window. Show the 5 dev agents in `agents.md` and the 6 skills in `skills/`. Hover on a skill to show it loaded on demand.

**Voice-over**:
> "Built entirely inside Google Antigravity. Five specialised dev agents, six on-demand skills, two workflows: Antigravity orchestrates the build."

### 0:35 – 1:10 — The query in Roman Urdu (35 s)

**Visual**: Flutter app, WhatsApp-style chat screen. Tap the mic. Speak (or play the pre-recorded clip):

> *"Mujhe kal subah G-13 mein AC technician chahiye."*

The transcribed text appears in the chat. User taps send.

**Voice-over**:
> "I'll ask in Roman Urdu: the way most users actually talk."

### 1:10 – 2:00 — Live agent trace (50 s)

**Visual**: The Trace screen pops up. Cards animate in one by one:

1. **IntentAgent (Plan)** — "Detected Roman Urdu; AC_TECHNICIAN, G-13, tomorrow 06:00–12:00"
2. **Orchestrator (Plan)** — "Plan: 1) Resolve G-13 → 2) Find AC techs within 5km → 3) Rank by distance+rating+availability → 4) Book top → 5) Schedule T-1h reminder"
3. **DiscoveryAgent (Act)** — chips: `Geocoder` `ProviderStore` `Search`. "Found 6 candidates; enriched top-3 via Antigravity Browser subagent"
4. **RankingAgent (Decide)** — "Ali AC Services: 2.1 km, rating 4.7, exact slot free, Rs. 1500 — score 0.89"
5. **DecisionAgent (Decide)** — "Choosing Ali AC Services: nazdeek, high rating, available."
6. **BookingAgent (Act)** — chips: `Availability.check_and_hold` `Bookings.create` `Notifier.send`. "Booked Ali AC Services for 10:00; receipt #a8f3..."
7. **FollowupAgent (Follow-up)** — "Scheduled T-1h reminder, T+15min watchdog, T+2h completion"

**Voice-over** (over the animation):
> "Watch the agents work. Intent. Plan. Discover: using Antigravity's Browser subagent to enrich the providers with reputation snippets. Rank. Decide. Book. Schedule follow-ups. Every step is labelled with its phase (Plan, Decide, Act, Follow-up) and every tool call is named. This is the agent trace the brief asks for."

### 2:00 – 2:25 — Confirmation (25 s)

**Visual**: App switches to the faux-WhatsApp confirmation screen — green bubbles, "Karigar Booking Confirmed", details in Roman Urdu, ticks.

**Voice-over**:
> "Confirmation arrives in Roman Urdu: the same language the user spoke. A receipt is generated, a booking is in SQLite and three follow-up jobs are queued."

### 2:25 - 3:10: The recovery moment (45 s): **the differentiator**

**Visual**: Title overlay: *"Demo time-scale: 1 sec = 1 min."* The bookings list shows the booking. ~15 seconds pass (= 15 simulated minutes after the slot start). A notification fires: *"Ali AC Services didn't confirm, auto-rebooking..."*

Cut back to the Trace screen. New cards animate in with amber **Recover** badges:

1. **ConflictResolverAgent (Recover)** — "no_show_detected on provider Ali AC Services; attempt 1/3; excluded from candidates"
2. **DiscoveryAgent (Recover)** — "5 candidates after exclusion"
3. **RankingAgent (Decide)** — "Hassan Cooling Experts: 2.8 km, rating 4.5, exact slot free, Rs. 1600 — score 0.81"
4. **DecisionAgent (Decide)** — "Choosing Hassan Cooling Experts."
5. **BookingAgent (Act)** — "Booked Hassan Cooling Experts for 10:00."

Then a new faux-WhatsApp message pops:
> *"Ali AC Services ne confirm nahi kiya. Hum ne Hassan Cooling Experts ko 10:00 ke liye book kar diya hai."*

**Voice-over** (over the recovery):
> "Provider Ali AC Services doesn't show up. The no-show watchdog fires. The seventh agent (the Conflict Resolver) wakes up, excludes Ali and re-runs the pipeline. Within seconds, Hassan Cooling Experts is booked. The user is notified in their language. This is the agentic autonomy the brief is looking for: recovery from real-world failure, with no human prompt."

### 3:10 – 3:30 — Multilingual proof (20 s)

**Visual**: Quick cut — same query in Urdu script ("کل صبح جی-۱۳ میں اے سی ٹیکنیشن چاہیے") and in English ("I need an AC technician in G-13 tomorrow morning"). Show that the same agent flow runs and the confirmation comes back in matching language.

**Voice-over**:
> "Same query, three languages: Urdu, Roman Urdu, English. The agent always replies in the language the user spoke."

### 3:30 – 3:50 — Antigravity, end to end (20 s)

**Visual**: Cut back to Antigravity. Show:
- The Walkthrough Artifact (this run's Implementation Plan)
- The Browser Recording Artifact (this very demo, captured by Antigravity)
- The exported `trace.md` open in the Editor

**Voice-over**:
> "Everything you just saw: built in Antigravity, executed using its Browser subagent at runtime, recorded by Antigravity, exported as Antigravity Artifacts. The trace markdown (Decisions, Tool usage, Action execution, in that order) is part of our submission."

### 3:50 – 4:00 — Wrap (10 s)

**Visual**: Logo + tagline: *"Karigar: an agent for every karigar."* GitHub URL on screen.

**Voice-over**:
> "Karigar. One sentence, seven agents, zero missed appointments. Thank you."

## Backup beats (if you have extra time)

- Show `pyproject.toml` + `uv.lock` to prove reproducible builds.
- Set `GOOGLE_MAPS_KEY` live to show the real-API swap.
- Show the `flutter build web` deployed instance.

## Pacing checklist

- Aim for **120 ± 20 words per minute** of voice-over. The script above is ~480 words → ~4 minutes.
- Pause for 1 second after each agent card animates in during 1:10–2:00 — let the visual breathe.
- The recovery moment (2:25–3:10) is the climax. Volume + cadence should lift there.

## Recording with the Antigravity Browser subagent

1. Open Antigravity Agent Manager → start a new conversation.
2. Prompt: *"Record a 4-minute demo of the Karigar app following `demo/script.md`. Use the Browser subagent to drive the Flutter web build at `http://localhost:5000` and capture both the app and the trace stream."*
3. Approve the JavaScript execution permission when prompted.
4. The subagent produces a `.webm` file + screenshots in `demo/artifacts/`. Convert to `.mp4` with `ffmpeg` if needed.

## Submission artifact list

- [ ] `demo/karigar-demo.mp4`: final cut, 4 min, 1080p
- [ ] `demo/karigar-demo-browser-recording.webm`: the raw Antigravity Browser recording
- [ ] `demo/trace-export.md`: the agent trace for the demo session, exported via `GET /sessions/{id}/trace.md`
- [ ] `demo/screenshots/` — at least: trace timeline, faux-WhatsApp confirmation, recovery moment
