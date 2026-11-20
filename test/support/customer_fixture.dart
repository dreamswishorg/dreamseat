import 'package:dreameats/models/models.dart';
import 'package:dreameats/providers/app_state.dart';

/// A signed-in customer with a couple of orders and one open support ticket —
/// enough state for every customer screen to render something realistic.
class CustomerStateForTest extends AppStateManager {
  @override
  AppState build() {
    final now = DateTime(2026, 11, 20, 12);
    final deal = FoodDeal(
      id: 'deal-1',
      businessId: 'biz-1',
      businessName: 'Sweet Tooth Bakery',
      title: 'Surprise Bakery Box',
      description: 'Assorted pastries baked this morning.',
      category: 'Bakery Pack',
      originalPrice: 60,
      discountedPrice: 25,
      pickupWindow: 'Today · 5:00 PM - 7:00 PM',
      quantityRemaining: 5,
      quantityTotal: 10,
      imageUrl: '',
    );
    return AppState.empty().copyWith(
      currentUser: AppUser(
        id: 'cust-1',
        email: 'ama.mensah@example.com',
        name: 'Ama Mensah',
        role: 'customer',
        phone: '0245678901',
        dreamPoints: 340,
        referralCode: 'AMA-4821',
        createdAt: DateTime(2026),
      ),
      orders: [
        for (var i = 0; i < 3; i++)
          Order(
            id: 'order-$i',
            dealId: 'deal-$i',
            dealTitle: 'Surprise Bakery Box',
            businessId: 'biz-1',
            businessName: 'Sweet Tooth Bakery',
            customerId: 'cust-1',
            customerName: 'Ama Mensah',
            price: 25.0,
            originalPrice: 60.0,
            category: 'Bakery Pack',
            status: i == 0 ? 'ready' : 'collected',
            timestamp: now.subtract(Duration(days: i)),
            paymentMethod: 'MoMo',
            paymentReference: 'PAY-$i',
            collectionCode: '82${i}7A',
            payoutStatus: 'pending',
          ),
      ],
      businesses: [
        BusinessProfile(
          id: 'biz-1',
          ownerId: 'owner-1',
          name: 'Sweet Tooth Bakery',
          description: 'Pastries & Breads',
          logoUrl: '',
          category: 'Bakery Pack',
          location: 'Osu, Accra',
          distance: 1.2,
          rating: 4.8,
        ),
      ],
      deals: [deal],
      basket: [
        BasketItem(
          deal: deal,
          quantity: 2,
        ),
      ],
      notifications: [
        AppNotification(
          id: 'n-1',
          userId: 'cust-1',
          title: 'Your order is ready',
          body: 'Show code 8207A at Sweet Tooth Bakery before 7:00 PM.',
          screen: 'orders',
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        AppNotification(
          id: 'n-2',
          userId: 'cust-1',
          title: 'New surplus deal nearby',
          body: 'Garden Kitchen listed 6 lunch packs at 60% off.',
          screen: 'deal_detail',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
        ),
      ],
      supportTickets: [
        SupportTicket(
          id: 't-1',
          userId: 'cust-1',
          userName: 'Ama Mensah',
          subject: 'Order #1042 collection issue',
          message: 'The store was closed when I arrived.',
          status: 'open',
          priority: 'normal',
          category: 'order',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }
}
