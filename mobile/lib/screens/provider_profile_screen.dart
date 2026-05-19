import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppState>(context, listen: false).selectedProvider;

    if (provider == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('No provider selected')));
    }

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280, pinned: true,
            backgroundColor: _teal, foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/pak_bg.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: _teal)),
                  Container(decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, _teal.withValues(alpha: 0.8), _teal]),
                  )),
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Stack(children: [
                      CircleAvatar(radius: 50, backgroundImage: NetworkImage(provider.imageUrl), backgroundColor: Colors.white),
                      Positioned(bottom: 0, right: 0, child: Container(
                        padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.white, size: 16),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Text(provider.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Professional verified by Karigar AI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 24),
                  ]),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(value: provider.rating.toStringAsFixed(1), label: 'Rating', icon: Icons.star, color: const Color(0xFFF59E0B)),
                        Container(width: 1, height: 40, color: const Color(0xFFE4E6EB)),
                        _StatItem(value: '${provider.distanceKm.toStringAsFixed(1)} km', label: 'Distance', icon: Icons.location_on, color: _teal),
                        Container(width: 1, height: 40, color: const Color(0xFFE4E6EB)),
                        _StatItem(value: '${(provider.score * 100).toStringAsFixed(0)}%', label: 'AI Match', icon: Icons.auto_awesome, color: _green),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),
                    const Text('Services Offered', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: provider.services.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(12)),
                        child: Text(s.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
                      )).toList(),
                    ).animate().fadeIn(delay: 300.ms),

                    if (provider.reasoning.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text('Why Karigar AI Recommends Them', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4E6EB))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.auto_awesome, color: _teal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(provider.reasoning, style: const TextStyle(color: _textDark, fontSize: 13, height: 1.5))),
                        ]),
                      ).animate().fadeIn(delay: 400.ms),
                    ],

                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Estimated Cost', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('PKR ${provider.pricePerVisit}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        ]),
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<AppState>(context, listen: false).confirmBooking(provider);
                            Navigator.pushReplacementNamed(context, AppRoutes.bookingConfirmed);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, foregroundColor: _teal, elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label; final IconData icon; final Color color;
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 28),
    const SizedBox(height: 8),
    Text(value, style: const TextStyle(color: Color(0xFF111B21), fontSize: 16, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12)),
  ]);
}
