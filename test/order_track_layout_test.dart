import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dreameats/core/theme.dart';
import 'package:dreameats/features/customer/order_track_screen.dart';
import 'package:dreameats/models/models.dart';
import 'package:dreameats/providers/app_state.dart';

import 'support/customer_fixture.dart';

Order _order({required String type, required String status}) => Order(
      id: 'o-$type',
      dealId: 'd-1',
      dealTitle: 'Surprise Bakery Box',
      businessId: 'biz-1',
      businessName: 'Sweet Tooth Bakery',
      customerId: 'cust-1',
      customerName: 'Ama Mensah',
      price: 25,
      originalPrice: 60,
      category: 'Bakery Pack',
      status: status,
      timestamp: DateTime(2026, 11, 20, 12),
      paymentMethod: 'MoMo',
      paymentReference: 'PAY-1',
      collectionCode: '8207A',
      payoutStatus: 'pending',
      fulfillmentType: type,
      courierName: type == 'delivery' ? 'Kwame Asante' : null,
      deliveryPin: type == 'delivery' ? '4821' : '',
    );

Future<void> _pump(WidgetTester tester, Size size, Order order) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appStateProvider.overrideWith(() => CustomerStateForTest())],
      child: MaterialApp(theme: AppTheme.lightTheme, home: OrderTrackScreen(order: order)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final size in const [Size(320, 568), Size(390, 844), Size(1280, 800)]) {
    final w = size.width.toInt();

    testWidgets('pickup tracker shows progress and collection code at ${w}px', (tester) async {
      await _pump(tester, size, _order(type: 'pickup', status: 'ready'));
      expect(find.text('Store Pickup Tracker'), findsOneWidget);
      expect(find.text('Pickup progress'), findsOneWidget);
      expect(find.text('#8207A'), findsOneWidget);
      expect(find.text('Placed'), findsOneWidget);
      expect(find.text('Rescued'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('delivery tracker shows courier and PIN at ${w}px', (tester) async {
      await _pump(tester, size, _order(type: 'delivery', status: 'out_for_delivery'));
      expect(find.text('Delivery Tracker'), findsOneWidget);
      expect(find.text('Kwame Asante'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.byTooltip('Call courier'), findsNothing); // semantics label, not tooltip
      expect(tester.takeException(), isNull);
    });
  }
}
