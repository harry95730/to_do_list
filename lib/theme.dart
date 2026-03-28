import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrchestrateTheme {
  static const primary = Color(0xFF004AC6);
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF191B23);
  static const tertiary = Color(0xFFBA1A1A);
  static const surfaceContainerHigh = Color(0xFFEDEDF9);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        onSurface: onSurface,
        tertiary: tertiary,
      ),
      textTheme: TextTheme(
        displaySmall: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          color: onSurface,
          fontSize: 32,
        ),
        titleMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: primary,
        ),
      ),
    );
  }
}