import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';
import '../widgets/karigar_screen_header.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});
  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String _selected = 'roman_urdu';

  final _languages = [
    _LangOption(
      code: 'english',
      name: 'English',
      subtitle: 'English',
      flagWidget: _FlagUK(),
    ),
    _LangOption(
      code: 'urdu',
      name: 'اردو',
      subtitle: 'Urdu',
      flagWidget: _FlagPK(),
    ),
    _LangOption(
      code: 'roman_urdu',
      name: 'Roman Urdu',
      subtitle: 'Roman Urdu',
      flagWidget: _FlagRU(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Shared header ──────────────────────────────────────
          const KarigarScreenHeader(height: 220),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Choose Your Language',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Color(0xFF111B21),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 6),

                  const Text(
                    'Apni zaban muntakhib karein / اپنی زبان منتخب کریں',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8696A0)),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 24),

                  // Language cards
                  ..._languages.asMap().entries.map((e) {
                    final i = e.key;
                    final lang = e.value;
                    final selected = _selected == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _LangCard(
                        lang: lang,
                        selected: selected,
                        onTap: () => setState(() => _selected = lang.code),
                        delay: 400 + i * 100,
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Continue button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<AppState>(context, listen: false).setLanguage(_selected);
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Aage Chalein / Continue',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: 14),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'You can change this later in settings',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language card ──────────────────────────────────────────────
class _LangCard extends StatelessWidget {
  final _LangOption lang;
  final bool selected;
  final VoidCallback onTap;
  final int delay;

  const _LangCard({
    required this.lang, required this.selected,
    required this.onTap, required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF25D366) : const Color(0xFFE4E6EB),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF25D366).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 14 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag/icon
            SizedBox(width: 48, height: 48, child: lang.flagWidget),
            const SizedBox(width: 16),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.name,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF111B21),
                    ),
                  ),
                  Text(
                    lang.subtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0)),
                  ),
                ],
              ),
            ),
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF25D366) : Colors.transparent,
                border: Border.all(
                  color: selected ? const Color(0xFF25D366) : const Color(0xFFCED4DA),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.08),
    );
  }
}

class _LangOption {
  final String code, name, subtitle;
  final Widget flagWidget;
  const _LangOption({
    required this.code, required this.name,
    required this.subtitle, required this.flagWidget,
  });
}

// ── Flag widgets ──────────────────────────────────────────────
class _FlagUK extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: const BoxDecoration(shape: BoxShape.circle),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Container(color: const Color(0xFF012169)),
        Center(child: Text('🇬🇧', style: const TextStyle(fontSize: 28))),
      ],
    ),
  );
}

class _FlagPK extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFF01411C),
    ),
    child: const Center(child: Text('🇵🇰', style: TextStyle(fontSize: 28))),
  );
}

class _FlagRU extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFF075E54),
    ),
    child: const Center(
      child: Text(
        'RU',
        style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800,
          color: Colors.white, letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
