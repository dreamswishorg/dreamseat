import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';

class TabAnalytics extends ConsumerStatefulWidget {
  const TabAnalytics({super.key});

  @override
  ConsumerState<TabAnalytics> createState() => _TabAnalyticsState();
}

class _TabAnalyticsState extends ConsumerState<TabAnalytics> {
  int _timeRangeIndex = 1; // 0: Today, 1: 7 Days, 2: 30 Days, 3: All Time
  bool _useBarChart = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final state = ref.watch(appStateProvider);
    final allCollected = state.orders.where((o) =>
        o.status == 'collected' ||
        o.status == 'completed' ||
        o.payoutStatus == 'paid' ||
        o.payoutStatus == 'pending').toList();
    final commissionRate = state.commissionRate;
    final deals = state.deals;

    // Time-based filtering
    final now = DateTime.now();
    List<Order> filteredOrders;
    switch (_timeRangeIndex) {
      case 0:
        final startOfDay = DateTime(now.year, now.month, now.day);
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(startOfDay)).toList();
        break;
      case 1:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(sevenDaysAgo)).toList();
        break;
      case 2:
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filteredOrders = allCollected.where((o) => o.timestamp.isAfter(thirtyDaysAgo)).toList();
        break;
      case 3:
      default:
        filteredOrders = allCollected;
        break;
    }

    final activeOrders = filteredOrders.isNotEmpty ? filteredOrders : allCollected;
    final double totalRevenue = activeOrders.fold(0.0, (s, o) => s + o.price);
    final double netProfit = totalRevenue * commissionRate;
    final int mealsRescuedCount = activeOrders.length;
    final int activeDealsCount = deals.where((d) => d.quantityRemaining > 0).length;

    // Environmental calculations
    final double co2SavedKg = mealsRescuedCount * 2.5;
    final double waterSavedLitres = mealsRescuedCount * 450.0;
    final double landfillSavedKg = mealsRescuedCount * 0.45;

    // Chart points
    final spots = <FlSpot>[];
    final List<String> dayLabels = [];

    if (_timeRangeIndex == 0) {
      // Today: 6 intervals (12 AM, 4 AM, 8 AM, 12 PM, 4 PM, 8 PM)
      for (int i = 0; i < 6; i++) {
        final hour = i * 4;
        final hourLabel = hour == 0
            ? '12 AM'
            : (hour < 12 ? '$hour AM' : (hour == 12 ? '12 PM' : '${hour - 12} PM'));
        dayLabels.add(hourLabel);
        final hourOrders = activeOrders.where((o) =>
            o.timestamp.year == now.year &&
            o.timestamp.month == now.month &&
            o.timestamp.day == now.day &&
            o.timestamp.hour >= hour &&
            o.timestamp.hour < hour + 4);
        final sum = hourOrders.fold(0.0, (s, o) => s + o.price);
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else if (_timeRangeIndex == 2) {
      // 30 Days: 6 intervals of 5 days each
      for (int i = 0; i < 6; i++) {
        final start = now.subtract(Duration(days: (5 - i) * 5));
        dayLabels.add(DateFormat('d MMM').format(start));
        final end = start.add(const Duration(days: 5));
        final bracketOrders = activeOrders.where((o) => o.timestamp.isAfter(start) && o.timestamp.isBefore(end));
        final sum = bracketOrders.fold(0.0, (s, o) => s + o.price);
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else if (_timeRangeIndex == 3) {
      // All Time: 6 monthly intervals
      for (int i = 0; i < 6; i++) {
        final monthDate = DateTime(now.year, now.month - (5 - i), 1);
        final label = monthDate.year == now.year
            ? DateFormat('MMM').format(monthDate)
            : DateFormat("MMM ''yy").format(monthDate);
        dayLabels.add(label);
        final monthOrders = allCollected.where((o) => o.timestamp.year == monthDate.year && o.timestamp.month == monthDate.month);
        final sum = monthOrders.fold(0.0, (s, o) => s + o.price);
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else {
      // 7 Days: Exactly past 7 distinct days in chronological order with no repetition
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        final label = (i == 6) ? 'Today' : DateFormat('E').format(day);
        dayLabels.add(label);
        final dayTotal = activeOrders
            .where((o) => o.timestamp.year == day.year && o.timestamp.month == day.month && o.timestamp.day == day.day)
            .fold(0.0, (sum, o) => sum + o.price);
        spots.add(FlSpot(i.toDouble(), dayTotal));
      }
    }

    // Top Merchants
    final merchantStats = <String, _MerchantStat>{};
    for (final o in activeOrders) {
      final stat = merchantStats.putIfAbsent(
        o.businessId,
        () {
          final biz = state.businesses.where((b) => b.id == o.businessId).firstOrNull;
          return _MerchantStat(
            id: o.businessId,
            name: o.businessName.isNotEmpty ? o.businessName : (biz?.name ?? "Partner Hub"),
            category: o.category.isNotEmpty ? o.category : (biz?.category ?? "Food"),
          );
        },
      );
      stat.orderCount += 1;
      stat.totalRevenue += o.price;
    }
    final topMerchants = merchantStats.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Platform Performance",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.4,
                ),
              ),
              _buildTimeFilterPills(),
            ],
          ),
          const SizedBox(height: 18),

          // ── Sleek 4 KPI Stat Cards ────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 600 ? 2 : (width < 1000 ? 3 : 4);
              final childAspectRatio = width < 420 ? 1.0 : (width < 600 ? 1.25 : (width < 1000 ? 1.5 : 1.7));
              final spacing = width < 600 ? 10.0 : 14.0;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  _statCard("GROSS VOLUME", "GHS ${totalRevenue.toStringAsFixed(2)}", "+12.4%", Icons.payments_outlined, AppTheme.primaryGreen),
                  _statCard("NET COMMISSION", "GHS ${netProfit.toStringAsFixed(2)}", "${(commissionRate * 100).toInt()}% Rate", Icons.account_balance_outlined, const Color(0xFF2563EB)),
                  _statCard("MEALS RESCUED", "$mealsRescuedCount Saved", "Eco Impact", Icons.eco_outlined, const Color(0xFFD97706)),
                  _statCard("LIVE LISTINGS", "$activeDealsCount Deals", "Active", Icons.storefront_outlined, const Color(0xFF7C3AED)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Revenue Velocity Line Chart ───────────────
          LayoutBuilder(
            builder: (context, chartConstraints) {
              final chartNarrow = chartConstraints.maxWidth < 560;
              return Container(
                padding: EdgeInsets.all(chartNarrow ? 16 : 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _useBarChart ? "Revenue Volume Distribution" : "Revenue Growth Velocity",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _useBarChart
                                    ? "Periodic transaction totals across the selected timeline"
                                    : "Total order value trend over the selected period",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreenBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "GHS ${totalRevenue.toStringAsFixed(2)} Total",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _miniChartTypeBtn(Icons.show_chart_rounded, !_useBarChart, () => setState(() => _useBarChart = false), "Line Chart"),
                                    _miniChartTypeBtn(Icons.bar_chart_rounded, _useBarChart, () => setState(() => _useBarChart = true), "Bar Chart"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: _useBarChart
                          ? _buildBarChart(spots, dayLabels, chartNarrow)
                          : _buildLineChart(spots, dayLabels, chartNarrow),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Two Clean Bottom Cards: Top Merchants & Impact ────
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final cardPadding = constraints.maxWidth < 600 ? 16.0 : 22.0;
              final topMerchantsCard = Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Top Performing Merchants",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Partners generating the highest rescue volume",
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                    ),
                    const SizedBox(height: 16),
                    if (topMerchants.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text("No transactions recorded in this period", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                        ),
                      )
                    else
                      ...topMerchants.take(5).map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      m.name.isNotEmpty ? m.name[0].toUpperCase() : "M",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text("${m.orderCount} meals sold", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "GHS ${m.totalRevenue.toStringAsFixed(2)}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              );

              final impactCard = Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sustainability Impact",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Environmental savings from rescued food waste",
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                    ),
                    const SizedBox(height: 20),
                    _impactRow("CO₂ Emissions Prevented", "${co2SavedKg.toStringAsFixed(1)} kg", Icons.cloud_outlined, const Color(0xFF2563EB)),
                    const SizedBox(height: 14),
                    _impactRow("Freshwater Saved", "${waterSavedLitres.toStringAsFixed(0)} L", Icons.water_drop_outlined, const Color(0xFF0D9488)),
                    const SizedBox(height: 14),
                    _impactRow("Landfill Waste Diverted", "${landfillSavedKg.toStringAsFixed(1)} kg", Icons.delete_outline_rounded, const Color(0xFFD97706)),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: topMerchantsCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: impactCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    topMerchantsCard,
                    const SizedBox(height: 20),
                    impactCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String badge, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
          ),
          const SizedBox(width: 8),
          Text(value, maxLines: 1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimeFilterPills() {
    final options = ["Today", "7 Days", "30 Days", "All Time"];
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width - 48).clamp(0.0, 360.0)),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(options.length, (i) {
              final isSelected = _timeRangeIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _timeRangeIndex = i;
                    if (i == 3) {
                      _useBarChart = true; // Auto-switch to Bar Chart for All Time so data is never compressed!
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                        : [],
                  ),
                  child: Text(
                    options[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.mutedGrey,
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

  Widget _miniChartTypeBtn(IconData icon, bool selected, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                : [],
          ),
          child: Icon(
            icon,
            size: 15,
            color: selected ? AppTheme.primaryGreen : AppTheme.mutedGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, List<String> dayLabels, bool narrow) {
    final maxSpotY = spots.fold<double>(0.0, (p, s) => s.y > p ? s.y : p);
    final maxY = maxSpotY == 0 ? 100.0 : (maxSpotY * 1.25);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final label = (idx >= 0 && idx < dayLabels.length) ? dayLabels[idx] : '';
                return LineTooltipItem(
                  '$label\nGH₵ ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: narrow ? 36 : 48,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                if (val >= 1000) {
                  return Text(
                    '${(val / 1000).toStringAsFixed(1)}k',
                    maxLines: 1,
                    style: TextStyle(fontSize: narrow ? 9 : 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                  );
                }
                return Text(
                  val.toInt().toString(),
                  maxLines: 1,
                  style: TextStyle(fontSize: narrow ? 9 : 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: narrow ? 30 : 38,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      dayLabels[idx],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: narrow ? 9 : 11, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                    ),
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
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.18),
                  AppTheme.primaryGreen.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<FlSpot> spots, List<String> dayLabels, bool narrow) {
    final maxSpotY = spots.fold<double>(0.0, (p, s) => s.y > p ? s.y : p);
    final maxY = maxSpotY == 0 ? 100.0 : (maxSpotY * 1.25);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt();
              final label = (idx >= 0 && idx < dayLabels.length) ? dayLabels[idx] : '';
              return BarTooltipItem(
                '$label\nGH₵ ${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: narrow ? 36 : 48,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                if (val >= 1000) {
                  return Text(
                    '${(val / 1000).toStringAsFixed(1)}k',
                    maxLines: 1,
                    style: TextStyle(fontSize: narrow ? 9 : 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                  );
                }
                return Text(
                  val.toInt().toString(),
                  maxLines: 1,
                  style: TextStyle(fontSize: narrow ? 9 : 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: narrow ? 30 : 38,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: (narrow ? 34.0 : 48.0)),
                      child: Text(
                        dayLabels[idx],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: narrow ? 9 : 11, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(spots.length, (idx) {
          final val = spots[idx].y;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), AppTheme.primaryGreen],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: narrow ? 18 : 26,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MerchantStat {
  final String id;
  final String name;
  final String category;
  int orderCount = 0;
  double totalRevenue = 0.0;

  _MerchantStat({required this.id, required this.name, required this.category});
}
