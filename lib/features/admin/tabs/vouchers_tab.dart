import 'package:flutter/material.dart';
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
  final _c = TextEditingController();
  final _a = TextEditingController();
  final String _t = 'percentage';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAdd,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isCompact ? "New" : "New Voucher"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(isCompact ? 100 : 160, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.vouchers.isEmpty
                ? const NoDataState(msg: "No active vouchers found.")
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1400 ? 4 : (constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 3.0,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: state.vouchers.length,
                        itemBuilder: (ctx, i) => VoucherCard(voucher: state.vouchers[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAdd() => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Create"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _c, decoration: const InputDecoration(labelText: "Code")),
              TextField(controller: _a, decoration: const InputDecoration(labelText: "Amount")),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                ref.read(appStateProvider.notifier).createVoucher(
                      code: _c.text,
                      amount: double.parse(_a.text),
                      type: _t,
                      limit: 100,
                      fundedBy: 'platform',
                    );
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            )
          ],
        ),
      );
}

class VoucherCard extends ConsumerWidget {
  final Voucher voucher;
  const VoucherCard({super.key, required this.voucher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  voucher.code,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: voucher.isActive,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (v) => ref.read(appStateProvider.notifier).toggleVoucher(voucher.id, v),
                ),
              )
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${voucher.discountAmount}${voucher.discountType == 'percentage' ? '%' : ' GHS'} OFF",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.charcoal),
                  ),
                  Text(
                    "${voucher.usageCount}/${voucher.usageLimit} uses",
                    style: const TextStyle(fontSize: 10, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (voucher.isActive)
                const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryGreen)
              else
                const Icon(Icons.pause_circle_filled_rounded, size: 16, color: AppTheme.mutedGrey),
            ],
          ),
        ],
      ),
    );
  }
}
