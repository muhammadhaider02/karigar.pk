import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/routes.dart';

class WorkerHubScreen extends StatefulWidget {
  const WorkerHubScreen({super.key});
  @override
  State<WorkerHubScreen> createState() => _WorkerHubScreenState();
}

class _WorkerHubScreenState extends State<WorkerHubScreen> {
  bool _isAvailable = true;
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, bottom: 0,
                  child: Opacity(opacity: 0.05,
                    child: Image.asset('assets/images/pak_bg.png', fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => const SizedBox()))),
                SafeArea(bottom: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Builder(builder: (context) {
                    final user = FirebaseAuth.instance.currentUser;
                    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Worker';
                    final photoUrl = user?.photoURL;
                    return Row(children: [
                    // Avatar
                    Stack(children: [
                      CircleAvatar(radius: 24,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: _teal.withValues(alpha: 0.15),
                        child: photoUrl == null ? Text(name[0].toUpperCase(),
                          style: const TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 18)) : null),
                      Positioned(bottom: 1, right: 1, child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: _isAvailable ? _green : Colors.grey, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      )),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Salam, $name! 👋', style: const TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(_isAvailable ? 'You are Online' : 'You are Offline',
                        style: TextStyle(color: _isAvailable ? _green : _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                    ])),
                    // Online toggle
                    GestureDetector(
                      onTap: () => setState(() => _isAvailable = !_isAvailable),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52, height: 28,
                        decoration: BoxDecoration(
                          color: _isAvailable ? _teal : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          alignment: _isAvailable ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 22, height: 22, margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.notifications_outlined, color: _textDark), onPressed: () {}),
                  ]);
                  }),
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
                  // Earnings Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF075E54), Color(0xFF054E46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF075E54).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Stack(
                      children: [
                        Positioned(right: -10, top: -10,
                          child: Opacity(opacity: 0.08,
                            child: Image.asset('assets/images/pak_bg.png', width: 120,
                              errorBuilder: (_, __, ___) => const SizedBox()))),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Today\'s Earnings', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Text('PKR 4,500', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          Row(children: [
                            _EarningChip(label: 'This Week', value: 'PKR 22,750'),
                            const SizedBox(width: 16),
                            _EarningChip(label: 'Jobs Today', value: '3 Completed'),
                            const SizedBox(width: 16),
                            _EarningChip(label: 'Rating', value: '4.9 ⭐'),
                          ]),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05),

                  const SizedBox(height: 24),

                  // Active Requests header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Active Requests', style: TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(12)),
                      child: const Text('3 New', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  _JobCard(
                    service: 'Pipe Leaking', serviceIcon: Icons.plumbing, area: 'Gulberg III',
                    distance: '2.3 km', budget: 'PKR 1,500–2,000', time: '2 min ago',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.workerJobRequest),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _JobCard(
                    service: 'Bathroom Fitting', serviceIcon: Icons.bathroom, area: 'DHA Phase 5',
                    distance: '4.1 km', budget: 'PKR 3,000–4,500', time: '8 min ago',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.workerJobRequest),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _JobCard(
                    service: 'Water Heater Install', serviceIcon: Icons.water_damage, area: 'Model Town',
                    distance: '3.5 km', budget: 'PKR 2,500–3,500', time: '15 min ago',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.workerJobRequest),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05),

                  const SizedBox(height: 24),

                  // Pakistani footer pride
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E6EB))),
                    child: const Row(children: [
                      Icon(Icons.shield_outlined, color: _teal, size: 18), SizedBox(width: 10),
                      Expanded(child: Text('Karigar AI — Empowering Pakistani Professionals',
                        style: TextStyle(color: _textGrey, fontSize: 12))),
                      Text('🇵🇰', style: TextStyle(fontSize: 16)),
                    ]),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningChip extends StatelessWidget {
  final String label, value;
  const _EarningChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}

class _JobCard extends StatelessWidget {
  final String service, area, distance, budget, time;
  final IconData serviceIcon; final VoidCallback onTap;
  const _JobCard({required this.service, required this.serviceIcon, required this.area,
    required this.distance, required this.budget, required this.time, required this.onTap});

  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4E6EB)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(12)),
          child: Icon(serviceIcon, color: _teal, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(service, style: const TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w700)),
          Text('$area  •  $distance', style: const TextStyle(color: _textGrey, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(10)),
          child: Text(time, style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 14),
      const Divider(height: 1, color: Color(0xFFF0F2F5)),
      const SizedBox(height: 14),
      Row(children: [
        Text(budget, style: const TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: _textGrey, side: const BorderSide(color: Color(0xFFE4E6EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Decline', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    ]),
  );
}
