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

    // 1. CORE OPERATIONS
    final coreItems = <_SidebarNavItem>[];
    if (user?.hasPrivilege('analytics') ?? false) {
      coreItems.add(_SidebarNavItem(0, Icons.insights_rounded, "Analytics Hub", currentTab == 0));
    }
    if (user?.hasPrivilege('approvals') ?? false) {
      coreItems.add(_SidebarNavItem(1, Icons.verified_user_rounded, "Merchant Approvals", currentTab == 1, badge: approvals > 0 ? "$approvals" : null));
    }
    if (user?.hasPrivilege('directory') ?? false) {
      coreItems.add(_SidebarNavItem(2, Icons.people_alt_rounded, "User Directory", currentTab == 2));
    }
    if (user != null) {
      coreItems.add(_SidebarNavItem(9, Icons.category_rounded, "Categories & Photos", currentTab == 9));
    }

    // 2. FINANCIALS
    final financialItems = <_SidebarNavItem>[];
    if (user?.hasPrivilege('ledger') ?? false) {
      financialItems.add(_SidebarNavItem(3, Icons.account_balance_wallet_rounded, "System Ledger", currentTab == 3));
    }
    if (user?.hasPrivilege('vouchers') ?? false) {
      financialItems.add(_SidebarNavItem(5, Icons.confirmation_number_rounded, "Promo Vouchers", currentTab == 5));
    }

    // 3. GOVERNANCE
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

    // 4. SYSTEM
    final systemItems = <_SidebarNavItem>[];
    if (user != null) {
      systemItems.add(_SidebarNavItem(10, Icons.history_edu_rounded, "Audit Trail", currentTab == 10));
    }
    if (user?.hasPrivilege('config') ?? false) {
      systemItems.add(_SidebarNavItem(8, Icons.settings_suggest_rounded, "Infrastructure Config", currentTab == 8));
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Sleek single brand block (No duplicate HQ header, No customer app button)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DreamEats",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.charcoal,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                                    : AppTheme.lightGreenBg,
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
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 10),
          // Navigation sections
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (coreItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "CORE OPERATIONS", coreItems),
                    const SizedBox(height: 14),
                  ],
                  if (financialItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "FINANCIALS", financialItems),
                    const SizedBox(height: 14),
                  ],
                  if (governanceItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "GOVERNANCE", governanceItems),
                    const SizedBox(height: 14),
                  ],
                  if (systemItems.isNotEmpty) ...[
                    _buildSidebarSection(context, "SYSTEM", systemItems),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          _buildSidebarFooter(context),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(BuildContext context, String title, List<_SidebarNavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _item(context, item)),
      ],
    );
  }

  Widget _item(BuildContext context, _SidebarNavItem nav) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTab(nav.index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF1F5F9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
            decoration: BoxDecoration(
              gradient: nav.isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF166534), Color(0xFF14532D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: nav.isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF166534).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  nav.icon,
                  size: 18,
                  color: nav.isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nav.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: nav.isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: nav.isSelected ? Colors.white : const Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (nav.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: nav.isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      nav.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
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

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            _pulseRow(context, "Database", true),
            const SizedBox(height: 6),
            _pulseRow(context, "Services", true),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shield_rounded, size: 13, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                const Text(
                  "SECURE ENVIRONMENT",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseRow(BuildContext context, String label, bool ok) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ok ? AppTheme.primaryGreen : AppTheme.errorRed,
            shape: BoxShape.circle,
            boxShadow: [
              if (ok)
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const Spacer(),
        Text(
          ok ? "ONLINE" : "OFFLINE",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: ok ? AppTheme.primaryGreen : AppTheme.errorRed,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
