<div align="center">

# Karigar AI: Flutter App

**Pakistan's AI-powered service marketplace**

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-karigar--ai--c0f37-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)

Customers send a natural-language service request in Urdu, Roman Urdu or English. The app streams live events from the 7-agent LangGraph backend and renders a real-time Mission Control timeline as the pipeline runs: intent parsing, provider ranking, booking confirmation and autonomous conflict recovery, all visible step by step.

[Backend Docs](../docs/README.md) · [Architecture](../docs/architecture.md) · [Project Plan](../plan.md)

</div>

---

## Quick Start

The backend must be running before the app can make bookings.

```bash
# 1. Start the backend (from repo root)
cd backend && uv run uvicorn app.main:app --reload

# 2. Run the app
cd mobile
flutter pub get

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Physical device — replace with your machine's LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

---

## Screens

| Screen | File | Role |
|:---|:---|:---|
| Splash | `lib/screens/splash_screen.dart` | Branding, Firebase init check |
| Language selection | `lib/screens/language_select_screen.dart` | Urdu / Roman Urdu / English |
| Role selection | `lib/screens/role_selection_screen.dart` | Customer or Worker |
| Home | `lib/screens/home_screen.dart` | Natural-language service request entry |
| Provider selection | `lib/screens/provider_selection_screen.dart` | Ranked candidates from backend |
| Live agent trace | `lib/screens/agent_trace_screen.dart` | Mission Control: real-time pipeline steps |
| Booking confirmed | `lib/screens/booking_confirmed_screen.dart` | Receipt, faux-WhatsApp confirmation |
| Booking history | `lib/screens/booking_history_screen.dart` | Past and active bookings |
| Live tracking | `lib/screens/live_tracking_screen.dart` | Provider en-route map |
| Worker hub | `lib/screens/worker_hub_screen.dart` | Incoming job requests for providers |

---

## Project Structure

```
lib/
├── main.dart                     # Entry point — Firebase init, Provider setup, KarigarApp
├── firebase_options.dart         # FlutterFire generated (karigar-ai-c0f37)
├── app/
│   ├── routes.dart               # Named route definitions
│   └── theme.dart                # Material 3 light and dark themes
├── constants/
│   └── app_colors.dart
├── models/
│   ├── agent_event.dart          # AgentTraceEvent, ToolCall
│   ├── booking.dart              # Booking with status helpers
│   └── provider_model.dart       # ProviderModel with ranking data
├── providers/
│   └── app_state.dart            # ChangeNotifier — auth, pipeline state, booking history
├── screens/                      # 20 screen files across customer and worker flows
├── services/
│   ├── api_client.dart           # KarigarApiClient — all backend HTTP calls
│   ├── sse_stub.dart             # SSE stub for native platforms
│   └── sse_web.dart              # SSE implementation for web
└── widgets/
    ├── animated_background.dart
    ├── karigar_logo.dart
    ├── karigar_screen_header.dart
    ├── agent_step_card.dart
    ├── provider_card.dart
    └── language_badge.dart
```

---

## Configuration

| Setting | How to set | Default |
|:---|:---|:---|
| Backend URL (Android emulator) | `--dart-define=API_BASE_URL=...` | `http://10.0.2.2:8000` |
| Backend URL (web) | hardcoded | `http://127.0.0.1:8000` |
| Firebase project | `lib/firebase_options.dart` | `karigar-ai-c0f37` |

---

## Firebase Setup

The app uses Firebase Authentication and Cloud Firestore.

- Android config: `android/app/google-services.json` (present)
- iOS config: `ios/Runner/GoogleService-Info.plist` (**not committed**); download from the Firebase Console (`karigar-ai-c0f37` project) and place at that path before building for iOS
- For Auth to work on a physical device, register the application ID `com.karigar.karigar` in the Firebase Console with your debug SHA-1 fingerprint (`keytool -list -v -keystore ~/.android/debug.keystore`)

---

## App Identity

| Field | Value |
|:---|:---|
| Dart package name | `karigar` |
| Android application ID | `com.karigar.karigar` |
| iOS bundle ID | `com.karigar.karigar` |
| Firebase project | `karigar-ai-c0f37` |
| Minimum Flutter | 3.38.0 |
| Minimum Dart SDK | 3.10.0 |
