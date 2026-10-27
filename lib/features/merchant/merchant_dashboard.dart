import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../common/help_support_screen.dart';
import 'merchant_kit.dart';
import 'merchant_profile_screen.dart';
import 'tabs/merchant_financials_tab.dart';
import 'tabs/merchant_home_tab.dart';
import 'tabs/merchant_impact_tab.dart';
import 'tabs/merchant_listings_tab.dart';
import 'tabs/merchant_orders_tab.dart';
import 'tabs/merchant_reviews_tab.dart';
import 'tabs/merchant_verify_tab.dart';
import 'theme/merchant_theme.dart';
import 'widgets/merchant_sidebar.dart';

/// All available destinations in the merchant portal.
const List<MTab> kAllMerchantTabs = [
  MTab.home,
  MTab.orders,
  MTab.listings,
  MTab.verify,
  MTab.financials,
  MTab.impact,
  MTab.reviews,
  MTab.shop,
];

/// Destinations surfaced in mobile phone bottom navigation.
const List<MTab> kPhoneBottomTabs = [
  MTab.home,
  MTab.orders,
  MTab.listings,
  MTab.verify,
  MTab.shop,
];

/// Responsive shell for the merchant portal:
/// - Desktop / PC (width >= 850): Dedicated executive sidebar with categorized navigation & header command bar.
/// - Tablet (width 600 - 850): Adaptive collapsible rail / slide-out drawer matching desktop aesthetics.
/// - Mobile (< 600): Floating bottom bar with quick drawer access to all portal capabilities.
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
      MerchantFinancialsTab(business: business),
      MerchantImpactTab(business: business),
      MerchantReviewsTab(business: business),
      MerchantProfileScreen(business: business),
    ];

    const phoneNavItems = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Listings'),
      (Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Verify'),
      (Icons.storefront_outlined, Icons.storefront_rounded, 'Shop'),
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 850;
    final isPhone = screenWidth < 600;

    final selectedIndex = kAllMerchantTabs.indexOf(_tab).clamp(0, kAllMerchantTabs.length - 1);
    final phoneSelectedIndex = kPhoneBottomTabs.indexOf(_tab);

    // Only the visible tab is built. Building all eight up front (IndexedStack)
    // laid out every screen on each rebuild and made taps feel dead on phones.
    if (_composeListing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _composeListing) setState(() => _composeListing = false);
      });
    }

    final body = Column(
      children: [
        _TopBar(
          business: business,
          tab: _tab,
          onProfile: () => _go(tab: MTab.shop),
          onNewListing: () => _go(tab: MTab.listings, compose: true),
          onVerifyCode: () => _go(tab: MTab.verify),
          isWide: isWide,
        ),
        Expanded(
          child: IndexedStack(
            index: selectedIndex,
            children: tabs,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: MerchantTheme.canvasBg,
      drawer: !isWide
          ? Drawer(
              width: 240,
              backgroundColor: Colors.white,
              elevation: 12,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
              ),
              child: MerchantSidebar(
                currentTab: _tab,
                onSelectTab: (tab) {
                  Navigator.of(context).pop();
                  _go(tab: tab);
                },
                business: business,
                openOrdersCount: openCount,
                isCollapsed: false,
                onNewListing: () {
                  Navigator.of(context).pop();
                  _go(tab: MTab.listings, compose: true);
                },
                onVerifyCode: () {
                  Navigator.of(context).pop();
                  _go(tab: MTab.verify);
                },
              ),
            )
          : null,
      bottomNavigationBar: isPhone
          ? _BottomNav(
              selectedIndex: phoneSelectedIndex,
              orderBadge: openCount,
              items: phoneNavItems,
              onTap: (idx) {
                _go(tab: kPhoneBottomTabs[idx]);
              },
            )
          : null,
      body: isWide
          ? Row(
              children: [
                MerchantSidebar(
                  currentTab: _tab,
                  onSelectTab: (tab) => _go(tab: tab),
                  business: business,
                  openOrdersCount: openCount,
                  isCollapsed: _navCollapsed,
                  onToggleCollapse: () => setState(() => _navCollapsed = !_navCollapsed),
                  onNewListing: () => _go(tab: MTab.listings, compose: true),
                  onVerifyCode: () => _go(tab: MTab.verify),
                ),
                Expanded(child: body),
              ],
            )
          : SafeArea(
              bottom: false,
              child: body,
            ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final BusinessProfile business;
  final MTab tab;
  final VoidCallback onProfile;
  final VoidCallback onNewListing;
  final VoidCallback onVerifyCode;
  final bool isWide;

  const _TopBar({
    required this.business,
    required this.tab,
    required this.onProfile,
    required this.onNewListing,
    required this.onVerifyCode,
    required this.isWide,
  });

  (String, String) _getMeta() {
    switch (tab) {
      case MTab.home:
        return ('Overview', 'Operations hub & real-time store pulse');
      case MTab.orders:
        return ('Live Orders', 'Kitchen fulfilment & dispatch queue');
      case MTab.listings:
        return ('Surplus Inventory', 'Manage surplus packs & stock levels');
      case MTab.verify:
        return ('Verify Pickup', 'Validate customer rescue codes & hand over packs');
      case MTab.financials:
        return ('Payouts & Statements', 'Revenue settlements & commission statements');
      case MTab.impact:
        return ('Rescue & Impact', 'Track food waste prevented & environmental savings');
      case MTab.reviews:
        return ('Customer Reviews', 'Ratings & verified rescuer feedback');
      case MTab.shop:
        return ('Shop Profile', 'Storefront details, hours & compliance');
      default:
        return ('Overview', 'Operations command center');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuCtrl = MenuController();
    final user = ref.watch(appStateProvider).currentUser;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'M';
    final (title, subtitle) = _getMeta();

    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 12, isWide ? 14 : 10, isWide ? 20 : 10, isWide ? 14 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          // Drawer toggle button when on mobile / narrow tablet
          if (!isWide) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: MK.ink, size: 23),
                tooltip: 'Open menu',
                visualDensity: VisualDensity.compact,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Title & Subtitle or Brand
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isWide ? 21 : 17.5,
                          fontWeight: FontWeight.w800,
                          color: MK.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          MToast.ok(context, 'Storefront is active & discoverable on customer map');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreenBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'STORE ONLINE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isWide ? subtitle : business.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Desktop Command Bar Actions
          if (isWide) ...[
            MButton(
              'Verify Code',
              icon: Icons.qr_code_scanner_rounded,
              kind: MKind.ghost,
              height: 38,
              onPressed: onVerifyCode,
            ),
            const SizedBox(width: 8),
            MButton(
              'New Pack',
              icon: Icons.add_rounded,
              height: 38,
              onPressed: onNewListing,
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 6),
          ],

          // Notification Bell Anchor
          buildNotificationMenuAnchor(context, ref, iconColor: MK.ink),

          // User Profile Menu Anchor
          MenuAnchor(
            controller: menuCtrl,
            alignmentOffset: const Offset(-190, 8),
            style: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              elevation: WidgetStateProperty.all(14),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            builder: (context, controller, child) => MPressable(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Merchant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MK.ink),
                          ),
                          Text(
                            business.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.mutedGrey, size: 22),
                    ],
                  ],
                ),
              ),
            ),
            menuChildren: [
              SizedBox(
                width: 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Merchant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: MK.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? MK.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? MK.ink),
                ),
              ),
            ],
          ),
        ),
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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = i == selectedIndex;
                final item = items[i];
                final showBadge = i == kPhoneBottomTabs.indexOf(MTab.orders) && orderBadge > 0;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    splashColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                selected ? item.$2 : item.$1,
                                size: 22,
                                color: selected ? AppTheme.primaryGreen : const Color(0xFF64748B),
                              ),
                              if (showBadge)
                                Positioned(
                                  top: -3,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      '$orderBadge',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$3,
                            maxLines: 1,
                            overflow: selected ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? AppTheme.primaryGreen : const Color(0xFF64748B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
