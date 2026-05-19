import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/routes.dart';

enum _Role { customer, worker }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _Role _selected = _Role.customer;
  static const _teal = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);
  static const _bg = Color(0xFFF7F8FA);
  static const _textDark = Color(0xFF111B21);
  static const _textGrey = Color(0xFF8696A0);

  void _onContinue() {
    // Both roles must authenticate first. The auth screen routes to
    // workerProfile (registration) or home based on the selected role.
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final destAfterAuth = _selected == _Role.worker
        ? AppRoutes.workerProfile
        : AppRoutes.home;

    if (isLoggedIn) {
      Navigator.pushNamed(context, destAfterAuth);
    } else {
      Navigator.pushNamed(context, AppRoutes.auth, arguments: destAfterAuth);
    }
  }

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
                  child: Opacity(opacity: 0.05,
                    child: Image.asset('assets/images/pak_bg.png', fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => const SizedBox()))),
                SafeArea(bottom: false, child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Image.asset('assets/images/karigar_logo.png', height: 44, width: 44, alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const Icon(Icons.handyman, color: _teal, size: 44)),
                    const SizedBox(height: 24),
                    const Text('Welcome to Karigar AI',
                      style: TextStyle(color: _textDark, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('How would you like to use the app?',
                      style: TextStyle(color: _textGrey, fontSize: 14)),
                  ]),
                )),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RoleCard(
                    selected: _selected == _Role.customer,
                    onTap: () => setState(() => _selected = _Role.customer),
                    icon: Icons.home_work_outlined,
                    title: "I need a Service",
                    subtitle: 'Hire verified electricians, plumbers,\ncarpenters and more.',
                    delay: 200,
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    selected: _selected == _Role.worker,
                    onTap: () => setState(() => _selected = _Role.worker),
                    icon: Icons.handyman_outlined,
                    title: "I want to Work (Rozgar)",
                    subtitle: 'Find jobs, receive bookings,\nand grow your income in Pakistan.',
                    delay: 300,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 20),
                      ]),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text('You can change this anytime', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 24),
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFFE4E6EB))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600))),
                    const Expanded(child: Divider(color: Color(0xFFE4E6EB))),
                  ]).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: 'Already have an account? ', style: TextStyle(color: _textGrey, fontSize: 14)),
                          TextSpan(text: 'Sign in', style: TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ).animate().fadeIn(delay: 550.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected; final VoidCallback onTap; final IconData icon;
  final String title, subtitle; final int delay;

  const _RoleCard({required this.selected, required this.onTap, required this.icon,
    required this.title, required this.subtitle, required this.delay});

  static const _teal = Color(0xFF075E54);
  static const _textDark = Color(0xFF111B21);
  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5EF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _teal : const Color(0xFFE4E6EB), width: selected ? 2 : 1.5),
          boxShadow: selected
              ? [BoxShadow(color: _teal.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 58, height: 58,
            decoration: BoxDecoration(
              color: selected ? _teal : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 28, color: selected ? Colors.white : _teal),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: selected ? _teal : _textDark)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF8696A0), height: 1.4)),
          ])),
          Container(width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: selected ? _teal : Colors.transparent,
              border: Border.all(color: selected ? _teal : const Color(0xFFCED4DA), width: 2),
            ),
            child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.08),
    );
  }
}
