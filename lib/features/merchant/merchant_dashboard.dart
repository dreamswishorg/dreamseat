import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui_utils.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../common/help_support_screen.dart';
import 'merchant_kit.dart';
import 'merchant_profile_screen.dart';
import 'tabs/merchant_home_tab.dart';
import 'tabs/merchant_listings_tab.dart';
import 'tabs/merchant_orders_tab.dart';
import 'tabs/merchant_verify_tab.dart';

/// Responsive shell for the merchant portal: left rail on wide screens,
/// floating bottom navigation on phones.
class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  MTab _tab = MTab.home;
  bool _navCollapsed = false;

  String? _ordersFilter;
  bool _composeListing = false;

  static const _openStatuses = {'reserved', 'preparing', 'ready', 'out_for_delivery'};

  void _go({MTab? tab, String? filter, bool compose = false}) {
    setState(() {
      if (tab != null) _tab = tab;
      _ordersFilter = filter;
      _composeListing = compose;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final business = notifier.getMerchantBusiness();

    if (business == null) {
      return _NoBusinessScreen(onRetry: notifier.refreshMerchantBusiness);
    }

    final openCount = state.orders
        .where((o) => o.businessId == business.id && _openStatuses.contains(o.status))
        .length;

    final tabs = <Widget>[
      MerchantHomeTab(business: business, navigate: _go),
      MerchantOrdersTab(business: business, initialFilter: _ordersFilter),
      MerchantListingsTab(business: business, composeNew: _composeListing),
      MerchantVerifyTab(business: business),
      MerchantProfileScreen(business: business),
    ];

    const navItems = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Listings'),
      (Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Verify'),
      (Icons.storefront_outlined, Icons.storefront_rounded, 'Shop'),
    ];

    final wide = useSideNav(context);
    final selectedIndex = kMerchantNavTabs.indexOf(_tab);

    final body = Column(
      children: [
        _TopBar(
          business: business,
          title: switch (_tab) {
            MTab.home => 'Overview',
            MTab.orders => 'Orders',
            MTab.listings => 'Listings',
            MTab.verify => 'Verify pickup',
            MTab.shop => 'Shop profile',
            _ => 'Overview',
          },
          onProfile: () => _go(tab: MTab.shop),
          brandTitle: wide,
        ),
        Expanded(child: IndexedStack(index: selectedIndex, children: tabs)),
      ],
    );

    return Scaffold(
      backgroundColor: MK.canvas,
      body: wide
          ? Row(
              children: [
                DesktopSideNav(
                  accentColor: MK.brand,
                  selectedIndex: selectedIndex,
                  isCollapsed: _navCollapsed,
                  onToggleCollapse: () => setState(() => _navCollapsed = !_navCollapsed),
                  onSelect: (idx) {
                    setState(() {
                      _tab = kMerchantNavTabs[idx];
                      _ordersFilter = null;
                      _composeListing = false;
                      if (MediaQuery.sizeOf(context).width < 1150) _navCollapsed = true;
                    });
                  },
                  header: _BrandChip(business: business),
                  items: [
                    for (var i = 0; i < navItems.length; i++)
                      SideNavItem(
                        icon: navItems[i].$1,
                        activeIcon: navItems[i].$2,
                        label: navItems[i].$3,
                        badgeCount: kMerchantNavTabs[i] == MTab.orders ? openCount : 0,
                      ),
                  ],
                ),
                Expanded(child: body),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(child: SafeArea(bottom: false, child: body)),
                _BottomNav(
                  selectedIndex: selectedIndex,
                  orderBadge: openCount,
                  items: navItems,
                  onTap: (idx) {
                    setState(() {
                      _tab = kMerchantNavTabs[idx];
                      _ordersFilter = null;
                      _composeListing = false;
                    });
                  },
                ),
              ],
            ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final BusinessProfile business;
  final String title;
  final VoidCallback onProfile;
  final bool brandTitle;

  const _TopBar({
    required this.business,
    required this.title,
    required this.onProfile,
    required this.brandTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuCtrl = MenuController();
    final user = ref.watch(appStateProvider).currentUser;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'M';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: MK.line))),
      child: Row(
        children: [
          if (brandTitle) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset('assets/images/logo.jpg', height: 30, width: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brandTitle ? title : business.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.4),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    MPill(
                      business.isApproved ? 'Verified' : 'In review',
                      color: business.isApproved ? MK.brand : MK.amber,
                      pulse: !business.isApproved,
                      fontSize: 8,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        brandTitle ? business.name : 'Merchant portal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: MK.inkSoft, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          buildNotificationMenuAnchor(context, ref, iconColor: MK.ink),
          MenuAnchor(
            controller: menuCtrl,
            alignmentOffset: const Offset(-190, 8),
            style: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              elevation: WidgetStateProperty.all(12),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: MK.line)),
              ),
            ),
            builder: (context, controller, child) => MPressable(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: MK.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: MK.brand.withValues(alpha: 0.24)),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(color: MK.brandDeep, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            menuChildren: [
              SizedBox(
                width: 230,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Merchant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: MK.ink),
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: MK.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: MK.line),
                    _MenuTile(
                      icon: Icons.storefront_rounded,
                      label: 'Shop profile',
                      onTap: () {
                        menuCtrl.close();
                        onProfile();
                      },
                    ),
                    _MenuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () {
                        menuCtrl.close();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                      },
                    ),
                    const Divider(height: 1, color: MK.line),
                    _MenuTile(
                      icon: Icons.logout_rounded,
                      label: 'Log out',
                      color: MK.danger,
                      onTap: () {
                        menuCtrl.close();
                        showModernLogoutConfirmDialog(context, () => ref.read(appStateProvider.notifier).signOut());
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? MK.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color ?? MK.ink),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BrandChip extends StatelessWidget {
  final BusinessProfile business;
  const _BrandChip({required this.business});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/images/logo.jpg', height: 26, width: 26, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  children: [
                    TextSpan(text: 'DREAM', style: TextStyle(color: MK.brand)),
                    TextSpan(text: 'EATS', style: TextStyle(color: MK.amber)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: MK.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_rounded, size: 12, color: MK.brand),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: MK.brandDeep),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final int orderBadge;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.orderBadge,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        left: 10,
        right: 10,
        bottom: 10,
        child: Material(
          elevation: 14,
          shadowColor: MK.ink.withValues(alpha: 0.16),
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: List.generate(items.length, (i) {
                  final selected = i == selectedIndex;
                  final item = items[i];
                  final showBadge = i == kMerchantNavTabs.indexOf(MTab.orders) && orderBadge > 0;
                  return Expanded(
                    child: MPressable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                width: 46,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: selected ? MK.brand.withValues(alpha: 0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  selected ? item.$2 : item.$1,
                                  size: 19,
                                  color: selected ? MK.brand : MK.inkSoft,
                                ),
                              ),
                              if (showBadge)
                                Positioned(
                                  top: -2,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    constraints: const BoxConstraints(minWidth: 16),
                                    decoration: BoxDecoration(
                                      color: MK.coral,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: Colors.white, width: 1.4),
                                    ),
                                    child: Text(
                                      '$orderBadge',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                              color: selected ? MK.brand : MK.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
}

class _NoBusinessScreen extends ConsumerStatefulWidget {
  final Future<BusinessProfile?> Function() onRetry;
  const _NoBusinessScreen({required this.onRetry});

  @override
  ConsumerState<_NoBusinessScreen> createState() => _NoBusinessScreenState();
}

class _NoBusinessScreenState extends ConsumerState<_NoBusinessScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _retry() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final biz = await widget.onRetry();
      if (!mounted) return;
      if (biz == null) {
        setState(() => _error = 'Still no shop linked to this account. Ask our team to finish your registration.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MK.canvas,
      body: Center(
        child: ResponsiveCenter(
          maxWidth: 420,
          child: _error == null
              ? const MFeedbackBlock(
                  icon: Icons.storefront_outlined,
                  title: 'No shop linked yet',
                  message:
                      'You are signed in, but DreamEats has not attached a business profile to this account yet.',
                  problem: true,
                )
              : MFeedbackBlock(
                  icon: Icons.cloud_off_rounded,
                  title: 'Shop not found',
                  message: _error!,
                  problem: true,
                ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Row(
          children: [
            Expanded(
              child: MButton(
                'Re-sync account',
                icon: Icons.refresh_rounded,
                loading: _busy,
                onPressed: _busy ? null : _retry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MButton(
                'Log out',
                kind: MKind.danger,
                icon: Icons.logout_rounded,
                onPressed: () => ref.read(appStateProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
