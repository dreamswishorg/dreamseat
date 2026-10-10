import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabVouchers extends ConsumerStatefulWidget {
  const TabVouchers({super.key});

  @override
  ConsumerState<TabVouchers> createState() => _TabVouchersState();
}

class _TabVouchersState extends ConsumerState<TabVouchers> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    final filtered = state.vouchers.where((v) {
      if (_searchQuery.isEmpty) return true;
      return v.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final activeCount = state.vouchers.where((v) => v.isActive).length;
    final totalUsed = state.vouchers.fold(0, (sum, v) => sum + v.usageCount);

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Toolbar ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal),
                    decoration: const InputDecoration(
                      hintText: "Search promo codes...",
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Create Voucher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Quick Summary Row ────────────────────────────────
          Row(
            children: [
              _summaryChip("Active Vouchers", "$activeCount live", AppTheme.primaryGreen),
              const SizedBox(width: 10),
              _summaryChip("Total Claims", "$totalUsed redeemed", const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 18),

          // ── Vouchers List ────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const NoDataState(msg: "No promo vouchers match your search.")
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 750;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isNarrow ? 1 : 2,
                          childAspectRatio: isNarrow ? 2.8 : 3.0,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _VoucherItemCard(voucher: filtered[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: "100");
    String type = 'percentage';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Create Promo Voucher", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.charcoal)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("VOUCHER CODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "e.g. SAVE20, EASTER50",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DISCOUNT TYPE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: type,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'percentage', child: Text("Percentage (%)", style: TextStyle(fontSize: 13))),
                                    DropdownMenuItem(value: 'fixed', child: Text("Fixed (GHS)", style: TextStyle(fontSize: 13))),
                                  ],
                                  onChanged: (v) => setDlgState(() => type = v ?? 'percentage'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("AMOUNT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: type == 'percentage' ? "e.g. 20" : "e.g. 15.00",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (v == null || double.tryParse(v) == null) ? "Invalid" : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text("USAGE LIMIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Max redemptions (e.g. 100)",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final code = codeCtrl.text.trim().toUpperCase();
                  final amount = double.parse(amountCtrl.text.trim());
                  final limit = int.tryParse(limitCtrl.text.trim()) ?? 100;
                  ref.read(appStateProvider.notifier).createVoucher(
                        code: code,
                        amount: amount,
                        type: type,
                        limit: limit,
                        fundedBy: 'platform',
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Voucher '$code' created!"), backgroundColor: AppTheme.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Create Voucher"),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherItemCard extends ConsumerWidget {
  final Voucher voucher;
  const _VoucherItemCard({required this.voucher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = voucher.usageLimit > 0 ? (voucher.usageCount / voucher.usageLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      voucher.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.mutedGrey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: "Copy code",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: voucher.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Copied '${voucher.code}'"), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    voucher.isActive ? "ACTIVE" : "PAUSED",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: voucher.isActive ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: voucher.isActive,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (v) => ref.read(appStateProvider.notifier).toggleVoucher(voucher.id, v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${voucher.discountAmount}${voucher.discountType == 'percentage' ? '%' : ' GHS'} OFF",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3),
                  ),
                  Text(
                    "Platform funded",
                    style: TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${voucher.usageCount} / ${voucher.usageLimit} uses",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: progress > 0.8 ? AppTheme.warningOrange : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
