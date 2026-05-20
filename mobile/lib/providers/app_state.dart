import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _isAuthenticated = session != null;
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

  final List<ProviderModel> _nearbyWorkers = [];
  List<ProviderModel> get nearbyWorkers => List.unmodifiable(_nearbyWorkers);
  bool _isLoadingNearby = false;
  bool get isLoadingNearby => _isLoadingNearby;

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

  // ── Worker Registration ──────────────────────────────────────────
  final WorkerRegistrationData workerRegistrationData = WorkerRegistrationData();
  bool _isRegisteringWorker = false;
  bool get isRegisteringWorker => _isRegisteringWorker;

  Future<void> submitWorkerRegistration() async {
    _isRegisteringWorker = true;
    notifyListeners();
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('User must be logged in to register as a worker.');
      }

      String? avatarUrl;
      if (workerRegistrationData.profilePhoto != null) {
        final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supa.storage.from('avatars').upload(path, workerRegistrationData.profilePhoto!);
        avatarUrl = supa.storage.from('avatars').getPublicUrl(path);
      }

      String? cnicFrontUrl;
      if (workerRegistrationData.cnicFront != null) {
        final path = '$uid/front_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supa.storage.from('cnic-documents').upload(path, workerRegistrationData.cnicFront!);
        cnicFrontUrl = supa.storage.from('cnic-documents').getPublicUrl(path);
      }

      String? cnicBackUrl;
      if (workerRegistrationData.cnicBack != null) {
        final path = '$uid/back_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supa.storage.from('cnic-documents').upload(path, workerRegistrationData.cnicBack!);
        cnicBackUrl = supa.storage.from('cnic-documents').getPublicUrl(path);
      }

      // Optional proof-of-skill certificate
      final List<String> proofOfSkillUrls = [];
      if (workerRegistrationData.cert != null) {
        final path = '$uid/cert_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supa.storage.from('skill-proofs').upload(path, workerRegistrationData.cert!);
        proofOfSkillUrls.add(supa.storage.from('skill-proofs').getPublicUrl(path));
      }

      // Upsert into unified workers table (auth_user_id links to auth.users)
      final primaryArea = workerRegistrationData.areas.isNotEmpty
          ? workerRegistrationData.areas.first
          : workerRegistrationData.district;
      await supa.from('workers').upsert({
        'auth_user_id': uid,
        'full_name': workerRegistrationData.fullName,
        'phone_number': workerRegistrationData.phone,
        'cnic_number': workerRegistrationData.cnic,
        'cnic_front_url': cnicFrontUrl,
        'cnic_back_url': cnicBackUrl,
        'profile_photo_url': avatarUrl,
        'skills': workerRegistrationData.skills.toList(),
        'rate_per_hour': workerRegistrationData.hourlyRate.toInt(),
        'minimum_charge': workerRegistrationData.hourlyRate.toInt(),
        'district': workerRegistrationData.district,
        'area': primaryArea,
        'home_address': workerRegistrationData.address,
        'verification_status': 'pending',
        if (proofOfSkillUrls.isNotEmpty) 'proof_of_skill_urls': proofOfSkillUrls,
        if (workerRegistrationData.homeLat != null) 'home_lat': workerRegistrationData.homeLat,
        if (workerRegistrationData.homeLng != null) 'home_lng': workerRegistrationData.homeLng,
      }, onConflict: 'auth_user_id');

      // Mark user as worker in metadata so fetchUserRole() works without a DB call
      await supa.auth.updateUser(UserAttributes(data: {'role': 'worker'}));

      // Insert service areas — worker_id is the UUID from workers (not uid)
      if (workerRegistrationData.areas.isNotEmpty) {
        final workerRow = await supa
            .from('workers')
            .select('id')
            .eq('auth_user_id', uid)
            .single();
        final workerId = workerRow['id'] as String;
        final areaInserts = workerRegistrationData.areas.map((area) => {
          'worker_id': workerId,
          'district': workerRegistrationData.district,
          'area': area,
          'is_primary': area == workerRegistrationData.areas.first,
        }).toList();
        await supa.from('worker_service_areas').insert(areaInserts);
      }
      
    } catch (e) {
      debugPrint('Error registering worker: $e');
      rethrow;
    } finally {
      _isRegisteringWorker = false;
      notifyListeners();
    }
  }

  // ── Methods ──────────────────────────────────────────────────

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
    // Persist to Supabase profiles.language so the AI agents (and the worker
    // app) can use it too. Silently swallow errors — UX shouldn't block on this.
    () async {
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client
              .from('customers')
              .update({'language': lang})
              .eq('id', uid);
        }
      } catch (e) {
        debugPrint('Could not persist language: $e');
      }
    }();
  }

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  // Read role from user_metadata (set at signup / worker registration).
  // No DB query needed — role lives in auth.users.user_metadata.
  Future<String?> fetchUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      final meta = user.userMetadata;
      final lang = meta?['language'] as String?;
      if (lang != null && lang.isNotEmpty) _language = lang;
      return meta?['role'] as String?;
    } catch (e) {
      debugPrint('fetchUserRole failed: $e');
    }
    return null;
  }

  Future<void> startBookingFlow(String query, {double? lat, double? lng}) async {
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
      final sessionId = await _api.startSession(
        userId: _userId,
        rawText: query,
        language: _language,
        lat: lat ?? _customerLat,
        lng: lng ?? _customerLng,
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

  // Customer-chosen time slot for the next booking. Null = "now/ASAP".
  DateTime? _bookingSlot;
  DateTime? get bookingSlot => _bookingSlot;
  void setBookingSlot(DateTime? when) {
    _bookingSlot = when;
    notifyListeners();
  }

  Future<void> confirmBooking(ProviderModel provider) async {
    _selectedProvider = provider;
    notifyListeners();

    try {
      final String code = 'BKG-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).substring(0, 8).toUpperCase()}';
      
      // Clean up service type to match the Supabase `service_category` enum.
      // Valid values: plumber, electrician, ac_technician, carpenter, painter,
      //               cleaner, mason, welder, pest_control, appliance_repair
      String serviceType = provider.serviceType.toLowerCase().replaceAll(' ', '_');
      const validEnums = {
        'plumber','electrician','ac_technician','carpenter','painter',
        'cleaner','mason','welder','pest_control','appliance_repair',
        'tutor','beautician','solar_technician','driver',
      };
      if (!validEnums.contains(serviceType)) serviceType = 'plumber';

      final slot = _bookingSlot ?? DateTime.now().add(const Duration(hours: 1));
      // Determine urgency from how soon the slot is. <2h = high, <24h = medium, else low.
      final hoursAway = slot.difference(DateTime.now()).inMinutes / 60;
      final urgency = hoursAway < 2 ? 'high' : (hoursAway < 24 ? 'medium' : 'low');

      // Only include worker_id if it looks like a real UUID (not a Google Places gplace_ id)
      final isRealUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(provider.id);

      final bookingData = <String, dynamic>{
        'booking_code': code,
        'customer_id': _userId,
        if (isRealUuid && provider.id.isNotEmpty) 'worker_id': provider.id,
        'service_type': serviceType,
        'description': _currentQuery.isNotEmpty ? _currentQuery : serviceType,
        'raw_input': _currentQuery.isNotEmpty ? _currentQuery : serviceType,
        'urgency': urgency,
        'status': 'worker_assigned',
        'price_estimate': provider.pricePerVisit > 0 ? provider.pricePerVisit : 500,
        'slot_time': slot.toUtc().toIso8601String(),
        if (_customerLat != null) 'job_lat': _customerLat,
        if (_customerLng != null) 'job_lng': _customerLng,
      };

      final response = await Supabase.instance.client
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      _currentBooking = Booking.fromJson(response);
      await loadBookings();
    } catch (e) {
      debugPrint('confirmBooking error: $e');
      rethrow;
    }
  }

  // ── Booking history ──────────────────────────────────────────

  Future<void> loadBookings() async {
    _isLoadingBookings = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, workers(full_name)')
          .eq('customer_id', _userId)
          .order('created_at', ascending: false);
      _bookings
        ..clear()
        ..addAll((response as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          // Flatten joined workers.full_name → provider_name
          final workerMap = m['workers'] as Map<String, dynamic>?;
          if (workerMap != null) m['provider_name'] = workerMap['full_name'] ?? '';
          return Booking.fromJson(m);
        }));
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId, {bool rebook = false}) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      await loadBookings();
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
    }
  }

  Future<void> workerAcceptBooking(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'worker_accepted'})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('workerAcceptBooking error: $e');
    }
  }

  Future<void> workerDeclineBooking(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('workerDeclineBooking error: $e');
    }
  }

  Future<void> markBookingArrived(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'arrived'})
          .eq('id', bookingId);
      await loadBookings();
    } catch (e) {
      debugPrint('Error marking booking arrived: $e');
    }
  }

  Future<void> markBookingInProgress(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'in_progress'})
          .eq('id', bookingId);
      await loadBookings();
    } catch (e) {
      debugPrint('Error marking booking in-progress: $e');
    }
  }

  // Haversine distance in km between two lat/lng points
  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final dLng = (lng2 - lng1) * 3.141592653589793 / 180;
    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        (lat1 * 3.141592653589793 / 180).abs() * (lat2 * 3.141592653589793 / 180).abs() *
        (dLng / 2).abs() * (dLng / 2).abs();
    return r * 2 * (a < 1 ? a : 1);
  }

  // The customer's current location — set from the home screen GPS fetch.
  double? _customerLat;
  double? _customerLng;
  double? get customerLat => _customerLat;
  double? get customerLng => _customerLng;
  void setCustomerLocation(double lat, double lng) {
    _customerLat = lat;
    _customerLng = lng;
  }

  // Customer-side: load all verified workers offering a given service.
  // Used by home-screen category cards (e.g. tap "Electrician" → see all of them).
  // If [area] is set, prefers workers in that area; otherwise sorts by distance
  // from the customer's current location (if known).
  Future<void> loadWorkersByService(String serviceType, {String? area}) async {
    _recommendedProviders.clear();
    _pipelineError = null;
    notifyListeners();
    try {
      final supa = Supabase.instance.client;
      // workers.skills is service_category[]; full_name and phone_number are direct columns
      var query = supa
          .from('workers')
          .select('id, skills, rate_per_hour, district, area, home_lat, home_lng, rating, total_reviews, profile_photo_url, full_name, phone_number')
          .contains('skills', [serviceType])
          .eq('verification_status', 'verified');
      if (area != null && area.isNotEmpty) {
        query = query.eq('area', area);
      }
      final rows = await query.order('rating', ascending: false);

      final List<ProviderModel> built = [];
      for (final row in (rows as List)) {
        final m = row as Map<String, dynamic>;
        final name = (m['full_name'] as String?) ?? 'Worker';
        final wLat = (m['home_lat'] ?? 0.0).toDouble();
        final wLng = (m['home_lng'] ?? 0.0).toDouble();
        final dist = (_customerLat != null && _customerLng != null && wLat != 0.0)
            ? haversineKm(_customerLat!, _customerLng!, wLat, wLng)
            : 0.0;
        built.add(ProviderModel(
          id: m['id'] as String,
          name: name,
          services: List<String>.from(m['skills'] ?? []),
          lat: wLat,
          lng: wLng,
          rating: (m['rating'] ?? 0.0).toDouble(),
          pricePerVisit: (m['rate_per_hour'] ?? 0) as int,
          phone: (m['phone_number'] as String?) ?? '',
          distanceKm: dist,
          score: (m['rating'] ?? 0.0).toDouble(),
          reasoning: '${m['area'] ?? ''}, ${m['district'] ?? ''} · ${m['total_reviews'] ?? 0} reviews',
          imageUrl: (m['profile_photo_url'] as String?) ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=4CAF50&color=fff&size=200',
        ));
      }
      // Closest first when we have customer GPS
      if (_customerLat != null) {
        built.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }
      _recommendedProviders.addAll(built);
    } catch (e) {
      _pipelineError = e.toString();
      debugPrint('Error loading workers by service: $e');
    } finally {
      notifyListeners();
    }
  }

  // Top 6 closest verified workers regardless of service type — for "Near You" home section.
  Future<void> loadNearbyWorkers() async {
    if (_customerLat == null || _customerLng == null) return;
    _isLoadingNearby = true;
    notifyListeners();
    try {
      final supa = Supabase.instance.client;
      final rows = await supa
          .from('workers')
          .select('id, skills, rate_per_hour, district, area, home_lat, home_lng, rating, total_reviews, profile_photo_url, full_name, phone_number')
          .eq('verification_status', 'verified')
          .not('home_lat', 'is', null)
          .not('home_lng', 'is', null);

      final List<ProviderModel> built = [];
      for (final row in (rows as List)) {
        final m = row as Map<String, dynamic>;
        final wLat = (m['home_lat'] ?? 0.0).toDouble();
        final wLng = (m['home_lng'] ?? 0.0).toDouble();
        if (wLat == 0.0 && wLng == 0.0) continue;
        final dist = haversineKm(_customerLat!, _customerLng!, wLat, wLng);
        final name = (m['full_name'] as String?) ?? 'Worker';
        built.add(ProviderModel(
          id: m['id'] as String,
          name: name,
          services: List<String>.from(m['skills'] ?? []),
          lat: wLat,
          lng: wLng,
          rating: (m['rating'] ?? 0.0).toDouble(),
          pricePerVisit: (m['rate_per_hour'] ?? 0) as int,
          phone: (m['phone_number'] as String?) ?? '',
          distanceKm: dist,
          score: (m['rating'] ?? 0.0).toDouble(),
          reasoning: '${m['area'] ?? ''}, ${m['district'] ?? ''}',
          imageUrl: (m['profile_photo_url'] as String?) ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=4CAF50&color=fff&size=200',
        ));
      }
      built.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      _nearbyWorkers
        ..clear()
        ..addAll(built.take(6));
    } catch (e) {
      debugPrint('loadNearbyWorkers error: $e');
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }

  // Worker-side dashboard stats — computed from bookings + workers.
  // Returns: {todayEarnings, weekEarnings, jobsToday, rating, totalReviews, jobsCompleted}
  Future<Map<String, dynamic>> loadWorkerStats() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return {};
    try {
      // Resolve auth UID → workers.id (auto-generated UUID)
      final workerRow = await supa
          .from('workers')
          .select('id')
          .eq('auth_user_id', uid)
          .maybeSingle();
      if (workerRow == null) return {};
      final workerId = workerRow['id'] as String;

      // Fetch completed bookings for this worker (price + completed_at)
      final bookings = await supa
          .from('bookings')
          .select('price_estimate, final_price, completed_at, status')
          .eq('worker_id', workerId)
          .eq('status', 'completed');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1)); // Monday

      int todayEarn = 0, weekEarn = 0, totalEarn = 0;
      int jobsToday = 0, jobsWeek = 0;
      for (final row in (bookings as List)) {
        final m = row as Map<String, dynamic>;
        final price = (m['final_price'] ?? m['price_estimate'] ?? 0) as int;
        totalEarn += price;
        final completedIso = m['completed_at'] as String?;
        if (completedIso == null) continue;
        final completed = DateTime.tryParse(completedIso)?.toLocal();
        if (completed == null) continue;
        if (completed.isAfter(today)) { todayEarn += price; jobsToday++; }
        if (completed.isAfter(weekStart)) { weekEarn += price; jobsWeek++; }
      }

      // Worker profile for rating + total counts (workers.auth_user_id = uid)
      final profileRows = await supa
          .from('workers')
          .select('rating, total_reviews, jobs_completed')
          .eq('auth_user_id', uid)
          .limit(1);
      double rating = 0.0;
      int totalReviews = 0, jobsCompleted = 0;
      if (profileRows is List && profileRows.isNotEmpty) {
        final p = profileRows.first as Map<String, dynamic>;
        rating = (p['rating'] ?? 0.0).toDouble();
        totalReviews = (p['total_reviews'] ?? 0) as int;
        jobsCompleted = (p['jobs_completed'] ?? 0) as int;
      }

      return {
        'todayEarnings': todayEarn,
        'weekEarnings':  weekEarn,
        'totalEarnings': totalEarn,
        'jobsToday':     jobsToday,
        'jobsWeek':      jobsWeek,
        'jobsCompleted': jobsCompleted,
        'rating':        rating,
        'totalReviews':  totalReviews,
      };
    } catch (e) {
      debugPrint('Error loading worker stats: $e');
      return {};
    }
  }

  // Worker-side: list jobs assigned to this worker
  Future<List<Booking>> loadWorkerJobs() async {
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) return [];
      // Resolve auth UID → workers.id (auto-generated UUID)
      final workerRow = await supa
          .from('workers')
          .select('id')
          .eq('auth_user_id', uid)
          .maybeSingle();
      if (workerRow == null) return [];
      final workerId = workerRow['id'] as String;
      final response = await supa
          .from('bookings')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading worker jobs: $e');
      return [];
    }
  }

  Future<void> markBookingComplete(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
      await loadBookings();
    } catch (e) {
      debugPrint('Error marking booking complete: $e');
    }
  }
}

class WorkerRegistrationData {
  String fullName = '';
  String phone = '';
  String cnic = '';
  String district = '';
  String address = '';
  File? profilePhoto;
  
  Set<String> skills = {};
  double hourlyRate = 750;
  
  Set<String> areas = {};
  File? cnicFront;
  File? cnicBack;
  File? cert;

  double? homeLat;
  double? homeLng;
}
