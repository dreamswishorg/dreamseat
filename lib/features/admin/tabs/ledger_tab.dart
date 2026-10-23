import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/web_utils.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';
import '../admin_providers.dart';

class TabLedger extends ConsumerStatefulWidget {
  const TabLedger({super.key});
  @override
  ConsumerState<TabLedger> createState() => _TabLedgerState();
}

class _TabLedgerState extends ConsumerState<TabLedger> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _groupByMerchant = false;

  @override
  void initState() {
    super.initState();
    final prefill = ref.read(adminLedgerSearchProvider);
    if (prefill.isNotEmpty) {
      _query = prefill;
      _searchController.text = prefill;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final orders = state.orders.where((o) =>
        o.status == 'collected' ||
        o.status == 'completed' ||
        o.payoutStatus == 'paid' ||
        o.payoutStatus == 'pending').toList();

    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Metrics Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              final gross = orders.fold(0.0, (s, o) => s + o.price);
              final pending = orders.where((o) => o.payoutStatus == 'pending').fold(0.0, (s, o) => s + (o.price * (1 - state.commissionRate)));
              final settled = orders.where((o) => o.payoutStatus == 'paid').fold(0.0, (s, o) => s + (o.price * (1 - state.commissionRate)));

              return _buildKpiBar(gross, pending, settled, isNarrow);
            },
          ),
          const SizedBox(height: 16),

          // Streamlined Unified Toolbar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 850;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Search Box + Export CSV
                  Row(
                    children: [
                      Expanded(child: _buildSearchBox()),
                      const SizedBox(width: 10),
                      isCompact
                          ? IconButton(
                              onPressed: () => _exportLedger(orders, state.commissionRate),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              tooltip: "Export CSV",
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(10),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _exportLedger(orders, state.commissionRate),
                              icon: const Icon(Icons.download_rounded, size: 15),
                              label: const Text("Export CSV", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Filters under the Search Bar
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildViewToggle(),
                      _buildPayoutFilter(orders),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _groupByMerchant
                ? _buildMerchantGrouped(orders, state.commissionRate)
                : _buildIndividual(orders, state.commissionRate),
          ),
        ],
      ),
    );
  }

  void _exportLedger(List<Order> orders, double rate) {
    final buffer = StringBuffer();
    buffer.writeln("Order ID,Merchant,Customer,Gross,Net Payout,Status,Date");
    for (var o in orders) {
      final net = o.price * (1 - rate);
      buffer.writeln("${o.id},${o.businessName},${o.customerName},${o.price},${net.toStringAsFixed(2)},${o.payoutStatus},${o.timestamp}");
    }

    try {
      downloadFile(
        content: buffer.toString(),
        fileName: "ledger_export_${DateTime.now().millisecondsSinceEpoch}.csv",
        mimeType: 'text/csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to trigger download: $e")));
      }
    }
  }

  Widget _buildSearchBox() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() => _query = v);
          if (v.isEmpty) {
            ref.read(adminLedgerSearchProvider.notifier).state = '';
          }
        },
        style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: "Search Transaction ID, Merchant...",
          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
          prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppTheme.mutedGrey),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.mutedGrey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                    ref.read(adminLedgerSearchProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildKpiBar(double gross, double pending, double settled, bool isNarrow) {
    final chips = [
      _statChip("TOTAL GROSS", "GHS ${gross.toStringAsFixed(2)}", Icons.payments_outlined, const Color(0xFF2563EB)),
      _statChip("PENDING PAYOUT", "GHS ${pending.toStringAsFixed(2)}", Icons.pending_actions_rounded, AppTheme.warningOrange),
      _statChip("SETTLED PAYOUTS", "GHS ${settled.toStringAsFixed(2)}", Icons.check_circle_outline_rounded, AppTheme.primaryGreen),
    ];

    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width * 0.72).clamp(200.0, 320.0),
                ),
                child: chips[i],
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: chips[i]),
        ],
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
              ),
              const SizedBox(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardSubtleColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.borderSubtleColor),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _toggleBtn("Orders", !_groupByMerchant, Icons.receipt_long_rounded, expanded: fullWidth),
          _toggleBtn("Merchants", _groupByMerchant, Icons.storefront_rounded, expanded: fullWidth),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool sel, IconData icon, {bool expanded = false}) {
    final btn = GestureDetector(
      onTap: () => setState(() => _groupByMerchant = label == "Merchants"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? context.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: sel && !context.isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: sel ? AppTheme.primaryGreen : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: sel ? AppTheme.primaryGreen : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? Expanded(child: btn) : btn;
  }

  Widget _buildPayoutFilter(List<Order> orders, {bool fullWidth = false}) {
    final pendingCount = orders.where((o) => o.payoutStatus == 'pending').length;
    final paidCount = orders.where((o) => o.payoutStatus == 'paid').length;
    final allCount = orders.length;

    final filterCounts = {
      'All': allCount,
      'Pending': pendingCount,
      'Paid': paidCount,
    };

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardSubtleColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.borderSubtleColor),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: ['All', 'Pending', 'Paid'].map((f) {
          final sel = _filter == f;
          final count = filterCounts[f] ?? 0;
          final btn = GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? context.cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: sel && !context.isDark
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: sel ? AppTheme.primaryGreen : context.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : context.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$count",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: sel ? AppTheme.primaryGreen : context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          return fullWidth ? Expanded(child: btn) : btn;
        }).toList(),
      ),
    );
  }

  Widget _buildIndividual(List<Order> orders, double rate) {
    final filtered = orders.where((o) {
      final matchesSearch = o.id.toLowerCase().contains(_query.toLowerCase()) ||
          o.businessName.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == 'All' || o.payoutStatus == _filter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();

    if (filtered.isEmpty) return const NoDataState(msg: "No matching settlements found.");

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 950;

        if (isCompact) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (ctx, idx) => Divider(height: 1, indent: 16, endIndent: 16, color: context.borderColor),
              itemBuilder: (ctx, i) => _buildCompactCard(filtered[i], rate),
            ),
          );
        }

        // Desktop/Tablet table form
        final tableWidth = constraints.maxWidth < 1040 ? 1040.0 : constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.borderColor),
            boxShadow: context.clientShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Sticky Header
                  Container(
                    color: context.cardAltColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: context.borderColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _tableHeaderLabel("TRANSACTION ID")),
                        Expanded(flex: 3, child: _tableHeaderLabel("MERCHANT")),
                        Expanded(flex: 3, child: _tableHeaderLabel("CUSTOMER")),
                        Expanded(flex: 2, child: _tableHeaderLabel("GROSS", align: TextAlign.end)),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _tableHeaderLabel("NET PAYOUT", align: TextAlign.end),
                          ),
                        ),
                        Expanded(flex: 2, child: _tableHeaderLabel("DATE")),
                        Expanded(flex: 2, child: _tableHeaderLabel("STATUS", align: TextAlign.center)),
                        Expanded(flex: 2, child: _tableHeaderLabel("ACTION", align: TextAlign.end)),
                      ],
                    ),
                  ),
                  // Table Body List
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, idx) => Divider(height: 1, color: context.borderColor),
                      itemBuilder: (ctx, i) => _buildIndividualRow(filtered[i], rate),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeaderLabel(String label, {TextAlign align = TextAlign.start}) {
    return Text(
      label,
      textAlign: align,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: context.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildIndividualRow(Order order, double rate) {
    final share = order.price * (1 - rate);
    final isP = order.payoutStatus == 'pending';
    final dateStr = DateFormat('MMM d, yyyy').format(order.timestamp);

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // Transaction ID
            Expanded(
              flex: 2,
              child: Text(
                order.id.substring(0, 8).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: context.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Merchant
            Expanded(
              flex: 3,
              child: Text(
                order.businessName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Customer
            Expanded(
              flex: 3,
              child: Text(
                order.customerName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Gross
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  "GHS ${order.price.toStringAsFixed(2)}",
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
            // Net Payout
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "GHS ${share.toStringAsFixed(2)}",
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: PayoutStatusBadge(status: order.payoutStatus),
              ),
            ),
            // Action
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: isP
                    ? ElevatedButton(
                        onPressed: () => _pay(context, ref, order, share),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text("Settle", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    : const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(Order order, double rate) {
    final share = order.price * (1 - rate);
    final platformFee = order.price * rate;
    final isP = order.payoutStatus == 'pending';
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(order.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.borderColor),
        boxShadow: context.clientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Transaction ID + Payout Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.cardSubtleColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long_rounded, size: 16, color: context.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "#${order.id.length > 10 ? order.id.substring(0, 10).toUpperCase() : order.id.toUpperCase()}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: context.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: PayoutStatusBadge(status: order.payoutStatus),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Merchant & Customer Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardAltColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtleColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 14, color: context.textSecondary),
                    const SizedBox(width: 6),
                    Text("Merchant: ", style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Text(
                        order.businessName.isNotEmpty ? order.businessName : "Partner Hub",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: context.textSecondary),
                    const SizedBox(width: 6),
                    Text("Customer: ", style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Text(
                        order.customerName.isNotEmpty ? order.customerName : "Rescuer",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: context.textSecondary),
                    const SizedBox(width: 6),
                    Text("Date: ", style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Vertical Financial Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gross Total", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text("GHS ${order.price.toStringAsFixed(2)}", maxLines: 1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textPrimary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Platform Fee", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text("GHS ${platformFee.toStringAsFixed(2)}", maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.indigo)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Net Payout", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text("GHS ${share.toStringAsFixed(2)}", maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: Full-width Action Button
          if (isP)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _pay(context, ref, order, share),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text("Settle Payout (GHS ${share.toStringAsFixed(2)})", maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text("Payout Disbursed to Merchant", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMerchantGrouped(List<Order> orders, double rate) {
    final Map<String, List<Order>> grouped = {};
    for (var o in orders) {
      grouped.putIfAbsent(o.businessId, () => []).add(o);
    }

    final merchants = grouped.entries.map((e) {
      final p = e.value.where((o) => o.payoutStatus == 'pending').fold(0.0, (s, o) => s + (o.price * (1 - rate)));
      return {'id': e.key, 'name': e.value.first.businessName, 'pending': p, 'orders': e.value};
    }).where((m) => (m['name'] as String).toLowerCase().contains(_query.toLowerCase())).toList();

    if (merchants.isEmpty) return const NoDataState(msg: "No merchants matching search criteria.");

    return ListView.builder(
      itemCount: merchants.length,
      itemBuilder: (ctx, i) {
        final m = merchants[i];
        final p = m['pending'] as double;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderColor),
                boxShadow: context.isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: isCompact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: context.textPrimary),
                                  ),
                                  Text("${(m['orders'] as List).length} Rescues", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.cardAltColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderSubtleColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text("PENDING BALANCE", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "GHS ${p.toStringAsFixed(2)}",
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: p > 0 ? AppTheme.warningOrange : AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (p > 0)
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmBatch(m['name'] as String, p, m['orders'] as List<Order>),
                              icon: const Icon(Icons.payment_rounded, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text("Batch Payout (GHS ${p.toStringAsFixed(2)})", maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 6),
                                  const Text("All Balances Settled", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: context.textPrimary),
                              ),
                              Text(
                                "${(m['orders'] as List).length} Total Rescues",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "GHS ${p.toStringAsFixed(2)}",
                                  maxLines: 1,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: p > 0 ? AppTheme.warningOrange : AppTheme.primaryGreen),
                                ),
                              ),
                              Text("PENDING BALANCE", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        if (p > 0)
                          ElevatedButton.icon(
                            onPressed: () => _confirmBatch(m['name'] as String, p, m['orders'] as List<Order>),
                            icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                            label: const Text("Batch Payout", style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          )
                        else
                          Chip(
                            label: const Text("SETTLED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1),
                            side: BorderSide.none,
                          )
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  void _confirmBatch(String name, double amount, List<Order> all) {
    final pending = all.where((o) => o.payoutStatus == 'pending').toList();
    showDialog(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.sizeOf(ctx).width * 0.94).clamp(240.0, 560.0),
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
          ),
          child: AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text("Authorize Dispersal", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Text(
                "You are about to initiate a MoMo settlement of GHS ${amount.toStringAsFixed(2)} to $name for ${pending.length} rescues.",
                style: TextStyle(color: context.textSecondary),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: context.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                onPressed: () async {
                  for (var o in pending) {
                    await ref.read(appStateProvider.notifier).updatePayoutStatus(o.id, 'paid');
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("✅ Dispersal of GHS ${amount.toStringAsFixed(2)} to $name successful.")));
                  }
                },
                child: const Text("Confirm & Send"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pay(BuildContext context, WidgetRef ref, Order order, double share) => showDialog(
        context: context,
        builder: (ctx) => Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.sizeOf(ctx).width * 0.94).clamp(240.0, 560.0),
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
            ),
            child: AlertDialog(
              backgroundColor: context.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Settle Transaction", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Text("Disburse GHS ${share.toStringAsFixed(2)} to ${order.businessName}?", style: TextStyle(color: context.textSecondary)),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: context.textSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    ref.read(appStateProvider.notifier).updatePayoutStatus(order.id, 'paid');
                    Navigator.pop(ctx);
                  },
                  child: const Text("Confirm"),
                ),
              ],
            ),
          ),
        ),
      );
}
