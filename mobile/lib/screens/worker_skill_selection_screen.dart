import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class WorkerSkillSelectionScreen extends StatefulWidget {
  const WorkerSkillSelectionScreen({super.key});
  @override
  State<WorkerSkillSelectionScreen> createState() => _WorkerSkillSelectionScreenState();
}

class _WorkerSkillSelectionScreenState extends State<WorkerSkillSelectionScreen> {
  final Set<String> _selectedSkills = {};
  double _hourlyRate = 750;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final data = appState.workerRegistrationData;
    _selectedSkills.addAll(data.skills);
    _hourlyRate = data.hourlyRate;
  }

  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  // `value` MUST match the Supabase `service_category` enum (used by
  // worker_profiles.skills[] and bookings.service_type). Customer-side
  // category cards query by these exact strings.
  final _skills = [
    {'icon': Icons.plumbing,            'label': 'Plumbing',       'urdu': 'پلمبنگ',     'value': 'plumber'},
    {'icon': Icons.electrical_services, 'label': 'Electrical',     'urdu': 'الیکٹریشن', 'value': 'electrician'},
    {'icon': Icons.ac_unit,             'label': 'AC / HVAC',      'urdu': 'اے سی',     'value': 'ac_technician'},
    {'icon': Icons.carpenter,           'label': 'Carpentry',      'urdu': 'بڑھئی',     'value': 'carpenter'},
    {'icon': Icons.format_paint,        'label': 'Painting',       'urdu': 'رنگ و روغن','value': 'painter'},
    {'icon': Icons.cleaning_services,   'label': 'Cleaning',       'urdu': 'صفائی',     'value': 'cleaner'},
    {'icon': Icons.foundation,          'label': 'Masonry',        'urdu': 'راج گیر',    'value': 'mason'},
    {'icon': Icons.local_fire_department,'label': 'Welding',       'urdu': 'ویلڈنگ',     'value': 'welder'},
    {'icon': Icons.bug_report,          'label': 'Pest Control',   'urdu': 'کیڑے مار',   'value': 'pest_control'},
    {'icon': Icons.build,               'label': 'Appliance Repair','urdu': 'مرمت',       'value': 'appliance_repair'},
    {'icon': Icons.school,              'label': 'Tutoring',        'urdu': 'پڑھانا',     'value': 'tutor'},
    {'icon': Icons.face_retouching_natural, 'label': 'Beautician', 'urdu': 'بیوٹیشن',    'value': 'beautician'},
    {'icon': Icons.solar_power,         'label': 'Solar Tech',      'urdu': 'سولر',       'value': 'solar_technician'},
    {'icon': Icons.drive_eta,           'label': 'Driver',          'urdu': 'ڈرائیور',    'value': 'driver'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Monument
          Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, bottom: 0,
                  child: Opacity(opacity: 0.06,
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
                    // Step indicator
                    Row(children: [
                      const Text('STEP 2 OF 3', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(width: 12),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(value: 2/3,
                          backgroundColor: Color(0xFFE4E6EB),
                          valueColor: AlwaysStoppedAnimation(_teal), minHeight: 4),
                      )),
                    ]),
                    const SizedBox(height: 14),
                    const Text('Apni Skills Chunein', style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Select all services you can professionally offer.', style: TextStyle(color: _textGrey, fontSize: 13)),
                  ]),
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
                  // Skills Grid
                  GridView.count(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    children: _skills.map((skill) {
                      final label = skill['label'] as String;
                      final icon = skill['icon'] as IconData;
                      final urdu = skill['urdu'] as String;
                      final value = skill['value'] as String;
                      final isSelected = _selectedSkills.contains(value);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) _selectedSkills.remove(value); else _selectedSkills.add(value);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F5EF) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? _teal : const Color(0xFFE4E6EB), width: isSelected ? 2 : 1),
                            boxShadow: isSelected ? [BoxShadow(color: _teal.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))] : [],
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? _teal : _bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: isSelected ? Colors.white : _textGrey, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(label, style: TextStyle(
                              color: isSelected ? _teal : _textDark,
                              fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            Text(urdu, style: TextStyle(color: isSelected ? _teal : _textGrey, fontSize: 10)),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: _green, size: 14),
                          ]),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // Rate Section
                  const Text('Hourly Rate / Ghante ki Ujrat', style: TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E6EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Your Rate', style: TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5EF), borderRadius: BorderRadius.circular(20)),
                          child: Text('PKR ${_hourlyRate.toInt()}/hr',
                            style: const TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _teal, inactiveTrackColor: const Color(0xFFE4E6EB),
                          thumbColor: _teal, overlayColor: _teal.withValues(alpha: 0.1),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          trackHeight: 4,
                        ),
                        child: Slider(value: _hourlyRate, min: 300, max: 3000, divisions: 27,
                          onChanged: (v) => setState(() => _hourlyRate = v)),
                      ),
                      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('PKR 300', style: TextStyle(color: _textGrey, fontSize: 11)),
                        Text('PKR 3,000', style: TextStyle(color: _textGrey, fontSize: 11)),
                      ]),
                    ]),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedSkills.isNotEmpty
                          ? () {
                              final appState = Provider.of<AppState>(context, listen: false);
                              appState.workerRegistrationData.skills = _selectedSkills;
                              appState.workerRegistrationData.hourlyRate = _hourlyRate;
                              Navigator.pushNamed(context, AppRoutes.workerArea);
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        _selectedSkills.isEmpty ? 'Select at least 1 skill' : 'Continue (${_selectedSkills.length} selected)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB), elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
