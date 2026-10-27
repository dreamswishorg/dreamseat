import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';

class AdminSidebar extends ConsumerWidget {
  final int currentTab;
  final int approvals;
  final int disputes;
  final Function(int) onTab;

  const AdminSidebar({
    required this.currentTab,
    required this.approvals,
    required this.disputes,
    required this.onTab,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    final isSuperAdmin = user?.role == 'super_admin';
    final isDark = context.isDark;

    // 1. OPERATIONS
    final operationsItems = <_SidebarNavItem>[];
    if (user?.hasPrivilege('analytics') ?? false) {
      operationsItems.add(_SidebarNavItem(0, Icons.grid_view_rounded, "Overview", currentTab == 0));
    }
    if (user?.hasPrivilege('approvals') ?? false) {
      operationsItems.add(_SidebarNavItem(1, Icons.verified_user_rounded, "Merchant Approvals", currentTab == 1, badge: approvals > 0 ? "$approvals" : null));
    }
    if (user?.hasPrivilege('directory') ?? false) {
      operationsItems.add(_SidebarNavItem(2, Icons.people_alt_rounded, "User Directory", currentTab == 2));
    }
    if (user != null) {
      operationsItems.add(_SidebarNavItem(9, Icons.category_rounded, "Categories & Photos", currentTab == 9));
    }

    // 2. FINANCES & GROWTH
    final financesItems = <_SidebarNavItem>[];
    if (user?.hasPrivilege('ledger') ?? false) {
      financesItems.add(_SidebarNavItem(3, Icons.account_balance_wallet_rounded, "Payouts & Ledger", currentTab == 3));
    }
    if (user?.hasPrivilege('vouchers') ?? false) {
      financesItems.add(_SidebarNavItem(5, Icons.confirmation_number_rounded, "Promo Vouchers", currentTab == 5));
    }

    // 3. GOVERNANCE & TRUST
    final governanceItems = <_SidebarNavItem>[];
    if (user?.hasPrivilege('disputes') ?? false) {
      governanceItems.add(_SidebarNavItem(4, Icons.gavel_rounded, "Dispute Center", currentTab == 4, badge: disputes > 0 ? "$disputes" : null));
    }
    if (user?.hasPrivilege('support') ?? false) {
      governanceItems.add(_SidebarNavItem(12, Icons.support_agent_rounded, "Support Desk", currentTab == 12));
    }
    if (user?.hasPrivilege('map') ?? false) {
      governanceItems.add(_SidebarNavItem(6, Icons.map_rounded, "Operational Map", currentTab == 6));
    }
    if (user?.hasPrivilege('broadcasts') ?? false) {
      governanceItems.add(_SidebarNavItem(7, Icons.campaign_rounded, "Global Broadcasts", currentTab == 7));
    }

    // 4. SYSTEM & CONFIG
    final systemItems = <_SidebarNavItem>[];
    // Audit Trail is kept in database but hidden from Super Admin navigation per request
    if (user?.hasPrivilege('config') ?? false) {
      systemItems.add(_SidebarNavItem(8, Icons.settings_suggest_rounded, "Infrastructure Config", currentTab == 8));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Brand Header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DreamEats",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Admin Console",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.mutedGrey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSuperAdmin
                                    ? AppTheme.errorRed.withValues(alpha: 0.1)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSuperAdmin ? "SUPER" : "OPS",
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action Row (matches merchant sidebar top button) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        // Quick switch to Broadcasts or Approvals
                        if (approvals > 0) {
                          onTab(1); // Approvals
                        } else {
                          onTab(7); // Broadcasts
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              approvals > 0 ? "Review ($approvals)" : "+ Broadcast",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),

          // ── Navigation Sections ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (operationsItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "OPERATIONS", operationsItems),
                    const SizedBox(height: 12),
                  ],
                  if (financesItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "FINANCES & GROWTH", financesItems),
                    const SizedBox(height: 12),
                  ],
                  if (governanceItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "GOVERNANCE & TRUST", governanceItems),
                    const SizedBox(height: 12),
                  ],
                  if (systemItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "SYSTEM & CONFIG", systemItems),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          _buildSidebarFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(BuildContext context, String title, List<_SidebarNavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
        ),
        ...items.map((item) => _item(context, item)),
      ],
    );
  }

  Widget _item(BuildContext context, _SidebarNavItem nav) {
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTab(nav.index),
          borderRadius: BorderRadius.circular(14),
          hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              // Active styling matches Shop Profile pill in screenshot
              color: nav.isSelected
                  ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE8F5E9))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: nav.isSelected
                  ? Border.all(
                      color: isDark ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFC8E6C9),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  nav.icon,
                  size: 19,
                  color: nav.isSelected
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF1B5E20))
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nav.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: nav.isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: nav.isSelected
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF1B5E20))
                          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (nav.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      nav.badge!,
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

  Widget _buildSidebarFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "SYSTEM ACTIVE",
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Icon(Icons.shield_rounded, size: 14, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final String? badge;

  _SidebarNavItem(this.index, this.icon, this.label, this.isSelected, {this.badge});
}
