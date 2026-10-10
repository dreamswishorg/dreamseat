import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

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

  void _exportCsv(List<Order> orders, double totalRev, double netPayout) {
    HapticFeedback.lightImpact();
    final buffer = StringBuffer();
    buffer.writeln('Order ID,Date,Customer,Deal,Price (GHS),Net Payout (85%),Payout Status');
    for (final o in orders) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(o.timestamp);
      final net = (o.price * 0.85).toStringAsFixed(2);
      buffer.writeln('${o.id},$dateStr,"${o.customerName}","${o.dealTitle}",${o.price.toStringAsFixed(2)},$net,${o.payoutStatus}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial statement copied to clipboard in CSV format!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestEarlyPayout(double pendingAmount) {
    HapticFeedback.mediumImpact();
    if (pendingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending payout balance available for settlement at this time.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Request Early Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have GHS ${pendingAmount.toStringAsFixed(2)} pending settlement.',
              style: const TextStyle(fontSize: 14, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Standard payouts process automatically every Monday to your registered Mobile Money wallet. Would you like to submit an instant disbursement request to our finance desk?',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Early settlement request for GHS ${pendingAmount.toStringAsFixed(2)} queued! Our finance desk will verify and dispatch within 2 business hours.'),
                  backgroundColor: AppTheme.primaryGreen,
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

    return ResponsiveCenter(
      maxWidth: 1100,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // ── Header Card ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2F1E), Color(0xFF144D31)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2F1E).withValues(alpha: 0.3),
                  blurRadius: 18,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'SETTLEMENTS & PAYOUTS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _exportCsv(collectedOrders, grossRevenue, netPayout),
                      icon: const Icon(Icons.download_rounded, size: 15),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                  'Total Gross Rescue Sales',
                  style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Net Earnings (85%)',
                        'GHS ${netPayout.toStringAsFixed(2)}',
                        const Color(0xFF6EE7B7),
                        Icons.trending_up_rounded,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricItem(
                        'Settled Out',
                        'GHS ${settledPayout.toStringAsFixed(2)}',
                        Colors.blue.shade200,
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricItem(
                        'Pending Payout',
                        'GHS ${pendingPayout.toStringAsFixed(2)}',
                        Colors.amber.shade200,
                        Icons.hourglass_empty_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick Action Strip ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
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
                  foregroundColor: AppTheme.charcoal,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Disbursement Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mobile Money & Bank Settlement details:', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                              child: const Icon(Icons.phone_android_rounded, color: Colors.brown, size: 20),
                            ),
                            title: Text(widget.business.phone.isNotEmpty ? widget.business.phone : '024 123 4567', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('MTN Mobile Money / Telecel Cash'),
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
                icon: const Icon(Icons.account_balance_rounded, size: 18, color: AppTheme.primaryGreen),
                label: const Text('MoMo Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Filter & Search Bar ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search ledger by customer, code or order...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.mutedGrey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No Transactions Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Completed rescue orders will appear here in your settlement ledger.', style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13), textAlign: TextAlign.center),
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPaid ? AppTheme.lightGreenBg : Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                          color: isPaid ? AppTheme.primaryGreen : Colors.amber.shade800,
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
                                '#${order.collectionCode}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.charcoal),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaid ? AppTheme.lightGreenBg : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'PENDING',
                                  style: TextStyle(
                                    color: isPaid ? AppTheme.primaryGreen : Colors.amber.shade900,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${order.customerName} • ${order.dealTitle}',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'GHS ${net.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen),
                        ),
                        Text(
                          'Gross: GHS ${order.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
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

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
