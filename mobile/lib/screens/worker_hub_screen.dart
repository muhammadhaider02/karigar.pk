import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../constants/strings.dart';
import '../models/booking.dart';
import '../providers/app_state.dart';

class WorkerHubScreen extends StatefulWidget {
  const WorkerHubScreen({super.key});
  @override
  State<WorkerHubScreen> createState() => _WorkerHubScreenState();
}

class _WorkerHubScreenState extends State<WorkerHubScreen> {
  bool _isAvailable = true;
  List<Booking> _jobs = [];
  bool _loadingJobs = true;
  Map<String, dynamic> _stats = {};
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final state = Provider.of<AppState>(context, listen: false);
    final results = await Future.wait([
      state.loadWorkerJobs(),
      state.loadWorkerStats(),
    ]);
    if (mounted) setState(() {
      _jobs = results[0] as List<Booking>;
      _stats = results[1] as Map<String, dynamic>;
      _loadingJobs = false;
    });
  }

  String _fmt(int v) {
    if (v < 1000) return v.toString();
    final s = v.toString();
    final out = StringBuffer();
    final remainder = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (i - remainder) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  Future<void> _toggleAvailable() async {
    setState(() => _isAvailable = !_isAvailable);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client
            .from('workers')
            .update({'is_online': _isAvailable})
            .eq('auth_user_id', uid);
      }
    } catch (e) {
      // Silently keep local state — server can resync next refresh
    }
  }

  String _humanService(String t) {
    switch (t) {
      case 'plumber': return 'Plumbing';
      case 'electrician': return 'Electrical';
      case 'ac_technician': return 'AC / HVAC';
      case 'carpenter': return 'Carpentry';
      case 'painter': return 'Painting';
      case 'cleaner': return 'Cleaning';
      case 'handyman': return 'General Repair';
      case 'appliance_repair': return 'Appliance Repair';
      case 'locksmith': return 'Locksmith';
      default: return t.isEmpty ? 'Service' : t;
    }
  }

  IconData _iconForService(String t) {
    switch (t) {
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      case 'ac_technician': return Icons.ac_unit;
      case 'carpenter': return Icons.carpenter;
      case 'painter': return Icons.format_paint;
      case 'cleaner': return Icons.cleaning_services;
      case 'handyman': return Icons.handyman;
      default: return Icons.work_outline;
    }
  }
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
                    final user = Supabase.instance.client.auth.currentUser;
                    final name = user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'Worker';
                    final photoUrl = user?.userMetadata?['avatar_url'];
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
                      onTap: _toggleAvailable,
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
                          Text(Strings.of(context).earningsToday, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('PKR ${_fmt((_stats['todayEarnings'] ?? 0) as int)}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          Row(children: [
                            _EarningChip(label: Strings.of(context).thisWeek, value: 'PKR ${_fmt((_stats['weekEarnings'] ?? 0) as int)}'),
                            const SizedBox(width: 16),
                            _EarningChip(label: Strings.of(context).jobsToday, value: '${_stats['jobsToday'] ?? 0}'),
                            const SizedBox(width: 16),
                            _EarningChip(label: Strings.of(context).rating,
                                value: ((_stats['totalReviews'] ?? 0) as int) == 0
                                    ? 'New ⭐'
                                    : '${((_stats['rating'] ?? 0.0) as double).toStringAsFixed(1)} ⭐'),
                          ]),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05),

                  const SizedBox(height: 24),

                  // Active Requests header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(Strings.of(context).activeRequests, style: const TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(12)),
                      child: Text('${_jobs.where((j) => !j.isCompleted && !j.isCancelled).length} New',
                        style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  if (_loadingJobs)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: _teal)))
                  else if (_jobs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E6EB))),
                      child: const Column(children: [
                        Icon(Icons.inbox_outlined, size: 36, color: _textGrey),
                        SizedBox(height: 8),
                        Text('No job requests yet', style: TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Stay online — new jobs will appear here', style: TextStyle(color: _textGrey, fontSize: 12)),
                      ]),
                    )
                  else
                    ..._jobs.take(10).map((j) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JobCard(
                        service: _humanService(j.serviceType),
                        serviceIcon: _iconForService(j.serviceType),
                        area: j.displayDate.isNotEmpty ? j.displayDate : 'Scheduled',
                        distance: j.status,
                        budget: j.displayCost,
                        time: 'Booking ${j.id.length > 6 ? j.id.substring(0, 6) : j.id}',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.workerJobRequest),
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                    )),

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
