import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabPulse extends ConsumerWidget {
  const TabPulse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // source: audit_logs filtered for important events
    final logs = ref.watch(appStateProvider.select((s) => s.auditLogs));

    final isMobile = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: logs.isEmpty
                        ? const NoDataState(msg: "Waiting for platform signals...", icon: Icons.sensors_rounded)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) => _PulseTile(log: logs[i]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          const Text("Live Activity Ticker", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  final dynamic log;
  const _PulseTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(log.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Text(time, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.mutedGrey.withValues(alpha: 0.6))),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getBg(log.action),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.action.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _getColor(log.action)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppTheme.charcoal),
                children: [
                  TextSpan(text: log.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: " "),
                  TextSpan(text: log.description, style: const TextStyle(color: AppTheme.mutedGrey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String action) {
    if (action.contains('create')) return Colors.blue;
    if (action.contains('approve')) return AppTheme.primaryGreen;
    if (action.contains('suspend') || action.contains('cancel')) return AppTheme.errorRed;
    return AppTheme.charcoal;
  }

  Color _getBg(String action) => _getColor(action).withValues(alpha: 0.1);
}
