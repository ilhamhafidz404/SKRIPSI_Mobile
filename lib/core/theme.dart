import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Redline Apparel Palette ───────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const primary = Color(0xFFC0202A); // deep crimson
  static const primaryDark = Color(0xFF8B0000); // blood red
  static const primaryLight = Color(0xFFE8312A); // signal red

  static const paper = Color(0xFFFAF7F2); // warm white (card)
  static const parchment = Color(0xFFF5EFE6); // surface
  static const ecru = Color(0xFFF0EBE3); // page bg
  static const ink = Color(0xFF2C1A1A); // body text

  static const inkLight = Color(0x702C1A1A);
  static const inkFaint = Color(0x302C1A1A);
  static const primaryTint = Color(0x12C0202A);
  static const primaryBorder = Color(0x30C0202A);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.ecru,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.paper,
      onPrimary: Colors.white,
      onSurface: AppColors.ink,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      // Serif untuk heading (Georgia fallback via letterSpacing trick)
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: 4,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: 2,
      ),
      labelSmall: GoogleFonts.sourceCodePro(
        fontSize: 9,
        letterSpacing: 3,
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.ink),
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 16,
        color: AppColors.ink,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.sourceCodePro(
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
