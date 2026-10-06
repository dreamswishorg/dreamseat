import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabAudit extends ConsumerStatefulWidget {
  const TabAudit({super.key});

  @override
  ConsumerState<TabAudit> createState() => _TabAuditState();
}

class _TabAuditState extends ConsumerState<TabAudit> {
  String _query = '';
  String _actorFilter = 'All';
  String _actionFilter = 'All';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final allLogs = state.auditLogs;

    // Filter logic
    final filteredLogs = allLogs.where((l) {
      final matchesSearch = l.description.toLowerCase().contains(_query.toLowerCase()) ||
                            l.actorName.toLowerCase().contains(_query.toLowerCase()) ||
                            l.action.toLowerCase().contains(_query.toLowerCase());
      
      final matchesActor = _actorFilter == 'All' || 
                            l.actorRole.toLowerCase() == _actorFilter.toLowerCase();
      
      final matchesAction = _actionFilter == 'All' || 
                            l.action.toUpperCase().contains(_actionFilter.toUpperCase());

      return matchesSearch && matchesActor && matchesAction;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "System Audit Trail",
                      style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Monitor staff settings changes, security updates, and administrative overrides.",
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _isRefreshing
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isRefreshing = true);
                        await ref.read(appStateProvider.notifier).adminRefresh();
                        setState(() => _isRefreshing = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text("✅ Audit logs reloaded successfully!"), backgroundColor: AppTheme.primaryGreen),
                          );
                        }
                      },
                icon: _isRefreshing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                    : const Icon(Icons.refresh_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightGreenBg,
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Toolbar (Search + Filters)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: "Search logs by description, staff name, action...",
                              prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedGrey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 16),
                        _buildFilterDropdown("Actor Role", _actorFilter, ['All', 'Super_Admin', 'Admin', 'System'], (val) {
                          setState(() => _actorFilter = val ?? 'All');
                        }),
                        const SizedBox(width: 16),
                        _buildFilterDropdown("Action Category", _actionFilter, ['All', 'USER', 'PAYOUT', 'CONFIG', 'BROADCAST', 'SYSTEM'], (val) {
                          setState(() => _actionFilter = val ?? 'All');
                        }),
                      ]
                    ],
                  ),
                  if (isCompact) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown("Actor Role", _actorFilter, ['All', 'Super_Admin', 'Admin', 'System'], (val) {
                            setState(() => _actorFilter = val ?? 'All');
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterDropdown("Action Category", _actionFilter, ['All', 'USER', 'PAYOUT', 'CONFIG', 'BROADCAST', 'SYSTEM'], (val) {
                            setState(() => _actionFilter = val ?? 'All');
                          }),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Table / Cards
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1000;
                
                if (isCompact) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: filteredLogs.isEmpty
                        ? const NoDataState(msg: "No matching audit logs found.")
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (ctx, i) => _buildCompactCard(filteredLogs[i]),
                          ),
                  );
                }

                // Desktop Table structure
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Sticky table header
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _tableHeaderLabel("TIMESTAMP")),
                            Expanded(flex: 3, child: _tableHeaderLabel("ACTOR")),
                            Expanded(flex: 3, child: _tableHeaderLabel("ACTION")),
                            Expanded(flex: 3, child: _tableHeaderLabel("TARGET ENTITY")),
                            Expanded(flex: 6, child: _tableHeaderLabel("DESCRIPTION")),
                            Expanded(flex: 2, child: _tableHeaderLabel("DETAILS", align: TextAlign.end)),
                          ],
                        ),
                      ),
                      // Table body
                      Expanded(
                        child: filteredLogs.isEmpty
                            ? const NoDataState(msg: "No matching audit logs found.")
                            : ListView.separated(
                                itemCount: filteredLogs.length,
                                separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (ctx, i) => _buildTableRow(filteredLogs[i]),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderLabel(String label, {TextAlign align = TextAlign.start}) {
    return Text(
      label,
      textAlign: align,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        color: AppTheme.mutedGrey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
        ),
      ),
    );
  }

  Widget _buildTableRow(AuditLog log) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(log.createdAt);
    
    // Determine colors/badges based on actions
    Color actionColor = AppTheme.charcoal;
    IconData actionIcon = Icons.info_outline_rounded;
    if (log.action.contains('SUSPEND') || log.action.contains('DELETE') || log.action.contains('BAN')) {
      actionColor = AppTheme.errorRed;
      actionIcon = Icons.gavel_rounded;
    } else if (log.action.contains('PAYOUT') || log.action.contains('LEDGER')) {
      actionColor = AppTheme.primaryGreen;
      actionIcon = Icons.account_balance_wallet_rounded;
    } else if (log.action.contains('BROADCAST')) {
      actionColor = Colors.purple;
      actionIcon = Icons.campaign_rounded;
    } else if (log.action.contains('CONFIG') || log.action.contains('SYSTEM')) {
      actionColor = Colors.blue;
      actionIcon = Icons.settings_rounded;
    }

    return InkWell(
      onTap: () => _showAuditDetails(log),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // Timestamp
            Expanded(
              flex: 3,
              child: Text(
                timeStr,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
              ),
            ),
            // Actor Name + Role
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.actorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.charcoal)),
                  const SizedBox(height: 2),
                  Text(log.actorRole.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.5)),
                ],
              ),
            ),
            // Action
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(actionIcon, size: 14, color: actionColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        log.action,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: actionColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Target Entity
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.entityType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.charcoal)),
                  const SizedBox(height: 2),
                  Text(
                    log.entityId.length > 8 ? log.entityId.substring(0, 8).toUpperCase() : log.entityId,
                    style: const TextStyle(fontSize: 10, fontFamily: 'Courier', color: AppTheme.mutedGrey),
                  ),
                ],
              ),
            ),
            // Description
            Expanded(
              flex: 6,
              child: Text(
                log.description,
                style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Details Action
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.primaryGreen),
                  onPressed: () => _showAuditDetails(log),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(AuditLog log) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(log.createdAt);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStr, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Text(log.action, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(log.description, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Actor: ${log.actorName} (${log.actorRole})", style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () => _showAuditDetails(log),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text("Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAuditDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AuditDetailDrawer(log: log),
    );
  }
}

class _AuditDetailDrawer extends StatelessWidget {
  final AuditLog log;
  const _AuditDetailDrawer({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMMM d, yyyy • h:mm a').format(log.createdAt);
    final hasMetadata = log.metadata.isNotEmpty;
    final metaJson = hasMetadata ? const JsonEncoder.withIndent('  ').convert(log.metadata) : '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.history_edu_rounded, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Audit Record Details", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text("Action ID: ${log.id}", style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey, fontFamily: 'Courier')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detail list items
          _detailItem("Timestamp", timeStr),
          _detailItem("Action Code", log.action.toUpperCase()),
          _detailItem("Actor Account", "${log.actorName} (${log.actorRole.toUpperCase()})"),
          _detailItem("Target Entity", "${log.entityType.toUpperCase()} (ID: ${log.entityId})"),
          _detailItem("Action Summary", log.description),

          if (hasMetadata) ...[
            const SizedBox(height: 16),
            const Text("Payload Metadata (JSON)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.charcoal)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: SingleChildScrollView(
                  child: Text(
                    metaJson,
                    style: const TextStyle(fontSize: 11.5, fontFamily: 'Courier', color: AppTheme.charcoal),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          ),
        ],
      ),
    );
  }
}
