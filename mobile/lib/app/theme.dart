import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ── Shared text styles ───────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
      TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w700, color: primary),
        displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.25),
        headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32, fontWeight: FontWeight.w700, color: primary),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
        bodyLarge: GoogleFonts.workSans(
            fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.workSans(
            fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
        bodySmall: GoogleFonts.workSans(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      );

  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(AppColors.onSurface, AppColors.onSurfaceVariant),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15))),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        hintStyle: GoogleFonts.workSans(color: AppColors.outline),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 60,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.outlineVariant, thickness: 0.5),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryFixed,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurface),
        side: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryContainer,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0B1E1C);
  static const Color _darkSurface = Color(0xFF122320);
  static const Color _darkCard = Color(0xFF1A2F2C);
  static const Color _darkCardHigh = Color(0xFF213835);
  static const Color _darkOutline = Color(0xFF2E4A47);
  static const Color _darkOutlineVariant = Color(0xFF1D3330);
  static const Color _darkOnSurface = Color(0xFFE0F2EF);
  static const Color _darkOnSurfaceVariant = Color(0xFF8EAAA6);
  static const Color _darkPrimary = Color(0xFF00C896); // bright teal for dark mode

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        primaryContainer: Color(0xFF074E3F),
        onPrimary: Colors.white,
        secondary: Color(0xFF25D366),
        secondaryContainer: Color(0xFF25D366),
        onSecondaryContainer: Colors.white,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        error: Color(0xFFFF6B6B),
        errorContainer: Color(0xFF4A1010),
        outline: _darkOnSurfaceVariant,
        outlineVariant: _darkOutlineVariant,
        surfaceContainerLowest: _darkCard,
        surfaceContainerLow: _darkCard,
        surfaceContainer: _darkCardHigh,
        surfaceContainerHigh: Color(0xFF2A4340),
        surfaceContainerHighest: Color(0xFF314E4B),
      ),
      scaffoldBackgroundColor: _darkBg,
      textTheme: _buildTextTheme(_darkOnSurface, _darkOnSurfaceVariant),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15))),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkOutline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _darkOutline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _darkOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _darkPrimary, width: 1.5)),
        hintStyle: GoogleFonts.workSans(color: _darkOnSurfaceVariant),
        labelStyle: GoogleFonts.plusJakartaSans(color: _darkOnSurfaceVariant),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: _darkOnSurface),
        iconTheme: IconThemeData(color: _darkOnSurface),
        toolbarHeight: 60,
      ),

      dividerTheme: const DividerThemeData(color: _darkOutline, thickness: 0.5),

      chipTheme: ChipThemeData(
        backgroundColor: _darkCard,
        selectedColor: const Color(0xFF074E3F),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: _darkOnSurface),
        side: const BorderSide(color: _darkOutline, width: 0.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _darkPrimary : _darkOnSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? _darkPrimary.withValues(alpha: 0.3)
                : _darkOutline),
      ),
    );
  }
}
