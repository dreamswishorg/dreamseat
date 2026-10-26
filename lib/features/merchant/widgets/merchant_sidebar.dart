import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../merchant_kit.dart';

/// Merchant navigation rail, built on the customer portal's side nav language:
/// white surface, hairline edge, forest-green tinted active pill.
class MerchantSidebar extends StatelessWidget {
  final MTab currentTab;
  final ValueChanged<MTab> onSelectTab;
  final BusinessProfile business;
  final int openOrdersCount;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onNewListing;
  final VoidCallback? onVerifyCode;

  const MerchantSidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.business,
    this.openOrdersCount = 0,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onNewListing,
    this.onVerifyCode,
  });

  static const Color _accent = AppTheme.primaryGreen;
  static const Color _muted = AppTheme.mutedGrey;
  static const Color _hairline = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 74.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _hairline, width: 1)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),

            const Divider(height: 1, color: _hairline),

            if (!isCollapsed && (onNewListing != null || onVerifyCode != null))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    if (onNewListing != null)
                      Expanded(
                        child: Material(
                          color: _accent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onNewListing,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: Colors.white, size: 17),
                                  SizedBox(width: 6),
                                  Text(
                                    'New Pack',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onNewListing != null && onVerifyCode != null) const SizedBox(width: 8),
                    if (onVerifyCode != null)
                      Material(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onVerifyCode,
                          borderRadius: BorderRadius.circular(12),
                          child: const Tooltip(
                            message: 'Verify pickup code or scan QR',
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.qr_code_scanner_rounded, size: 18, color: _accent),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(
                      title: 'Operations',
                      items: [
                        _SidebarItem(
                          tab: MTab.home,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                          label: 'Overview',
                        ),
                        _SidebarItem(
                          tab: MTab.orders,
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long_rounded,
                          label: 'Live Orders',
                          badgeCount: openOrdersCount,
                        ),
                        _SidebarItem(
                          tab: MTab.listings,
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2_rounded,
                          label: 'Surplus Inventory',
                        ),
                        _SidebarItem(
                          tab: MTab.verify,
                          icon: Icons.qr_code_scanner_outlined,
                          activeIcon: Icons.qr_code_scanner_rounded,
                          label: 'Verify Pickup',
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Finances & Growth',
                      items: [
                        _SidebarItem(
                          tab: MTab.financials,
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet_rounded,
                          label: 'Payouts',
                        ),
                        _SidebarItem(
                          tab: MTab.impact,
                          icon: Icons.eco_outlined,
                          activeIcon: Icons.eco_rounded,
                          label: 'Impact',
                        ),
                        _SidebarItem(
                          tab: MTab.reviews,
                          icon: Icons.star_outline_rounded,
                          activeIcon: Icons.star_rounded,
                          label: 'Reviews',
                        ),
                      ],
                    ),
                    _buildSection(
                      title: 'Storefront',
                      items: [
                        _SidebarItem(
                          tab: MTab.shop,
                          icon: Icons.storefront_outlined,
                          activeIcon: Icons.storefront_rounded,
                          label: 'Shop Profile',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          children: [
            const _BrandMark(size: 38),
            const SizedBox(height: 8),
            if (onToggleCollapse != null)
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22, color: _muted),
                tooltip: 'Expand sidebar',
                onPressed: onToggleCollapse,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _BrandLockup()),
              if (onToggleCollapse != null)
                IconButton(
                  icon: const Icon(Icons.menu_open_rounded, size: 22, color: _muted),
                  tooltip: 'Collapse sidebar',
                  onPressed: onToggleCollapse,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _BusinessBadge(business: business),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<_SidebarItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _muted,
                letterSpacing: 1.1,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: _hairline),
          ),
        ...items.map(_buildItem),
      ],
    );
  }

  Widget _buildItem(_SidebarItem item) {
    final selected = currentTab == item.tab;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 6),
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          child: Material(
            color: selected ? _accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              hoverColor: _accent.withValues(alpha: 0.08),
              onTap: () => onSelectTab(item.tab),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 24,
                      color: selected ? _accent : _muted,
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        top: -2,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.badgeCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? _accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: _accent.withValues(alpha: 0.06),
          onTap: () => onSelectTab(item.tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 21,
                  color: selected ? _accent : _muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppTheme.charcoal : _muted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (item.badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (isCollapsed) return const SizedBox(height: 12);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _hairline))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.storefront_rounded, size: 17, color: _accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  business.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                ),
                Text(
                  business.rating > 0 ? '${business.rating.toStringAsFixed(1)} ★ rating' : 'Verified Merchant',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppTheme.lightGreenBg,
          borderRadius: BorderRadius.circular(size * 0.27),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.21),
          child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
        ),
      );
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const _BrandMark(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    children: [
                      TextSpan(text: 'DREAM', style: TextStyle(color: AppTheme.primaryGreen)),
                      TextSpan(text: 'EATS', style: TextStyle(color: Color(0xFFFFB300))),
                    ],
                  ),
                ),
                const Text(
                  'Merchant Portal',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedGrey,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _BusinessBadge extends StatelessWidget {
  final BusinessProfile business;
  const _BusinessBadge({required this.business});

  @override
  Widget build(BuildContext context) {
    final live = business.isApproved;
    final dot = live ? AppTheme.primaryGreen : AppTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: live ? AppTheme.lightGreenBg : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withValues(alpha: 0.40), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              business.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
            ),
          ),
          Text(
            live ? 'LIVE' : 'REVIEW',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.4, color: dot),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final MTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  _SidebarItem({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}
