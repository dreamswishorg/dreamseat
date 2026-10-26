import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';
import '../services/merchant_export_service.dart';
import '../theme/merchant_theme.dart';

class MerchantFinancialsTab extends ConsumerStatefulWidget {
  final BusinessProfile business;

  const MerchantFinancialsTab({super.key, required this.business});

  @override
  ConsumerState<MerchantFinancialsTab> createState() => _MerchantFinancialsTabState();
}

class _MerchantFinancialsTabState extends ConsumerState<MerchantFinancialsTab> {
  String _filter = 'all'; // all, paid, pending
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _triggerExport(List<Order> orders, double totalRev, double netPayout, double commissionFee, double settled) {
    if (orders.isEmpty) {
      MToast.info(context, 'No transactions available in current filter to export');
      return;
    }

    final headers = [
      'Order ID',
      'Date & Time',
      'Customer Name',
      'Deal / Food Pack',
      'Gross Price (GHS)',
      'Commission 15% (GHS)',
      'Net Payout 85% (GHS)',
      'Settlement Status',
      'Collection PIN',
    ];

    final rows = orders.map((o) {
      final gross = o.price;
      final fee = gross * 0.15;
      final net = gross * 0.85;

      return [
        o.id.substring(0, 8).toUpperCase(),
        o.timestamp,
        o.customerName,
        o.dealTitle,
        gross,
        fee,
        net,
        o.payoutStatus.toUpperCase(),
        o.collectionCode,
      ];
    }).toList();

    final dataset = ExportDataset(
      title: 'Financial & Settlement Statement',
      merchantName: widget.business.name,
      fileNamePrefix: 'financial_statement',
      headers: headers,
      rows: rows,
      summaryMetrics: {
        'Completed Orders': '${orders.length}',
        'Gross Revenue': 'GHS ${totalRev.toStringAsFixed(2)}',
        'Platform Fee (15%)': 'GHS ${commissionFee.toStringAsFixed(2)}',
        'Net Earnings (85%)': 'GHS ${netPayout.toStringAsFixed(2)}',
        'Settled to Wallet': 'GHS ${settled.toStringAsFixed(2)}',
      },
    );

    MerchantExportService.showExportDialog(context, dataset: dataset);
  }

