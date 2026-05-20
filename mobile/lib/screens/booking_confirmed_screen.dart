import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final provider = state.selectedProvider;
    final booking = state.currentBooking;

    // Use booking_code (e.g. BKG-A3F8B2C1) stored in sessionId; fallback to short UUID
    final bookingId = booking?.sessionId.isNotEmpty == true
        ? booking!.sessionId
        : (booking?.id.length != null && booking!.id.length > 8
            ? 'BKG-${booking.id.substring(0, 8).toUpperCase()}'
            : booking?.id.toUpperCase() ?? 'KRG-00000');

    final priceStr = booking != null
        ? 'PKR ${booking.priceEstimate}'
        : provider != null ? 'PKR ${provider.pricePerVisit}' : 'PKR 1,500';

    final slotStr = booking != null && booking.slotStart.isNotEmpty
        ? _formatSlot(booking.slotStart) : 'Today, 3:00 PM';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Monument watermark
          Positioned(
            right: -20, bottom: 200,
            child: Opacity(
              opacity: 0.04,
              child: Image.asset('assets/images/pak_bg.png', width: 300,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4E6EB)), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close, color: _textDark, size: 18),
                        ),
                      ),
                      const Spacer(),
                      const Text('Karigar AI', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Success Icon with confetti feel
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5EF),
                                shape: BoxShape.circle,
                              ),
                            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                            Container(
                              width: 80, height: 80,
                              decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
                            ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Booking Confirmed!',
                          style: TextStyle(color: _textDark, fontSize: 26, fontWeight: FontWeight.w800),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
                          child: Text('Booking ID: #$bookingId',
                            style: const TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 32),

                        // Provider Card
                        if (provider != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE4E6EB)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(children: [
                              Stack(children: [
                                CircleAvatar(radius: 28, backgroundImage: NetworkImage(provider.imageUrl)),
                                Positioned(bottom: 0, right: 0, child: Container(
                                  width: 14, height: 14,
                                  decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                )),
                              ]),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(provider.name, style: const TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                const Text('Professional Verified ✓', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Row(children: [
                                  const Icon(Icons.star, color: _teal, size: 14),
                                  Text(' ${provider.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                                ]),
                                const Text('Karigar Pro', style: TextStyle(color: _textGrey, fontSize: 11)),
                              ]),
                            ]),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        // Booking Details Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE4E6EB)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(children: [
                            _DetailTile(icon: Icons.schedule_outlined, label: 'Scheduled Time', value: slotStr),
                            const Divider(height: 1, indent: 60),
                            _DetailTile(icon: Icons.payments_outlined, label: 'Estimated Cost', value: priceStr),
                            const Divider(height: 1, indent: 60),
                            _DetailTile(icon: Icons.location_on_outlined, label: 'Location', value: 'Your saved address'),
                            const Divider(height: 1, indent: 60),
                            _DetailTile(icon: Icons.check_circle_outline, label: 'Status', value: booking?.status ?? 'CONFIRMED'),
                          ]),
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 16),

                        // Pakistani safety note
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(children: [
                            Icon(Icons.shield_outlined, color: _teal, size: 18),
                            SizedBox(width: 10),
                            Expanded(child: Text('Your safety is our priority. All Karigar professionals are verified.',
                              style: TextStyle(color: _textGrey, fontSize: 12))),
                            Text('🇵🇰', style: TextStyle(fontSize: 16)),
                          ]),
                        ).animate().fadeIn(delay: 750.ms),

                        const SizedBox(height: 16),

                        // Invoice / Receipt
                        if (booking != null && booking.id.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showInvoice(context, booking.id, provider?.name ?? 'Provider', priceStr, slotStr, bookingId, booking.receiptUrl),
                              icon: const Icon(Icons.receipt_long, size: 18, color: _teal),
                              label: const Text('View Invoice', style: TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _teal, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ).animate().fadeIn(delay: 780.ms),

                        const SizedBox(height: 16),

                        // Track button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.liveTracking),
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Track Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                          child: const Text('Back to Home', style: TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w600)),
                        ).animate().fadeIn(delay: 850.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoice(BuildContext context, String bookingId, String providerName, String price, String slot, String shortId, String? receiptUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Center(child: Text('Karigar AI', style: TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2))),
              const SizedBox(height: 6),
              const Center(child: Text('INVOICE', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800))),
              const SizedBox(height: 4),
              Center(child: Text('#$shortId', style: const TextStyle(color: _textGrey, fontSize: 12, letterSpacing: 1.2))),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE4E6EB)),
              const SizedBox(height: 16),
              _invRow('Provider', providerName),
              _invRow('Booking ID', bookingId),
              _invRow('Scheduled', slot),
              _invRow('Status', 'CONFIRMED'),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE4E6EB)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Service Fee', style: TextStyle(color: _textGrey, fontSize: 14)),
                Text(price, style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Platform', style: TextStyle(color: _textGrey, fontSize: 14)),
                Text('PKR 0', style: TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(price, style: const TextStyle(color: _teal, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: receiptUrl != null
                    ? Image.network(
                        receiptUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _receiptPlaceholder(),
                        loadingBuilder: (_, child, prog) => prog == null ? child : const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: _teal))),
                      )
                    : _receiptPlaceholder(),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Thank you for using Karigar AI 🇵🇰', style: TextStyle(color: _textGrey, fontSize: 12))),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _receiptPlaceholder() => Container(
    height: 160, alignment: Alignment.center,
    decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(12)),
    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long, color: _textGrey, size: 32),
      SizedBox(height: 8),
      Text('Receipt generating...', style: TextStyle(color: _textGrey, fontSize: 12)),
    ]),
  );

  Widget _invRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: _textGrey, fontSize: 13)),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );

  String _formatSlot(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final day = days[dt.weekday - 1];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day, ${dt.day} ${months[dt.month]} · $h:$m $period';
    } catch (_) { return 'Scheduled'; }
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF075E54), size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 11)),
        Text(value, style: const TextStyle(color: Color(0xFF111B21), fontSize: 14, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}
