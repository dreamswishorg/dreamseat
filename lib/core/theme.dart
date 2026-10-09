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

  // Client Drop Shadow Tokens (used across client and admin)
  static const List<BoxShadow> clientCardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x042E7D32),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> clientElevatedShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x082E7D32),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  // Dark mode completely removed per user specification
  static ThemeData get darkTheme => lightTheme;

  /// Formats a price in GHS. If there are pesewas (e.g. 0.10, 15.50), shows 2 decimal places.
  /// If it is a whole number (>= 1 with no fractional part), shows whole cedis (e.g. 15, 50).
  static String formatPrice(num price) {
    final double val = price.toDouble();
    if (val == 0) return '0';
    final int roundedCents = (val * 100).round();
    if (roundedCents % 100 == 0 && roundedCents >= 100) {
      return (roundedCents ~/ 100).toString();
    }
    return (roundedCents / 100).toStringAsFixed(2);
  }
}

extension ThemeContextExtension on BuildContext {
  // Dark mode permanently disabled across the application
  bool get isDark => false;
  Color get cardColor => Colors.white;
  Color get cardAltColor => const Color(0xFFF9FAF9);
  Color get cardSubtleColor => AppTheme.lightGreenBg;
  Color get textPrimary => AppTheme.charcoal;
  Color get textSecondary => AppTheme.mutedGrey;
  Color get borderColor => const Color(0xFFE2E8F0);
  Color get borderSubtleColor => const Color(0xFFF1F5F9);
  List<BoxShadow> get clientShadow => AppTheme.clientCardShadow;
  List<BoxShadow> get clientElevatedShadow => AppTheme.clientElevatedShadow;
}

