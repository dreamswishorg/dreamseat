import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreameats/main.dart';
import 'package:dreameats/features/customer/deal_detail_screen.dart';
import 'package:dreameats/models/models.dart';
import 'package:dreameats/providers/app_state.dart';

class TestAppStateNotifier extends AppStateManager {
  @override
  AppState build() {
    return AppState.empty().copyWith(
      businesses: [
        BusinessProfile(
          id: 'merchant-1',
          ownerId: 'owner-1',
          name: 'Garden Kitchen',
          description: 'Fresh meals',
          logoUrl: '',
          category: 'Restaurant Meal',
          location: 'Accra',
          distance: 1.2,
          rating: 4.8,
        ),
      ],
      deals: [
        FoodDeal(
          id: 'deal-1',
          businessId: 'merchant-1',
          businessName: 'Garden Kitchen',
          title: 'Lunch Rescue Box',
          description: 'A hearty meal bundle',
          category: 'Restaurant Meal',
          originalPrice: 30,
          discountedPrice: 12,
          pickupWindow: 'Today · 6:00 PM',
          quantityRemaining: 5,
          quantityTotal: 10,
          imageUrl: 'https://example.com/food.jpg',
        ),
      ],
    );
  }
}

void main() {
  testWidgets('DreamEats app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DreamEatsApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Deal detail screen uses a hero transition for the meal image', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWith(() => TestAppStateNotifier()),
        ],
        child: MaterialApp(
          home: DealDetailScreen(
            deal: FoodDeal(
              id: 'deal-1',
              businessId: 'merchant-1',
              businessName: 'Garden Kitchen',
              title: 'Lunch Rescue Box',
              description: 'A hearty meal bundle',
              category: 'Restaurant Meal',
              originalPrice: 30,
              discountedPrice: 12,
              pickupWindow: 'Today · 6:00 PM',
              quantityRemaining: 5,
              quantityTotal: 10,
              imageUrl: 'https://example.com/food.jpg',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsAtLeastNWidgets(1));
  });
}
