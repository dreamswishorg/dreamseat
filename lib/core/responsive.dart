import 'package:flutter/material.dart';

/// Comprehensive responsive utilities and wrappers for DreamEats.
/// Ensures optimal viewing experience across mobile devices, tablets,
/// desktop browsers, and device emulators.
class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Returns adaptive width based on percentage of screen width
  static double width(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  /// Returns adaptive height based on percentage of screen height
  static double height(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  /// Returns grid crossAxisCount adapted to device width
  static int gridCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final w = MediaQuery.of(context).size.width;
    if (w >= tabletBreakpoint) return desktop;
    if (w >= mobileBreakpoint) return tablet;
    return mobile;
  }

  /// Clamps dimensions to avoid overflow on very small emulator screens
  static double scaleVal(BuildContext context, double baseVal, {double min = 10, double max = 500}) {
    final h = MediaQuery.of(context).size.height;
    final scale = (h / 800).clamp(0.75, 1.2);
    return (baseVal * scale).clamp(min, max);
  }
}

/// App-wide responsive builder wrapper for MaterialApp.
/// Ensures clean text scaling and frames mobile views nicely on wide emulators/tablets.
class ResponsiveAppWrapper extends StatelessWidget {
  final Widget? child;
  const ResponsiveAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    // Comfortably boost text scaling by ~12% across the whole app for all users
    // (Customers, Store Owners, Admins) for crisp, effortless readability.
    final baseScale = mediaQuery.textScaler.scale(1.0);
    final boostedTextScaler = TextScaler.linear(
      (baseScale * 1.12).clamp(1.10, 1.45),
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: boostedTextScaler),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return child!;
        },
      ),
    );
  }
}
