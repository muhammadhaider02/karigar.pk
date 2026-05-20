import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import 'workers_by_role_screen.dart';

const _roleIcons = <String, IconData>{
  'ac_technician':   Icons.ac_unit,
  'electrician':     Icons.electrical_services,
  'plumber':         Icons.water_damage,
  'carpenter':       Icons.handyman,
  'painter':         Icons.format_paint,
  'cleaner':         Icons.cleaning_services,
  'solar_technician':Icons.solar_power,
  'pest_control':    Icons.pest_control,
  'driver':          Icons.directions_car,
  'welder':          Icons.construction,
  'tutor':           Icons.school,
  'beautician':      Icons.face_retouching_natural,
};

const _roleColors = <String, Color>{
  'ac_technician':   Color(0xFF00897B),
  'electrician':     Color(0xFFFFB300),
  'plumber':         Color(0xFF1565C0),
  'carpenter':       Color(0xFF6D4C41),
  'painter':         Color(0xFFE53935),
  'cleaner':         Color(0xFF7B1FA2),
  'solar_technician':Color(0xFFF57F17),
  'pest_control':    Color(0xFF2E7D32),
  'driver':          Color(0xFF0277BD),
  'welder':          Color(0xFF37474F),
  'tutor':           Color(0xFF6A1B9A),
  'beautician':      Color(0xFFAD1457),
};

class AllRolesScreen extends StatefulWidget {
  const AllRolesScreen({super.key});

  @override
  State<AllRolesScreen> createState() => _AllRolesScreenState();
}

class _AllRolesScreenState extends State<AllRolesScreen> {
  final _api = KarigarApiClient();
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roles = await _api.getRoles();
    if (mounted) setState(() { _roles = roles; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1E1C) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('All Services', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF0B1E1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? const Center(child: Text('No services available'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _roles.length,
                    itemBuilder: (context, i) {
                      final role = _roles[i];
                      final id = role['id'] as String;
                      final displayName = role['display_name'] as String;
                      final count = role['worker_count'] as int? ?? 0;
                      final color = _roleColors[id] ?? const Color(0xFF0A7C42);
                      final icon = _roleIcons[id] ?? Icons.build;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WorkersByRoleScreen(role: id, displayName: displayName)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A2E2C) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(icon, color: color, size: 28),
                              ),
                              const SizedBox(height: 10),
                              Text(displayName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(height: 4),
                              Text('$count workers', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
