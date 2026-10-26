import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Merchant Portal design tokens.
/// Mirrors the customer portal design system (AppTheme) so both surfaces
/// read as one product: forest green on white, hairline borders, soft depth.
class MerchantTheme {
  MerchantTheme._();

  // ── Navigation Surfaces (light, same as the customer side nav) ──
  static const Color navSurface = Colors.white;
  static const Color navSurfaceAlt = AppTheme.lightGrey; // #F5F7F6
  static const Color navBorder = Color(0xFFE2E8F0);
  static const Color navActiveBg = AppTheme.lightGreenBg; // #E8F5E9
  static const Color navHover = Color(0xFFF1F5F9);

  // ── Canvas & Surfaces ──
  static const Color canvasBg = AppTheme.lightGrey; // #F5F7F6
  static const Color canvasAlt = AppTheme.lightGreenBg; // #E8F5E9
  static const Color cardSurface = AppTheme.pureWhite;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardBorderSubtle = Color(0xFFF1F5F9);
  static const Color cardHairline = Color(0x0F1E293B); // charcoal @ 6%

  // ── Brand Accents (customer portal greens) ──
  static const Color brandGreen = AppTheme.primaryGreen; // #2E7D32
  static const Color brandDeepGreen = Color(0xFF1B5E20);
  static const Color brandSoftGreen = AppTheme.secondaryGreen; // #4CAF50
  static const Color brandTint = AppTheme.lightGreenBg; // #E8F5E9

  // ── Semantic Accents ──
  static const Color amberWarning = AppTheme.warningOrange; // #F59E0B
  static const Color amberLightBg = Color(0xFFFFF8E1);
  static const Color goldAccent = AppTheme.goldAccent; // #D97706
  static const Color goldLightBg = Color(0xFFFEF3C7);
  static const Color skyInfo = Color(0xFF3B82F6);
  static const Color skyLightBg = Color(0xFFEFF6FF);
  static const Color roseDanger = AppTheme.errorRed; // #EF4444
  static const Color roseLightBg = Color(0xFFFEF2F2);
  static const Color violetAccent = Color(0xFF7C3AED);
  static const Color violetLightBg = Color(0xFFF5F3FF);
  static const Color tealSuccess = Color(0xFF0D9488);
  static const Color tealLightBg = Color(0xFFF0FDFA);

  // ── Typography Colors ──
  static const Color textDark = AppTheme.charcoal; // #1E293B
  static const Color textMuted = AppTheme.mutedGrey; // #64748B
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Colors.white;

  // ── Radii (customer portal scale) ──
  static const double radiusHero = 26.0;
  static const double radiusLg = 16.0;
  static const double radiusMd = 14.0;
  static const double radiusSm = 12.0;
  static const double radiusXs = 8.0;

  // ── Depth (customer "liquid glass" ambient tokens) ──
  static List<BoxShadow> get cardElevation => AppTheme.clientCardShadow;

  static List<BoxShadow> get cardLifted => AppTheme.clientElevatedShadow;

  static List<BoxShadow> brandGlowShadow({double alpha = 0.28}) => [
        BoxShadow(
          color: brandGreen.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get sidebarShadow => const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 18,
          offset: Offset(2, 0),
        ),
      ];
}
