class ProviderModel {
  final String id;
  final String name;
  final List<String> services;
  final double lat;
  final double lng;
  final double rating;
  final int pricePerVisit;
  final String phone;
  final double distanceKm;
  final double score;
  final String reasoning;
  final String? slotStart;
  final String? slotEnd;
  final String imageUrl;

  // UI-compatibility aliases
  String get serviceType => services.isNotEmpty ? services.first : 'service';
  String get district => '';
  int get ratePerHr => pricePerVisit;
  double get responseRate => score;

  ProviderModel({
    required this.id,
    required this.name,
    required this.services,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.pricePerVisit,
    required this.phone,
    required this.distanceKm,
    required this.score,
    required this.reasoning,
    this.slotStart,
    this.slotEnd,
    required this.imageUrl,
  });

  // From a RankedCandidate object returned by GET /sessions/{id}
  factory ProviderModel.fromRankedCandidate(Map<String, dynamic> json) {
    final p = json['provider'] as Map<String, dynamic>? ?? {};
    final name = p['name'] as String? ?? 'Provider';
    return ProviderModel(
      id: p['id'] as String? ?? '',
      name: name,
      services: List<String>.from(p['services'] ?? []),
      lat: (p['lat'] ?? 0.0).toDouble(),
      lng: (p['lng'] ?? 0.0).toDouble(),
      rating: (p['rating'] ?? 0.0).toDouble(),
      pricePerVisit: (p['price_per_visit'] ?? 0) as int,
      phone: p['phone'] as String? ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      score: (json['score'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] as String? ?? '',
      slotStart: json['slot_start'] as String?,
      slotEnd: json['slot_end'] as String?,
      imageUrl:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=4CAF50&color=fff&size=200',
    );
  }

  // Legacy fromJson — kept for backward compatibility with any remaining call sites
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    // If it has a nested 'provider' key it's a RankedCandidate
    if (json.containsKey('provider')) {
      return ProviderModel.fromRankedCandidate(json);
    }
    final name = json['name'] as String? ?? 'Provider';
    return ProviderModel(
      id: json['id'] as String? ?? json['provider_id'] as String? ?? '',
      name: name,
      services: List<String>.from(json['services'] ?? [json['service_type'] ?? '']),
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      pricePerVisit: (json['price_per_visit'] ?? json['rate_per_hr'] ?? 0) as int,
      phone: json['phone'] as String? ?? '',
      distanceKm: (json['dist_km'] ?? json['distance_km'] ?? 0.0).toDouble(),
      score: (json['score'] ?? json['response_rate'] ?? 1.0).toDouble(),
      reasoning: json['reasoning'] as String? ?? '',
      slotStart: json['slot_start'] as String?,
      slotEnd: json['slot_end'] as String?,
      imageUrl: json['imageUrl'] as String? ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=4CAF50&color=fff&size=200',
    );
  }
}
