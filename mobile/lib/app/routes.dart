import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/language_select_screen.dart';
import '../screens/phone_auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/agent_trace_screen.dart';
import '../screens/provider_selection_screen.dart';
import '../screens/booking_confirmed_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/review_screen.dart';
import '../screens/booking_history_screen.dart';
import '../screens/dispute_screen.dart';
import '../screens/provider_profile_screen.dart';
import '../screens/worker_skill_selection_screen.dart';
import '../screens/worker_area_screen.dart';
import '../screens/worker_hub_screen.dart';
import '../screens/worker_profile_setup_screen.dart';
import '../screens/worker_job_request_screen.dart';
import '../screens/messages_screen.dart';

class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String roleSelect    = '/role';
  static const String languageSelect = '/language';
  static const String auth          = '/auth';
  static const String home          = '/home';
  static const String agentTrace    = '/trace';
  static const String providerSelect = '/providers';
  static const String providerProfile = '/provider-profile';
  static const String bookingConfirmed = '/booking-confirmed';
  static const String liveTracking  = '/tracking';
  static const String review        = '/review';
  static const String history       = '/history';
  static const String dispute       = '/dispute';
  // Worker
  static const String workerProfile   = '/worker/profile';
  static const String workerSkills   = '/worker/skills';
  static const String workerArea     = '/worker/area';
  static const String workerHub      = '/worker/hub';
  static const String workerJobRequest = '/worker/job-request';
  static const String messages         = '/messages';

  static Map<String, WidgetBuilder> get routes => {
    splash:           (_) => const SplashScreen(),
    login:            (_) => const LoginScreen(),
    roleSelect:       (_) => const RoleSelectionScreen(),
    languageSelect:   (_) => const LanguageSelectScreen(),
    auth:             (_) => const PhoneAuthScreen(),
    home:             (_) => const HomeScreen(),
    agentTrace:       (_) => const AgentTraceScreen(),
    providerSelect:   (_) => const ProviderSelectionScreen(),
    providerProfile:  (_) => const ProviderProfileScreen(),
    bookingConfirmed: (_) => const BookingConfirmedScreen(),
    liveTracking:     (_) => const LiveTrackingScreen(),
    review:           (_) => const ReviewScreen(),
    history:          (_) => const BookingHistoryScreen(),
    dispute:          (_) => const DisputeScreen(),
    workerProfile:    (_) => const WorkerProfileSetupScreen(),
    workerSkills:     (_) => const WorkerSkillSelectionScreen(),
    workerArea:       (_) => const WorkerAreaScreen(),
    workerHub:        (_) => const WorkerHubScreen(),
    workerJobRequest: (_) => const WorkerJobRequestScreen(),
    messages:         (_) => const MessagesScreen(),
  };
}
