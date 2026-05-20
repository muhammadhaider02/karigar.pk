import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'sse_stub.dart' if (dart.library.html) 'sse_web.dart' as sse;

class KarigarApiClient {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'https://karigar-pk.onrender.com';
  }

  final http.Client _client = http.Client();

  Future<String> startSession({
    required String userId,
    required String rawText,
    String userPhone = '0300-0000000',
    String language = 'english',
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'raw_text': rawText,
      'user_phone': userPhone,
      'language': language,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final response = await _client.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to start session: ${response.statusCode}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['session_id'] as String;
  }

  // Returns a stream of {event: 'trace'|'done'|'ping', data: decoded_json}
  // Uses polling on both web and native — SSE buffering is unreliable on
  // Flutter web (XHR) and android HTTP stacks. Polling is dead simple.
  Stream<Map<String, dynamic>> streamSession(String sessionId) async* {
    int lastCount = 0;
    int identicalCount = 0;
    bool sawTerminal = false;
    while (identicalCount < 12 && !sawTerminal) {
      await Future.delayed(const Duration(milliseconds: 900));
      try {
        final resTrace = await _client.get(Uri.parse('$baseUrl/sessions/$sessionId/trace'));
        if (resTrace.statusCode == 200) {
          final traces = json.decode(resTrace.body) as List;
          for (int i = lastCount; i < traces.length; i++) {
            yield {'event': 'trace', 'data': traces[i]};
          }
          if (traces.length > lastCount) {
            lastCount = traces.length;
            identicalCount = 0;
          } else {
            identicalCount++;
          }
        }

        final resMeta = await _client.get(Uri.parse('$baseUrl/sessions/$sessionId'));
        if (resMeta.statusCode == 200) {
          final meta = json.decode(resMeta.body) as Map<String, dynamic>;
          if (meta['chosen'] != null || meta['booking'] != null) {
            sawTerminal = true;
          }
        }
      } catch (_) {
        identicalCount++;
      }
    }
    yield {'event': 'done', 'data': {}};
    return;
  }

  // Kept for backwards compat / native SSE option — not currently used.
  Stream<Map<String, dynamic>> _streamSessionViaSSE(String sessionId) async* {
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/sessions/$sessionId/stream'),
    );
    request.headers['Accept'] = 'text/event-stream';
    final response = await _client.send(request);

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final block = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);

        String? eventType;
        String? dataStr;

        for (final line in block.split('\n')) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            dataStr = line.substring(6).trim();
          }
        }

        if (eventType != null && dataStr != null && dataStr.isNotEmpty) {
          try {
            final decoded = json.decode(dataStr);
            yield {'event': eventType, 'data': decoded};
          } catch (_) {}
        }
      }
    }
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response =
        await _client.get(Uri.parse('$baseUrl/sessions/$sessionId'));
    if (response.statusCode != 200) {
      throw Exception('Session not found: $sessionId');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // Full session with ranked list and booking (needed after pipeline done)
  Future<Map<String, dynamic>> getSessionFull(String sessionId) async {
    // The base GET /sessions/{id} returns a summary. We need ranked + booking.
    // They are included in the response as chosen + booking.
    return getSession(sessionId);
  }

  Future<List<Map<String, dynamic>>> listBookings(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/bookings?user_id=${Uri.encodeComponent(userId)}'),
      );
      if (response.statusCode != 200) return [];
      final list = json.decode(response.body) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId, {bool rebook = false}) async {
    await _client.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rebook': rebook}),
    );
  }

  Future<void> markArrived(String bookingId) async {
    await _client.post(Uri.parse('$baseUrl/bookings/$bookingId/arrived'));
  }

  Future<void> markComplete(String bookingId) async {
    await _client.post(Uri.parse('$baseUrl/bookings/$bookingId/complete'));
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/roles'));
      if (response.statusCode != 200) return [];
      return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorkersByRole(String role) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/workers?role=${Uri.encodeComponent(role)}'),
      );
      if (response.statusCode != 200) return [];
      return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
