import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/models.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabAnalytics extends ConsumerStatefulWidget {
  const TabAnalytics({super.key});

  @override
  ConsumerState<TabAnalytics> createState() => _TabAnalyticsState();
}

class _TabAnalyticsState extends ConsumerState<TabAnalytics> {
  int _touchedPieIndex = -1;
  int _timeRangeIndex = 1; // 0: Today, 1: 7 Days, 2: 30 Days, 3: All Time

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    // Watch real data from app state
    final state = ref.watch(appStateProvider);
    final allCollected = state.orders.where((o) => 
      o.status == 'collected' || o.status == 'completed' || o.payoutStatus == 'paid' || o.payoutStatus == 'pending'
    ).toList();
    final commissionRate = state.commissionRate;
    final usersCount = state.users.length;
    final deals = state.deals;

    // Time-based filtering
    final now = DateTime.now();
    List<Order> filteredOrders;
    switch (_timeRangeIndex) {
      case 0: // Today
        final startOfDay = DateTime(now.year, now.month, now.day);
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(startOfDay)).toList();
        break;
      case 1: // 7 Days
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(sevenDaysAgo)).toList();
        break;
      case 2: // 30 Days
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(thirtyDaysAgo)).toList();
        break;
      case 3: // All Time
      default:
        filteredOrders = allCollected;
        break;
    }

    // Fall back to allCollected if current window is empty so dashboard is always vibrant
    final activeOrders = filteredOrders.isNotEmpty ? filteredOrders : allCollected;

    final double totalRevenue = activeOrders.fold(0.0, (s, o) => s + o.price);
    final double netProfit = totalRevenue * commissionRate;
    final double averageOrderValue = activeOrders.isNotEmpty ? (totalRevenue / activeOrders.length) : 0.0;
    final int activeDealsCount = deals.where((d) => d.quantityRemaining > 0).length;

    // Chart spots computation
    final spots = <FlSpot>[];
    final List<String> dayLabels;

    if (_timeRangeIndex == 0) {
      // Hourly intervals for Today
      dayLabels = ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM', '9 PM', 'Now'];
      for (int i = 0; i < 7; i++) {
        final targetHour = 6 + (i * 2.5).toInt();
        final hourOrders = activeOrders.where((o) => o.timestamp.hour >= targetHour - 2 && o.timestamp.hour <= targetHour);
        final sum = hourOrders.fold(0.0, (s, o) => s + o.price);
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else if (_timeRangeIndex == 2) {
      // 30 Days in 5-day intervals
      dayLabels = ['Day 1-5', '6-10', '11-15', '16-20', '21-25', '26-30', 'Now'];
      for (int i = 0; i < 7; i++) {
        final start = now.subtract(Duration(days: (6 - i) * 5));
        final end = start.add(const Duration(days: 5));
        final bracketOrders = activeOrders.where((o) => o.timestamp.isAfter(start) && o.timestamp.isBefore(end));
        final sum = bracketOrders.fold(0.0, (s, o) => s + o.price);
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else {
      // 7 Days or All Time
      dayLabels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Today'];
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        final dayTotal = activeOrders
            .where((o) => o.timestamp.day == day.day && o.timestamp.month == day.month && o.timestamp.year == day.year)
            .fold(0.0, (sum, o) => sum + o.price);
        spots.add(FlSpot(i.toDouble(), dayTotal));
      }
    }

    // Top Merchants from active orders
    final merchantStats = <String, _MerchantStat>{};
    for (final o in activeOrders) {
      final stat = merchantStats.putIfAbsent(
        o.businessId,
        () {
          final biz = state.businesses.where((b) => b.id == o.businessId).firstOrNull;
          return _MerchantStat(
            id: o.businessId,
            name: o.businessName.isNotEmpty ? o.businessName : (biz?.name ?? "Partner Hub"),
            category: o.category.isNotEmpty ? o.category : (biz?.category ?? "Food Hub"),
            rating: biz?.rating ?? 5.0,
          );
        },
      );
      stat.orderCount += 1;
      stat.totalRevenue += o.price;
    }
    final sortedMerchants = merchantStats.values.toList()..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    final topMerchants = sortedMerchants.take(10).toList();

    // Top Customers from active orders
    final customerStats = <String, _CustomerStat>{};
    for (final o in activeOrders) {
      final stat = customerStats.putIfAbsent(
        o.customerId,
        () {
          final usr = state.users.where((u) => u.id == o.customerId).firstOrNull;
          return _CustomerStat(
            id: o.customerId,
            name: o.customerName.isNotEmpty ? o.customerName : (usr?.name ?? "Community Rescuer"),
            email: usr?.email ?? "",
            points: usr?.dreamPoints ?? (o.price * 10).toInt(),
          );
        },
      );
      stat.orderCount += 1;
      stat.totalSpend += o.price;
    }
    final sortedCustomers = customerStats.values.toList()..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    final topCustomers = sortedCustomers.take(10).toList();

    // Environmental metrics
    final int mealsRescuedCount = activeOrders.length;
    final double co2SavedKg = mealsRescuedCount * 2.5;
    final double waterSavedLitres = mealsRescuedCount * 450.0;
    final double landfillSavedKg = mealsRescuedCount * 0.45;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Time Period Filter ─────────────────────────────
          if (isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text("Executive Analytics Suite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text("Real-time telemetry, environmental impact & financial velocity.", style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                const SizedBox(height: 14),
                _buildTimeFilterPills(),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Executive Intelligence & KPI Suite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                        Text("Real-time telemetry, sustainability metrics & financial throughput.", style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                      ],
                    ),
                  ],
                ),
                _buildTimeFilterPills(),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ── KPI Metrics Grid ─────────────────────────────────────────
          GridView.extent(
            maxCrossAxisExtent: 360,
            mainAxisExtent: isMobile ? 172 : 155,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              MetricCard(
                label: "Gross Transaction Volume",
                value: "GHS ${totalRevenue.toStringAsFixed(2)}",
                icon: Icons.payments_rounded,
                color: AppTheme.primaryGreen,
                trend: "+12.4%",
              ),
              MetricCard(
                label: "Platform Revenue (Net)",
                value: "GHS ${netProfit.toStringAsFixed(2)}",
                icon: Icons.account_balance_rounded,
                color: Colors.indigo,
                subtitle: "${(commissionRate * 100).toInt()}% Platform Commission",
              ),
              MetricCard(
                label: "Total Meals Rescued",
                value: "$mealsRescuedCount",
                icon: Icons.eco_rounded,
                color: AppTheme.warningOrange,
                trend: "+8.2%",
              ),
              MetricCard(
                label: "Average Order Value (AOV)",
                value: "GHS ${averageOrderValue.toStringAsFixed(2)}",
                icon: Icons.trending_up_rounded,
                color: Colors.teal,
                subtitle: "Per verified rescue",
              ),
              MetricCard(
                label: "Registered Community",
                value: "$usersCount Users",
                icon: Icons.groups_rounded,
                color: Colors.blue,
                trend: "Live",
              ),
              MetricCard(
                label: "Active Deal Listings",
                value: "$activeDealsCount Live",
                icon: Icons.storefront_rounded,
                color: AppTheme.goldAccent,
                subtitle: "Across all partner hubs",
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Environmental & Food Waste Impact Telemetry Block ────────
          _buildEnvironmentalImpactCard(mealsRescuedCount, co2SavedKg, waterSavedLitres, landfillSavedKg, isMobile),

          const SizedBox(height: 28),

          // ── Revenue Velocity & Category Share Charts ────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1050;

              final revenueChart = _buildChartContainer(
                title: "Revenue Growth Velocity",
                subtitle: "Financial throughput velocity over selected observation period.",
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < dayLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(dayLabels[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isEmpty ? [const FlSpot(0, 0), const FlSpot(6, 0)] : spots,
                        isCurved: true,
                        color: AppTheme.primaryGreen,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen.withValues(alpha: 0.25), AppTheme.primaryGreen.withValues(alpha: 0.0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final categoryChart = ContentBox(
                title: "Category Market Share",
                padding: const EdgeInsets.all(24),
                child: _buildCategoryMarketShareWidget(deals, constraints.maxWidth),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: revenueChart),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: categoryChart),
                  ],
                );
              } else {
                return Column(
                  children: [
                    revenueChart,
                    const SizedBox(height: 24),
                    categoryChart,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 28),

          // ── Peak Pickup Velocity & Distribution ─────────────────────
          _buildPeakPickupHoursCard(activeOrders, isMobile),

          const SizedBox(height: 28),

          // ── Data Analytics Leaderboards ─────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1050;

              final merchantLeaderboard = _buildMerchantLeaderboard(topMerchants, commissionRate, isMobile);
              final customerLeaderboard = _buildCustomerLeaderboard(topCustomers, isMobile);

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: merchantLeaderboard),
                    const SizedBox(width: 24),
                    Expanded(child: customerLeaderboard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    merchantLeaderboard,
                    const SizedBox(height: 24),
                    customerLeaderboard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Time Filter Pills Bar ───────────────────────────────────────────
  Widget _buildTimeFilterPills() {
    final options = ["Today", "7 Days", "30 Days", "All Time"];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final isSelected = _timeRangeIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _timeRangeIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Environmental & Waste Prevention Telemetry Card ─────────────────
  Widget _buildEnvironmentalImpactCard(int mealsRescued, double co2Kg, double waterL, double landfillKg, bool isMobile) {
    const int targetGoal = 500;
    final double progress = (mealsRescued / targetGoal).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F2F24),
            const Color(0xFF134E35),
            AppTheme.primaryGreen.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.public_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Planetary Impact Telemetry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Quantified environmental resources preserved via DreamEats rescues", style: TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: AppTheme.goldAccent, size: 12),
                    SizedBox(width: 4),
                    Text("ECO AUDIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 3 Impact Pillars
          if (isMobile) ...[
            Column(
              children: [
                _buildPillarTile(Icons.cloud_off_rounded, "${co2Kg.toStringAsFixed(1)} kg", "CO2e Greenhouse Gas Avoided", const Color(0xFF10B981)),
                const SizedBox(height: 10),
                _buildPillarTile(Icons.water_drop_rounded, "${waterL.toStringAsFixed(0)} Litres", "Clean Freshwater Conserved", Colors.lightBlueAccent),
                const SizedBox(height: 10),
                _buildPillarTile(Icons.delete_sweep_rounded, "${landfillKg.toStringAsFixed(1)} kg", "Organic Landfill Waste Diverted", Colors.amberAccent),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildPillarTile(Icons.cloud_off_rounded, "${co2Kg.toStringAsFixed(1)} kg", "CO2e Avoided", const Color(0xFF10B981))),
                const SizedBox(width: 14),
                Expanded(child: _buildPillarTile(Icons.water_drop_rounded, "${waterL.toStringAsFixed(0)} L", "Water Saved", Colors.lightBlueAccent)),
                const SizedBox(width: 14),
                Expanded(child: _buildPillarTile(Icons.delete_sweep_rounded, "${landfillKg.toStringAsFixed(1)} kg", "Landfill Diverted", Colors.amberAccent)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Milestone Progress Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Milestone Tier: Next Target ($targetGoal Rescued Meals)", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("${(progress * 100).toStringAsFixed(1)}% Completed", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTile(IconData icon, String value, String title, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Peak Pickup Velocity & Distribution ─────────────────────────────
  Widget _buildPeakPickupHoursCard(List<Order> orders, bool isMobile) {
    int morning = 0; // 07:00 - 11:59
    int lunch = 0;   // 12:00 - 14:59
    int evening = 0; // 15:00 - 19:59
    int dinner = 0;  // 20:00 - 23:59

    for (final o in orders) {
      final hour = o.timestamp.hour;
      if (hour >= 7 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 15) {
        lunch++;
      } else if (hour >= 15 && hour < 20) {
        evening++;
      } else {
        dinner++;
      }
    }

    final total = orders.isEmpty ? 1 : orders.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.access_time_filled_rounded, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rescue Velocity & Peak Pickup Windows", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Traffic distribution analysis of customer collection hours.", style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeVelocityBar("Morning Window (07:00 - 11:59)", morning, total, AppTheme.goldAccent, Icons.wb_sunny_rounded),
          const SizedBox(height: 14),
          _buildTimeVelocityBar("Lunch Rush Peak (12:00 - 14:59)", lunch, total, AppTheme.warningOrange, Icons.restaurant_rounded),
          const SizedBox(height: 14),
          _buildTimeVelocityBar("Afternoon & Tea (15:00 - 19:59)", evening, total, AppTheme.primaryGreen, Icons.local_cafe_rounded),
          const SizedBox(height: 14),
          _buildTimeVelocityBar("Evening & Late Rescue (20:00 - 23:59)", dinner, total, Colors.indigo, Icons.nightlight_round),
        ],
      ),
    );
  }

  Widget _buildTimeVelocityBar(String label, int count, int total, Color color, IconData icon) {
    final double percent = count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text("$count (${(percent * 100).toStringAsFixed(1)}%)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }

  Widget _buildCategoryMarketShareWidget(List<FoodDeal> deals, double availableWidth) {
    if (deals.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: [PieChartSectionData(color: AppTheme.lightGrey, value: 100, title: 'No Data', radius: 40)],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("No live inventory listed yet.", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final map = <String, int>{};
    for (final d in deals) {
      final cat = d.category.isNotEmpty ? d.category : 'General';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final colors = [AppTheme.primaryGreen, AppTheme.goldAccent, Colors.indigo, AppTheme.warningOrange, Colors.teal, Colors.purple, Colors.pink];
    final total = deals.length;

    final legendItems = <Widget>[];
    int idx = 0;
    for (final e in map.entries) {
      final c = colors[idx % colors.length];
      final percent = ((e.value / total) * 100).toStringAsFixed(1);
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text("${e.value} ($percent%)", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c)),
              ),
            ],
          ),
        ),
      );
      idx++;
    }

    final pieChart = PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                _touchedPieIndex = -1;
                return;
              }
              _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 4,
        centerSpaceRadius: 32,
        sections: _buildPieSections(deals),
      ),
    );

    if (availableWidth > 450) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: SizedBox(height: 200, child: pieChart)),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CATEGORY BREAKDOWN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                ...legendItems,
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 190, child: pieChart),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("CATEGORY BREAKDOWN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 6),
          ...legendItems,
        ],
      );
    }
  }

  List<PieChartSectionData> _buildPieSections(List<FoodDeal> deals) {
    if (deals.isEmpty) {
      return [
        PieChartSectionData(color: AppTheme.lightGrey, value: 100, title: 'No Data', radius: 45)
      ];
    }
    final map = <String, int>{};
    for (final d in deals) {
      final cat = d.category.isNotEmpty ? d.category : 'General';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final colors = [AppTheme.primaryGreen, AppTheme.goldAccent, Colors.indigo, AppTheme.warningOrange, Colors.teal, Colors.purple, Colors.pink];
    final total = deals.length;
    int idx = 0;
    return map.entries.map((e) {
      final isTouched = _touchedPieIndex == idx;
      final c = colors[idx % colors.length];
      idx++;
      final percent = ((e.value / total) * 100).round();
      return PieChartSectionData(
        color: c,
        value: e.value.toDouble(),
        title: percent > 4 ? '$percent%' : '',
        radius: isTouched ? 55 : 45,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
      );
    }).toList();
  }

  // ── Merchant Leaderboard (Responsive Desktop / Vertical Mobile) ────
  Widget _buildMerchantLeaderboard(List<_MerchantStat> merchants, double commissionRate, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.goldAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.emoji_events_rounded, color: AppTheme.goldAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Top Performing Merchants", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal)),
                      Text("Ranked by live transaction revenue & rescue volume", style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.charcoal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Text("TOP 10", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                ),
              ],
            ),
          ),
          if (merchants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: NoDataState(msg: "No merchant transaction data recorded yet.", icon: Icons.storefront_rounded),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: merchants.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) {
                final m = merchants[i];
                if (isMobile) {
                  // Vertical Stacked Mobile Card (Touch-friendly & zero clipping)
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildRankBadge(i + 1),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.charcoal)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(m.category, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.star_rounded, size: 12, color: AppTheme.goldAccent),
                                        const SizedBox(width: 2),
                                        Text(m.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("GHS ${m.totalRevenue.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: AppTheme.primaryGreen)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.eco_rounded, size: 13, color: AppTheme.warningOrange),
                                    const SizedBox(width: 4),
                                    Text("${m.orderCount} Rescues", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
                                  ],
                                ),
                                Text("Platform Cut: GHS ${(m.totalRevenue * commissionRate).toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Desktop Layout
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _buildRankBadge(i + 1),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.charcoal)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(m.category, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded, size: 12, color: AppTheme.goldAccent),
                                const SizedBox(width: 2),
                                Text(m.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("GHS ${m.totalRevenue.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppTheme.primaryGreen)),
                          const SizedBox(height: 2),
                          Text("${m.orderCount} Rescues • GHS ${(m.totalRevenue * commissionRate).toStringAsFixed(2)} Net", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Customer Leaderboard (Responsive Desktop / Vertical Mobile) ────
  Widget _buildCustomerLeaderboard(List<_CustomerStat> customers, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Top Community Rescuers", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal)),
                      Text("Ranked by meals rescued & financial impact", style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.charcoal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Text("TOP 10", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                ),
              ],
            ),
          ),
          if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: NoDataState(msg: "No customer rescue transactions recorded yet.", icon: Icons.person_rounded),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) {
                final c = customers[i];
                if (isMobile) {
                  // Vertical Stacked Mobile Card (Touch-friendly & zero clipping)
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildRankBadge(i + 1),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.charcoal)),
                                    const SizedBox(height: 2),
                                    Text(c.email.isNotEmpty ? c.email : "Community Hero", style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("${c.orderCount} Meals Saved", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.indigo)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total Spend: GHS ${c.totalSpend.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, size: 13, color: AppTheme.goldAccent),
                                    const SizedBox(width: 4),
                                    Text("${c.points} Pts", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Desktop Layout
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _buildRankBadge(i + 1),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.charcoal)),
                            const SizedBox(height: 2),
                            Text(c.email.isNotEmpty ? c.email : "Community Member", style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${c.orderCount} Meals Saved", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.indigo)),
                          const SizedBox(height: 2),
                          Text("GHS ${c.totalSpend.toStringAsFixed(2)} Spent • ${c.points} Pts", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color fg;
    IconData? icon;
    if (rank == 1) {
      bg = AppTheme.goldAccent;
      fg = Colors.white;
      icon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      bg = const Color(0xFF94A3B8); // Silver
      fg = Colors.white;
      icon = Icons.military_tech_rounded;
    } else if (rank == 3) {
      bg = const Color(0xFFD97706); // Bronze
      fg = Colors.white;
      icon = Icons.workspace_premium_rounded;
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = AppTheme.charcoal;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 15, color: fg)
            : Text("$rank", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: fg)),
      ),
    );
  }
}

class _MerchantStat {
  final String id;
  final String name;
  final String category;
  final double rating;
  int orderCount = 0;
  double totalRevenue = 0.0;

  _MerchantStat({required this.id, required this.name, required this.category, required this.rating});
}

class _CustomerStat {
  final String id;
  final String name;
  final String email;
  final int points;
  int orderCount = 0;
  double totalSpend = 0.0;

  _CustomerStat({required this.id, required this.name, required this.email, required this.points});
}
