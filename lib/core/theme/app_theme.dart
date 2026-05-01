// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand palette ─────────────────────────────────
  static const Color primary      = Color(0xFF6C63FF); // violet
  static const Color primaryDark  = Color(0xFF4A41D8);
  static const Color secondary    = Color(0xFF00BFA5); // teal accent
  static const Color error        = Color(0xFFFF5252);
  static const Color warning      = Color(0xFFFFB300);
  static const Color success      = Color(0xFF00C853);

  static const Color surface      = Color(0xFF1E1E2E);
  static const Color surfaceVar   = Color(0xFF27273D);
  static const Color outline      = Color(0xFF383850);
  static const Color onSurface    = Color(0xFFF0F0FF);
  static const Color onSurfaceSub = Color(0xFF9090B0);

  // Status badge colours
  static Color statusColor(String status) => switch (status) {
    'approved' => success,
    'rejected' => error,
    _          => warning, // pending
  };

  // ── Dark Theme ────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary:       primary,
        primaryContainer: primaryDark,
        secondary:     secondary,
        surface:       surface,
        surfaceContainerHighest: surfaceVar,
        error:         error,
        onPrimary:     Colors.white,
        onSurface:     onSurface,
        outline:       outline,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:       onSurface,
        displayColor:    onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:   surface,
        surfaceTintColor:  Colors.transparent,
        elevation:         0,
        titleTextStyle:    GoogleFonts.inter(
          color:      onSurface,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color:        surfaceVar,
        elevation:    0,
        shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:         const BorderSide(color: outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   surfaceVar,
        border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: error),
        ),
        labelStyle:  const TextStyle(color: onSurfaceSub),
        hintStyle:   const TextStyle(color: onSurfaceSub),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side:            const BorderSide(color: primary),
          shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVar,
        labelStyle:      const TextStyle(color: onSurface),
        side:            const BorderSide(color: outline),
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:  surfaceVar,
        selectedIconTheme: const IconThemeData(color: primary, size: 26),
        unselectedIconTheme: const IconThemeData(color: onSurfaceSub, size: 24),
        selectedLabelTextStyle: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: GoogleFonts.inter(color: onSurfaceSub),
        indicatorColor: primary.withOpacity(0.15),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVar,
        contentTextStyle: GoogleFonts.inter(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
