import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/routes.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  final Set<String> _selectedTags = {};

  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  final _tags = ['Punctual', 'Skilled', 'Affordable', 'Polite', 'Clean Work', 'Fast'];
  static const _ratingLabels = ['', 'Poor 😞', 'Fair 😐', 'Good 👍', 'Great 😊', 'Excellent! 🎉'];

  @override
  Widget build(BuildContext context) {
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
                    const Text('Rate Your Experience', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Your feedback helps improve quality for all Pakistanis.', style: TextStyle(color: _textGrey, fontSize: 13)),
                  ]),
                )),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Worker card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E6EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(children: [
                      Stack(children: [
                        const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                        Positioned(bottom: 0, right: 0, child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        )),
                      ]),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ali Plumbing Services', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Service Completed ✓', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Karigar Pro', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ).animate().fadeIn().slideY(begin: 0.05),
                  const SizedBox(height: 28),
                  // Stars
                  const Text('How was the service?', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedScale(
                            scale: _rating > i ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(_rating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 48, color: _rating > i ? _teal : const Color(0xFFD1D5DB)),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + i * 80)).scale();
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 12),
                    Text(_ratingLabels[_rating],
                      style: const TextStyle(color: _teal, fontSize: 18, fontWeight: FontWeight.w700),
                    ).animate().fadeIn().scale(),
                  ],
                  const SizedBox(height: 28),
                  // Tags
                  const Align(alignment: Alignment.centerLeft,
                    child: Text('What went well?', style: TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _tags.map((tag) {
                      final sel = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => setState(() { if (sel) _selectedTags.remove(tag); else _selectedTags.add(tag); }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _teal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? _teal : const Color(0xFFD1D5DB), width: 1.5),
                          ),
                          child: Text(tag, style: TextStyle(color: sel ? Colors.white : _textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),
                  // Comment box
                  Container(
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E6EB))),
                    child: TextField(
                      controller: _commentCtrl, maxLines: 4,
                      style: const TextStyle(color: _textDark, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Share your experience (optional)...',
                        hintStyle: TextStyle(color: _textGrey, fontSize: 14),
                        border: InputBorder.none, contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Text('🇵🇰', style: TextStyle(fontSize: 18)), SizedBox(width: 10),
                      Expanded(child: Text('You\'re helping build a trusted professional community in Pakistan.',
                        style: TextStyle(color: _textGrey, fontSize: 12))),
                    ]),
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _rating > 0 ? () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB), elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                    child: const Text('Skip for now', style: TextStyle(color: _textGrey, fontSize: 14)),
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
