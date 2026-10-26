import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dreameats/features/merchant/merchant_dashboard.dart';
import 'package:dreameats/models/models.dart';
import 'package:dreameats/providers/app_state.dart';

final _biz = BusinessProfile(
  id: 'biz-1',
  ownerId: 'owner-1',
  name: 'Sweet Tooth Bakery',
  description: 'Pastries & Breads',
  logoUrl: '',
  category: 'Bakery Pack',
  location: 'Osu, Accra',
  distance: 1.0,
  rating: 4.9,
);

List<FoodDeal> _deals() => [
      for (var i = 1; i <= 4; i++)
        FoodDeal(
          id: 'deal-$i',
          businessId: 'biz-1',
          businessName: _biz.name,
          title: 'Family Pastry Box Assortment Extra Long Title $i',
          description: 'Assorted freshly baked pastries packed this morning, ideal for a shared table.',
          category: 'Bakery Pack',
          originalPrice: 60.0 + i,
          discountedPrice: 24.0 + i,
          pickupWindow: 'Today · 5:00 PM - 7:00 PM',
          quantityRemaining: i == 2 ? 1 : 6,
          quantityTotal: 10,
          imageUrl: '',
        ),
    ];

List<Order> _orders() {
  final now = DateTime.now();
  const statuses = ['reserved', 'preparing', 'ready', 'collected', 'out_for_delivery'];
  return [
    for (var i = 0; i < statuses.length; i++)
      Order(
        id: 'order-$i',
        dealId: 'deal-1',
        dealTitle: 'Family Pastry Box Assortment Extra Long Title 1',
        businessId: 'biz-1',
        businessName: _biz.name,
        customerId: 'cust-$i',
        customerName: 'Ama Serwaa Mensah',
        price: 25.0 + i,
        originalPrice: 60.0 + i,
        category: 'Bakery Pack',
        status: statuses[i],
        timestamp: now.subtract(Duration(minutes: 10 * i)),
        paymentMethod: 'MoMo',
        paymentReference: 'PAY-1234567890-$i',
        collectionCode: '827${i}A',
        payoutStatus: 'pending',
      ),
  ];
}

class MerchantAppStateForTest extends AppStateManager {
  @override
  AppState build() {
    return AppState.empty().copyWith(
      currentUser: AppUser(
        id: 'owner-1',
        email: 'shop@sweettooth.test',
        name: 'Ama Mensah',
        role: 'merchant',
        createdAt: DateTime(2026),
      ),
      businesses: [_biz],
      deals: _deals().where((d) => d.isActive).toList(),
      merchantDeals: _deals(),
      orders: _orders(),
    );
  }
}

Future<void> _usePhoneSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpPortal(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appStateProvider.overrideWith(() => MerchantAppStateForTest())],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2E7D32)),
        home: const MerchantDashboardScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Icons used by the phone bottom navigation for each destination.
  const navIcons = <String, IconData>{
    'Home': Icons.home_outlined,
    'Orders': Icons.receipt_long_outlined,
    'Listings': Icons.inventory_2_outlined,
    'Verify': Icons.qr_code_scanner_rounded,
    'Shop': Icons.storefront_outlined,
  };

  for (final size in const [Size(320, 568), Size(375, 812), Size(430, 932)]) {
    for (final entry in navIcons.entries) {
      testWidgets(
          'merchant ${entry.key} tab renders without overflow at ${size.width}px',
          (tester) async {
        await _usePhoneSize(tester, size);
        await _pumpPortal(tester);

        if (find.byIcon(entry.value).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(entry.value).first, warnIfMissed: false);
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('every sidebar destination renders at desktop width', (tester) async {
    await _usePhoneSize(tester, const Size(1280, 900));
    await _pumpPortal(tester);

    for (final label in const [
      'Live Orders',
      'Surplus Inventory',
      'Verify Pickup',
      'Payouts',
      'Impact',
      'Reviews',
      'Shop Profile',
      'Overview',
    ]) {
      await tester.tap(find.text(label).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'error while showing $label');
    }
  });

  testWidgets('selected bottom nav keeps its full label visible', (tester) async {
    await _usePhoneSize(tester, const Size(320, 568));
    await _pumpPortal(tester);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined).first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final labels = tester.widgetList<Text>(find.text('Listings')).toList();
    expect(labels, isNotEmpty);
    expect(
      labels.any((t) => t.overflow != TextOverflow.ellipsis),
      isTrue,
      reason: 'the active pill must show its full label, not a clipped one',
    );
  });
}
