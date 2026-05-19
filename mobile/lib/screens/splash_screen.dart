import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app/routes.dart';
import '../constants/app_colors.dart';
import '../providers/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && !_navigated) {
        _navigated = true;
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.isAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B2D2A),
              Color(0xFF0D3530),
              Color(0xFF0A2B27),
              Color(0xFF072220),
              Color(0xFF051A18),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Decorative rings ──────────────────────────────────
            Positioned(
              top: size.height * 0.15,
              left: size.width / 2 - 130,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: 0.08 + _pulseController.value * 0.06,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C896), width: 1),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
            Positioned(
              top: size.height * 0.15 + 30,
              left: size.width / 2 - 100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: 0.06 + _pulseController.value * 0.04,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C896), width: 0.5),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

            // ── City skyline at bottom ────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SizedBox(
                height: size.height * 0.22,
                child: CustomPaint(
                  painter: _SkylinePainter(),
                ),
              ).animate().fadeIn(delay: 1500.ms, duration: 1000.ms),
            ),

            // ── Main content ──────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),

                  // Logo image
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withValues(alpha: 0.2),
                          blurRadius: 40, spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/images/karigar_logo.png',
                        width: 140, height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: const Color(0xFF0D3530),
                          ),
                          child: const Icon(Icons.handyman, color: Color(0xFF00C896), size: 64),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.3, 0.3), duration: 800.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 1400.ms, color: Colors.white12),

                  const SizedBox(height: 32),

                  // KARGAR AI text
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'KARGAR ',
                          style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 2,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800,
                            color: Color(0xFF00C896), letterSpacing: 2,
                            fontFamily: 'PlusJakartaSans',
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'Har zaroorat ka, smart hal.',
                    style: TextStyle(
                      fontSize: 16, color: Color(0xFF8ECFC9),
                      fontWeight: FontWeight.w400, letterSpacing: 0.3,
                    ),
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 8),

                  // Teal divider underline
                  Container(
                    width: 50, height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ).animate().scaleX(delay: 1200.ms, duration: 400.ms),

                  SizedBox(height: size.height * 0.045),

                  // Service icons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _ServiceIcon(icon: Icons.electric_bolt, label: 'Electric'),
                        _ServiceIcon(icon: Icons.water_drop, label: 'Plumber'),
                        _ServiceIcon(icon: Icons.construction, label: 'Repair'),
                        _ServiceIcon(icon: Icons.format_paint, label: 'Painter'),
                        _ServiceIcon(icon: Icons.settings, label: 'AC Tech'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.1),

                  SizedBox(height: size.height * 0.04),

                  // Feature cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                      child: Row(
                        children: [
                          const _FeatureCard(
                            icon: Icons.auto_awesome,
                            title: 'AI-Powered\nMatching',
                          ),
                          _VerticalDivider(),
                          const _FeatureCard(
                            icon: Icons.verified_user_outlined,
                            title: 'Verified & Trusted\nProfessionals',
                          ),
                          _VerticalDivider(),
                          const _FeatureCard(
                            icon: Icons.location_on_outlined,
                            title: 'Fast Service,\nNear You',
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 1500.ms).slideY(begin: 0.1),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service icon chip ──────────────────────────────────────────
class _ServiceIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ServiceIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00C896), size: 28),
        ],
      );
}

// ── Feature card ──────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const _FeatureCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00C896).withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, color: const Color(0xFF00C896), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11, color: Color(0xFF8ECFC9),
                fontWeight: FontWeight.w500, height: 1.4,
              ),
            ),
          ],
        ),
      );
}

// ── Vertical separator ───────────────────────────────────────
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 60,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

