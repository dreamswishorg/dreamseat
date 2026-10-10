import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../merchant_kit.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header / Brand ──
            _buildHeader(context),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // ── Quick Actions (when expanded) ──
            if (!isCollapsed && (onNewListing != null || onVerifyCode != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    if (onNewListing != null)
                      Expanded(
                        child: Material(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: onNewListing,
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'New Pack',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onNewListing != null && onVerifyCode != null)
                      const SizedBox(width: 8),
                    if (onVerifyCode != null)
                      Material(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: onVerifyCode,
                          borderRadius: BorderRadius.circular(10),
                          child: const Tooltip(
                            message: 'Verify pickup code',
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppTheme.charcoal),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Navigation Sections ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSection(
                      context,
                      title: 'OPERATIONS',
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
                    const SizedBox(height: 10),
                    _buildSection(
                      context,
                      title: 'FINANCES & GROWTH',
                      items: [
                        _SidebarItem(
                          tab: MTab.financials,
                          icon: Icons.account_balance_wallet_outlined,
                          activeIcon: Icons.account_balance_wallet_rounded,
                          label: 'Payouts & Ledger',
                        ),
                        _SidebarItem(
                          tab: MTab.impact,
                          icon: Icons.eco_outlined,
                          activeIcon: Icons.eco_rounded,
                          label: 'Impact & Rescues',
                        ),
                        _SidebarItem(
                          tab: MTab.reviews,
                          icon: Icons.star_outline_rounded,
                          activeIcon: Icons.star_rounded,
                          label: 'Store Reviews',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(
                      context,
                      title: 'STOREFRONT',
                      items: [
                        _SidebarItem(
                          tab: MTab.shop,
                          icon: Icons.storefront_outlined,
                          activeIcon: Icons.storefront_rounded,
                          label: 'Shop Profile',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Footer ──
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            if (onToggleCollapse != null)
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Expand sidebar',
                onPressed: onToggleCollapse,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                        children: [
                          TextSpan(text: 'Dream', style: TextStyle(color: AppTheme.primaryGreen)),
                          TextSpan(text: 'Eats', style: TextStyle(color: Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                    const Text(
                      'Merchant Portal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleCollapse != null)
                IconButton(
                  icon: const Icon(Icons.menu_open_rounded, size: 20, color: Color(0xFF64748B)),
                  tooltip: 'Collapse sidebar',
                  onPressed: onToggleCollapse,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Business Badge Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: business.isApproved ? AppTheme.primaryGreen : Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (business.isApproved ? AppTheme.primaryGreen : Colors.amber).withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: business.isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    business.isApproved ? 'LIVE' : 'REVIEW',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: business.isApproved ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<_SidebarItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
        ...items.map((item) => _buildItem(context, item)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, _SidebarItem item) {
    final isSelected = currentTab == item.tab;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          child: Material(
            color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              hoverColor: const Color(0xFFF1F5F9),
              onTap: () => onSelectTab(item.tab),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 21,
                      color: isSelected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${item.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF1F5F9),
          onTap: () => onSelectTab(item.tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 19,
                  color: isSelected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF15803D) : const Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (item.badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
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
    if (isCollapsed) {
      return const SizedBox(height: 12);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  business.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  business.rating > 0 ? '${business.rating.toStringAsFixed(1)} ★ rating' : 'New store',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
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
