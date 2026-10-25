import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Distinctive design system tokens for DreamEats Merchant Portal.
/// Crafted for a high-value SaaS food-commerce experience.
class MerchantTheme {
  MerchantTheme._();

  // ── Navigation & Deep Surfaces (Midnight Charcoal) ──
  static const Color midnightSidebar = Color(0xFF0B1320);
  static const Color midnightSidebarSurface = Color(0xFF131F33);
  static const Color midnightSidebarBorder = Color(0xFF1E2E48);
  static const Color midnightActiveGlow = Color(0xFF0F382A);
  static const Color midnightHover = Color(0xFF16253D);

  // ── Canvas & Surfaces ──
  static const Color canvasBg = Color(0xFFF6F8FB);
  static const Color canvasAlt = Color(0xFFEEF2F6);
  static const Color cardSurface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardBorderSubtle = Color(0xFFEDF2F7);

  // ── Brand Accents ──
  static const Color emeraldPrimary = AppTheme.primaryGreen; // #10B981
  static const Color emeraldDeep = Color(0xFF065F46);
  static const Color emeraldGlow = Color(0xFF34D399);
  static const Color emeraldLightBg = Color(0xFFECFDF5);

  // ── Semantic Accents ──
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberLightBg = Color(0xFFFFFBEB);
  static const Color skyInfo = Color(0xFF2563EB);
  static const Color skyLightBg = Color(0xFFEFF6FF);
  static const Color roseDanger = Color(0xFFEF4444);
  static const Color roseLightBg = Color(0xFFFEF2F2);
  static const Color violetAccent = Color(0xFF7C3AED);
  static const Color violetLightBg = Color(0xFFF5F3FF);
  static const Color tealSuccess = Color(0xFF0D9488);
  static const Color tealLightBg = Color(0xFFF0FDFA);

  // ── Typography Colors ──
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Colors.white;

  // ── Radii ──
  static const double radiusLg = 20.0;
  static const double radiusMd = 14.0;
  static const double radiusSm = 10.0;
  static const double radiusXs = 6.0;

  // ── Box Shadows with Depth ──
  static List<BoxShadow> get cardElevation => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardLifted => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: emeraldPrimary.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get sidebarShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(4, 0),
        ),
      ];
}
