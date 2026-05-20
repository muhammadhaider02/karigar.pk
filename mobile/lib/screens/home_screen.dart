import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';
import 'all_roles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _queryController = TextEditingController();
  int _selectedNavIndex = 0;
  String _locationLabel = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadBookings();
    });
  }

  Future<void> _fetchLocation() async {
    if (kIsWeb) { setState(() => _locationLabel = 'Islamabad, Pakistan'); return; }
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _locationLabel = 'Location access denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      // Make the GPS available to AppState so booking + provider distance use it
      if (mounted) {
        Provider.of<AppState>(context, listen: false)
            .setCustomerLocation(pos.latitude, pos.longitude);
      }
      setState(() => _locationLabel = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}');
    } catch (_) {
      setState(() => _locationLabel = 'Islamabad, Pakistan');
    }
  }

  void _submitQuery() {
    if (_queryController.text.trim().isEmpty) return;
    Provider.of<AppState>(context, listen: false)
        .startBookingFlow(_queryController.text);
    Navigator.pushNamed(context, AppRoutes.agentTrace);
  }

  void _submitServiceQuery(String query) {
    Provider.of<AppState>(context, listen: false).startBookingFlow(query);
    Navigator.pushNamed(context, AppRoutes.agentTrace);
  }

  // Tap a category card → fetch all registered workers of that service from Supabase
  // and go straight to the provider list (skip the AI agent flow).
  void _openCategory(String supabaseService) {
    final state = Provider.of<AppState>(context, listen: false);
    state.loadWorkersByService(supabaseService).then((_) {
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.providerSelect);
    });
  }

  void _showEmergencySheet(BuildContext context) {
    const emergencyRoles = [
      ('electrician',    'Electrician',    Icons.electrical_services, Color(0xFFFFB300)),
      ('plumber',        'Plumber',        Icons.water_damage,         Color(0xFF1565C0)),
      ('ac_technician',  'AC Technician',  Icons.ac_unit,              Color(0xFF00897B)),
      ('carpenter',      'Carpenter',      Icons.handyman,             Color(0xFF6D4C41)),
      ('cleaner',        'Cleaner',        Icons.cleaning_services,    Color(0xFF7B1FA2)),
      ('pest_control',   'Pest Control',   Icons.pest_control,         Color(0xFF2E7D32)),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('What do you need urgently?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Tap a service — we\'ll find someone near you right now', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: emergencyRoles.map((r) {
                final (role, label, icon, color) = r;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final query = 'I need a $label urgently right now, emergency';
                    Provider.of<AppState>(context, listen: false).startBookingFlow(query);
                    Navigator.pushNamed(context, AppRoutes.agentTrace);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 32),
                        const SizedBox(height: 8),
                        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selectedNavIndex == 4) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1E1C) : const Color(0xFFF7F8FA),
        bottomNavigationBar: _buildNavBar(isDark),
        body: _ProfilePanel(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // ── Background Header Image ───────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: 320,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/pak_bg.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF7F8FA).withValues(alpha: 0.7),
                        const Color(0xFFF7F8FA).withValues(alpha: 0.9),
                        const Color(0xFFF7F8FA),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 800.ms),
          ),

          // ── Scrollable Body ────────────────────────────────────
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF075E54), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: Color(0xFF111B21),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF111B21)),
                      const Spacer(),
                      Stack(
                        children: [
                          const Icon(Icons.notifications_none, color: Color(0xFF111B21), size: 28),
                          Positioned(
                            right: 2, top: 2,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: -0.1),

                  const SizedBox(height: 32),

                  // Greeting
                  const Text(
                    'Aaj kya chahiye? 👋',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: Color(0xFF111B21), letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
                  const SizedBox(height: 6),
                  const Text(
                    'Find trusted professionals near you',
                    style: TextStyle(fontSize: 15, color: Color(0xFF8696A0)),
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05),

                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(Icons.search, color: Color(0xFF8696A0), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Search for services...',
                              hintStyle: TextStyle(color: Color(0xFF8696A0)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _submitQuery(),
                          ),
                        ),
                        const Icon(Icons.mic_none, color: Color(0xFF111B21), size: 24),
                        const SizedBox(width: 12),
                        Container(
                          margin: const EdgeInsets.all(6),
                          width: 44, height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF075E54),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.center_focus_weak, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms).scaleXY(begin: 0.95),

                  const SizedBox(height: 16),

                  // ── Live location mini-map ───────────────────────────
                  Consumer<AppState>(builder: (_, st, __) {
                    final lat = st.customerLat;
                    final lng = st.customerLng;
                    if (lat == null || lng == null) {
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0E8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.gps_not_fixed, color: Color(0xFF8696A0), size: 18),
                            SizedBox(width: 8),
                            Text('Waiting for GPS…', style: TextStyle(color: Color(0xFF8696A0))),
                          ]),
                        ),
                      );
                    }
                    final me = LatLng(lat, lng);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 160,
                        child: Stack(children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: me, initialZoom: 15,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.karigar.ai', maxZoom: 19,
                              ),
                              MarkerLayer(markers: [
                                Marker(point: me, width: 44, height: 44, child: Container(
                                  decoration: BoxDecoration(color: const Color(0xFF25D366), shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [BoxShadow(color: const Color(0xFF25D366).withValues(alpha: 0.5), blurRadius: 10)]),
                                  child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 22),
                                )),
                              ]),
                            ],
                          ),
                          Positioned(
                            left: 12, bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)]),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.my_location, size: 14, color: Color(0xFF075E54)),
                                const SizedBox(width: 6),
                                Text('Your location · $_locationLabel',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF111B21), fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    );
                  }).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _CategoryCard(
                        icon: Icons.electric_bolt, color: const Color(0xFF075E54),
                        title: 'Electrician', subtitle: 'Wiring, Fixing & More',
                        onTap: () => _openCategory('electrician'),
                        delay: 450,
                      ),
                      _CategoryCard(
                        icon: Icons.plumbing, color: const Color(0xFF1976D2),
                        title: 'Plumber', subtitle: 'Pipes, Leaks & More',
                        onTap: () => _openCategory('plumber'),
                        delay: 550,
                      ),
                      _CategoryCard(
                        icon: Icons.ac_unit, color: const Color(0xFFE65100),
                        title: 'AC Repair', subtitle: 'Cooling Solutions',
                        onTap: () => _openCategory('ac_technician'),
                        delay: 650,
                      ),
                      _CategoryCard(
                        icon: Icons.cleaning_services, color: const Color(0xFF673AB7),
                        title: 'Cleaning', subtitle: 'Home & Office',
                        onTap: () => _openCategory('cleaner'),
                        delay: 750,
                      ),
                      _CategoryCard(
                        icon: Icons.carpenter, color: const Color(0xFF8D6E63),
                        title: 'Carpenter', subtitle: 'Woodwork & Fixing',
                        onTap: () => _openCategory('carpenter'),
                        delay: 850,
                      ),
                      _CategoryCard(
                        icon: Icons.more_horiz, color: const Color(0xFF25D366),
                        title: 'More', subtitle: 'See all services',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllRolesScreen())),
                        delay: 950,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Emergency Banner
                  GestureDetector(
                    onTap: () => _showEmergencySheet(context),
                    child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF075E54).withValues(alpha: 0.3),
                          blurRadius: 16, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Service',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Need urgent help? We\'re available 24/7',
                                style: TextStyle(
                                  color: Colors.white70, fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.verified, color: Color(0xFF25D366), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Fast Response • Verified Pros',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Request Now',
                                style: TextStyle(
                                  color: Color(0xFF075E54), fontSize: 12, fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF075E54), size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Recent Booking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Booking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111B21)),
                      ),
                      Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF075E54).withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: const Color(0xFF075E54).withValues(alpha: 0.8)),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 1150.ms),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF075E54).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.electric_bolt, color: Color(0xFF075E54)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Electrician Visit',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111B21)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Today, 2:00 PM', style: TextStyle(fontSize: 12, color: Color(0xFF8696A0))),
                                  const SizedBox(width: 6),
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFD1D7DB), shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('Confirmed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF25D366))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: Color(0xFF8696A0)),
                                  SizedBox(width: 4),
                                  Text('Bahria Town, Lahore', style: TextStyle(fontSize: 12, color: Color(0xFF8696A0))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: Color(0xFF111B21), fontSize: 12, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1250.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Providers Near You
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Providers Near You',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111B21)),
                      ),
                      Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF075E54).withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: const Color(0xFF075E54).withValues(alpha: 0.8)),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 1350.ms),
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/map_placeholder.png'), // Will add a fallback color if asset missing
                        fit: BoxFit.cover,
                      ),
                      color: const Color(0xFFE8F5EF),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16, top: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Trusted pros', style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.w600, fontSize: 12)),
                              const Text('Near You', style: TextStyle(color: Color(0xFF111B21), fontWeight: FontWeight.w800, fontSize: 20)),
                              const SizedBox(height: 4),
                              Text('See who\'s available in\nBahria Town, Lahore', style: TextStyle(color: const Color(0xFF111B21).withValues(alpha: 0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16, bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('View Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1450.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation ─────────────────────────────────────
      bottomNavigationBar: _buildNavBar(isDark),
    );
  }

  Widget _buildNavBar(bool isDark) {
    final navBg = isDark ? const Color(0xFF122320) : Colors.white;
    final unselectedColor = isDark ? const Color(0xFF8EAAA6) : const Color(0xFF8696A0);
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2E4A47) : const Color(0xFFE4E6EB), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF075E54) : unselectedColor,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? const Color(0xFF075E54) : unselectedColor, size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (i) {
            setState(() => _selectedNavIndex = i);
            if (i == 1) Navigator.pushNamed(context, AppRoutes.history);
            if (i == 2) Navigator.pushNamed(context, AppRoutes.liveTracking);
            if (i == 3) Navigator.pushNamed(context, AppRoutes.messages);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF25D366).withValues(alpha: 0.15),
          height: 68,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ── Profile / Settings Tab ────────────────────────────────────
class _ProfilePanel extends StatefulWidget {
  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  static const _teal  = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  File? _profileImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);
    final user = context.select<AppState, bool>((s) => s.isAuthenticated);
    final card  = isDark ? const Color(0xFF1A2F2C)  : Colors.white;
    final text  = isDark ? const Color(0xFFE0F2EF)  : const Color(0xFF111B21);
    final grey  = isDark ? const Color(0xFF8EAAA6)  : const Color(0xFF8696A0);
    final border = isDark ? const Color(0xFF2E4A47) : const Color(0xFFE4E6EB);

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final displayName = supabaseUser?.userMetadata?['full_name'] as String? ?? 
                        supabaseUser?.email?.split('@').first ?? 
                        supabaseUser?.phone ?? 
                        (user ? 'Signed In' : 'Guest User');
    final emailLabel = supabaseUser?.email ?? supabaseUser?.phone ?? (user ? 'Supabase Auth' : 'Not authenticated');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: text)),
            const SizedBox(height: 24),

            // Account card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
              child: Row(children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF075E54).withValues(alpha: 0.15),
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person, color: _teal, size: 32)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(color: _teal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 11),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(emailLabel, style: TextStyle(color: grey, fontSize: 13)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                  child: const Text('🇵🇰', style: TextStyle(fontSize: 16)),
                ),
              ]),
            ),

            const SizedBox(height: 24),
            Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: grey, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            // Theme toggle
            Container(
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
              child: Column(children: [
                _SettingRow(
                  icon: isDark ? Icons.dark_mode : Icons.wb_sunny_outlined,
                  iconColor: isDark ? const Color(0xFF00C896) : const Color(0xFFF59E0B),
                  label: isDark ? 'Dark Mode' : 'Morning Mode',
                  subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                  textColor: text,
                  subtitleColor: grey,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => appState.toggleTheme(),
                    activeColor: _teal,
                    activeTrackColor: _green.withValues(alpha: 0.3),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),
            Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: grey, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
              child: Column(children: [
                _SettingRow(icon: Icons.history, iconColor: _teal, label: 'Booking History', textColor: text, subtitleColor: grey,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.history)),
                Divider(height: 1, indent: 56, color: border),
                _SettingRow(icon: Icons.security_outlined, iconColor: _teal, label: 'Privacy & Security', textColor: text, subtitleColor: grey),
                Divider(height: 1, indent: 56, color: border),
                _SettingRow(icon: Icons.logout, iconColor: const Color(0xFFDC2626), label: 'Sign Out',
                  textColor: const Color(0xFFDC2626), subtitleColor: grey,
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                    }
                  }),
              ]),
            ),

            const SizedBox(height: 32),
            Center(child: Column(children: [
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Karigar ', style: TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: 14)),
                TextSpan(text: 'AI', style: TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 14)),
              ])),
              const SizedBox(height: 4),
              Text('v1.0.0 — Proudly Pakistani 🇵🇰', style: TextStyle(color: grey, fontSize: 12)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color textColor;
  final Color subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.textColor,
    required this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(color: subtitleColor, fontSize: 12)),
            ],
          ])),
          if (trailing != null) trailing!
          else if (onTap != null) Icon(Icons.chevron_right, color: subtitleColor, size: 20),
        ]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;

  const _CategoryCard({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.onTap, required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111B21),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9, color: Color(0xFF8696A0), fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).scaleXY(begin: 0.9),
    );
  }
}
