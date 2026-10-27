import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreameats/features/customer/deal_detail_screen.dart';
import 'package:dreameats/features/customer/modern_checkout_screen.dart';
import 'package:dreameats/services/location_service.dart';
import 'package:dreameats/models/models.dart';
import 'package:dreameats/providers/app_state.dart';

class TestAppStateNotifier extends AppStateManager {
  @override
  AppState build() {
    return AppState.empty().copyWith(
      businesses: [
        BusinessProfile(
          id: 'biz-1',
          ownerId: 'owner-1',
          name: 'Sweet Tooth Bakery',
          description: 'Pastries & Breads',
          logoUrl: '',
          category: 'Bakery Pack',
          location: 'Osu, Accra',
          distance: 1.0,
          rating: 4.9,
        ),
      ],
      deals: [
        FoodDeal(
          id: 'deal-test-1',
          businessId: 'biz-1',
          businessName: 'Sweet Tooth Bakery',
          title: 'Pastry Box Special',
          description: 'Delicious assortment of freshly baked pastries',
          category: 'Bakery Pack',
          originalPrice: 50.0,
          discountedPrice: 25.0,
          pickupWindow: 'Today · 5:00 PM - 7:00 PM',
          quantityRemaining: 4,
          quantityTotal: 8,
          imageUrl: '',
        ),
      ],
    );
  }
}

void main() {
  final testDeal = FoodDeal(
    id: 'deal-test-1',
    businessId: 'biz-1',
    businessName: 'Sweet Tooth Bakery',
    title: 'Pastry Box Special',
    description: 'Delicious assortment of freshly baked pastries',
    category: 'Bakery Pack',
    originalPrice: 50.0,
    discountedPrice: 25.0,
    pickupWindow: 'Today · 5:00 PM - 7:00 PM',
    quantityRemaining: 4,
    quantityTotal: 8,
    imageUrl: '',
  );

  group('Deal Detail Screen Button Tests', () {
    testWidgets('Single Add to Basket button is present and amount button is removed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => TestAppStateNotifier()),
          ],
          child: MaterialApp(
            home: DealDetailScreen(deal: testDeal),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Add to Basket" should exist as primary action
      expect(find.text('Add to Basket'), findsOneWidget);

      // The old amount button with 'GHS 25.00' text as a separate button should NOT exist
      expect(find.widgetWithText(ElevatedButton, 'GHS 25.00'), findsNothing);
      expect(find.byIcon(Icons.bolt_rounded), findsNothing);
    });
  });

  group('PredictedAddress Model Tests', () {
    test('PredictedAddress formatting and shortDisplay', () {
      final suggestion = PredictedAddress(
        displayName: 'Oxford Street, Osu, Accra, Greater Accra Region, Ghana',
        primaryText: 'Oxford Street, Osu',
        secondaryText: 'Accra, Greater Accra',
        latitude: 5.5560,
        longitude: -0.1820,
      );

      expect(suggestion.primaryText, equals('Oxford Street, Osu'));
      expect(suggestion.shortDisplay, equals('Oxford Street, Osu, Accra, Greater Accra'));
      final pos = suggestion.toPosition();
      expect(pos.latitude, equals(5.5560));
      expect(pos.longitude, equals(-0.1820));
    });
  });

  group('Modern Checkout Delivery Address Tests', () {
    testWidgets('Address is not prefilled with hardcoded address and supports manual entry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith(() => TestAppStateNotifier()),
          ],
          child: const MaterialApp(
            home: ModernCheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Rider Delivery
      final riderDelivery = find.text('Rider Delivery');
      expect(riderDelivery, findsOneWidget);
      await tester.tap(riderDelivery);
      await tester.pumpAndSettle();

      // Verify "Use my current location" button is displayed
      expect(find.text('Use my current location'), findsOneWidget);

      // Find the address textfield by its hint text
      final addressField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText?.contains('landmark') == true,
      );
      expect(addressField, findsOneWidget);

      final textFinder = find.descendant(of: addressField, matching: find.byType(EditableText));
      final editable = tester.widget<EditableText>(textFinder);

      // Verify it is NOT hardcoded to 'Accra Central, Greater Accra, Ghana'
      expect(editable.controller.text, isNot(equals('Accra Central, Greater Accra, Ghana')));

      // Test manual entry
      await tester.enterText(addressField, '12 Jungle Road, East Legon');
      await tester.pumpAndSettle();
      expect(editable.controller.text, equals('12 Jungle Road, East Legon'));

      // Test clear button
      final clearButton = find.byTooltip('Clear address');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      expect(editable.controller.text, isEmpty);
    });
  });
}
