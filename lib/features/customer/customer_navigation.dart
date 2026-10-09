import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../providers/app_state.dart';
import 'customer_home.dart';
import 'map_explore_screen.dart';
import 'impact_screen.dart';
import 'basket_screen.dart';
import 'customer_profile.dart';

import '../admin/admin_dashboard.dart';

class CustomerNavigation extends ConsumerStatefulWidget {
  const CustomerNavigation({super.key});

  @override
  ConsumerState<CustomerNavigation> createState() =>
      _CustomerNavigationState();
}

class _CustomerNavigationState extends ConsumerState<CustomerNavigation> {
  bool _isSideNavCollapsed = false;
  final Set<int> _loadedTabs = {0};

  void _onTabSelected(int idx, double screenWidth) {
    if (!_loadedTabs.contains(idx)) {
      setState(() => _loadedTabs.add(idx));
    }
    ref.read(customerTabProvider.notifier).state = idx;
    if (screenWidth < 1150) {
      setState(() => _isSideNavCollapsed = true);
    }
  }

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const MapExploreScreen(),
    const ImpactScreen(),
    const BasketScreen(),
    const CustomerProfileScreen(),
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

    if (!_loadedTabs.contains(currentIndex)) {
      _loadedTabs.add(currentIndex);
    }

    final tabs = IndexedStack(
      index: currentIndex,
      children: List.generate(_screens.length, (i) {
        if (_loadedTabs.contains(i)) {
          return _screens[i];
        }
        return const SizedBox.shrink();
      }),
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
                  onSelect: (i) => _onTabSelected(i, screenWidth),
                  header: _buildSideNavBrand(),
                  items: const [
                    SideNavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
                    SideNavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map Explore'),
                    SideNavItem(icon: Icons.eco_outlined, activeIcon: Icons.eco_rounded, label: 'Impact'),
                    SideNavItem(icon: Icons.shopping_basket_outlined, activeIcon: Icons.shopping_basket, label: 'Basket'),
                    SideNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person, label: 'Profile'),
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
      floatingActionButton: null,
      bottomNavigationBar: wide ? null : _buildFloatingPillNavBar(context, currentIndex, isDark, basketCount),
    );
  }

  Widget _buildFloatingPillNavBar(BuildContext context, int currentIndex, bool isDark, int basketCount) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final items = const [
      _PillNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _PillNavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Map'),
      _PillNavItem(icon: Icons.eco_outlined, activeIcon: Icons.eco_rounded, label: 'Impact'),
      _PillNavItem(icon: Icons.shopping_basket_outlined, activeIcon: Icons.shopping_basket_rounded, label: 'Basket'),
      _PillNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final isSelected = currentIndex == idx;

              if (isSelected) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.activeIcon, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final iconWidget = Icon(
                item.icon,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 22,
              );

              return IconButton(
                icon: (idx == 3 && basketCount > 0)
                    ? Badge(
                        label: Text('$basketCount'),
                        backgroundColor: const Color(0xFFEF4444),
                        child: iconWidget,
                      )
                    : iconWidget,
                onPressed: () => _onTabSelected(idx, screenWidth),
              );
            }),
          ),
        ),
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

class _PillNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _PillNavItem({required this.icon, required this.activeIcon, required this.label});
}

