class Booking {
  final String id;
  final String sessionId;
  final String userId;
  final String providerId;
  final String providerName;
  final String serviceType;
  final String slotStart;
  final String slotEnd;
  final String status;
  final int priceEstimate;
  final String? receiptPngPath;
  final String createdAt;

  Booking({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    required this.priceEstimate,
    this.receiptPngPath,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? '',
        providerName: json['provider_name'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? '',
        slotStart: json['slot_start'] as String? ?? '',
        slotEnd: json['slot_end'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        priceEstimate: (json['price_estimate'] ?? 0) as int,
        receiptPngPath: json['receipt_png_path'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  // Short display date from ISO slot_start string
  String get displayDate {
    try {
      final dt = DateTime.parse(slotStart).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  String get displayCost => 'PKR ${priceEstimate.toString()}';

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
}