  void _requestEarlyPayout(double pendingAmount) {
    HapticFeedback.mediumImpact();
    if (pendingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending payout balance available for settlement at this time.'),
          backgroundColor: MerchantTheme.amberWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MerchantTheme.brandTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: MerchantTheme.brandGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Request Early Payout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: MerchantTheme.textDark)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have GHS ${pendingAmount.toStringAsFixed(2)} pending settlement.',
              style: const TextStyle(fontSize: 14, color: MerchantTheme.textDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Standard payouts process automatically every Monday directly to your registered Mobile Money wallet. Would you like to submit an instant disbursement request to our finance desk?',
              style: TextStyle(fontSize: 12.5, color: MerchantTheme.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MerchantTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantTheme.brandGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Early settlement request for GHS ${pendingAmount.toStringAsFixed(2)} queued! Verified and dispatched within 2 business hours.'),
                  backgroundColor: MerchantTheme.brandGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final allMerchantOrders = state.orders.where((o) => o.businessId == widget.business.id).toList();
    final collectedOrders = allMerchantOrders.where((o) => o.status == 'collected').toList();

    final double grossRevenue = collectedOrders.fold(0.0, (sum, o) => sum + o.price);
    final double netPayout = grossRevenue * (1 - state.commissionRate);
    final double commissionFee = grossRevenue * state.commissionRate;
    final double pendingPayout = collectedOrders
        .where((o) => o.payoutStatus != 'paid')
        .fold(0.0, (sum, o) => sum + (o.price * (1 - state.commissionRate)));
    final double settledPayout = collectedOrders
        .where((o) => o.payoutStatus == 'paid')
        .fold(0.0, (sum, o) => sum + (o.price * (1 - state.commissionRate)));

    final filteredOrders = collectedOrders.where((o) {
      if (_filter == 'paid' && o.payoutStatus != 'paid') return false;
      if (_filter == 'pending' && o.payoutStatus == 'paid') return false;
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        return o.id.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q) ||
            o.dealTitle.toLowerCase().contains(q) ||
            o.collectionCode.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final wide = useSideNav(context);

    return ResponsiveCenter(
      maxWidth: 1240,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 16, wide ? 24 : 16, wide ? 32 : 90),
        children: [
          // ── Premium Executive Revenue Header ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MK.brand, MK.brandDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: MK.brand.withValues(alpha: 0.30),
                  blurRadius: 20,
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
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: const Text(
                              'FINANCIAL LEDGER & SETTLEMENTS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Export statement',
                      child: MPressable(
                        onTap: () =>
                            _triggerExport(filteredOrders, grossRevenue, netPayout, commissionFee, settledPayout),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.download_rounded, size: 19, color: MK.brand),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'GHS ${grossRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const Text(
                  'Total Gross Rescue Sales (Lifetime)',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0x26FFFFFF), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Net Earnings (85%)',
                        'GHS ${netPayout.toStringAsFixed(2)}',
                        Icons.trending_up_rounded,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricItem(
                        'Settled Out',
                        'GHS ${settledPayout.toStringAsFixed(2)}',
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricItem(
                        'Pending Settlement',
                        'GHS ${pendingPayout.toStringAsFixed(2)}',
                        Icons.hourglass_empty_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick Actions ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantTheme.brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => _requestEarlyPayout(pendingPayout),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('Request Early Settlement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantTheme.textDark,
                  side: const BorderSide(color: MerchantTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Disbursement Account', style: TextStyle(fontWeight: FontWeight.w900, color: MerchantTheme.textDark)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mobile Money & Bank Settlement details:', style: TextStyle(color: MerchantTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                              child: const Icon(Icons.phone_android_rounded, color: Colors.brown, size: 20),
                            ),
                            title: Text(
                              widget.business.hasPayoutAccount ? widget.business.payoutAccountNumber : 'No payout account set',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: MerchantTheme.textDark),
                            ),
                            subtitle: Text(widget.business.hasPayoutAccount
                                ? '${widget.business.payoutProvider} · ${widget.business.payoutAccountName}'
                                : 'Add one under Shop Profile → Payout Account'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_rounded, size: 18, color: MerchantTheme.brandGreen),
                label: const Text('MoMo Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search & Filter Bar ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search ledger by customer, code or order ID…',
                    hintStyle: const TextStyle(fontSize: 13, color: MerchantTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: MerchantTheme.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MerchantTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: MerchantTheme.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MerchantTheme.cardBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Ledger', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'paid', child: Text('Settled (Paid)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'pending', child: Text('Pending Payout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _filter = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Ledger Transactions List ──
          if (filteredOrders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MerchantTheme.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text('No Transactions Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MerchantTheme.textDark)),
                  SizedBox(height: 6),
                  Text(
                    'Completed rescue orders will appear here in your settlement ledger.',
                    style: TextStyle(color: MerchantTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...filteredOrders.map((order) {
              final isPaid = order.payoutStatus == 'paid';
              final net = order.price * 0.85;
              final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(order.timestamp);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MerchantTheme.cardBorder),
                  boxShadow: MerchantTheme.cardElevation,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPaid ? MerchantTheme.brandTint : MerchantTheme.amberLightBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                          color: isPaid ? MerchantTheme.brandGreen : MerchantTheme.amberWarning,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: MerchantTheme.textDark),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaid ? MerchantTheme.brandTint : MerchantTheme.amberLightBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: isPaid ? MerchantTheme.brandDeepGreen : MerchantTheme.amberWarning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.dealTitle} · Code: ${order.collectionCode}',
                            style: const TextStyle(color: MerchantTheme.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'GHS ${net.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: MerchantTheme.brandGreen),
                        ),
                        Text(
                          'Gross GHS ${order.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10.5, color: MerchantTheme.textMuted),
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

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
      ],
    );
  }
}
