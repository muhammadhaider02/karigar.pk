import 'package:flutter/material.dart';

class AppColors {
  // ── Primary (WhatsApp Dark Teal) ─────────────────────────────
  static const Color primary = Color(0xFF075E54);
  static const Color primaryContainer = Color(0xFF075E54);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD4EDE8);

  // ── Secondary / Accent (WhatsApp Green) ──────────────────────
  static const Color secondary = Color(0xFF128C7E);
  static const Color secondaryContainer = Color(0xFF25D366); // action buttons
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFB8F5D0);

  // ── Backgrounds & Surfaces ───────────────────────────────────
  static const Color background = Color(0xFFF0F2F5);
  static const Color surface = Color(0xFFF0F2F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F8FA);
  static const Color surfaceContainer = Color(0xFFEDEFF2);
  static const Color surfaceContainerHigh = Color(0xFFE4E6EB);
  static const Color surfaceContainerHighest = Color(0xFFDBDDE2);
  static const Color surfaceVariant = Color(0xFFE4E6EB);
  static const Color surfaceDim = Color(0xFFD1D3D8);

  // ── Text ─────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF111B21);
  static const Color onSurfaceVariant = Color(0xFF54656F);
  static const Color outline = Color(0xFF8696A0);
  static const Color outlineVariant = Color(0xFFD1D7DB);

  // ── Status ───────────────────────────────────────────────────
  static const Color error = Color(0xFFEA0038);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF25D366);
  static const Color warning = Color(0xFFFFA726);

  // ── Chat Bubble Colors ───────────────────────────────────────
  static const Color chatBubbleOut = Color(0xFFD9FDD3); // outgoing message
  static const Color chatBubbleIn = Color(0xFFFFFFFF); // incoming message

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF075E54), Color(0xFF128C7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
