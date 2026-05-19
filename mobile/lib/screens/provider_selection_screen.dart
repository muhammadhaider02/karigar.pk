import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';
import '../models/provider_model.dart';

class ProviderSelectionScreen extends StatelessWidget {
  const ProviderSelectionScreen({super.key});

  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final providers = state.recommendedProviders;

    return Scaffold(
      backgroundColor: _bg,
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
                    const Text('Choose a Professional', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${providers.length} verified Karigar professionals found near you.',
                      style: const TextStyle(color: _textGrey, fontSize: 13)),
                    const SizedBox(height: 16),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _FilterChip(label: 'Top Rated', isSelected: true),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Nearest'),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Lowest Price'),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Most Jobs'),
                      ]),
                    ),
                  ]),
                )),
              ],
            ),
          ),
          // Provider List
          Expanded(
            child: providers.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 80, height: 80,
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EF), shape: BoxShape.circle),
                        child: const Icon(Icons.search_off, color: _teal, size: 36)),
                      const SizedBox(height: 16),
                      const Text('No professionals found', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('Try adjusting your search or location', style: TextStyle(color: _textGrey, fontSize: 13)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      return _ProviderCard(
                        provider: provider,
                        onBook: () {
                          state.confirmBooking(provider);
                          Navigator.pushNamed(context, AppRoutes.bookingConfirmed);
                        },
                        onProfile: () {
                          state.selectProvider(provider);
                          Navigator.pushNamed(context, AppRoutes.providerProfile);
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.08);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool isSelected;
  const _FilterChip({required this.label, this.isSelected = false});
  static const _teal = Color(0xFF075E54);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: isSelected ? _teal : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: isSelected ? _teal : const Color(0xFFE4E6EB)),
    ),
    child: Text(label, style: TextStyle(
      color: isSelected ? Colors.white : const Color(0xFF8696A0),
      fontSize: 12, fontWeight: FontWeight.w600,
    )),
  );
}

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onBook, onProfile;
  const _ProviderCard({required this.provider, required this.onBook, required this.onProfile});
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onProfile,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E6EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
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
            Text('${provider.district} • ${provider.distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(color: _textGrey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, color: _teal, size: 14),
              Text(' ${provider.rating.toStringAsFixed(1)}',
                style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)),
              const Text('  •  ', style: TextStyle(color: Color(0xFFD1D5DB))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(6)),
                child: const Text('Verified', style: TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('PKR ${provider.ratePerHr}/hr',
              style: const TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w800)),
            const Text('per hour', style: TextStyle(color: _textGrey, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0F2F5)),
        const SizedBox(height: 14),
        Row(children: [
          TextButton.icon(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline, size: 15),
            label: const Text('View Profile', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: _teal, padding: EdgeInsets.zero),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    ),
  );
}
