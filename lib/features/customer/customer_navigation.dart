import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../providers/app_state.dart';
import 'customer_home.dart';
import 'partners_directory_screen.dart';
import 'loyalty_referral_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import 'basket_screen.dart';

import '../admin/admin_dashboard.dart';

class CustomerNavigation extends ConsumerStatefulWidget {
  const CustomerNavigation({super.key});

  @override
  ConsumerState<CustomerNavigation> createState() =>
      _CustomerNavigationState();
}

class _CustomerNavigationState extends ConsumerState<CustomerNavigation> {
  bool _isSideNavCollapsed = false;

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
    final user = state.currentUser;
    final isAdmin = user?.role == 'admin' || user?.role == 'super_admin';
    final basketCount = state.basketItemCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final wide = useSideNav(context);

    final tabs = IndexedStack(
      index: currentIndex,
      children: _screens,
    );

    return Scaffold(
      body: Stack(
        children: [
          if (wide)
            Row(
              children: [
                DesktopSideNav(
                  accentColor: AppTheme.primaryGreen,
                  selectedIndex: currentIndex,
                  isCollapsed: _isSideNavCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSideNavCollapsed = !_isSideNavCollapsed);
                  },
                  onSelect: (i) {
                    ref.read(customerTabProvider.notifier).state = i;
                    // Auto-collapse in tablet mode (width < 1150) to maximize view canvas
                    if (screenWidth < 1150) {
                      setState(() => _isSideNavCollapsed = true);
                    }
                  },
                  header: _buildSideNavBrand(),
                  items: const [
                    SideNavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
                    SideNavItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Favorites'),
                    SideNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Partners'),
                    SideNavItem(icon: Icons.stars_outlined, activeIcon: Icons.stars, label: 'Rewards'),
                    SideNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
                  ],
                  footer: basketCount > 0
                      ? (_isSideNavCollapsed
                          ? Tooltip(
                              message: "Basket ($basketCount)",
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.shopping_basket, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BasketScreen()),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.shopping_basket, size: 18),
                                label: Text('Basket ($basketCount)',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BasketScreen()),
                                ),
                              ),
                            ))
                      : null,
                ),
                Expanded(child: tabs),
              ],
            )
          else
            tabs,
          if (isAdmin)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              top: MediaQuery.of(context).padding.top + 8,
              left: wide ? (_isSideNavCollapsed ? 90 : 256) : 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.7), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Admin Session Active (${user?.role == 'super_admin' ? 'Super Admin' : 'Staff'})",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("HQ Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                                SizedBox(width: 3),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Floating basket button (visible on home & favorites tabs only)
      floatingActionButton: !wide && currentIndex <= 1 && basketCount > 0
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
      bottomNavigationBar: wide ? null : BottomNavigationBar(
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

  Widget _buildSideNavBrand() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/images/logo.jpg', height: 32, width: 32, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            children: [
              TextSpan(text: 'DREAM', style: TextStyle(color: AppTheme.primaryGreen)),
              TextSpan(text: 'EATS', style: TextStyle(color: Color(0xFFFFB300))),
            ],
          ),
        ),
      ],
    );
  }
}

