import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/routes.dart';
import '../widgets/karigar_screen_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Shared header (logo + skyline) ──────────────────
            const KarigarScreenHeader(height: 270),

            // ── Dark green service card with wave ────────────────
            ClipPath(
              clipper: KarigarWaveClipper(),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF0D2D2A),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 52),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ServiceChip(icon: Icons.electric_bolt, label: 'Electrician'),
                    _ServiceChip(icon: Icons.plumbing, label: 'Plumber'),
                    _ServiceChip(icon: Icons.construction, label: 'Carpenter'),
                    _ServiceChip(icon: Icons.format_paint, label: 'Painter'),
                    _ServiceChip(icon: Icons.settings, label: '& More'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            // ── White bottom card ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Heading
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Color(0xFF111B21),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15),

                  const SizedBox(height: 8),

                  const Text(
                    'Login to continue and book the best service\nnear you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, color: Color(0xFF8696A0), height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 28),

                  // Continue with Google
                  _AuthButton(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-In coming soon!')),
                    ),
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    icon: _GoogleIcon(),
                    label: 'Continue with Google',
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Continue with Apple
                  _AuthButton(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apple Sign-In coming soon!')),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF111B21),
                    border: true,
                    icon: const Icon(Icons.apple, size: 22, color: Color(0xFF111B21)),
                    label: 'Continue with Apple',
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Continue with Email
                  _AuthButton(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.auth),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF111B21),
                    border: true,
                    icon: const Icon(Icons.email_outlined, size: 22, color: Color(0xFF075E54)),
                    label: 'Continue with Email',
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // OR divider
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  ]).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 16),

                  // Sign up
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.roleSelect),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                          ),
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: Color(0xFF25D366), fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auth button ───────────────────────────────────────────────
class _AuthButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor, foregroundColor;
  final Widget icon;
  final String label;
  final bool border;

  const _AuthButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: border
                ? Border.all(color: const Color(0xFFE0E0E0), width: 1.5)
                : null,
            boxShadow: !border
                ? [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.25),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              SizedBox(width: 28, height: 28, child: Center(child: icon)),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Service icon chip ─────────────────────────────────────────
class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF25D366), size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11, color: Color(0xFF8ECFC9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

// ── Google G icon (colored) ───────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      );
}
