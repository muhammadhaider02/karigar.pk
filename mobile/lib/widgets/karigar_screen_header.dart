import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared top-header used on Login, Role Selection, and Language screens.
/// Shows the Pakistan monument photo with a teal gradient overlay,
/// Karigar logo, "KARIGAR AI" text + tagline.
class KarigarScreenHeader extends StatelessWidget {
  final double height;
  const KarigarScreenHeader({super.key, this.height = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          // ── Pakistan monument background photo ────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/pak_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8F5EF),
                child: CustomPaint(painter: _FallbackSkylinePainter()),
              ),
            ),
          ),

          // ── Teal gradient overlay (bottom-heavy so text pops) ─
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.82),
                    Colors.white.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Subtle teal tint layer for brand consistency ───────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF075E54).withValues(alpha: 0.06),
                    const Color(0xFF25D366).withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),

          // ── Decorative location pins ───────────────────────────
          Positioned(
            top: 52, left: 28,
            child: Icon(
              Icons.location_on,
              color: const Color(0xFF075E54).withValues(alpha: 0.55),
              size: 18,
            ).animate().fadeIn(delay: 600.ms),
          ),
          Positioned(
            top: 38, right: 36,
            child: Icon(
              Icons.location_on,
              color: const Color(0xFF25D366).withValues(alpha: 0.45),
              size: 14,
            ).animate().fadeIn(delay: 800.ms),
          ),

          // ── Logo + text centred ────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/karigar_logo.png',
                    width: 100, height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF075E54),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.handyman, color: Colors.white, size: 40),
                    ),
                  )
                      .animate()
                      .scale(duration: 700.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 10),

                  // KARIGAR AI
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'KARIGAR ',
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Color(0xFF075E54), letterSpacing: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Color(0xFF25D366), letterSpacing: 1.5,
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 3),
                  const Text(
                    'Har zaroorat ka, smart hal.',
                    style: TextStyle(
                      fontSize: 12.5, color: Color(0xFF8696A0),
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 420.ms),

                  const SizedBox(height: 5),
                  Container(
                    width: 34, height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().scaleX(delay: 520.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback skyline if the image asset isn't found
class _FallbackSkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF075E54).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path();
    final w = size.width;
    final h = size.height;
    // Simple skyline silhouette
    path.moveTo(0, h * 0.7);
    path.lineTo(w * 0.1, h * 0.7);
    path.lineTo(w * 0.1, h * 0.55);
    path.lineTo(w * 0.2, h * 0.55);
    path.lineTo(w * 0.2, h * 0.35);
    path.lineTo(w * 0.21, h * 0.2);
    path.lineTo(w * 0.22, h * 0.35);
    path.lineTo(w * 0.32, h * 0.35);
    path.arcTo(
      Rect.fromCenter(center: Offset(w * 0.38, h * 0.35), width: w * 0.12, height: h * 0.2),
      math.pi, math.pi, false,
    );
    path.lineTo(w * 0.44, h * 0.55);
    path.lineTo(w * 0.6, h * 0.55);
    path.lineTo(w * 0.6, h * 0.4);
    path.lineTo(w * 0.61, h * 0.25);
    path.lineTo(w * 0.62, h * 0.4);
    path.lineTo(w * 0.72, h * 0.4);
    path.arcTo(
      Rect.fromCenter(center: Offset(w * 0.77, h * 0.4), width: w * 0.1, height: h * 0.18),
      math.pi, math.pi, false,
    );
    path.lineTo(w * 0.82, h * 0.55);
    path.lineTo(w, h * 0.55);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Wave clipper for the bottom of the dark green section on Login screen
class KarigarWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 38);
    path.quadraticBezierTo(
      size.width * 0.25, size.height + 16,
      size.width * 0.5, size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 56,
      size.width, size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
