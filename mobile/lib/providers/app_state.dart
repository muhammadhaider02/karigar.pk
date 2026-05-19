import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider_model.dart';
import '../models/agent_event.dart';
import '../models/booking.dart';
import '../services/api_client.dart';

class AppState extends ChangeNotifier {
  String _language = 'english';
  String get language => _language;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // ── Theme mode ───────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark; // default to dark (matches brand)
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  // ── Pipeline state ────────────────────────────────────────────
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  final List<AgentTraceEvent> _traceEvents = [];
  List<AgentTraceEvent> get traceEvents => List.unmodifiable(_traceEvents);

  final List<ProviderModel> _recommendedProviders = [];
  List<ProviderModel> get recommendedProviders => List.unmodifiable(_recommendedProviders);

  ProviderModel? _selectedProvider;
  ProviderModel? get selectedProvider => _selectedProvider;

  Booking? _currentBooking;
  Booking? get currentBooking => _currentBooking;

  bool _isPipelineRunning = false;
  bool get isPipelineRunning => _isPipelineRunning;

  String? _finalDecision;
  String? get finalDecision => _finalDecision;

  String? _pipelineError;
  String? get pipelineError => _pipelineError;

  // ── Booking history ──────────────────────────────────────────
  final List<Booking> _bookings = [];
  List<Booking> get bookings => List.unmodifiable(_bookings);

  bool _isLoadingBookings = false;
  bool get isLoadingBookings => _isLoadingBookings;

  // ── API client ───────────────────────────────────────────────
  final KarigarApiClient _api = KarigarApiClient();

  // ── Methods ──────────────────────────────────────────────────

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> startBookingFlow(String query) async {
    _currentQuery = query;
    _traceEvents.clear();
    _recommendedProviders.clear();
    _selectedProvider = null;
    _currentBooking = null;
    _finalDecision = null;
    _pipelineError = null;
    _isPipelineRunning = true;
    _currentSessionId = null;
    notifyListeners();

    try {
      // 1. Start session on the backend
      final sessionId = await _api.startSession(
        userId: _userId,
        rawText: query,
        language: _language,
      );
      _currentSessionId = sessionId;

      // 2. Stream SSE trace events
      await for (final msg in _api.streamSession(sessionId)) {
        final eventType = msg['event'] as String;
        final data = msg['data'];

        if (eventType == 'trace' && data is Map<String, dynamic>) {
          final event = AgentTraceEvent.fromJson(data);
          _traceEvents.add(event);

          // Capture provider list from RankingAgent event during SSE stream
          if (event.candidateProviders != null &&
              event.candidateProviders!.isNotEmpty) {
            _recommendedProviders
              ..clear()
              ..addAll(event.candidateProviders!.map(
                (p) => ProviderModel.fromJson(p as Map<String, dynamic>),
              ));
          }

          // Capture routing decision
          if (event.antigravityDecision != null) {
            _finalDecision = event.antigravityDecision;
          }

          notifyListeners();
        } else if (eventType == 'done') {
          // Pipeline finished — fetch final session for booking details
          await _loadSessionResult(sessionId);
          break;
        }
        // 'ping' events are heartbeats — ignore
      }
    } catch (e) {
      _pipelineError = e.toString();
    } finally {
      _isPipelineRunning = false;
      notifyListeners();
    }
  }

  Future<void> _loadSessionResult(String sessionId) async {
    try {
      final session = await _api.getSession(sessionId);

      // Extract ranked candidates
      // The GET /sessions/{id} returns chosen + booking, not the full ranked list.
      // We build recommendedProviders from available data.
      final chosen = session['chosen'] as Map<String, dynamic>?;
      if (chosen != null) {
        _recommendedProviders
          ..clear()
          ..add(ProviderModel.fromRankedCandidate(chosen));
      }

      // Extract current booking
      final bookingJson = session['booking'] as Map<String, dynamic>?;
      if (bookingJson != null) {
        _currentBooking = Booking.fromJson(bookingJson);
      }

      // Decide navigation
      if (_recommendedProviders.isNotEmpty) {
        _finalDecision = 'show_options';
      } else if (pipelineError != null) {
        _finalDecision = 'error';
      }
    } catch (_) {
      // Session fetch failed — still show whatever trace we have
      if (_traceEvents.isNotEmpty) {
        _finalDecision = 'show_options';
      }
    }
  }

  void selectProvider(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  void confirmBooking(ProviderModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  // ── Booking history ──────────────────────────────────────────

  Future<void> loadBookings() async {
    _isLoadingBookings = true;
    notifyListeners();
    try {
      final raw = await _api.listBookings(_userId);
      _bookings
        ..clear()
        ..addAll(raw.map(Booking.fromJson));
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId, {bool rebook = false}) async {
    await _api.cancelBooking(bookingId, rebook: rebook);
    await loadBookings();
  }

  Future<void> markBookingArrived(String bookingId) async {
    await _api.markArrived(bookingId);
    await loadBookings();
  }

  Future<void> markBookingComplete(String bookingId) async {
    await _api.markComplete(bookingId);
    await loadBookings();
  }
}
