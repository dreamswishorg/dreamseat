import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import '../../core/ui_utils.dart';
import 'merchant_profile_screen.dart';
import '../common/help_support_screen.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  int _currentTab = 0;
  bool _isSideNavCollapsed = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(appStateProvider);
    final business = ref.read(appStateProvider.notifier).getMerchantBusiness();

    if (business == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 64, color: AppTheme.mutedGrey),
                const SizedBox(height: 16),
                const Text(
                  "No Business Profile Found",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your user account is logged in, but no business profile is linked yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13.5),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await ref.read(appStateProvider.notifier).refreshCurrentUser();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text("Refresh Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => showModernLogoutConfirmDialog(context, () => ref.read(appStateProvider.notifier).signOut()),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text("Log Out"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }

    final wide = useSideNav(context);
    const tabTitles = ['Dashboard', 'Inventory', 'Order Verification', 'Orders', 'Shop Profile'];

    final appBar = AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: wide ? Colors.white : null,
        shape: wide
            ? Border(bottom: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)))
            : null,
        systemOverlayStyle: wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        flexibleSpace: wide
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wide ? tabTitles[_currentTab] : business.name,
              style: TextStyle(
                color: wide ? AppTheme.charcoal : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: business.isApproved
                        ? const Color(0xFF10B981).withValues(alpha: 0.22)
                        : Colors.amber.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: business.isApproved
                          ? const Color(0xFF34D399)
                          : Colors.amber.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: business.isApproved
                              ? const Color(0xFF34D399)
                              : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        business.isApproved ? "Verified Merchant Portal" : "Pending Verification",
                        style: TextStyle(
                          fontSize: 10,
                          color: wide
                              ? (business.isApproved ? const Color(0xFF047857) : Colors.amber.shade900)
                              : (business.isApproved
                                  ? const Color(0xFFECFDF5)
                                  : Colors.amber.shade100),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          buildNotificationMenuAnchor(context, ref, iconColor: wide ? AppTheme.charcoal : Colors.white),
          Builder(
            builder: (context) {
              final menuCtrl = MenuController();
              return MenuAnchor(
                controller: menuCtrl,
                alignmentOffset: const Offset(-185, 8),
            style: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              elevation: WidgetStateProperty.all(12),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
                ),
              ),
            ),
            builder: (context, controller, child) {
              final user = ref.watch(appStateProvider).currentUser;
              final initials = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'M';
              return GestureDetector(
                onTap: () => controller.isOpen ? controller.close() : controller.open(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: wide ? AppTheme.lightGreenBg : Colors.white,
                      radius: 17,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            menuChildren: [
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Info Block (Compact)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F5B3C), Color(0xFF003D27)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (ref.watch(appStateProvider).currentUser?.name.isNotEmpty == true)
                                    ? ref.watch(appStateProvider).currentUser!.name[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: AppTheme.charcoal,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  ref.watch(appStateProvider).currentUser?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.mutedGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Rating & Category Compact Pill
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppTheme.primaryGreen, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                business.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${business.rating.toStringAsFixed(1)} ★",
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.08)),
                    const SizedBox(height: 4),

                    _buildMerchantMenuItem(
                      context,
                      controller: menuCtrl,
                      icon: Icons.storefront_rounded,
                      label: "Business Profile",
                      onTap: () => setState(() => _currentTab = 4),
                    ),
                    _buildMerchantMenuItem(
                      context,
                      controller: menuCtrl,
                      icon: Icons.help_outline_rounded,
                      label: "Help & Support",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      ),
                    ),

                    const SizedBox(height: 4),
                    Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.08)),
                    const SizedBox(height: 4),

                    _buildMerchantMenuItem(
                      context,
                      controller: menuCtrl,
                      icon: Icons.logout_rounded,
                      label: "Log Out",
                      color: AppTheme.errorRed,
                      onTap: () => showModernLogoutConfirmDialog(context, () => ref.read(appStateProvider.notifier).signOut()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
        ],
      );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: wide ? null : appBar,
      body: wide
          ? Row(
              children: [
                DesktopSideNav(
                  accentColor: AppTheme.primaryGreen,
                  selectedIndex: _currentTab,
                  isCollapsed: _isSideNavCollapsed,
                  onToggleCollapse: () => setState(() => _isSideNavCollapsed = !_isSideNavCollapsed),
                  onSelect: (idx) {
                    setState(() {
                      _currentTab = idx;
                      if (MediaQuery.of(context).size.width < 1150) {
                        _isSideNavCollapsed = true;
                      }
                    });
                  },
                  header: _buildMerchantSideNavBrand(business),
                  items: const [
                    SideNavItem(
                      icon: Icons.space_dashboard_outlined,
                      activeIcon: Icons.space_dashboard_rounded,
                      label: 'Dashboard',
                    ),
                    SideNavItem(
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2_rounded,
                      label: 'Inventory',
                    ),
                    SideNavItem(
                      icon: Icons.qr_code_scanner_rounded,
                      activeIcon: Icons.qr_code_scanner_rounded,
                      label: 'Verify',
                    ),
                    SideNavItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'Orders',
                    ),
                    SideNavItem(
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront_rounded,
                      label: 'Shop',
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: kToolbarHeight + 8, child: appBar),
                      Expanded(
                        child: IndexedStack(
                          index: _currentTab,
                          children: [
                            _MerchantAnalyticsTab(business: business),
                            _MerchantListingsTab(business: business),
                            _MerchantVerificationTab(business: business),
                            _MerchantOrdersTab(business: business),
                            MerchantProfileScreen(business: business),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: _currentTab,
              children: [
                _MerchantAnalyticsTab(business: business),
                _MerchantListingsTab(business: business),
                _MerchantVerificationTab(business: business),
                _MerchantOrdersTab(business: business),
                MerchantProfileScreen(business: business),
              ],
            ),
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentTab,
                onTap: (idx) => setState(() => _currentTab = idx),
                selectedItemColor: AppTheme.primaryGreen,
                unselectedItemColor: AppTheme.mutedGrey,
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.space_dashboard_outlined),
                    activeIcon: Icon(Icons.space_dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2_outlined),
                    activeIcon: Icon(Icons.inventory_2_rounded),
                    label: 'Inventory',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code_scanner_rounded),
                    activeIcon: Icon(Icons.qr_code_scanner_rounded),
                    label: 'Verify',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long_rounded),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront_rounded),
                    label: 'Shop',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMerchantSideNavBrand(BusinessProfile business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.jpg', height: 28, width: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                children: [
                  TextSpan(text: 'DREAM', style: TextStyle(color: AppTheme.primaryGreen)),
                  TextSpan(text: 'EATS', style: TextStyle(color: Color(0xFFFFB300))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.lightGreenBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, size: 13, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  business.name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= ANALYTICS TAB =================
class _MerchantAnalyticsTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  const _MerchantAnalyticsTab({required this.business});

  @override
  ConsumerState<_MerchantAnalyticsTab> createState() => _MerchantAnalyticsTabState();
}

class _MerchantAnalyticsTabState extends ConsumerState<_MerchantAnalyticsTab> {
  String _selectedChartType = 'Weekly';

  void _exportFinancialStatement(double gross, double net, double fee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Financial Statement exported for ${widget.business.name} (Gross: GHS ${gross.toStringAsFixed(2)})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareImpactCertificate(int meals, double co2, double water) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              widget.business.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal),
            ),
            const SizedBox(height: 4),
            const Text(
              "Verified Green Food Rescuer",
              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildImpactRow(Icons.restaurant_rounded, "Surplus Meals Saved", "$meals packs"),
                  const Divider(height: 16),
                  _buildImpactRow(Icons.co2_rounded, "CO2e Emissions Prevented", "${co2.toStringAsFixed(1)} kg"),
                  const Divider(height: 16),
                  _buildImpactRow(Icons.water_drop_outlined, "Freshwater Conserved", "${water.toStringAsFixed(0)} L"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Certificate saved to device!"), backgroundColor: AppTheme.primaryGreen),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text("Save Certificate Badge"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final allMerchantOrders = state.orders.where((o) => o.businessId == widget.business.id).toList();
    final collectedOrders = allMerchantOrders.where((o) => o.status == 'collected').toList();

    // Calculate real metrics from database orders
    final double revenueGenerated = collectedOrders.fold(0.0, (sum, item) => sum + item.price);
    final double netPayout = revenueGenerated * (1 - state.commissionRate);
    final double platformCommission = revenueGenerated * state.commissionRate;
    final double pendingPayout = collectedOrders.where((o) => o.payoutStatus != 'paid').fold(0.0, (sum, item) => sum + (item.price * (1 - state.commissionRate)));
    final double settledPayout = collectedOrders.where((o) => o.payoutStatus == 'paid').fold(0.0, (sum, item) => sum + (item.price * (1 - state.commissionRate)));

    // Real Environmental & Sustainability Stats
    final int mealsSaved = collectedOrders.length;
    final double wasteReducedKg = mealsSaved * 0.8;
    final double co2AvoidedKg = mealsSaved * 2.5;
    final double waterSavedLitres = mealsSaved * 800.0;

    final int totalOrders = allMerchantOrders.length;
    final double wasteReductionPercent = totalOrders > 0 ? (collectedOrders.length / totalOrders) * 100.0 : (collectedOrders.isNotEmpty ? 100.0 : 0.0);

    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 20, vertical: isTablet ? 12 : 16),
      child: ResponsiveCenter(
        maxWidth: 1100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Executive Financial Overview Card ───────────────────────────
            _buildExecutiveFinancialCard(
              revenueGenerated: revenueGenerated,
              netPayout: netPayout,
              platformCommission: platformCommission,
              pendingPayout: pendingPayout,
              settledPayout: settledPayout,
            ),
            const SizedBox(height: 18),

            // ── Quick Operations Metrics (4-stat grid) ──────────────────────
            if (MediaQuery.of(context).size.width >= 700)
              Row(
                children: [
                  _buildMetricCard("Meals Rescued", "$mealsSaved", Icons.restaurant_rounded, AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  _buildMetricCard("Orders Fulfilled", "${collectedOrders.length}", Icons.receipt_long_outlined, Colors.blueAccent),
                  const SizedBox(width: 12),
                  _buildMetricCard("Waste Diverted", "${wasteReducedKg.toStringAsFixed(1)} kg", Icons.eco_rounded, Colors.teal),
                  const SizedBox(width: 12),
                  _buildMetricCard("Store Rating", widget.business.rating > 0 ? "${widget.business.rating.toStringAsFixed(1)} ★" : "5.0 ★", Icons.star_rounded, AppTheme.goldAccent),
                ],
              )
            else ...[
              Row(
                children: [
                  _buildMetricCard("Meals Rescued", "$mealsSaved", Icons.restaurant_rounded, AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  _buildMetricCard("Orders Fulfilled", "${collectedOrders.length}", Icons.receipt_long_outlined, Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard("Waste Diverted", "${wasteReducedKg.toStringAsFixed(1)} kg", Icons.eco_rounded, Colors.teal),
                  const SizedBox(width: 10),
                  _buildMetricCard("Store Rating", widget.business.rating > 0 ? "${widget.business.rating.toStringAsFixed(1)} ★" : "5.0 ★", Icons.star_rounded, AppTheme.goldAccent),
                ],
              ),
            ],
            const SizedBox(height: 18),
            // ── Real-Time Order Fulfillment Pipeline ───────────────────────
            _buildOrderFulfillmentPipeline(allMerchantOrders),
            const SizedBox(height: 20),

            // ── Top Performing Surplus Items Ranking ────────────────────────
            _buildTopDealsRankingCard(
              state.deals.where((d) => d.businessId == widget.business.id).toList(),
              collectedOrders,
            ),
            const SizedBox(height: 20),

            // ── Sales Trends Bar Chart ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sales & Revenue Velocity",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.charcoal),
                ),
                _buildTimeFilter(),
              ],
            ),
            const SizedBox(height: 12),
            _buildSalesChart(collectedOrders),
            const SizedBox(height: 20),

            // ── Surplus Category Performance ───────────────────────────────
            _buildCategoryPerformanceCard(state.deals.where((d) => d.businessId == widget.business.id).toList()),
            const SizedBox(height: 20),

            // ── Environmental ESG Impact Hub ───────────────────────────────
            _buildEsgImpactCard(
              meals: mealsSaved,
              wasteKg: wasteReducedKg,
              co2Kg: co2AvoidedKg,
              waterL: waterSavedLitres,
              percent: wasteReductionPercent,
            ),
            const SizedBox(height: 20),

            // ── Customer Retention & Sentiment ─────────────────────────────
            _buildCustomerRetentionCard(allMerchantOrders),
            const SizedBox(height: 20),

            // ── Store Growth & Operational Insights ────────────────────────
            _buildSmartRecommendationsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveFinancialCard({
    required double revenueGenerated,
    required double netPayout,
    required double platformCommission,
    required double pendingPayout,
    required double settledPayout,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryGreen, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "MERCHANT SETTLEMENTS",
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _exportFinancialStatement(revenueGenerated, netPayout, platformCommission),
                icon: const Icon(Icons.file_download_outlined, size: 13, color: Colors.white),
                label: const Text("Export CSV", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "GHS ${revenueGenerated.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8),
          ),
          const Text(
            "Gross Rescue Revenue",
            style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildFinancialSubItem(
                  "Net Earnings (85%)",
                  "GHS ${netPayout.toStringAsFixed(2)}",
                  AppTheme.primaryGreen,
                  Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialSubItem(
                  "Settled to MoMo",
                  "GHS ${settledPayout.toStringAsFixed(2)}",
                  Colors.blueAccent.shade100,
                  Icons.check_circle_outline_rounded,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialSubItem(
                  "Pending Payout",
                  "GHS ${pendingPayout.toStringAsFixed(2)}",
                  Colors.amber.shade300,
                  Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSubItem(String title, String val, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      val,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal, letterSpacing: -0.3),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFulfillmentPipeline(List<Order> orders) {
    final total = orders.length;
    final ready = orders.where((o) => o.status == 'ready').length;
    final inPrep = orders.where((o) => o.status == 'pending' || o.status == 'confirmed').length;
    final completed = orders.where((o) => o.status == 'collected').length;
    final cancelled = orders.where((o) => o.status == 'cancelled').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.sync_alt_rounded, color: Colors.indigo, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text("Order Fulfillment Pipeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                child: Text("$total Total Orders", style: const TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPipelineStatusBox("Ready for Pickup", ready, total, AppTheme.primaryGreen, Icons.shopping_bag_outlined),
              const SizedBox(width: 8),
              _buildPipelineStatusBox("In Preparation", inPrep, total, Colors.blueAccent, Icons.hourglass_top_rounded),
              const SizedBox(width: 8),
              _buildPipelineStatusBox("Completed", completed, total, Colors.teal, Icons.task_alt_rounded),
              const SizedBox(width: 8),
              _buildPipelineStatusBox("Cancelled", cancelled, total, AppTheme.mutedGrey, Icons.cancel_outlined),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (ready > 0) Expanded(flex: ready, child: Container(color: AppTheme.primaryGreen)),
                    if (inPrep > 0) Expanded(flex: inPrep, child: Container(color: Colors.blueAccent)),
                    if (completed > 0) Expanded(flex: completed, child: Container(color: Colors.teal)),
                    if (cancelled > 0) Expanded(flex: cancelled, child: Container(color: const Color(0xFFCBD5E1))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineStatusBox(String label, int count, int total, Color color, IconData icon) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              "$count",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
            ),
            Text(
              "$pct%",
              style: TextStyle(fontSize: 9, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDealsRankingCard(List<FoodDeal> deals, List<Order> collectedOrders) {
    if (deals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: Text(
            "No listings available. Create surplus packs to see item performance.",
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Rank deals by units sold
    final sortedDeals = List<FoodDeal>.from(deals);
    sortedDeals.sort((a, b) {
      final soldA = a.quantityTotal - a.quantityRemaining;
      final soldB = b.quantityTotal - b.quantityRemaining;
      return soldB.compareTo(soldA);
    });

    final topDeals = sortedDeals.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text("Top-Performing Surplus Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                ],
              ),
              const Text("Ranked by Velocity", style: TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...topDeals.asMap().entries.map((entry) {
            final idx = entry.key;
            final deal = entry.value;
            final sold = (deal.quantityTotal - deal.quantityRemaining).clamp(0, deal.quantityTotal);
            final revenue = sold * deal.discountedPrice;
            final selloutPct = deal.quantityTotal > 0 ? ((sold / deal.quantityTotal) * 100).round() : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: idx == 0 ? AppTheme.goldAccent.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${idx + 1}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: idx == 0 ? const Color(0xFFB45309) : AppTheme.charcoal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: deal.imageUrl.isNotEmpty
                        ? Image.network(deal.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood_rounded, size: 18, color: AppTheme.primaryGreen))
                        : const Icon(Icons.fastfood_rounded, size: 18, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$sold of ${deal.quantityTotal} sold ($selloutPct%) • GHS ${deal.discountedPrice.toStringAsFixed(0)} each",
                          style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "GHS ${revenue.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primaryGreen),
                      ),
                      const Text(
                        "Earned",
                        style: TextStyle(fontSize: 9.5, color: AppTheme.mutedGrey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceCard(List<FoodDeal> deals) {
    // Group merchant's active deals by category and calculate real sold inventory
    final Map<String, List<FoodDeal>> byCategory = {};
    for (final d in deals) {
      final cat = d.category.isNotEmpty ? d.category : 'Restaurant Meal';
      byCategory.putIfAbsent(cat, () => []).add(d);
    }

    final List<Widget> categoryRows = [];
    final colors = [AppTheme.primaryGreen, Colors.blueAccent, Colors.teal, Colors.orange, Colors.purple];
    int colorIdx = 0;

    if (byCategory.isEmpty) {
      categoryRows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "No active listings yet. Add surplus packs to track category performance.",
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    } else {
      byCategory.forEach((categoryName, dealsList) {
        final totalStock = dealsList.fold(0, (sum, d) => sum + d.quantityTotal);
        final remaining = dealsList.fold(0, (sum, d) => sum + d.quantityRemaining);
        final sold = (totalStock - remaining).clamp(0, totalStock);
        final rate = totalStock > 0 ? ((sold / totalStock) * 100).round() : 0;
        final color = colors[colorIdx % colors.length];
        colorIdx++;

        categoryRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCategoryVelocityRow(
              categoryName,
              rate,
              "$sold of $totalStock packs rescued",
              color,
            ),
          ),
        );
      });
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart_outline_rounded, color: Colors.orange, size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Surplus Category Sellout Velocity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
            ],
          ),
          const SizedBox(height: 14),
          ...categoryRows,
        ],
      ),
    );
  }

  Widget _buildCategoryVelocityRow(String name, int rate, String note, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
            Text("$rate% Sold Out", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(note, style: const TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100.0,
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEsgImpactCard({
    required int meals,
    required double wasteKg,
    required double co2Kg,
    required double waterL,
    required double percent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGreenBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text("ESG Sustainability Scorecard", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryGreen)),
                ],
              ),
              TextButton.icon(
                onPressed: () => _shareImpactCertificate(meals, co2Kg, waterL),
                icon: const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGreen),
                label: const Text("View Badge", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildImpactMetric("${wasteKg.toStringAsFixed(1)} kg", "Waste Diverted", Icons.delete_outline_rounded)),
              Expanded(child: _buildImpactMetric("${co2Kg.toStringAsFixed(1)} kg", "CO2e Avoided", Icons.co2_rounded)),
              Expanded(child: _buildImpactMetric("${(waterL / 1000).toStringAsFixed(1)}k L", "Water Saved", Icons.water_drop_outlined)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 7,
              backgroundColor: Colors.white,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(String val, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.primaryGreen),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
      ],
    );
  }

  Widget _buildCustomerRetentionCard(List<Order> allMerchantOrders) {
    // Calculate real repeat customer rate from database orders
    final customerOrderCounts = <String, int>{};
    for (final o in allMerchantOrders) {
      if (o.customerName.isNotEmpty) {
        customerOrderCounts[o.customerName] = (customerOrderCounts[o.customerName] ?? 0) + 1;
      }
    }

    final totalCustomers = customerOrderCounts.length;
    final repeatCustomers = customerOrderCounts.values.where((c) => c > 1).length;
    final repeatPercent = totalCustomers > 0 ? ((repeatCustomers / totalCustomers) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.repeat_rounded, color: Colors.purple, size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Customer Loyalty & Retention", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalCustomers > 0 ? "$repeatPercent%" : "0%",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                    ),
                    const Text("Repeat Buyer Rate", style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      totalCustomers > 0
                          ? "$repeatCustomers of $totalCustomers unique customers have ordered multiple surprise bags."
                          : "Customer retention metrics will populate as orders are completed.",
                      style: TextStyle(fontSize: 11, color: AppTheme.charcoal.withValues(alpha: 0.8), height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSentimentTag("Fresh Quality", "98%"),
                    _buildSentimentTag("Speedy Pickup", "95%"),
                    _buildSentimentTag("Generous Packs", "92%"),
                    _buildSentimentTag("Eco Champion", "99%"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentTag(String tag, String pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "✓ $tag ($pct)",
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
      ),
    );
  }

  Widget _buildSmartRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text("Smart Store Optimization Tips", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal)),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecommendationBullet("Publish listings between 3:30 PM and 5:00 PM for 38% faster evening bag sellout."),
          _buildRecommendationBullet("Add descriptive contents to your surprise bags to boost repeat reservations by 24%."),
          _buildRecommendationBullet("Keep GPS store pin updated so nearby walking customers receive instant proximity alerts."),
        ],
      ),
    );
  }

  Widget _buildRecommendationBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey, height: 1.35))),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<Order> collectedOrders) {
    List<BarChartGroupData> chartGroups;
    List<String> labels;
    double maxY = 100;
    final now = DateTime.now();

    switch (_selectedChartType) {
      case 'Daily':
        labels = ["6a", "9a", "12p", "3p", "6p", "9p", "12a"];
        List<double> dailyTotals = List.filled(7, 0.0);
        for (var o in collectedOrders) {
          if (o.timestamp.year == now.year && o.timestamp.month == now.month && o.timestamp.day == now.day) {
            int hour = o.timestamp.hour;
            int bucket = 0;
            if (hour < 6) {
              bucket = 0;
            } else if (hour < 9) {
              bucket = 1;
            } else if (hour < 12) {
              bucket = 2;
            } else if (hour < 15) {
              bucket = 3;
            } else if (hour < 18) {
              bucket = 4;
            } else if (hour < 21) {
              bucket = 5;
            } else {
              bucket = 6;
            }
            dailyTotals[bucket] += o.price;
          }
        }
        double maxVal = 0.0;
        for (var v in dailyTotals) {
          if (v > maxVal) maxVal = v;
        }
        maxY = maxVal > 0 ? maxVal * 1.3 : 200.0;
        chartGroups = List.generate(7, (i) => _makeBarGroup(i, dailyTotals[i]));
        break;
      case 'Monthly':
        final List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        int currentMonth = now.month;
        List<int> monthsToShow = [];
        for (int i = 6; i >= 0; i--) {
          int m = currentMonth - i;
          if (m <= 0) m += 12;
          monthsToShow.add(m);
        }
        labels = monthsToShow.map((m) => monthNames[m - 1]).toList();
        List<double> monthlyTotals = List.filled(7, 0.0);
        for (var o in collectedOrders) {
          for (int i = 0; i < 7; i++) {
            if (o.timestamp.month == monthsToShow[i]) {
              monthlyTotals[i] += o.price;
            }
          }
        }
        double maxVal = 0.0;
        for (var v in monthlyTotals) {
          if (v > maxVal) maxVal = v;
        }
        maxY = maxVal > 0 ? maxVal * 1.3 : 1000.0;
        chartGroups = List.generate(7, (i) => _makeBarGroup(i, monthlyTotals[i]));
        break;
      default: // Weekly
        labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        List<double> weeklyTotals = List.filled(7, 0.0);
        for (var o in collectedOrders) {
          if (now.difference(o.timestamp).inDays <= 7) {
            int dayIndex = o.timestamp.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyTotals[dayIndex] += o.price;
            }
          }
        }
        double maxVal = 0.0;
        for (var v in weeklyTotals) {
          if (v > maxVal) maxVal = v;
        }
        maxY = maxVal > 0 ? maxVal * 1.3 : 500.0;
        chartGroups = List.generate(7, (i) => _makeBarGroup(i, weeklyTotals[i]));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$_selectedChartType Revenue (GHS)",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.mutedGrey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.charcoal,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'GHS ${rod.toY.round()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(labels[val.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mutedGrey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: chartGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _selectedChartType = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Daily', child: Text("Daily")),
        const PopupMenuItem(value: 'Weekly', child: Text("Weekly")),
        const PopupMenuItem(value: 'Monthly', child: Text("Monthly")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Text(_selectedChartType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.mutedGrey),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.primaryGreen,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

// ================= VERIFICATION TAB =================
class _MerchantVerificationTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  const _MerchantVerificationTab({required this.business});

  @override
  ConsumerState<_MerchantVerificationTab> createState() => _MerchantVerificationTabState();
}

class _MerchantVerificationTabState extends ConsumerState<_MerchantVerificationTab> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  String? _error;

  void _onNumberTap(String val) {
    if (_codeController.text.length < 7) {
      setState(() {
        _codeController.text += val;
        _error = null;
      });
    }
  }

  void _onDelete() {
    if (_codeController.text.isNotEmpty) {
      setState(() {
        _codeController.text = _codeController.text.substring(0, _codeController.text.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim().toUpperCase();
    _verifyCode(code);
  }  Future<void> _verifyCode(String code) async {
    if (code.length < 4) return;

    setState(() {
      _isValidating = true;
      _error = null;
    });

    try {
      var state = ref.read(appStateProvider);
      Order? order;

      // 1. Try to find the order locally (regardless of status)
      try {
        order = state.orders.firstWhere(
          (o) => o.businessId == widget.business.id && o.collectionCode.toUpperCase() == code,
        );
      } catch (_) {
        // 2. If not found locally, refresh orders from backend and try again
        await ref.read(appStateProvider.notifier).refreshOrders();
        state = ref.read(appStateProvider);
        try {
          order = state.orders.firstWhere(
            (o) => o.businessId == widget.business.id && o.collectionCode.toUpperCase() == code,
          );
        } catch (_) {
          throw Exception("Invalid collection code.");
        }
      }

      // 3. Gracefully handle already collected status instead of showing a scary validation error
      if (order.status == 'collected') {
        if (mounted) {
          _showAlreadyCollectedDialog(order);
          _codeController.clear();
        }
        return;
      }

      if (order.status == 'cancelled') {
        throw Exception("This reservation was cancelled and cannot be collected.");
      }

      // 4. Perform collection confirmation
      await ref.read(appStateProvider.notifier).confirmCollection(order.id);

      if (mounted) {
        _showSuccessDialog(order);
        _codeController.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _showScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
          title: const Text("Scan Customer QR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    Navigator.pop(ctx);
                    _verifyCode(code);
                  }
                }
              },
            ),
            // Scanner Overlay
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGreen, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            const Text("Verification Successful", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("Rescue for ${order.customerName} has been recorded.", textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.mutedGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, minimumSize: const Size(double.infinity, 48)),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlreadyCollectedDialog(Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange, size: 64),
            const SizedBox(height: 16),
            const Text("Already Verified", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              "This rescue code for ${order.customerName} has already been verified and marked as collected.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mutedGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, minimumSize: const Size(double.infinity, 48)),
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      maxWidth: 480,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Verify Rescue Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Text("Enter the code or scan the customer's QR", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGreen),
                label: const Text("SCAN QR CODE", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.lightGreenBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Code Display
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _error != null ? AppTheme.errorRed : const Color(0xFFE2E8F0), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                _codeController.text.isEmpty ? "----" : _codeController.text,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: _error != null ? AppTheme.errorRed : AppTheme.charcoal,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 20),

            // Industrial Keypad
            _buildKeypad(),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isValidating || _codeController.text.isEmpty ? null : _handleVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isValidating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("VERIFY COLLECTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(children: [_key('1'), _key('2'), _key('3')]),
        const SizedBox(height: 12),
        Row(children: [_key('4'), _key('5'), _key('6')]),
        const SizedBox(height: 12),
        Row(children: [_key('7'), _key('8'), _key('9')]),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: SizedBox()),
          _key('0'),
          Expanded(
            child: IconButton(
              onPressed: _onDelete,
              icon: const Icon(Icons.backspace_rounded, color: AppTheme.mutedGrey),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _key(String val) {
    return Expanded(
      child: InkWell(
        onTap: () => _onNumberTap(val),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
        ),
      ),
    );
  }
}

Widget _buildMerchantMenuItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  MenuController? controller,
  Color? color,
}) {
  return InkWell(
    onTap: () {
      if (controller != null && controller.isOpen) {
        controller.close();
      }
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.charcoal.withValues(alpha: 0.75)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.charcoal,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: color?.withValues(alpha: 0.6) ?? AppTheme.mutedGrey,
          ),
        ],
      ),
    ),
  );
}

// ================= LISTINGS TAB =================
class _MerchantListingsTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  const _MerchantListingsTab({required this.business});

  @override
  ConsumerState<_MerchantListingsTab> createState() => _MerchantListingsTabState();
}

class _MerchantListingsTabState extends ConsumerState<_MerchantListingsTab> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _origPriceController = TextEditingController();
  final _discPriceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _pickupController = TextEditingController(text: "5:30 PM - 7:30 PM");

  String _selectedCategory = 'Restaurant Meal';
  final _formKey = GlobalKey<FormState>();

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  final List<String> _categories = [
    'Restaurant Meal',
    'Bakery Pack',
    'Grocery Bundle',
    'Fruit & Vegetable Pack',
    'Hotel Buffet',
    'Snacks & Drinks'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _origPriceController.dispose();
    _discPriceController.dispose();
    _qtyController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _submitDeal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      String imageUrl = '';
      try {
        if (_selectedImageBytes != null) {
          final fileName = 'deal_${DateTime.now().millisecondsSinceEpoch}.jpg';
          imageUrl = await SupabaseService().uploadImage(
            bucket: 'uploads',
            path: '${widget.business.id}/$fileName',
            fileBytes: _selectedImageBytes!,
          );
        }
        await ref.read(appStateProvider.notifier).addDeal(
              title: _titleController.text,
              description: _descController.text,
              category: _selectedCategory,
              originalPrice: double.parse(_origPriceController.text),
              discountedPrice: double.parse(_discPriceController.text),
              pickupWindow: _pickupController.text,
              quantity: int.parse(_qtyController.text),
              imageUrl: imageUrl,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Surplus food listing published successfully!"), backgroundColor: AppTheme.primaryGreen));
        _titleController.clear();
        _descController.clear();
        _origPriceController.clear();
        _discPriceController.clear();
        _qtyController.clear();
        _selectedImageBytes = null;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.errorRed));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _boostDeal(BuildContext context, FoodDeal deal) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Boosting '${deal.title}' to nearby customers!"), backgroundColor: AppTheme.primaryGreen, behavior: SnackBarBehavior.floating));
  }

  void _openAddListingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("New Surplus Listing", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.charcoal, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        const Text("Turn your surplus food into revenue and reduce waste.", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05))),
                            child: _selectedImageBytes != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity))
                                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen, size: 32), SizedBox(height: 8), Text("Add Package Photo", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(controller: _titleController, label: "Item Name", hint: "e.g., Breakfast Pastry Box", icon: Icons.fastfood_rounded),
                        const SizedBox(height: 16),
                        _buildInputField(controller: _descController, label: "What's in the pack?", hint: "Describe the contents", icon: Icons.description_rounded, maxLines: 2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.mutedGrey)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(16),
                                    dropdownColor: context.cardColor,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.mutedGrey),
                                    decoration: _inputDecoration("Category", Icons.category_rounded),
                                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w600)))).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: _buildInputField(controller: _qtyController, label: "Stock", hint: "Qty", icon: Icons.inventory_2_rounded, keyboard: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(controller: _origPriceController, label: "Original Price", hint: "GHS", icon: Icons.money_off_rounded, keyboard: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(controller: _discPriceController, label: "Rescue Price", hint: "GHS", icon: Icons.savings_rounded, keyboard: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDiscountNotice(),
                        const SizedBox(height: 16),
                        _buildInputField(controller: _pickupController, label: "Pickup Window", hint: "e.g., 6:00 PM - 8:30 PM", icon: Icons.access_time_filled_rounded),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isUploading ? null : _submitDeal,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                          child: _isUploading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Publish Listing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Notice: The Rescue/Surplus price must represent a discount of 20% to 25% (or more) off the original price. Make sure this is a discounted rescue rate, not your regular retail price.",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.mutedGrey)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboard, decoration: _inputDecoration(hint, icon), validator: (val) => val!.isEmpty ? "Required" : null),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: AppTheme.lightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final myDeals = state.deals.where((d) => d.businessId == widget.business.id).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, onPressed: _openAddListingSheet, label: const Text("Add Surplus"), icon: const Icon(Icons.add)),
      body: ResponsiveCenter(
        maxWidth: 1100,
        child: myDeals.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.mutedGrey.withValues(alpha: 0.5)), const SizedBox(height: 12), const Text("No active listings", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text("Tap 'Add Surplus' to create your first listing.", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13))]))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: myDeals.length,
                itemBuilder: (context, index) {
                  final deal = myDeals[index];
                  return _HoverLift(
                    child: Opacity(
                      opacity: deal.isActive ? 1.0 : 0.6,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: deal.isActive ? const Color(0xFFF1F5F9) : AppTheme.errorRed.withValues(alpha: 0.1))),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (deal.imageUrl.isNotEmpty)
                                    Image.network(
                                      deal.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Center(
                                        child: Icon(
                                          Icons.fastfood_rounded,
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                                          size: 26,
                                        ),
                                      ),
                                      loadingBuilder: (c, child, p) => p == null
                                          ? child
                                          : const Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                                              ),
                                            ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        Icons.fastfood_rounded,
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                                        size: 26,
                                      ),
                                    ),
                                  if (!deal.isActive)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      child: const Center(
                                        child: Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                                      ),
                                    )
                                  else if (deal.quantityRemaining == 0)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      child: const Center(
                                        child: Text(
                                          "SOLD OUT",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 8.5,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [Text(deal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal)), if (!deal.isActive) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(4)), child: const Text("PAUSED", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey)))]]),
                                  const SizedBox(height: 4),
                                  Row(children: [Text("GHS ${deal.originalPrice.toStringAsFixed(0)}", style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.mutedGrey, fontSize: 11)), const SizedBox(width: 6), Text("GHS ${deal.discountedPrice.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 15))]),
                                  const SizedBox(height: 8),
                                  Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: deal.quantityRemaining <= 2 ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(8)), child: Text("${deal.quantityRemaining} of ${deal.quantityTotal} left", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: deal.quantityRemaining <= 2 ? AppTheme.errorRed : AppTheme.primaryGreen))), if (deal.quantityRemaining > 0) ...[const SizedBox(width: 8), GestureDetector(onTap: () => _boostDeal(context, deal), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.secondaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.secondaryGreen.withValues(alpha: 0.3))), child: const Row(children: [Icon(Icons.bolt_rounded, size: 10, color: AppTheme.secondaryGreen), SizedBox(width: 4), Text("BOOST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondaryGreen))])))]]),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppTheme.mutedGrey),
                              onSelected: (val) {
                                if (val == 'toggle') {
                                  ref.read(appStateProvider.notifier).toggleDealStatus(deal.id, !deal.isActive);
                                } else if (val == 'edit') {
                                  _showEditModal(context, deal);
                                } else if (val == 'delete') {
                                  _confirmDelete(context, deal);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'toggle', child: Row(children: [Icon(deal.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 18), const SizedBox(width: 8), Text(deal.isActive ? "Pause Listing" : "Resume Listing")])),
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text("Edit Listing")])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorRed), SizedBox(width: 8), Text("Remove", style: TextStyle(color: AppTheme.errorRed))])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FoodDeal deal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing?", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
        content: Text("Are you sure you want to permanently remove '${deal.title}'? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ref.read(appStateProvider.notifier).deleteDeal(deal.id);
                messenger.showSnackBar(const SnackBar(content: Text("Listing deleted successfully."), backgroundColor: AppTheme.primaryGreen));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Failed to delete listing: $e"), backgroundColor: AppTheme.errorRed));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, FoodDeal deal) {
    final titleCtrl = TextEditingController(text: deal.title);
    final descCtrl = TextEditingController(text: deal.description);
    final origPriceCtrl = TextEditingController(text: deal.originalPrice.toStringAsFixed(2));
    final discPriceCtrl = TextEditingController(text: deal.discountedPrice.toStringAsFixed(2));
    final qtyCtrl = TextEditingController(text: deal.quantityTotal.toString());
    final pickupCtrl = TextEditingController(text: deal.pickupWindow);
    String category = deal.category.isNotEmpty ? deal.category : 'Restaurant Meal';
    Uint8List? newImageBytes;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Edit Listing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 75,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setModalState(() => newImageBytes = bytes);
                      }
                    },
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), style: BorderStyle.solid),
                      ),
                      child: newImageBytes != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(newImageBytes!, fit: BoxFit.cover, width: double.infinity))
                          : (deal.imageUrl.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(deal.imageUrl, fit: BoxFit.cover, width: double.infinity))
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryGreen, size: 28),
                                      SizedBox(height: 6),
                                      Text("Tap to change picture", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Listing Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: origPriceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Original Price (GHS)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: discPriceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Surplus Price (GHS)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDiscountNotice(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantity", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: pickupCtrl, decoration: InputDecoration(labelText: "Pickup Window", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              String? updatedImg = deal.imageUrl;
                              if (newImageBytes != null) {
                                final fileName = 'deal_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                updatedImg = await SupabaseService().uploadImage(
                                  bucket: 'uploads',
                                  path: '${widget.business.id}/$fileName',
                                  fileBytes: newImageBytes!,
                                );
                              }
                              await ref.read(appStateProvider.notifier).updateDeal(
                                    dealId: deal.id,
                                    title: titleCtrl.text,
                                    description: descCtrl.text,
                                    category: category,
                                    originalPrice: double.tryParse(origPriceCtrl.text) ?? deal.originalPrice,
                                    discountedPrice: double.tryParse(discPriceCtrl.text) ?? deal.discountedPrice,
                                    pickupWindow: pickupCtrl.text,
                                    quantity: int.tryParse(qtyCtrl.text) ?? deal.quantityTotal,
                                    imageUrl: updatedImg,
                                  );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing updated successfully!"), backgroundColor: AppTheme.primaryGreen));
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e"), backgroundColor: AppTheme.errorRed));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= ORDERS TAB =================
class _MerchantOrdersTab extends ConsumerWidget {
  final BusinessProfile business;
  const _MerchantOrdersTab({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final myOrders = state.orders.where((o) => o.businessId == business.id).toList();

    return ResponsiveCenter(
      maxWidth: 1100,
      child: myOrders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: myOrders.length,
              itemBuilder: (context, index) {
                final order = myOrders[index];
                return _buildMerchantOrderCard(context, ref, order);
              },
            ),
    );
  }

  Widget _buildMerchantOrderCard(BuildContext context, WidgetRef ref, Order order) {
    Color statusColor;
    String statusText;
    switch (order.status) {
      case 'reserved':
        statusColor = Colors.orange;
        statusText = 'Order Received';
        break;
      case 'preparing':
        statusColor = const Color(0xFFD97706);
        statusText = 'Preparing Food';
        break;
      case 'ready':
        statusColor = AppTheme.primaryGreen;
        statusText = 'Ready for Pickup';
        break;
      case 'out_for_delivery':
        statusColor = const Color(0xFF2563EB);
        statusText = 'Out for Delivery';
        break;
      case 'collected':
        statusColor = AppTheme.mutedGrey;
        statusText = 'Collected';
        break;
      default:
        statusColor = AppTheme.errorRed;
        statusText = order.status.toUpperCase();
        break;
    }

    final isCompleted = order.status == 'collected' || order.status == 'cancelled';

    return _HoverLift(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.fulfillmentType == 'delivery' ? '🛵 DELIVERY' : '🛍️ PICKUP',
                          style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w800, fontSize: 9.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.mutedGrey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showOrderDetailsBottomSheet(context, order),
                      ),
                    ],
                  ),
                  Text(
                    "GHS ${order.price.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.lightGreenBg,
                    radius: 16,
                    child: Text(
                      order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        Text(order.dealTitle, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                      ],
                    ),
                  ),
                ],
              ),

              // Tracking details display if assigned
              if (order.courierName != null && order.courierName!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Courier: ${order.courierName} ${order.courierPhone != null ? '(${order.courierPhone})' : ''}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (order.trackingNotes != null && order.trackingNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Notes: ${order.trackingNotes}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontStyle: FontStyle.italic),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 16),

              // Order Action Buttons (Update Status, Track, Verify)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isCompleted ? AppTheme.mutedGrey : AppTheme.primaryGreen),
                        foregroundColor: isCompleted ? AppTheme.mutedGrey : AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _showUpdateOrderStatusDialog(context, ref, order),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text("Status & Tracking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => _showCollectionDialog(context, ref, order),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _sendPickupReminder(context, ref, order),
                    icon: const Icon(Icons.notifications_active_outlined, size: 14),
                    label: const Text("Send Customer Reminder", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.mutedGrey,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _sendPickupReminder(BuildContext context, WidgetRef ref, Order order) async {
    // This would call an edge function or notification service to ping the customer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder sent to ${order.customerName}!"),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUpdateOrderStatusDialog(BuildContext context, WidgetRef ref, Order order) {
    String currentStatus = order.status;
    String currentFulfillment = order.fulfillmentType;
    final courierCtrl = TextEditingController(text: order.courierName ?? '');
    final phoneCtrl = TextEditingController(text: order.courierPhone ?? '');
    final notesCtrl = TextEditingController(text: order.trackingNotes ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Update Order Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text('Code: #${order.collectionCode} • ${order.customerName}', style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDER FULFILLMENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentStatus,
                        items: const [
                          DropdownMenuItem(value: 'reserved', child: Text('⏳ Order Received (Pending)')),
                          DropdownMenuItem(value: 'preparing', child: Text('🍳 Kitchen Preparing Food')),
                          DropdownMenuItem(value: 'ready', child: Text('📦 Ready for Pickup')),
                          DropdownMenuItem(value: 'out_for_delivery', child: Text('🛵 Out for Delivery / Dispatched')),
                          DropdownMenuItem(value: 'collected', child: Text('✅ Collected & Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('❌ Cancelled')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => currentStatus = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('FULFILLMENT TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('🛍️ Store Pickup'),
                          selected: currentFulfillment == 'pickup',
                          onSelected: (val) {
                            if (val) setDlgState(() => currentFulfillment = 'pickup');
                          },
                          selectedColor: AppTheme.lightGreenBg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('🛵 Delivery'),
                          selected: currentFulfillment == 'delivery',
                          onSelected: (val) {
                            if (val) setDlgState(() => currentFulfillment = 'delivery');
                          },
                          selectedColor: AppTheme.lightGreenBg,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('COURIER / RIDER DETAILS (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: courierCtrl,
                    decoration: InputDecoration(
                      labelText: 'Courier / Rider Name',
                      hintText: 'e.g. Swift Rider / Samuel K.',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Courier Phone Number',
                      hintText: 'e.g. +233 24 123 4567',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('TRACKING / PICKUP INSTRUCTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Package #4 at front pickup shelf. Ask Kwame.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDlgState(() => isSaving = true);
                        await ref.read(appStateProvider.notifier).updateMerchantOrderStatus(
                              orderId: order.id,
                              status: currentStatus,
                              fulfillmentType: currentFulfillment,
                              courierName: courierCtrl.text.trim().isEmpty ? null : courierCtrl.text.trim(),
                              courierPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              trackingNotes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order #${order.collectionCode} status updated to ${currentStatus.replaceAll('_', ' ')}!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save & Notify Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCollectionDialog(BuildContext context, WidgetRef ref, Order order) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Customer Pickup"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter the 4-digit code shown on the customer's phone screen to verify collection.",
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  decoration: const InputDecoration(
                    hintText: "e.g., 1234",
                  ),
                  validator: (val) {
                    if (val == null || val.trim().toUpperCase() != order.collectionCode.toUpperCase()) {
                      return "Invalid verification code";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(appStateProvider.notifier).confirmCollection(order.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Collection verified! Payout will be processed."),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
              child: const Text("Verify & Collect"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 64, color: AppTheme.mutedGrey),
            SizedBox(height: 16),
            Text(
              "No reservations today",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
            ),
            SizedBox(height: 8),
            Text(
              "Customer orders booked for pickup will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(BuildContext context, Order order) {
    final dateStr = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(order.timestamp);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Order Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status == 'reserved'
                          ? const Color(0xFFFEF3C7)
                          : (order.status == 'collected' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: order.status == 'reserved'
                            ? const Color(0xFFD97706)
                            : (order.status == 'collected' ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Order ID: #${order.id.toUpperCase()}",
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w700),
              ),
              const Divider(height: 32),

              // Customer Section
              const Text(
                "CUSTOMER INFORMATION",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.lightGreenBg,
                    radius: 20,
                    child: Text(
                      order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Verified DreamEats Customer",
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Rescue Deal Section
              const Text(
                "RESCUE ITEM DETAILS",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.dealTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                          ),
                        ),
                        Text(
                          "GHS ${order.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Original Value",
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "GHS ${order.originalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rescue Code",
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          order.collectionCode,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Timestamps & Payouts Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RESERVATION DATE",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "PAYOUT STATUS",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.payoutStatus == 'paid' ? 'SETTLED' : 'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: order.payoutStatus == 'paid' ? AppTheme.primaryGreen : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.charcoal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Close Details", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
