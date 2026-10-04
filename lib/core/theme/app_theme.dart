import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/business_config.dart';

class AppTheme {
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1C1C1E);
  static const Color muted = Color(0xFF8E8E93);
  static const Color line = Color(0x14000000);
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);

  static ThemeData lightTheme(BusinessType businessType) {
    final config = BusinessConfig.of(businessType);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: config.primary,
        secondary: config.secondary,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme().copyWith(
        displayLarge: GoogleFonts.hindSiliguri(
          fontSize: 32, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.hindSiliguri(
          fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.hindSiliguri(
          fontSize: 22, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.hindSiliguri(
          fontSize: 17, fontWeight: FontWeight.w600, color: ink,
        ),
        bodyLarge: GoogleFonts.hindSiliguri(
          fontSize: 16, fontWeight: FontWeight.w400, color: ink,
        ),
        bodyMedium: GoogleFonts.hindSiliguri(
          fontSize: 14, fontWeight: FontWeight.w400, color: muted,
        ),
        labelLarge: GoogleFonts.hindSiliguri(
          fontSize: 13, fontWeight: FontWeight.w600, color: muted, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1A8E8E93),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.hindSiliguri(fontSize: 15, color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BusinessType businessType) {
    final config = BusinessConfig.of(businessType);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: config.primary,
        secondary: config.secondary,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.hindSiliguri(
          fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.hindSiliguri(
          fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.hindSiliguri(
          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3,
        ),
        bodyLarge: GoogleFonts.hindSiliguri(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white,
        ),
        bodyMedium: GoogleFonts.hindSiliguri(
          fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF8E8E93),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
