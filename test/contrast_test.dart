import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dreameats/core/theme.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double ratio(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Every foreground/background pair the DreamEats kit puts text on.
  // Body text needs 4.5:1 (WCAG AA).
  final pairs = <String, (Color, Color)>{
    'charcoal on cream': (AppTheme.charcoal, AppTheme.cream),
    'charcoal on white': (AppTheme.charcoal, AppTheme.pureWhite),
    'muted on cream': (AppTheme.mutedGrey, AppTheme.cream),
    'muted on white': (AppTheme.mutedGrey, AppTheme.pureWhite),
    'muted on lightGrey': (AppTheme.mutedGrey, AppTheme.lightGrey),
    'muted on lightGreen': (AppTheme.mutedGrey, AppTheme.lightGreenBg),
    'primary on white': (AppTheme.primaryGreen, AppTheme.pureWhite),
    'primary on lightGreen': (AppTheme.primaryGreen, AppTheme.lightGreenBg),
    'white on primary': (AppTheme.pureWhite, AppTheme.primaryGreen),
    'white on deepGreen': (AppTheme.pureWhite, AppTheme.deepGreen),
    'mint on deepGreen': (AppTheme.mintGreen, AppTheme.deepGreen),
    'lime on deepGreen': (AppTheme.limeAccent, AppTheme.deepGreen),
    'deepGreen on lightGreen': (AppTheme.deepGreen, AppTheme.lightGreenBg),
    'error on white': (AppTheme.errorRed, AppTheme.pureWhite),
    'error on tint': (AppTheme.errorRed, const Color(0xFFFEECEC)),
    'deal on white': (AppTheme.dealOrange, AppTheme.pureWhite),
    'deal on dealBg': (AppTheme.dealOrange, AppTheme.dealOrangeBg),
    'white on deal': (AppTheme.pureWhite, AppTheme.dealOrange),
    'gold on white': (AppTheme.goldAccent, AppTheme.pureWhite),
    'gold on tint': (AppTheme.goldAccent, const Color(0xFFFFF6E0)),
    'info on white': (AppTheme.infoBlue, AppTheme.pureWhite),
    'info on infoBg': (AppTheme.infoBlue, AppTheme.infoBlueBg),
  };
  for (final e in pairs.entries) {
    test('contrast: ${e.key} >= 4.5:1', () {
      final r = ratio(e.value.$1, e.value.$2);
      expect(r, greaterThanOrEqualTo(4.5), reason: '${e.key} is ${r.toStringAsFixed(2)}:1');
    });
  }
}
