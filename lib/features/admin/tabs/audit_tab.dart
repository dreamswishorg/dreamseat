import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/web_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final logs = state.auditLogs;

    // Filter logs across all actors (Admin, Merchant, Customer, System)
    final filteredLogs = logs.where((l) {
      final matchesQuery = _query.isEmpty ||
          l.description.toLowerCase().contains(_query.toLowerCase()) ||
          l.actorName.toLowerCase().contains(_query.toLowerCase()) ||
          l.action.toLowerCase().contains(_query.toLowerCase()) ||
          l.entityId.toLowerCase().contains(_query.toLowerCase());

      final actorRole = l.actorRole.toLowerCase();
      final matchesActor = _actorFilter == 'All' ||
          (_actorFilter == 'Admin' && (actorRole.contains('admin') || actorRole == 'super_admin')) ||
          (_actorFilter == 'Merchant' && actorRole.contains('merchant')) ||
          (_actorFilter == 'Customer' && actorRole.contains('customer')) ||
          (_actorFilter == 'System' && actorRole.contains('system'));

      final action = l.action.toUpperCase();
      final matchesAction = _actionFilter == 'All' || action.contains(_actionFilter.toUpperCase());

      return matchesQuery && matchesActor && matchesAction;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek streamlined Toolbar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              return Column(
                children: [
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: "Search logs by description, staff, action...",
                              hintStyle: TextStyle(fontSize: 12.5, color: context.textSecondary),
                              prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 12),
                        AdminDropdown<String>(
                          label: "Actor Role",
                          value: _actorFilter,
                          items: const ['All', 'Admin', 'Merchant', 'Customer', 'System'],
                          onChanged: (val) => setState(() => _actorFilter = val ?? 'All'),
                        ),
                        const SizedBox(width: 12),
                        AdminDropdown<String>(
                          label: "Category",
                          value: _actionFilter,
                          items: const ['All', 'ORDER', 'DEAL', 'MERCHANT', 'USER', 'PAYOUT', 'SYSTEM'],
                          onChanged: (val) => setState(() => _actionFilter = val ?? 'All'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _exportAuditCsv(filteredLogs),
                          icon: const Icon(Icons.download_rounded, size: 15),
                          label: const Text("Export CSV", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ]
                    ],
                  ),
                  if (isCompact) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AdminDropdown<String>(
                            label: "Role",
                            value: _actorFilter,
                            items: const ['All', 'Admin', 'Merchant', 'Customer', 'System'],
                            onChanged: (val) => setState(() => _actorFilter = val ?? 'All'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminDropdown<String>(
                            label: "Category",
                            value: _actionFilter,
                            items: const ['All', 'ORDER', 'DEAL', 'MERCHANT', 'USER', 'PAYOUT', 'SYSTEM'],
                            onChanged: (val) => setState(() => _actionFilter = val ?? 'All'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _exportAuditCsv(filteredLogs),
                          icon: const Icon(Icons.download_rounded, size: 15),
                          label: const Text("CSV", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Main Table / Cards
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1000;

                if (isCompact) {
                  return Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: filteredLogs.isEmpty
                        ? const NoDataState(msg: "No matching audit logs found.")
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            separatorBuilder: (ctx, idx) => Divider(height: 1, color: context.borderColor),
                            itemBuilder: (ctx, i) => _buildCompactCard(filteredLogs[i]),
                          ),
                  );
                }

                // Desktop Table structure
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.borderColor),
                    boxShadow: context.clientShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Sticky table header
                      Container(
                        color: context.cardAltColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: context.borderColor)),
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
                                separatorBuilder: (ctx, idx) => Divider(height: 1, color: context.borderColor),
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
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        color: context.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTableRow(AuditLog log) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(log.createdAt);

    Color actionColor = AppTheme.primaryGreen;
    IconData actionIcon = Icons.info_outline_rounded;
    final act = log.action.toUpperCase();

    if (act.contains('ORDER')) {
      actionColor = AppTheme.primaryGreen;
      actionIcon = Icons.shopping_bag_outlined;
    } else if (act.contains('DEAL')) {
      actionColor = AppTheme.warningOrange;
      actionIcon = Icons.local_offer_outlined;
    } else if (act.contains('MERCHANT')) {
      actionColor = Colors.purple;
      actionIcon = Icons.storefront_outlined;
    } else if (act.contains('USER') || act.contains('PROFILE')) {
      actionColor = const Color(0xFF2563EB);
      actionIcon = Icons.person_outline_rounded;
    } else if (act.contains('SUSPEND') || act.contains('DELETE') || act.contains('BAN') || act.contains('CANCEL')) {
      actionColor = AppTheme.errorRed;
      actionIcon = Icons.gavel_rounded;
    } else if (act.contains('PAYOUT') || act.contains('LEDGER')) {
      actionColor = AppTheme.primaryGreen;
      actionIcon = Icons.account_balance_wallet_rounded;
    } else if (act.contains('BROADCAST')) {
      actionColor = Colors.indigo;
      actionIcon = Icons.campaign_rounded;
    } else if (act.contains('CONFIG') || act.contains('SYSTEM')) {
      actionColor = const Color(0xFF0D9488);
      actionIcon = Icons.settings_suggest_rounded;
    }

    // Role colors and badge labels
    Color roleColor = AppTheme.mutedGrey;
    String roleLabel = log.actorRole.toUpperCase();
    final role = log.actorRole.toLowerCase();
    if (role.contains('super')) {
      roleColor = AppTheme.errorRed;
      roleLabel = "👑 SUPER ADMIN";
    } else if (role.contains('admin')) {
      roleColor = const Color(0xFF2563EB);
      roleLabel = "🛡️ ADMIN";
    } else if (role.contains('merchant')) {
      roleColor = Colors.purple;
      roleLabel = "🏪 MERCHANT";
    } else if (role.contains('customer')) {
      roleColor = AppTheme.warningOrange;
      roleLabel = "🛍️ CUSTOMER";
    } else if (role.contains('system')) {
      roleColor = const Color(0xFF64748B);
      roleLabel = "⚙️ SYSTEM";
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
                style: TextStyle(fontSize: 12.5, color: context.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            // Actor Name + Role Badge
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.actorName,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.4),
                    ),
                  ),
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
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
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
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.entityType.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    log.entityId.length > 8 ? log.entityId.substring(0, 8).toUpperCase() : log.entityId,
                    style: TextStyle(fontSize: 10, fontFamily: 'Courier', color: context.textSecondary),
                  ),
                ],
              ),
            ),
            // Description
            Expanded(
              flex: 6,
              child: Text(
                log.description,
                style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Details Action
            Expanded(
              flex: 1,
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

    Color actionColor = AppTheme.primaryGreen;
    final act = log.action.toUpperCase();
    if (act.contains('ORDER')) {
      actionColor = AppTheme.primaryGreen;
    } else if (act.contains('DEAL')) {
      actionColor = AppTheme.warningOrange;
    } else if (act.contains('MERCHANT')) {
      actionColor = Colors.purple;
    } else if (act.contains('USER')) {
      actionColor = const Color(0xFF2563EB);
    } else if (act.contains('CANCEL') || act.contains('SUSPEND') || act.contains('BAN')) {
      actionColor = AppTheme.errorRed;
    }

    Color roleColor = AppTheme.mutedGrey;
    String roleLabel = log.actorRole.toUpperCase();
    final role = log.actorRole.toLowerCase();
    if (role.contains('super')) {
      roleColor = AppTheme.errorRed;
      roleLabel = "SUPER ADMIN";
    } else if (role.contains('admin')) {
      roleColor = const Color(0xFF2563EB);
      roleLabel = "ADMIN";
    } else if (role.contains('merchant')) {
      roleColor = Colors.purple;
      roleLabel = "MERCHANT";
    } else if (role.contains('customer')) {
      roleColor = AppTheme.warningOrange;
      roleLabel = "CUSTOMER";
    } else if (role.contains('system')) {
      roleColor = const Color(0xFF64748B);
      roleLabel = "SYSTEM";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStr, style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.action,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: actionColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(log.description, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.actorName,
                  style: TextStyle(fontSize: 11.5, color: context.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _showAuditDetails(log),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text("Details", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
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

  void _exportAuditCsv(List<AuditLog> logs) {
    final buffer = StringBuffer();
    buffer.writeln("Log ID,Timestamp,Actor,Role,Action,Entity Type,Entity ID,Description");
    for (var l in logs) {
      buffer.writeln("${l.id},${l.createdAt},${l.actorName},${l.actorRole},${l.action},${l.entityType},${l.entityId},\"${l.description.replaceAll('"', '""')}\"");
    }

    try {
      downloadFile(
        content: buffer.toString(),
        fileName: "audit_trail_${DateTime.now().millisecondsSinceEpoch}.csv",
        mimeType: 'text/csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
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
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 44, height: 5, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: context.isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_edu_rounded, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Audit Record Details", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: context.textPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text("Action ID: ${log.id}", style: TextStyle(fontSize: 11.5, color: context.textSecondary, fontFamily: 'Courier')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detail list items
          _detailItem(context, "Timestamp", timeStr),
          _detailItem(context, "Action Code", log.action.toUpperCase()),
          _detailItem(context, "Actor Account", "${log.actorName} (${log.actorRole.toUpperCase()})"),
          _detailItem(context, "Target Entity", "${log.entityType.toUpperCase()} (ID: ${log.entityId})"),
          _detailItem(context, "Action Summary", log.description),

          if (hasMetadata) ...[
            const SizedBox(height: 16),
            Text("Payload Metadata (JSON)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.textPrimary)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardAltColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    metaJson,
                    style: TextStyle(fontSize: 11.5, fontFamily: 'Courier', color: context.textPrimary),
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
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: context.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
          ),
        ],
      ),
    );
  }
}
