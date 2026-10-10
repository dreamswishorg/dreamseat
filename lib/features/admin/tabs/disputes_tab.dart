import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabDisputes extends ConsumerWidget {
  const TabDisputes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(appStateProvider.select((s) => s.disputes));
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: disputes.isEmpty
                ? const NoDataState(msg: "No open tickets.")
                : ListView.builder(
                    itemCount: disputes.length,
                    itemBuilder: (ctx, i) => DisputeCard(dispute: disputes[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class DisputeCard extends ConsumerWidget {
  final DisputeTicket dispute;
  const DisputeCard({super.key, required this.dispute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = dispute.status == 'open';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(isCompact ? 20 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isOpen ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
            boxShadow: context.clientShadow,
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
                        Icon(isOpen ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: isOpen ? Colors.red : Colors.green),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TICKET: ${dispute.id.substring(0, 8).toUpperCase()}",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11),
                              ),
                              Text(
                                dispute.issueDescription,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  if (!isOpen)
                    const Chip(
                      label: Text("RESOLVED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      backgroundColor: AppTheme.lightGreenBg,
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              isCompact
                ? Column(
                    children: [
                      _buildParticipant("CLAIMANT", dispute.customerName, Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      _buildParticipant("DEFENDANT", dispute.merchantName, Icons.storefront_rounded),
                      if (isOpen) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => ref.read(appStateProvider.notifier).resolveDispute(dispute.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text("Close Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildParticipant("CLAIMANT", dispute.customerName, Icons.person_outline_rounded)),
                      Expanded(child: _buildParticipant("DEFENDANT", dispute.merchantName, Icons.storefront_rounded)),
                      if (isOpen)
                        ElevatedButton(
                          onPressed: () => ref.read(appStateProvider.notifier).resolveDispute(dispute.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(140, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text("Close Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildParticipant(String role, String name, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.charcoal.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}
