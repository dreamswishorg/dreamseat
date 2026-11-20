import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dreameats/core/ds_kit.dart';
import 'package:dreameats/core/theme.dart';
import 'package:dreameats/features/common/help_support_screen.dart';
import 'package:dreameats/features/common/notification_screen.dart';
import 'package:dreameats/features/customer/impact_screen.dart';
import 'package:dreameats/features/customer/map_explore_screen.dart';
import 'package:dreameats/features/customer/modern_checkout_screen.dart';
import 'package:dreameats/features/customer/partners_directory_screen.dart';
import 'package:dreameats/features/customer/search_filter_screen.dart';
import 'package:dreameats/features/customer/loyalty_referral_screen.dart';
import 'package:dreameats/features/customer/customer_profile.dart';
import 'package:dreameats/features/customer/customer_settings_screen.dart';
import 'package:dreameats/features/customer/privacy_security_screen.dart';
import 'package:dreameats/providers/app_state.dart';

import 'support/customer_fixture.dart';

const _sizes = <Size>[
  Size(320, 568),
  Size(375, 812),
  Size(430, 932),
  Size(1280, 800),
];

Future<void> _pump(WidgetTester tester, Size size, Widget home) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appStateProvider.overrideWith(() => CustomerStateForTest())],
      child: MaterialApp(theme: AppTheme.lightTheme, home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  final pages = <String, Widget Function()>{
    'profile': () => const CustomerProfileScreen(),
    'settings': () => const CustomerSettingsScreen(),
    'privacy & security': () => const PrivacySecurityScreen(),
    'help & support': () => const HelpSupportScreen(),
    'impact': () => const ImpactScreen(),
    'rewards & referrals': () => const LoyaltyReferralScreen(),
    'notifications': () => const NotificationScreen(),
    'partners': () => const PartnersDirectoryScreen(),
    'search': () => const SearchFilterScreen(),
    'map': () => const MapExploreScreen(),
    'checkout': () => const ModernCheckoutScreen(),
  };

  for (final size in _sizes) {
    for (final e in pages.entries) {
      testWidgets('${e.key} renders without overflow at ${size.width.toInt()}px', (tester) async {
        await _pump(tester, size, e.value());
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('profile shows identity, points, referral code and live counts', (tester) async {
    await _pump(tester, const Size(390, 844), const CustomerProfileScreen());
    expect(find.text('Ama Mensah'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);
    expect(find.text('AMA-4821'), findsOneWidget);
    expect(find.text('3 orders'), findsOneWidget);
    expect(find.text('340 pts'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('settings pre-fills the saved name and phone', (tester) async {
    await _pump(tester, const Size(390, 844), const CustomerSettingsScreen());
    expect(find.widgetWithText(TextFormField, 'Ama Mensah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0245678901'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });

  testWidgets('settings refuses an empty name with an error toast', (tester) async {
    await _pump(tester, const Size(390, 844), const CustomerSettingsScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Ama Mensah'), '');
    await tester.tap(find.text('Save profile'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Name cannot be empty'), findsOneWidget);
  });

  testWidgets('help ticket form validates before sending', (tester) async {
    await _pump(tester, const Size(390, 844), const HelpSupportScreen());
    expect(find.text('My Active Requests'), findsOneWidget);
    expect(find.text('Order #1042 collection issue'), findsOneWidget);
    await tester.tap(find.text('Open Ticket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to support team'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Please add a subject'), findsOneWidget);
    expect(find.text('Please describe your issue'), findsOneWidget);
  });

  testWidgets('privacy keeps the password rules', (tester) async {
    await _pump(tester, const Size(390, 844), const PrivacySecurityScreen());
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Please enter your current password'), findsOneWidget);
  });

  testWidgets('impact shows level progress and earned badges', (tester) async {
    await _pump(tester, const Size(390, 844), const ImpactScreen());
    // 3 non-cancelled orders -> Waste Warrior, 7 meals from Eco Champion
    expect(find.text('Waste Warrior'), findsOneWidget);
    expect(find.text('7 more meals to reach Eco Champion'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('First Rescue Pioneer'), 300);
    expect(find.text('Earned'), findsOneWidget); // only the first badge (>=1 meal)
    expect(find.text('Locked'), findsNWidgets(2));
  });

  testWidgets('rewards locks vouchers the customer cannot afford yet', (tester) async {
    await _pump(tester, const Size(390, 844), const LoyaltyReferralScreen());
    expect(find.text('Redeem'), findsOneWidget);
    expect(find.text('Refer'), findsOneWidget);
    expect(find.text('Available Rewards'), findsOneWidget);
    await tester.tap(find.text('Refer'));
    await tester.pumpAndSettle();
    expect(tester.widget<DsSegmented>(find.byType(DsSegmented)).selected, 1);
    expect(find.text('Have a Friend\'s Code?'), findsOneWidget);
    await tester.ensureVisible(find.text('Apply code'));
    await tester.pump();
    await tester.tap(find.text('Apply code'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Enter code'), findsOneWidget);
  });

  testWidgets('notifications group unread under New and read under Earlier', (tester) async {
    await _pump(tester, const Size(390, 844), const NotificationScreen());
    expect(find.text('1 unread alert'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.text('Your order is ready'), findsOneWidget);
  });

  testWidgets('partners directory lists the partner and filters by search', (tester) async {
    await _pump(tester, const Size(390, 844), const PartnersDirectoryScreen());
    expect(find.text('Sweet Tooth Bakery'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No partners found'), findsOneWidget);
  });

  testWidgets('search uses the shared deal card and collapsible filters', (tester) async {
    await _pump(tester, const Size(390, 844), const SearchFilterScreen());
    expect(find.text('Surprise Bakery Box'), findsOneWidget);
    expect(find.text('Distance'), findsNothing); // filters start collapsed
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Distance'), findsOneWidget);
    await tester.tap(find.text('<1km'));
    await tester.pumpAndSettle();
    expect(find.text('Filters · 1'), findsOneWidget);
    expect(find.text('No deals match your search'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Surprise Bakery Box'), findsOneWidget);
  });

  testWidgets('checkout validates a promo code through the shared field', (tester) async {
    await _pump(tester, const Size(390, 844), const ModernCheckoutScreen());
    expect(find.text('Promo code'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, ''), 'NOPE');
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Invalid promo code'), findsOneWidget);
  });

  testWidgets('checkout falls back to built-in codes when server vouchers are not deployed', (tester) async {
    await _pump(tester, const Size(390, 844), const ModernCheckoutScreen());
    await tester.enterText(find.widgetWithText(TextFormField, ''), 'welcome20');
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('WELCOME20 applied'), findsOneWidget);
  });
}
