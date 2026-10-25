import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../auth/welcome_screen.dart';
import 'rider_delivery_screen.dart';
import 'rider_pending_screen.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isTogglingOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider.select((s) => s.currentUser));
    final orders = ref.watch(appStateProvider.select((s) => s.orders));

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If rider is pending approval by admin
    if (!user.isApproved) {
      return const RiderPendingScreen();
    }

    final isOnline = user.isOnline;

    // Filter available delivery orders waiting for a courier
    final availableOrders = orders.where((o) =>
        o.fulfillmentType == 'delivery' &&
        (o.courierId == null || o.courierId!.isEmpty) &&
        (o.status == 'reserved' || o.status == 'preparing' || o.status == 'ready')).toList();

    // Filter active deliveries for this rider
    final myActiveDeliveries = orders.where((o) =>
        o.courierId == user.id &&
        o.status != 'collected' &&
        o.status != 'cancelled' &&
        o.deliveryStatus != 'delivered' &&
        o.deliveryStatus != 'failed').toList();

    // Filter completed deliveries
    final completedDeliveries = orders.where((o) =>
        o.courierId == user.id &&
        (o.deliveryStatus == 'delivered' || o.status == 'collected')).toList();

    // Calculate today's earnings (Delivery fees: GHS 12 per completed order)
    final totalEarnings = completedDeliveries.fold<double>(
      0.0,
      (sum, o) => sum + (o.deliveryFee > 0 ? o.deliveryFee : 12.0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Courier Partner',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal),
                ),
                Text(
                  '${user.vehicleType} • ⭐ ${user.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.charcoal),
            onPressed: () => ref.read(appStateProvider.notifier).refreshOrders(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.mutedGrey),
            onPressed: () async {
              await ref.read(appStateProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: Column(
          children: [
            // ── Online / Offline Toggle Banner ───────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isOnline ? AppTheme.primaryGreen.withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppTheme.primaryGreen : Colors.grey,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 3,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: isOnline ? AppTheme.primaryGreen : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isOnline ? 'Ready to receive delivery dispatches' : 'Toggle online to see and accept orders',
                          style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  _isTogglingOnline
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Switch(
                          value: isOnline,
                          activeTrackColor: AppTheme.primaryGreen,
                          activeThumbColor: Colors.white,
                          onChanged: (val) async {
                            setState(() => _isTogglingOnline = true);
                            await ref.read(appStateProvider.notifier).setRiderOnline(val);
                            if (mounted) setState(() => _isTogglingOnline = false);
                          },
                        ),
                ],
              ),
            ),

            // ── Stats Summary Row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard('Active Trips', '${myActiveDeliveries.length}', Icons.navigation_rounded, const Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard('Delivered', '${completedDeliveries.length}', Icons.check_circle_rounded, AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard('Earnings', 'GHS ${AppTheme.formatPrice(totalEarnings)}', Icons.payments_rounded, const Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Tabs Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.mutedGrey,
                indicatorColor: AppTheme.primaryGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Available (${availableOrders.length})'),
                  Tab(text: 'Active (${myActiveDeliveries.length})'),
                  Tab(text: 'Completed (${completedDeliveries.length})'),
                ],
              ),
            ),

            // ── Tab Contents ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Available Deliveries
                  _buildAvailableTab(availableOrders, isOnline),

                  // Tab 2: My Active Deliveries
                  _buildActiveTab(myActiveDeliveries),

                  // Tab 3: Completed & Payout History
                  _buildCompletedTab(completedDeliveries, totalEarnings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(List<Order> orders, bool isOnline) {
    if (!isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.mutedGrey),
              const SizedBox(height: 12),
              const Text('You are currently Offline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Toggle your online switch above to start receiving delivery dispatches across Accra.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(appStateProvider.notifier).setRiderOnline(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Go Online Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
              child: const Icon(Icons.two_wheeler_rounded, size: 36, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 14),
            const Text('No unassigned deliveries right now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('New orders requiring delivery dispatch will appear here automatically.', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final fee = order.deliveryFee > 0 ? order.deliveryFee : 12.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: Text('TRIP #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF2563EB))),
                  ),
                  const Spacer(),
                  Text('GHS ${AppTheme.formatPrice(fee)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 12),
              // Pickup row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PICKUP RESTAURANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                        Text(order.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text(order.dealTitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Icon(Icons.arrow_downward_rounded, size: 14, color: AppTheme.mutedGrey),
              ),
              // Dropoff row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DELIVERY DESTINATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text(order.deliveryAddress ?? 'Accra, Ghana', style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(appStateProvider.notifier).riderAcceptDelivery(order.id);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Delivery accepted! Opening navigation...'), backgroundColor: AppTheme.primaryGreen),
                      );
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => RiderDeliveryScreen(order: order)),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept Delivery Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveTab(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No active trips in progress.', style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                    child: Text('STATUS: ${order.deliveryStatus.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.primaryGreen)),
                  ),
                  const Spacer(),
                  Text('Fee: GHS ${AppTheme.formatPrice(order.deliveryFee > 0 ? order.deliveryFee : 12.0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                ],
              ),
              const SizedBox(height: 10),
              Text(order.dealTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 4),
              Text('From: ${order.businessName}  ➔  To: ${order.customerName}', style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => RiderDeliveryScreen(order: order)),
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Open Trip Navigation & Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(List<Order> orders, double totalEarnings) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No completed deliveries yet.', style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.w600)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFD97706), size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Courier Payouts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    Text('GHS ${AppTheme.formatPrice(totalEarnings)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Courier earnings are transferred daily to your registered Mobile Money wallet!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Payout Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...orders.map((o) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.lightGreenBg,
                child: Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 20),
              ),
              title: Text(o.dealTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text('${o.businessName} • Delivered to ${o.customerName}', style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey)),
              trailing: Text(
                '+GHS ${AppTheme.formatPrice(o.deliveryFee > 0 ? o.deliveryFee : 12.0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 13),
              ),
            )),
      ],
    );
  }
}
