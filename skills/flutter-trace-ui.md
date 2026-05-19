# Skill: Flutter Trace UI

> Load this skill when working on `mobile/lib/screens/trace.dart`, `mobile/lib/widgets/agent_step_card.dart` or any widget that renders an agent trace event.
> Owner: `flutter-engineer`.

## Purpose

The trace timeline is the single most important screen in Karigar: judges spend most of their time looking at it. It must look intentional, polished and consistent with Antigravity's own Mission Control UI.

## Data shape (consumed from SSE)

```dart
// mobile/lib/models/trace_event.dart
class TraceEvent {
  final int step;
  final String agent;             // "IntentAgent", "DiscoveryAgent", ...
  final TracePhase phase;         // enum: plan, decide, act, follow_up, recover
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final List<ToolCall> toolCalls;
  final int latencyMs;
  final String reasoning;
  final String? triggeredBy;
  final DateTime receivedAt;
}

class ToolCall {
  final String name;              // e.g. "Geocoder.resolve"
  final Map<String, dynamic> args;
  final dynamic result;
  final int latencyMs;
}
```

The SSE client (`mobile/lib/services/sse_client.dart`) streams these into a Riverpod `StreamProvider<List<TraceEvent>>` keyed by session id.

## Per-agent visual identity

| Agent | Icon (Material) | Accent color | Notes |
|---|---|---|---|
| IntentAgent | `Icons.psychology` | `colorScheme.primary` | Brain: "understanding" |
| Orchestrator (Plan) | `Icons.checklist_rtl` | `colorScheme.secondary` | Numbered checklist |
| DiscoveryAgent | `Icons.search` | `colorScheme.tertiary` | Magnifier |
| RankingAgent | `Icons.bar_chart` | `colorScheme.tertiary` | Bar chart |
| DecisionAgent | `Icons.check_circle_outline` | `colorScheme.primary` | Checkmark |
| BookingAgent | `Icons.event_available` | `colorScheme.primary` | Calendar |
| FollowupAgent | `Icons.notifications_active` | `colorScheme.secondary` | Bell |
| **ConflictResolverAgent** | `Icons.warning_amber_rounded` | **`Colors.amber.shade700`** | Distinct amber so recovery moments POP |

Phase badge colours (small pill next to the agent name):

| Phase | Badge color | Label |
|---|---|---|
| `plan` | `colorScheme.secondaryContainer` | "Plan" |
| `decide` | `colorScheme.primaryContainer` | "Decide" |
| `act` | `colorScheme.tertiaryContainer` | "Act" |
| `follow_up` | `colorScheme.surfaceContainerHigh` | "Follow-up" |
| `recover` | `Colors.amber.shade100` (text amber.shade900) | "Recover" |

## `AgentStepCard` structure

A single trace event renders as one card on a vertical timeline rail:

```
┌──────────────────────────────────────────────────────────┐
│  ●─┤ [icon]  AgentName        [phase badge]  [⏱ 247 ms] │
│  │ │                                                    │
│  │ │  Reasoning text wraps here. Sentence case.        │
│  │ │                                                    │
│  │ │  [Geocoder] [ProviderStore] [Search]              │  ← tool-call chips
│  │ │                                                    │
│  │ │  ▾ Show input/output (tap to expand)              │
│  └─┘                                                     │
└──────────────────────────────────────────────────────────┘
```

- The bullet (●) is filled while the step is "live" (within last 2 s) and outlined otherwise.
- The vertical rail (│) connects consecutive cards.
- The latency badge color:
  - `< 500 ms` → green
  - `< 2000 ms` → yellow
  - `>= 2000 ms` → red
- Tap a chip → bottom sheet with the tool call's `args` and `result`.
- Tap `▾ Show input/output` → expands an inline JSON viewer (use `flutter_highlight` or a custom monospace `Text`).

## Animations

- **Fade-in + slide-up** on new event arrival (200 ms `Curves.easeOutCubic`).
- **Pulse** on the latency badge for events still streaming (use `AnimatedOpacity` looped).
- **Rail draw** as the next card mounts (250 ms vertical line growth using `AnimatedContainer`).
- No animation longer than 250 ms: the trace can fire 7+ events in under 2 s.

## States

| State | What to render |
|---|---|
| Empty (no session yet) | Centered Antigravity-style placeholder with caption *"Send a request to see the agents work."* |
| Loading (session started, no events yet) | Skeleton card with shimmer for 1 to 2 s |
| Streaming | Live cards, last one pulses |
| Error (SSE disconnected) | Persistent banner: *"Live trace disconnected, retrying..."*; client polls `GET /sessions/{id}/trace` every 500 ms as fallback |
| Complete | Static cards, last one shows a "✓ Done" pill |

## RTL (Urdu)

When `state.parsed_intent.language == "ur"`, wrap the timeline in `Directionality(textDirection: TextDirection.rtl, ...)`. Icons and chips stay in their natural reading order; the rail flips to the right. Test with the Urdu sample query before declaring done.

## Required widgets

- `mobile/lib/widgets/agent_step_card.dart`: the card above
- `mobile/lib/widgets/tool_call_chip.dart`: small pill, name + optional latency
- `mobile/lib/widgets/phase_badge.dart`: coloured pill
- `mobile/lib/widgets/latency_badge.dart`: clock icon + color-coded text
- `mobile/lib/screens/trace.dart`: the full timeline; consumes `traceProvider(sessionId)`

## Theming

Use `Theme.of(context).colorScheme` everywhere. Define the app theme in `mobile/lib/main.dart`:
- Light mode: a clean white background, primary green `#0A7C42` (Pakistani green tone).
- Dark mode (default for demo): `Material 3` dark, primary green tuned for OLED.
- Font: system (San Francisco / Roboto). Add Noto Nastaliq Urdu via `google_fonts` for Urdu text only.

## Don'ts

- Don't use raw hex colours in widgets: go through `colorScheme`.
- Don't truncate `reasoning`; it's the most important text on the card. Wrap, don't ellipsize.
- Don't sort events client-side: trust the `step` field's order from the server.
- Don't auto-collapse the input/output on Recover events: those are the moments the user wants to inspect.
