import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest Eco Green
  static const Color secondaryGreen = Color(0xFF4CAF50); // Muted Green
  static const Color lightGreenBg = Color(0xFFE8F5E9); // Light Green Accent
  static const Color pureWhite = Color(0xFFFFFFFF); // Clean White
  static const Color lightGrey = Color(0xFFF5F7F6); // Soft off-white with grey/green hue
  static const Color charcoal = Color(0xFF1E293B); // Slate dark grey for text
  static const Color mutedGrey = Color(0xFF64748B); // Muted slate for subtitle/details
  static const Color errorRed = Color(0xFFEF4444); // Red for cancel/strikeouts
  static const Color warningOrange = Color(0xFFF59E0B); // Amber warning
  static const Color goldAccent = Color(0xFFD97706); // Gold for premium status

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: pureWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryGreen,
        surface: lightGrey,
        onPrimary: pureWhite,
        onSecondary: charcoal,
        onSurface: charcoal,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        shadowColor: charcoal.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: charcoal.withValues(alpha: 0.06), width: 0.8),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: charcoal, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
          displayMedium: TextStyle(color: charcoal, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displaySmall: TextStyle(color: charcoal, fontSize: 24, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: charcoal, fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: charcoal, fontSize: 22, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: charcoal, fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: charcoal, fontSize: 21, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: charcoal, fontSize: 17.5, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: charcoal, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: charcoal, fontSize: 17.5, height: 1.4),
          bodyMedium: TextStyle(color: mutedGrey, fontSize: 15.5, height: 1.4),
          bodySmall: TextStyle(color: mutedGrey, fontSize: 13.5, height: 1.4),
          labelLarge: TextStyle(color: primaryGreen, fontSize: 15.5, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(color: charcoal, fontSize: 13.5, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(color: mutedGrey, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: charcoal.withValues(alpha: 0.05), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 2)),
        hintStyle: const TextStyle(color: mutedGrey, fontSize: 15),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: Color(0xFF22C55E),
        surface: Color(0xFF1E293B), // Slate 800
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Color(0xFFF87171),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFFE2E8F0), fontSize: 17.5, height: 1.4),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8), fontSize: 15.5, height: 1.4),
          bodySmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5, height: 1.4),
          labelLarge: TextStyle(color: Color(0xFF22C55E), fontSize: 15.5, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 2)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      ),
    );
  }
}
