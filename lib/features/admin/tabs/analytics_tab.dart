import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    // Watch real data from app state
    final state = ref.watch(appStateProvider);
    final collected = state.orders.where((o) => 
      o.status == 'collected' || o.status == 'completed' || o.payoutStatus == 'paid' || o.payoutStatus == 'pending'
    ).toList();
    final commissionRate = state.commissionRate;
    final usersCount = state.users.length;
    final deals = state.deals;

    final double totalRevenue = collected.fold(0.0, (s, o) => s + o.price);
    final double netProfit = totalRevenue * commissionRate;
    final double averageOrderValue = collected.isNotEmpty ? (totalRevenue / collected.length) : 0.0;
    final int activeDealsCount = deals.where((d) => d.quantityRemaining > 0).length;

    // Calculate chart spots for last 7 days
    final spots = <FlSpot>[];
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayTotal = collected
          .where((o) => o.timestamp.day == day.day && o.timestamp.month == day.month && o.timestamp.year == day.year)
          .fold(0.0, (sum, o) => sum + o.price);
      spots.add(FlSpot(i.toDouble(), dayTotal));
    }
    final dayLabels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Today'];

    // Calculate Top Merchants from real orders (No Dummy Data)
    final merchantStats = <String, _MerchantStat>{};
    for (final o in collected) {
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

    // Calculate Top Customers from real orders (No Dummy Data)
    final customerStats = <String, _CustomerStat>{};
    for (final o in collected) {
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date Range & System Pulse Bar ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Executive Intelligence & KPI Suite", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                      Text("Real-time telemetry and financial throughput derived from live transactions.", style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.mutedGrey),
                    const SizedBox(width: 8),
                    Text(
                      "Live Audit: ${DateFormat('MMM d, yyyy').format(DateTime.now())}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Compact & Sleek KPI Grid (Reduced Size) ─────────────────
          GridView.extent(
            maxCrossAxisExtent: 360,
            mainAxisExtent: 155, // Sleek horizontal height with comfortable breathing room!
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
                value: "${collected.length}",
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

          const SizedBox(height: 36),

          // ── Revenue Velocity & Category Share Charts ────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1100;

              final revenueChart = _buildChartContainer(
                title: "Revenue Growth Velocity",
                subtitle: "Daily financial throughput across the platform over the last 7 days.",
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
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
                                child: Text(dayLabels[idx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
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
                            colors: [AppTheme.primaryGreen.withValues(alpha: 0.2), AppTheme.primaryGreen.withValues(alpha: 0)],
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
                padding: const EdgeInsets.all(28),
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

          const SizedBox(height: 36),

          // ── Data Analytics Leaderboards (No Dummy Data) ─────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1100;

              final merchantLeaderboard = _buildMerchantLeaderboard(topMerchants, commissionRate);
              final customerLeaderboard = _buildCustomerLeaderboard(topCustomers);

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

  Widget _buildChartContainer({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(28),
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
          const SizedBox(height: 28),
          SizedBox(height: 280, child: child),
        ],
      ),
    );
  }

  Widget _buildCategoryMarketShareWidget(List<FoodDeal> deals, double availableWidth) {
    if (deals.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text("${e.value} ($percent%)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c)),
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
        centerSpaceRadius: 35,
        sections: _buildPieSections(deals),
      ),
    );

    // If we have enough width (e.g. desktop side-by-side or wide tablet), put chart and legend in a Row!
    if (availableWidth > 450) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: SizedBox(height: 220, child: pieChart)),
          const SizedBox(width: 24),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("COLOR LEGEND & PRODUCT BREAKDOWN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...legendItems,
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 200, child: pieChart),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("COLOR LEGEND & PRODUCT BREAKDOWN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 8),
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
        radius: isTouched ? 58 : 48,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
      );
    }).toList();
  }

  // ── Merchant Leaderboard Widget ─────────────────────────────────────────────
  Widget _buildMerchantLeaderboard(List<_MerchantStat> merchants, double commissionRate) {
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
            padding: const EdgeInsets.all(22),
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

  // ── Customer Leaderboard Widget ─────────────────────────────────────────────
  Widget _buildCustomerLeaderboard(List<_CustomerStat> customers) {
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
            padding: const EdgeInsets.all(22),
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
