import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing scale — everything stands on a 4-pt base.
class AppSpace {
  AppSpace._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3 = 32;
  static const double x4 = 40;
  static const double x5 = 48;
  static const double x6 = 64;

  /// Horizontal gutter used by every phone page.
  static const double gutter = 20;
}

/// Corner-radius scale. Use these instead of ad-hoc numbers.
class AppRadius {
  AppRadius._();
  static const double xs = 8; // tags, small thumbs
  static const double sm = 12; // inputs, chips
  static const double md = 16; // cards, buttons
  static const double lg = 24; // hero cards, sheets
  static const double xl = 32; // feature banners
  static const double pill = 999;

  static BorderRadius get rXs => BorderRadius.circular(xs);
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);
}

/// Motion tokens — short, purposeful, and exits faster than entrances.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest Eco Green
  static const Color secondaryGreen = Color(0xFF4CAF50); // Muted Green
  static const Color lightGreenBg = Color(0xFFE8F5E9); // Light Green Accent
  static const Color deepGreen = Color(0xFF0F3D26); // Hero / dark surfaces
  static const Color mintGreen = Color(0xFFD7F0DE); // Soft highlight
  static const Color limeAccent = Color(0xFFB7E34A); // Fresh highlight on dark

  // ── Neutrals (warm, food-friendly) ─────────────────────────────────────────
  static const Color pureWhite = Color(0xFFFFFFFF); // Clean White
  static const Color cream = Color(0xFFFAF9F6); // Page background
  static const Color lightGrey = Color(0xFFF5F7F6); // Soft off-white, green hue
  static const Color charcoal = Color(0xFF1E293B); // Slate text
  static const Color mutedGrey = Color(0xFF64748B); // Subtitle / details
  static const Color hairline = Color(0xFFE7E5E0); // Warm hairline border

  // ── Status & accent ────────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFEF4444); // Cancel / strikeouts
  static const Color warningOrange = Color(0xFFF59E0B); // Amber warning
  static const Color goldAccent = Color(0xFFD97706); // Premium status
  static const Color dealOrange = Color(0xFFEA580C); // Discounts & price tags
  static const Color dealOrangeBg = Color(0xFFFFF1E6); // Discount tint
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoBlueBg = Color(0xFFEAF1FF);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14522F), deepGreen],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A9444), primaryGreen],
  );

  static const LinearGradient scrimGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xB3000000)],
  );

  // ── Elevation (layered, soft, slightly green-tinted ambient) ───────────────
  static const List<BoxShadow> clientCardShadow = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> clientElevatedShadow = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A0F3D26), blurRadius: 32, offset: Offset(0, 14)),
  ];

  /// Tight shadow for pills / floating bars.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: charcoal, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.1),
        displayMedium: TextStyle(color: charcoal, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15),
        displaySmall: TextStyle(color: charcoal, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
        headlineLarge: TextStyle(color: charcoal, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
        headlineMedium: TextStyle(color: charcoal, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),
        headlineSmall: TextStyle(color: charcoal, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25),
        titleLarge: TextStyle(color: charcoal, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),
        titleMedium: TextStyle(color: charcoal, fontSize: 17.5, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3),
        titleSmall: TextStyle(color: charcoal, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.3),
        bodyLarge: TextStyle(color: charcoal, fontSize: 17.5, height: 1.5),
        bodyMedium: TextStyle(color: mutedGrey, fontSize: 15.5, height: 1.5),
        bodySmall: TextStyle(color: mutedGrey, fontSize: 13.5, height: 1.45),
        labelLarge: TextStyle(color: primaryGreen, fontSize: 15.5, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(color: charcoal, fontSize: 13.5, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: mutedGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );

    const colorScheme = ColorScheme.light(
      primary: primaryGreen,
      onPrimary: pureWhite,
      primaryContainer: lightGreenBg,
      onPrimaryContainer: deepGreen,
      secondary: secondaryGreen,
      onSecondary: charcoal,
      secondaryContainer: mintGreen,
      onSecondaryContainer: deepGreen,
      tertiary: dealOrange,
      onTertiary: pureWhite,
      tertiaryContainer: dealOrangeBg,
      onTertiaryContainer: Color(0xFF7C2D12),
      surface: lightGrey,
      onSurface: charcoal,
      onSurfaceVariant: mutedGrey,
      outline: hairline,
      outlineVariant: Color(0xFFF1EFEA),
      error: errorRed,
      onError: pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: cream,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: charcoal.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: const BorderSide(color: hairline, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.35),
          disabledForegroundColor: pureWhite.withValues(alpha: 0.8),
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: charcoal,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: pureWhite,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: primaryGreen, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: errorRed)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: errorRed, width: 2)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        labelStyle: const TextStyle(color: mutedGrey, fontWeight: FontWeight.w600),
        floatingLabelStyle: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
        errorStyle: const TextStyle(color: errorRed, fontSize: 12.5, fontWeight: FontWeight.w600),
        prefixIconColor: mutedGrey,
        suffixIconColor: mutedGrey,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pureWhite,
        selectedColor: deepGreen,
        disabledColor: lightGrey,
        side: const BorderSide(color: hairline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        labelStyle: const TextStyle(color: charcoal, fontSize: 13.5, fontWeight: FontWeight.w700),
        secondaryLabelStyle: const TextStyle(color: pureWhite, fontSize: 13.5, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        showCheckmark: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: pureWhite,
        // Sheets in this app draw their own handle, so none is added here.
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        titleTextStyle: const TextStyle(color: charcoal, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        contentTextStyle: const TextStyle(color: mutedGrey, fontSize: 15, height: 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: lightGreenBg,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? primaryGreen : mutedGrey,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: states.contains(WidgetState.selected) ? primaryGreen : mutedGrey,
            )),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: mutedGrey,
        indicatorColor: primaryGreen,
        dividerColor: hairline,
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(pureWhite),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryGreen : const Color(0xFFCBD5E1),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryGreen : Colors.transparent,
        ),
        side: const BorderSide(color: Color(0xFFB8C0CC), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: lightGreenBg,
        circularTrackColor: lightGreenBg,
        linearMinHeight: 6,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: mutedGrey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: charcoal, borderRadius: AppRadius.rXs),
        textStyle: const TextStyle(color: pureWhite, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: charcoal,
        contentTextStyle: const TextStyle(
          color: pureWhite,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        elevation: 6,
      ),
    );
  }

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
  Color get cardColor => Colors.white.withValues(alpha: 0.94);
  Color get cardAltColor => const Color(0xFFF8FAFC).withValues(alpha: 0.90);
  Color get cardSubtleColor => const Color(0xFFE8F5E9).withValues(alpha: 0.85);
  Color get textPrimary => AppTheme.charcoal;
  Color get textSecondary => AppTheme.mutedGrey;
  Color get borderColor => AppTheme.hairline;
  Color get borderSubtleColor => const Color(0xFFF1EFEA);
  List<BoxShadow> get clientShadow => AppTheme.clientCardShadow;
  List<BoxShadow> get clientElevatedShadow => AppTheme.clientElevatedShadow;
}

extension ShortIdExtension on String {
  /// First [n] characters (or the whole string when it is shorter) — safe for
  /// displaying a short reference from an id of any length.
  String shortId([int n = 8]) => length > n ? substring(0, n) : this;
}
