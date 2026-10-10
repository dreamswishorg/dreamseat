import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabDisputes extends ConsumerStatefulWidget {
  const TabDisputes({super.key});

  @override
  ConsumerState<TabDisputes> createState() => _TabDisputesState();
}

class _TabDisputesState extends ConsumerState<TabDisputes> {
  String _searchQuery = '';
  int _selectedStatusFilter = 0; // 0 = Open, 1 = Resolved, 2 = All

  @override
  Widget build(BuildContext context) {
    final disputes = ref.watch(appStateProvider.select((s) => s.disputes));
    final openCount = disputes.where((d) => d.status == 'open').length;
    final resolvedCount = disputes.where((d) => d.status != 'open').length;

    final filteredDisputes = disputes.where((d) {
      final matchesStatus = _selectedStatusFilter == 0
          ? d.status == 'open'
          : (_selectedStatusFilter == 1 ? d.status != 'open' : true);

      final matchesQuery = _searchQuery.isEmpty ||
          d.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.issueDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.merchantName.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesQuery;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Toolbar: Search & Queue Pills ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.charcoal),
                    decoration: const InputDecoration(
                      hintText: "Search dispute ID, customer, merchant...",
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _filterTab("Open ($openCount)", 0),
                    _filterTab("Resolved ($resolvedCount)", 1),
                    _filterTab("All (${disputes.length})", 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Disputes List ──────────────────────────────────────
          Expanded(
            child: filteredDisputes.isEmpty
                ? NoDataState(
                    icon: _selectedStatusFilter == 0 ? Icons.check_circle_outline_rounded : Icons.gavel_rounded,
                    msg: _selectedStatusFilter == 0
                        ? "Zero active disputes in arbitration."
                        : "No dispute records match your search criteria.",
                  )
                : ListView.builder(
                    itemCount: filteredDisputes.length,
                    itemBuilder: (ctx, i) => _DisputeCard(dispute: filteredDisputes[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, int index) {
    final isSel = _selectedStatusFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSel
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? (index == 0 && label.contains("0") == false ? AppTheme.errorRed : AppTheme.primaryGreen) : AppTheme.mutedGrey,
          ),
        ),
      ),
    );
  }
}

class _DisputeCard extends ConsumerWidget {
  final DisputeTicket dispute;
  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = dispute.status == 'open';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? AppTheme.errorRed.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header (Ticket ID badge + Status Badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "DISPUTE #${dispute.id.length > 8 ? dispute.id.substring(0, 8).toUpperCase() : dispute.id.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (dispute.orderId.isNotEmpty)
                    Text(
                      "Order: #${dispute.orderId.length > 8 ? dispute.orderId.substring(0, 8).toUpperCase() : dispute.orderId.toUpperCase()}",
                      style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isOpen ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                      size: 13,
                      color: isOpen ? AppTheme.errorRed : AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? "UNDER REVIEW" : "RESOLVED",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isOpen ? AppTheme.errorRed : AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Issue Statement
          Text(
            dispute.issueDescription,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Row 3: Parties involved & Action button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CLAIMANT", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                            Text(
                              dispute.customerName.isNotEmpty ? dispute.customerName : "Customer",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DEFENDANT", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                            Text(
                              dispute.merchantName.isNotEmpty ? dispute.merchantName : "Merchant Partner",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(appStateProvider.notifier).resolveDispute(dispute.id),
                    icon: const Icon(Icons.done_all_rounded, size: 14),
                    label: const Text("Resolve Dispute", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
