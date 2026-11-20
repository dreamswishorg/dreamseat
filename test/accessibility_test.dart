import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dreameats/core/theme.dart';
import 'package:dreameats/features/auth/admin_login_screen.dart';
import 'package:dreameats/features/auth/auth_screen.dart';
import 'package:dreameats/features/auth/forgot_password_screen.dart';
import 'package:dreameats/features/common/help_support_screen.dart';
import 'package:dreameats/features/common/notification_screen.dart';
import 'package:dreameats/features/customer/customer_profile.dart';
import 'package:dreameats/features/customer/customer_settings_screen.dart';
import 'package:dreameats/features/customer/impact_screen.dart';
import 'package:dreameats/features/customer/loyalty_referral_screen.dart';
import 'package:dreameats/features/customer/modern_checkout_screen.dart';
import 'package:dreameats/features/customer/partners_directory_screen.dart';
import 'package:dreameats/features/customer/privacy_security_screen.dart';
import 'package:dreameats/features/customer/search_filter_screen.dart';
import 'package:dreameats/providers/app_state.dart';

import 'support/customer_fixture.dart';

/// Screens every customer meets. Each must clear the platform tap-target
/// guidelines and have a text label on every tappable control.
final _screens = <String, Widget Function()>{
  'sign in': () => const AuthScreen(),
  'create account': () => const AuthScreen(initialTab: 1),
  'forgot password': () => const ForgotPasswordScreen(),
  'admin login': () => const AdminLoginScreen(),
  'profile': () => const CustomerProfileScreen(),
  'settings': () => const CustomerSettingsScreen(),
  'privacy': () => const PrivacySecurityScreen(),
  'help': () => const HelpSupportScreen(),
  'notifications': () => const NotificationScreen(),
  'impact': () => const ImpactScreen(),
  'rewards': () => const LoyaltyReferralScreen(),
  'partners': () => const PartnersDirectoryScreen(),
  'search': () => const SearchFilterScreen(),
  'checkout': () => const ModernCheckoutScreen(),
};

void main() {
  for (final e in _screens.entries) {
    testWidgets('${e.key}: tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [appStateProvider.overrideWith(() => CustomerStateForTest())],
        child: MaterialApp(theme: AppTheme.lightTheme, home: e.value()),
      ));
      await tester.pump(const Duration(milliseconds: 900));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
