import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  static const _teal = Color(0xFF075E54);
  // ignore: unused_field
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  DateTime _selectedSlot = DateTime.now(); // default = Abhi (Now)

  DateTime _todayAt(int hour) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, hour);
  }

  DateTime _tomorrowAt(int hour) {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day, hour);
  }

  DateTime _dayAfterAt(int hour) {
    final n = DateTime.now().add(const Duration(days: 2));
    return DateTime(n.year, n.month, n.day, hour);
  }

  bool _isSameSlot(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day && a.hour == b.hour;

  Future<void> _pickCustomSlot() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _selectedSlot = picked);
    Provider.of<AppState>(context, listen: false).setBookingSlot(picked);
  }

  String _slotLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDate = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final hr = h % 12 == 0 ? 12 : h % 12;
    final mm = dt.minute == 0 ? '' : ':${dt.minute.toString().padLeft(2, '0')}';
    final time = '$hr$mm $period';
    if (dtDate == today) return 'Aaj $time';
    if (dtDate == today.add(const Duration(days: 1))) return 'Kal $time';
    if (dtDate == today.add(const Duration(days: 2))) return 'Parso $time';
    return '${dt.day}/${dt.month} $time';
  }

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

                    // ── Time slot picker ──────────────────────────────
                    Row(children: const [
                      Icon(Icons.schedule, color: _teal, size: 18),
                      SizedBox(width: 8),
                      Text('Kab chahiye? (Pick a time slot)',
                          style: TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final now = DateTime.now();
                      final slots = <Map<String, dynamic>>[
                        {'label': 'Abhi (Now)',  'time': now},
                        {'label': 'Aaj 8 AM',    'time': _todayAt(8)},
                        {'label': 'Aaj 10 AM',   'time': _todayAt(10)},
                        {'label': 'Aaj 12 PM',   'time': _todayAt(12)},
                        {'label': 'Aaj 2 PM',    'time': _todayAt(14)},
                        {'label': 'Aaj 4 PM',    'time': _todayAt(16)},
                        {'label': 'Aaj 6 PM',    'time': _todayAt(18)},
                        {'label': 'Aaj 8 PM',    'time': _todayAt(20)},
                        {'label': 'Kal 8 AM',    'time': _tomorrowAt(8)},
                        {'label': 'Kal 10 AM',   'time': _tomorrowAt(10)},
                        {'label': 'Kal 12 PM',   'time': _tomorrowAt(12)},
                        {'label': 'Kal 2 PM',    'time': _tomorrowAt(14)},
                        {'label': 'Kal 4 PM',    'time': _tomorrowAt(16)},
                        {'label': 'Kal 6 PM',    'time': _tomorrowAt(18)},
                        {'label': 'Parso 8 AM',  'time': _dayAfterAt(8)},
                        {'label': 'Parso 10 AM', 'time': _dayAfterAt(10)},
                        {'label': 'Custom...',   'time': null},
                      ];
                      return SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: slots.map((s) {
                            final isCustom = s['time'] == null;
                            if (isCustom) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.event, size: 16, color: _teal),
                                  label: const Text('Custom...'),
                                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: _teal),
                                  side: const BorderSide(color: _teal, width: 1.5),
                                  backgroundColor: Colors.white,
                                  onPressed: _pickCustomSlot,
                                ),
                              );
                            }
                            final t = s['time'] as DateTime;
                            final isPast = t.isBefore(now.subtract(const Duration(minutes: 1)));
                            final selected = _isSameSlot(_selectedSlot, t);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(s['label'] as String),
                                selected: selected,
                                selectedColor: _teal,
                                backgroundColor: Colors.white,
                                side: BorderSide(color: selected ? _teal : const Color(0xFFD1D5DB), width: 1.5),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white
                                      : isPast ? const Color(0xFFB5BEC6) : _textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: isPast ? null : (_) {
                                  setState(() => _selectedSlot = t);
                                  Provider.of<AppState>(context, listen: false).setBookingSlot(t);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Estimated Cost', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('PKR ${provider.pricePerVisit}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(_slotLabel(_selectedSlot),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                        ElevatedButton(
                          onPressed: () {
                            final st = Provider.of<AppState>(context, listen: false);
                            st.setBookingSlot(_selectedSlot);
                            st.confirmBooking(provider);
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
