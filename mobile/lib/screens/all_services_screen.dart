import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  static const _categories = [
    {'icon': Icons.plumbing,                    'label': 'Plumbing',        'urdu': 'پلمبنگ',       'value': 'plumber'},
    {'icon': Icons.electrical_services,         'label': 'Electrical',      'urdu': 'الیکٹریشن',   'value': 'electrician'},
    {'icon': Icons.ac_unit,                     'label': 'AC / HVAC',       'urdu': 'اے سی',        'value': 'ac_technician'},
    {'icon': Icons.carpenter,                   'label': 'Carpentry',       'urdu': 'بڑھئی',        'value': 'carpenter'},
    {'icon': Icons.format_paint,                'label': 'Painting',        'urdu': 'رنگ و روغن',   'value': 'painter'},
    {'icon': Icons.cleaning_services,           'label': 'Cleaning',        'urdu': 'صفائی',        'value': 'cleaner'},
    {'icon': Icons.foundation,                  'label': 'Masonry',         'urdu': 'راج گیر',      'value': 'mason'},
    {'icon': Icons.local_fire_department,       'label': 'Welding',         'urdu': 'ویلڈنگ',       'value': 'welder'},
    {'icon': Icons.bug_report,                  'label': 'Pest Control',    'urdu': 'کیڑے مار',     'value': 'pest_control'},
    {'icon': Icons.build,                       'label': 'Appliance Repair','urdu': 'مرمت',         'value': 'appliance_repair'},
    {'icon': Icons.school,                      'label': 'Tutoring',        'urdu': 'پڑھانا',       'value': 'tutor'},
    {'icon': Icons.face_retouching_natural,     'label': 'Beautician',      'urdu': 'بیوٹیشن',      'value': 'beautician'},
    {'icon': Icons.solar_power,                 'label': 'Solar Tech',      'urdu': 'سولر',         'value': 'solar_technician'},
    {'icon': Icons.drive_eta,                   'label': 'Driver',          'urdu': 'ڈرائیور',      'value': 'driver'},
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B1E1C) : const Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          _Header(isDark: isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_categories.length, (index) {
                  final cat = _categories[index];
                  return _CategoryCard(
                    icon: cat['icon'] as IconData,
                    label: cat['label'] as String,
                    urdu: cat['urdu'] as String,
                    value: cat['value'] as String,
                    delayMs: index * 50,
                    isDark: isDark,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;

  const _Header({required this.isDark});

  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF122A27) : Colors.white,
      child: Stack(
        children: [
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/images/pak_bg.png',
                fit: BoxFit.fitHeight,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE4E6EB),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.white : _textDark,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Karigar AI',
                        style: TextStyle(
                          color: _teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tamam Services',
                    style: TextStyle(
                      color: isDark ? Colors.white : _textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All available professionals near you',
                    style: TextStyle(color: _textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String urdu;
  final String value;
  final int delayMs;
  final bool isDark;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.urdu,
    required this.value,
    required this.delayMs,
    required this.isDark,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  void _onTap() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.loadWorkersByService(widget.value);
    Navigator.pushNamed(context, AppRoutes.providerSelect);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1A3530) : Colors.white;
    final borderColor = _pressed ? _teal : (widget.isDark ? Colors.white12 : const Color(0xFFE4E6EB));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _pressed ? 2 : 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _pressed
                    ? _teal
                    : _teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: _pressed ? Colors.white : _teal,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.isDark ? Colors.white : _textDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              widget.urdu,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.delayMs), duration: 300.ms);
  }
}
