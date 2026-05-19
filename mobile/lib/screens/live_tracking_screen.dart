import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app/routes.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with TickerProviderStateMixin {
  static const _teal  = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  static final _workerPos = LatLng(33.7215, 73.0433);
  static final _homePos   = LatLng(33.7295, 73.0551);
  static final _center    = LatLng(33.7255, 73.0490);
  static final _routePoints = [
    _workerPos,
    LatLng(33.7230, 73.0450),
    LatLng(33.7245, 73.0495),
    LatLng(33.7275, 73.0520),
    _homePos,
  ];

  int _currentStatus = 1;
  late AnimationController _pulseCtrl;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 5),  () { if (mounted) setState(() => _currentStatus = 2); });
    Future.delayed(const Duration(seconds: 10), () { if (mounted) setState(() => _currentStatus = 3); });
    Future.delayed(const Duration(seconds: 18), () { if (mounted) setState(() => _currentStatus = 4); });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── OpenStreetMap (no API key needed) ─────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.karigar.ai',
                maxZoom: 19,
              ),
              PolylineLayer(polylines: [
                Polyline(points: _routePoints, color: _teal, strokeWidth: 4.0,
                  pattern: StrokePattern.dashed(segments: const [12, 8])),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: _workerPos, width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(color: _green, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.4), blurRadius: 8)]),
                    child: const Icon(Icons.directions_bike, color: Colors.white, size: 20),
                  ),
                ),
                Marker(
                  point: _homePos, width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(color: _teal, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.4), blurRadius: 8)]),
                    child: const Icon(Icons.home, color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ]),
            ],
          ),

          // ── Top HUD ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleBtn(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                        ),
                        child: RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: 'Karigar ', style: TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: 16)),
                            TextSpan(text: 'AI', style: TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 16)),
                          ]),
                        ),
                      ),
                      _CircleBtn(icon: Icons.headset_mic_outlined, onTap: () {}),
                    ],
                  ),
                ),

                // ETA Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: Color(0xFF8696A0))),
                          Text('12 Mins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _teal)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                          child: const Row(children: [
                            Icon(Icons.schedule, color: _teal, size: 14),
                            SizedBox(width: 4),
                            Text('On time', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(alignment: Alignment.center, children: [
                      Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE4E6EB), borderRadius: BorderRadius.circular(2))),
                      Row(children: [
                        Expanded(flex: 1, child: Container(height: 4, color: _teal)),
                        Expanded(flex: 1, child: Container(height: 4, color: Colors.transparent)),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _StepDot(isCompleted: true),
                        _StepDot(isActive: true),
                        _StepDot(isCompleted: false),
                      ]),
                    ]),
                    const SizedBox(height: 10),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Dispatched', style: TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
                      Text('En Route', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _teal)),
                      Text('Arrived', style: TextStyle(fontSize: 11, color: Color(0xFF8696A0))),
                    ]),
                  ]),
                ).animate().fadeIn().slideY(begin: -0.05),
              ],
            ),
          ),

          // Map zoom buttons
          Positioned(
            right: 20, bottom: 300,
            child: Column(children: [
              _CircleBtn(icon: Icons.add, onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1)),
              const SizedBox(height: 12),
              _CircleBtn(icon: Icons.remove, onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1)),
            ]).animate().fadeIn(delay: 200.ms),
          ),

          // ── Bottom Sheet ───────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, -10))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFFE4E6EB), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Row(children: [
                      Stack(children: [
                        const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                        Positioned(bottom: 0, right: 0, child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        )),
                      ]),
                      const SizedBox(width: 16),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ali Plumbing Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111B21))),
                        Row(children: [
                          Icon(Icons.circle, color: _green, size: 8),
                          SizedBox(width: 6),
                          Text('On his way', style: TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
                        ]),
                      ])),
                      const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(children: [
                          Icon(Icons.star, color: _teal, size: 16),
                          SizedBox(width: 4),
                          Text('4.9', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _teal)),
                        ]),
                        Text('120+ jobs', style: TextStyle(fontSize: 12, color: Color(0xFF8696A0))),
                      ]),
                    ]),
                    const SizedBox(height: 20),

                    // Contact row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _teal.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.call, color: _teal, size: 20),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Direct Contact', style: TextStyle(fontSize: 12, color: Color(0xFF8696A0))),
                          Text('0300-1234567', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _teal)),
                        ])),
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(color: Color(0xFFE8F5EF), shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline, color: _teal, size: 20),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal, side: const BorderSide(color: _teal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      )),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call Ali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )),
                    ]),

                    if (_currentStatus == 4) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.review),
                          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                          child: const Text('Service Complete — Leave Review'),
                        ),
                      ).animate().fadeIn().scale(),
                    ],
                  ]),
                ),
              ),
            ).animate().slideY(begin: 0.2, curve: Curves.easeOutCirc),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: const Color(0xFF111B21), size: 20),
    ),
  );
}

class _StepDot extends StatelessWidget {
  final bool isActive; final bool isCompleted;
  const _StepDot({this.isActive = false, this.isCompleted = false});
  @override
  Widget build(BuildContext context) {
    if (isCompleted) return Container(
      width: 16, height: 16,
      decoration: const BoxDecoration(color: Color(0xFF075E54), shape: BoxShape.circle),
      child: const Icon(Icons.check, color: Colors.white, size: 10),
    );
    if (isActive) return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF1C40F), width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFFF1C40F).withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF075E54), shape: BoxShape.circle))),
    );
    return Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFE4E6EB), shape: BoxShape.circle));
  }
}
