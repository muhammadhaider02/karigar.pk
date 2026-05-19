import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key});
  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String? _selectedReason;
  final _detailsCtrl = TextEditingController();
  bool _submitted = false;

  static const _teal = Color(0xFF075E54);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);
  static const _errorRed = Color(0xFFDC2626);

  final _reasons = [
    {'icon': Icons.person_off_outlined, 'label': 'Provider did not show up'},
    {'icon': Icons.thumb_down_outlined, 'label': 'Work quality was poor'},
    {'icon': Icons.money_off_outlined, 'label': 'Overcharged for services'},
    {'icon': Icons.sentiment_very_dissatisfied_outlined, 'label': 'Provider was rude / unprofessional'},
    {'icon': Icons.home_repair_service_outlined, 'label': 'Damage to property'},
    {'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 90, height: 90,
              decoration: BoxDecoration(color: const Color(0xFFE8F5EF), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: _teal, size: 44)),
            const SizedBox(height: 20),
            const Text('Report Submitted', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text('Our team will review your case and respond within 24 hours.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8696A0), fontSize: 14)),
            ),
            const SizedBox(height: 24),
            const Text('🇵🇰  Karigar AI cares about you.', style: TextStyle(color: _teal, fontSize: 13)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: const Text('Back to Booking', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      const Text('Karigar AI', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Report an Issue', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('We take every complaint seriously and resolve within 24 hours.',
                      style: TextStyle(color: _textGrey, fontSize: 13)),
                  ]),
                )),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: _errorRed, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Your report is completely confidential and protected.',
                        style: TextStyle(color: _errorRed, fontSize: 12))),
                    ]),
                  ).animate().fadeIn(),
                  const SizedBox(height: 24),
                  const Text('What went wrong?', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...List.generate(_reasons.length, (i) {
                    final r = _reasons[i];
                    final label = r['label'] as String;
                    final icon = r['icon'] as IconData;
                    final sel = _selectedReason == label;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReason = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFE8F5EF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? _teal : const Color(0xFFE4E6EB), width: sel ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Container(width: 36, height: 36,
                            decoration: BoxDecoration(color: sel ? _teal : _bg, borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, color: sel ? Colors.white : _textGrey, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(label, style: TextStyle(
                            color: sel ? _teal : _textDark, fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))),
                          if (sel) const Icon(Icons.check_circle, color: _teal, size: 20),
                        ]),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 60));
                  }),
                  const SizedBox(height: 24),
                  const Text('Additional Details', style: TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E6EB))),
                    child: TextField(
                      controller: _detailsCtrl, maxLines: 4,
                      style: const TextStyle(color: _textDark, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Describe the issue in detail (optional)...',
                        hintStyle: TextStyle(color: _textGrey, fontSize: 14),
                        border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedReason != null ? () => setState(() => _submitted = true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorRed, foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB), elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.shield_outlined, color: _teal, size: 16), SizedBox(width: 8),
                      Expanded(child: Text('Your identity is protected. Karigar AI ensures fair resolution.',
                        style: TextStyle(color: _textGrey, fontSize: 11))),
                    ]),
                  ).animate().fadeIn(delay: 650.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
