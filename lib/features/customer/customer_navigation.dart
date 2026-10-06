import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import 'customer_home.dart';
import 'partners_directory_screen.dart';
import 'loyalty_referral_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import 'basket_screen.dart';

class CustomerNavigation extends ConsumerStatefulWidget {
  const CustomerNavigation({super.key});

  @override
  ConsumerState<CustomerNavigation> createState() =>
      _CustomerNavigationState();
}

class _CustomerNavigationState extends ConsumerState<CustomerNavigation> {
  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const FavoritesScreen(),
    const PartnersDirectoryScreen(),
    const LoyaltyReferralScreen(),
    const OrderHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(customerTabProvider);
    final state = ref.watch(appStateProvider);
    final basketCount = state.basketItemCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      // Floating basket button (visible on home & favorites tabs only)
      floatingActionButton: currentIndex <= 1 && basketCount > 0
          ? FloatingActionButton.extended(
              heroTag: 'basket_fab',
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.shopping_basket, color: Colors.white),
              label: Text(
                'Basket ($basketCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BasketScreen()),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(customerTabProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: isDark ? const Color(0xFF64748B) : AppTheme.mutedGrey,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Partners',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars_outlined),
            activeIcon: Icon(Icons.stars),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}

