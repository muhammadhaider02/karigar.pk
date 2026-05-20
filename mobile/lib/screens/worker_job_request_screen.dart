import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class WorkerJobRequestScreen extends StatefulWidget {
  const WorkerJobRequestScreen({super.key});
  @override
  State<WorkerJobRequestScreen> createState() => _WorkerJobRequestScreenState();
}

class _WorkerJobRequestScreenState extends State<WorkerJobRequestScreen> {
  bool _accepted = false;
  bool _loading = false;
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);
  static const _errorRed = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    if (_accepted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 90, height: 90,
              decoration: BoxDecoration(color: const Color(0xFFE8F5EF), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: _teal, size: 44)),
            const SizedBox(height: 20),
            const Text('Job Accepted!', style: TextStyle(color: _textDark, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Head to: House #42, Block E, Gulberg III',
              textAlign: TextAlign.center, style: TextStyle(color: _textGrey, fontSize: 14)),
            const SizedBox(height: 24),
            const Text('🇵🇰  Karigar AI — Ehsaan ka badla', style: TextStyle(color: _teal, fontSize: 13)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: const Text('Back to Hub', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]).animate().fadeIn().scale(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, bottom: 0,
                  child: Opacity(opacity: 0.05,
                    child: Image.asset('assets/images/pak_bg.png', fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => const SizedBox()))),
                SafeArea(bottom: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(width: 36, height: 36,
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4E6EB)), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back, color: _textDark, size: 18)),
                      ),
                      const SizedBox(width: 12),
                      const Text('New Job Request', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(10)),
                        child: const Row(children: [
                          Icon(Icons.circle, color: _green, size: 8), SizedBox(width: 4),
                          Text('New', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ]),
                )),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E6EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Row(children: [
                      Stack(children: [
                        const CircleAvatar(radius: 26, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
                        Positioned(bottom: 0, right: 0, child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        )),
                      ]),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Ahmed Shaikh', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                        const Row(children: [
                          Icon(Icons.star, color: _teal, size: 13),
                          Text(' 4.7  •  12 bookings', style: TextStyle(color: Color(0xFF8696A0), fontSize: 12)),
                        ]),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          Icon(Icons.verified, color: _teal, size: 12), SizedBox(width: 4),
                          Text('Verified', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ).animate().fadeIn(),

                  const SizedBox(height: 16),

                  // Budget highlight
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF075E54), Color(0xFF054E46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Customer Budget', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const Text('PKR 1,500 – 2,000', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Est. 1.5-2 hrs • AI Assessment', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('Your Rate', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const Text('PKR 750/hr', style: TextStyle(color: _green, fontSize: 16, fontWeight: FontWeight.w800)),
                      ]),
                    ]),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 16),

                  // Job details
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E6EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(children: [
                      _JobDetailRow(icon: Icons.build_outlined, label: 'Service', value: 'Pipe Leaking — Kitchen'),
                      const Divider(height: 1, indent: 60),
                      _JobDetailRow(icon: Icons.location_on_outlined, label: 'Location', value: 'House #42, Block E, Gulberg III'),
                      const Divider(height: 1, indent: 60),
                      _JobDetailRow(icon: Icons.access_time, label: 'Posted', value: '2 minutes ago'),
                      const Divider(height: 1, indent: 60),
                      _JobDetailRow(icon: Icons.directions_car_outlined, label: 'Distance', value: '2.3 km from you'),
                    ]),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 16),

                  // Problem description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E6EB))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.chat_bubble_outline, color: _teal, size: 16), SizedBox(width: 8),
                        Text('Customer Note', style: TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      const Text(
                        '"Kitchen sink pipe is leaking badly. Water dripping from the joint under the sink. Need urgent fixing. Already tried tape but it didn\'t hold."',
                        style: TextStyle(color: _textGrey, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
                    ]),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 24),

                  // Action buttons
                  Builder(builder: (context) {
                    final bookingId = ModalRoute.of(context)?.settings.arguments as String?;
                    return Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : () async {
                            if (bookingId != null) {
                              setState(() => _loading = true);
                              await Provider.of<AppState>(context, listen: false).workerDeclineBooking(bookingId);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _errorRed, side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: ElevatedButton.icon(
                        onPressed: _loading ? null : () async {
                          if (bookingId != null) {
                            setState(() => _loading = true);
                            await Provider.of<AppState>(context, listen: false).workerAcceptBooking(bookingId);
                          }
                          if (mounted) setState(() { _accepted = true; _loading = false; });
                        },
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Accept Job', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )),
                    ]);
                  }).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.shield_outlined, color: _teal, size: 16), SizedBox(width: 8),
                      Expanded(child: Text('Karigar AI — Empowering Pakistani Workers. 🇵🇰',
                        style: TextStyle(color: _textGrey, fontSize: 11))),
                    ]),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _JobDetailRow({required this.icon, required this.label, required this.value});
  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _teal, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _textGrey, fontSize: 11)),
        Text(value, style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );
}