// ── Pakistan city skyline painter ────────────────────────────
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C896).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h);

    // Left buildings
    path.lineTo(0, h * 0.7);
    path.lineTo(w * 0.04, h * 0.7);
    path.lineTo(w * 0.04, h * 0.55);
    path.lineTo(w * 0.07, h * 0.55);
    path.lineTo(w * 0.07, h * 0.45);
    path.lineTo(w * 0.10, h * 0.45);
    path.lineTo(w * 0.10, h * 0.6);
    path.lineTo(w * 0.13, h * 0.6);
    path.lineTo(w * 0.13, h * 0.5);
    path.lineTo(w * 0.16, h * 0.5);
    path.lineTo(w * 0.16, h * 0.65);

    // Left mosque/minaret
    path.lineTo(w * 0.19, h * 0.65);
    path.lineTo(w * 0.19, h * 0.3);
    _addMinaret(path, w * 0.20, h * 0.3, w * 0.015, h * 0.12);
    path.lineTo(w * 0.21, h * 0.3);
    path.lineTo(w * 0.21, h * 0.65);

    // Dome
    path.lineTo(w * 0.27, h * 0.65);
    path.lineTo(w * 0.27, h * 0.45);
    _addDome(canvas, path, w * 0.32, h * 0.45, w * 0.10, h * 0.22, paint);
    path.lineTo(w * 0.37, h * 0.45);
    path.lineTo(w * 0.37, h * 0.65);

    // Right minaret
    path.lineTo(w * 0.42, h * 0.65);
    path.lineTo(w * 0.42, h * 0.3);
    _addMinaret(path, w * 0.43, h * 0.3, w * 0.015, h * 0.12);
    path.lineTo(w * 0.44, h * 0.3);
    path.lineTo(w * 0.44, h * 0.65);

    // Mid buildings
    path.lineTo(w * 0.50, h * 0.65);
    path.lineTo(w * 0.50, h * 0.5);
    path.lineTo(w * 0.54, h * 0.5);
    path.lineTo(w * 0.54, h * 0.38);
    path.lineTo(w * 0.58, h * 0.38);
    path.lineTo(w * 0.58, h * 0.55);
    path.lineTo(w * 0.63, h * 0.55);
    path.lineTo(w * 0.63, h * 0.65);

    // Second smaller mosque
    path.lineTo(w * 0.67, h * 0.65);
    path.lineTo(w * 0.67, h * 0.4);
    _addMinaret(path, w * 0.675, h * 0.4, w * 0.012, h * 0.10);
    path.lineTo(w * 0.685, h * 0.4);
    _addDome(canvas, path, w * 0.715, h * 0.4, w * 0.06, h * 0.16, paint);
    path.lineTo(w * 0.745, h * 0.4);
    _addMinaret(path, w * 0.75, h * 0.4, w * 0.012, h * 0.10);
    path.lineTo(w * 0.762, h * 0.4);
    path.lineTo(w * 0.762, h * 0.65);

    // Right buildings
    path.lineTo(w * 0.80, h * 0.65);
    path.lineTo(w * 0.80, h * 0.48);
    path.lineTo(w * 0.84, h * 0.48);
    path.lineTo(w * 0.84, h * 0.60);
    path.lineTo(w * 0.88, h * 0.60);
    path.lineTo(w * 0.88, h * 0.50);
    path.lineTo(w * 0.92, h * 0.50);
    path.lineTo(w * 0.92, h * 0.65);
    path.lineTo(w * 0.96, h * 0.65);
    path.lineTo(w * 0.96, h * 0.72);
    path.lineTo(w, h * 0.72);
    path.lineTo(w, h);

    path.close();
    canvas.drawPath(path, paint);
  }

  void _addMinaret(Path path, double cx, double top, double hw, double height) {
    path.lineTo(cx - hw, top);
    path.lineTo(cx, top - height);
    path.lineTo(cx + hw, top);
  }

  void _addDome(Canvas canvas, Path path, double cx, double baseY, double radius, double domeH, Paint paint) {
    path.arcTo(
      Rect.fromCenter(center: Offset(cx, baseY), width: radius * 2, height: domeH * 2),
      math.pi, math.pi, false,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
