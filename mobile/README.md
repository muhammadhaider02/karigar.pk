<div align="center">

# Karigar AI: Flutter App

**Pakistan's AI-powered service marketplace**

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-karigar--ai--c0f37-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)

Customers send a text or voice service request in Urdu, Roman Urdu or English. The app streams live events from the 7-agent LangGraph backend and renders a real-time Mission Control timeline as the pipeline runs: intent parsing, provider ranking, booking confirmation and autonomous conflict recovery, all visible step by step.

[Backend Docs](../docs/README.md) · [Architecture](../docs/architecture.md) · [Project Plan](../docs/plan.md)

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

# Physical device (replace with your machine's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

---

## Screens

### Customer flow

| Screen | File | Role |
|:---|:---|:---|
| Splash | `splash_screen.dart` | Branding and Firebase init check |
| Language selection | `language_select_screen.dart` | Urdu / Roman Urdu / English |
| Phone auth | `phone_auth_screen.dart` | Email/password signup and login |
| Login | `login_screen.dart` | Alternative auth entry point |
| Role selection | `role_selection_screen.dart` | Customer or Worker |
| Home | `home_screen.dart` | Text or voice service request, GPS location, booking list |
| All services | `all_services_screen.dart` | Grid of 14 service categories with Urdu labels |
| All roles | `all_roles_screen.dart` | Browse service categories with live worker counts |
| Workers by role | `workers_by_role_screen.dart` | List workers filtered by selected role |
| Live agent trace | `agent_trace_screen.dart` | Mission Control: real-time pipeline steps |
| Provider selection | `provider_selection_screen.dart` | Ranked candidates from backend |
| Provider profile | `provider_profile_screen.dart` | Provider detail and time slot picker |
| Booking confirmed | `booking_confirmed_screen.dart` | Receipt and faux-WhatsApp confirmation |
| Booking history | `booking_history_screen.dart` | Tabbed history (Active, Completed, Cancelled) |
| Live tracking | `live_tracking_screen.dart` | Provider en-route map with ETA |
| Review | `review_screen.dart` | Star rating and tag-based feedback |
| Dispute | `dispute_screen.dart` | File dispute with 6 reason categories |
| Messages | `messages_screen.dart` | Chat list with workers |
| Emergency | `emergency_screen.dart` | Quick-dial emergency services and location sharing |

### Worker flow

| Screen | File | Role |
|:---|:---|:---|
| Worker hub | `worker_hub_screen.dart` | Dashboard: job list, availability toggle, stats |
| Job request | `worker_job_request_screen.dart` | Accept or decline incoming job offers |
| Profile setup | `worker_profile_setup_screen.dart` | Name, phone, CNIC, address, profile photo |
| Skill selection | `worker_skill_selection_screen.dart` | Multi-select skills (14 options), hourly rate |
| Service area | `worker_area_screen.dart` | Coverage zones |

---

## Project Structure

```
lib/
├── main.dart                     # Entry point, Firebase init, Provider setup
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
│   └── app_state.dart            # ChangeNotifier: auth, pipeline state, booking history
├── screens/                      # 24 screen files across customer and worker flows
├── services/
│   ├── api_client.dart           # KarigarApiClient: all backend HTTP calls
│   ├── voice.dart                # Audio recording (record package) + base64 encoding
│   ├── notifications.dart        # Push notifications
│   ├── sse_client.dart           # SSE client
│   ├── sse_stub.dart             # SSE stub for native platforms
│   └── sse_web.dart              # SSE implementation for web
└── widgets/
    ├── agent_loader_overlay.dart  # Animated pipeline overlay
    ├── agent_step_card.dart
    ├── animated_background.dart
    ├── karigar_logo.dart
    ├── karigar_screen_header.dart
    ├── provider_card.dart
    └── language_badge.dart
```

---

## Configuration

| Setting | How to set | Default |
|:---|:---|:---|
| Backend URL (native) | `--dart-define=API_BASE_URL=...` | `https://karigar-pk.onrender.com` |
| Backend URL (web) | `--dart-define=API_BASE_URL=...` | `http://127.0.0.1:8000` |
| Firebase project | `lib/firebase_options.dart` | `karigar-ai-c0f37` |

---

## Firebase Setup

The app uses Firebase Authentication and Cloud Firestore.

- Android config: `android/app/google-services.json` (present)
- iOS config: `ios/Runner/GoogleService-Info.plist` (**not committed**); download from the Firebase Console (`karigar-ai-c0f37` project) and place at that path before building for iOS
- For Auth to work on a physical device, register the application ID `com.karigar.karigar` in the Firebase Console with your debug SHA-1 fingerprint (`keytool -list -v -keystore ~/.android/debug.keystore`)

---

## Web Deployment

The web build is generated with `flutter build web` and deployed to Vercel:

`https://karigar-pk.vercel.app/`

The web build connects to the production backend at `https://karigar-pk.onrender.com` by default.

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
