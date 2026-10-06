import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../common/help_support_screen.dart';
import 'settings/admin_profile_screen.dart';
import '../customer/customer_navigation.dart';

// Tabs
import 'tabs/analytics_tab.dart';
import 'tabs/approvals_tab.dart';
import 'tabs/accounts_tab.dart';
import 'tabs/ledger_tab.dart';
import 'tabs/disputes_tab.dart';
import 'tabs/vouchers_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/broadcasts_tab.dart';
import 'tabs/config_tab.dart';
import 'tabs/audit_tab.dart';
import 'tabs/pulse_tab.dart';
import 'tabs/support_tab.dart';
import 'widgets/admin_components.dart';
import 'widgets/admin_sidebar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();

  final Map<int, String> _tabTitles = {
    0: "Insights & Analytics",
    1: "Merchant Approvals",
    2: "User Directory",
    3: "Financial Ledger",
    4: "Dispute Center",
    5: "Promo Vouchers",
    6: "Operational Map",
    7: "Global Broadcasts",
    8: "Infrastructure Config",
    10: "Security Audit Trail",
    11: "Real-time Activity",
    12: "Customer Support Desk",
  };

  void _handleSearch(String query) {
    if (query.isEmpty) return;

    final state = ref.read(appStateProvider);

    if (state.businesses.any((b) => b.name.toLowerCase().contains(query.toLowerCase()))) {
      setState(() => _currentTab = 1);
      _searchController.clear();
      return;
    }

    if (state.users.any((u) => u.name.toLowerCase().contains(query.toLowerCase()) || u.email.toLowerCase().contains(query.toLowerCase()))) {
      setState(() => _currentTab = 2);
      _searchController.clear();
      return;
    }

    if (state.orders.any((o) => o.id.toLowerCase().contains(query.toLowerCase()))) {
      setState(() => _currentTab = 3);
      _searchController.clear();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No direct matches for '$query'."), backgroundColor: AppTheme.charcoal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final user = state.currentUser;
    final isSuperAdmin = user?.role == 'super_admin';
    
    // Calculate allowed tabs based on permissions
    final allowedTabs = <int>[];
    if (user?.hasPrivilege('analytics') ?? false) allowedTabs.add(0);
    if (user?.hasPrivilege('approvals') ?? false) allowedTabs.add(1);
    if (user?.hasPrivilege('directory') ?? false) allowedTabs.add(2);
    if (user?.hasPrivilege('ledger') ?? false) allowedTabs.add(3);
    if (user?.hasPrivilege('disputes') ?? false) allowedTabs.add(4);
    if (user?.hasPrivilege('vouchers') ?? false) allowedTabs.add(5);
    if (user?.hasPrivilege('map') ?? false) allowedTabs.add(6);
    if (user?.hasPrivilege('broadcasts') ?? false) allowedTabs.add(7);
    if (user?.hasPrivilege('config') ?? false) allowedTabs.add(8);
    if (user != null) allowedTabs.add(10);
    if (user?.hasPrivilege('pulse') ?? false) allowedTabs.add(11);
    if (user?.hasPrivilege('support') ?? false) allowedTabs.add(12);

    if (allowedTabs.isNotEmpty && !allowedTabs.contains(_currentTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentTab = allowedTabs.first);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1100;

    final pendingApprovals = state.businesses.where((b) => !b.isApproved).length;
    final openDisputes = state.disputes.where((d) => d.status == 'open').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: !isWide
          ? Drawer(
              width: 280,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: AdminSidebar(
                currentTab: _currentTab,
                approvals: pendingApprovals,
                disputes: openDisputes,
                onTab: (i) {
                  setState(() => _currentTab = i);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      appBar: AppBar(
        toolbarHeight: isWide ? 76 : 60,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            height: 1,
          ),
        ),
        title: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset('assets/images/logo.jpg', height: 22, width: 22, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSuperAdmin
                                  ? AppTheme.errorRed.withValues(alpha: 0.08)
                                  : AppTheme.primaryGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSuperAdmin ? "SUPERADMIN" : "OPERATIONS",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppTheme.mutedGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_tabTitles[_currentTab] ?? "Overview").toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppTheme.mutedGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "DreamEats HQ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.charcoal,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 280,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.mutedGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _handleSearch,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.charcoal,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search records...",
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : AppTheme.mutedGrey,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            "⌘K",
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppTheme.mutedGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              )
            : Text(
                _tabTitles[_currentTab] ?? "DreamEats HQ",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.charcoal,
                  fontSize: 16.5,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (isWide) ...[
            _HeaderAction(
              count: pendingApprovals,
              icon: Icons.how_to_reg_rounded,
              color: AppTheme.warningOrange,
              onTap: () => setState(() => _currentTab = 1),
            ),
            const SizedBox(width: 8),
            _HeaderAction(
              count: openDisputes,
              icon: Icons.gavel_rounded,
              color: AppTheme.errorRed,
              onTap: () => setState(() => _currentTab = 4),
            ),
            VerticalDivider(
              width: 32,
              indent: 20,
              endIndent: 20,
              color: const Color(0xFFE2E8F0),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerNavigation()),
                );
              },
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: const Text("Customer App"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
          ],

          PopupMenuButton<int>(
            offset: const Offset(0, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 16,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            onSelected: (v) {
              if (v == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              if (v == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              if (v == 2) _onLogout();
              if (v == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerNavigation()));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                            radius: 20,
                            child: Text(
                              state.currentUser?.name.isNotEmpty == true ? state.currentUser!.name[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.currentUser?.name ?? 'Admin Profile',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppTheme.charcoal,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.currentUser?.email ?? 'admin@dreameats.com',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.mutedGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSuperAdmin
                                    ? AppTheme.errorRed.withValues(alpha: 0.12)
                                    : AppTheme.primaryGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSuperAdmin
                                      ? AppTheme.errorRed.withValues(alpha: 0.3)
                                      : AppTheme.primaryGreen.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isSuperAdmin ? "👑 SUPER ADMIN" : "🛡️ STAFF ADMIN",
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 0,
                child: PopupItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  color: Color(0xFF2563EB),
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: PopupItem(
                  icon: Icons.storefront_rounded,
                  label: "Customer App",
                  color: AppTheme.primaryGreen,
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: PopupItem(
                  icon: Icons.headset_mic_outlined,
                  label: "Support",
                  color: AppTheme.warningOrange,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 2,
                child: PopupItem(
                  icon: Icons.logout_rounded,
                  label: "Logout",
                  color: AppTheme.errorRed,
                ),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.only(right: isWide ? 24 : 14),
              child: isWide
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                                radius: 14,
                                child: Text(
                                  state.currentUser?.name[0].toUpperCase() ?? 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              state.currentUser?.name ?? 'Admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.95) : AppTheme.charcoal,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.5) : AppTheme.mutedGrey,
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                          radius: 17,
                          child: Text(
                            state.currentUser?.name[0].toUpperCase() ?? 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: AdminSidebar(
                currentTab: _currentTab,
                approvals: pendingApprovals,
                disputes: openDisputes,
                onTab: (i) => setState(() => _currentTab = i),
              ),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                    child: _buildCurrentTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onLogout() async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(appStateProvider.notifier).signOut();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // Returns the widget for the currently selected tab.
  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return const TabAnalytics();
      case 1:
        return const TabApprovals();
      case 2:
        return const TabAccounts();
      case 3:
        return const TabLedger();
      case 4:
        return const TabDisputes();
      case 5:
        return const TabVouchers();
      case 6:
        return const TabMap();
      case 7:
        return const TabBroadcasts();
      case 8:
        return const TabConfig();
      case 10:
        return const TabAudit();
      case 11:
        return const TabPulse();
      case 12:
        return const TabSupport();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

}


class _HeaderAction extends StatelessWidget {
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderAction({required this.count, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: count > 0 
                ? color.withValues(alpha: 0.08) 
                : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: count > 0 
                  ? color.withValues(alpha: 0.2) 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon, 
                color: count > 0 
                    ? color 
                    : (isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.mutedGrey), 
                size: 20,
              ),
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color, 
                      shape: BoxShape.circle, 
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white, 
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        "$count", 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 8, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
