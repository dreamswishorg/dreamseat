import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/web_utils.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabAccounts extends ConsumerStatefulWidget {
  const TabAccounts({super.key});
  @override
  ConsumerState<TabAccounts> createState() => _TabAccountsState();
}

class _TabAccountsState extends ConsumerState<TabAccounts> {
  String _query = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  int _currentPage = 0;
  static const int _itemsPerPage = 20;

  // Bulk selection state
  final Set<String> _selectedUserIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    // Filtering Logic
    final filteredUsers = state.users.where((u) {
      final matchesSearch = u.name.toLowerCase().contains(_query.toLowerCase()) ||
                          u.email.toLowerCase().contains(_query.toLowerCase());

      final matchesRole = _roleFilter == 'All' ||
                         (_roleFilter == 'Staff' ? (u.role == 'admin' || u.role == 'super_admin') : u.role == _roleFilter.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
                           (_statusFilter == 'Active' ? !u.isSuspended : u.isSuspended);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    // Pagination Logic
    final totalPages = (filteredUsers.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final paginatedUsers = filteredUsers.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Quick Filter Bar
          _buildKpiCards(state),
          const SizedBox(height: 16),

          // Filter Toolbar
          _buildToolbar(filteredUsers),
          const SizedBox(height: 16),

          // User Table
          Expanded(
            child: Container(
              decoration: isMobile
                  ? null
                  : BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.clientShadow,
                    ),
              clipBehavior: isMobile ? Clip.none : Clip.antiAlias,
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: paginatedUsers.isEmpty
                        ? const NoDataState(msg: "No accounts match your filters.")
                        : ListView.separated(
                            padding: isMobile ? const EdgeInsets.symmetric(vertical: 8) : EdgeInsets.zero,
                            itemCount: paginatedUsers.length,
                            separatorBuilder: (_, _) => isMobile ? const SizedBox(height: 8) : const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final u = paginatedUsers[i];
                              return _UserRow(
                                user: u,
                                onView: () => _showUserDetails(u),
                                isSuperAdmin: state.currentUser?.role == 'super_admin',
                                currentAdminId: state.currentUser?.id,
                                isSelected: _selectedUserIds.contains(u.id),
                                onSelectChanged: (v) => _toggleSelection(u.id),
                              );
                            },
                          ),
                  ),
                  if (totalPages > 1) _buildPagination(totalPages),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(AppState state) {
    final total = state.users.length;
    final customers = state.users.where((u) => u.role == 'customer').length;
    final merchants = state.users.where((u) => u.role == 'merchant').length;
    final staff = state.users.where((u) => u.role == 'admin' || u.role == 'super_admin').length;
    final suspended = state.users.where((u) => u.isSuspended).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _kpiPill("All Accounts", total, Icons.people_alt_rounded, _roleFilter == 'All' && _statusFilter == 'All', () {
            setState(() { _roleFilter = 'All'; _statusFilter = 'All'; _currentPage = 0; });
          }, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          _kpiPill("Customers", customers, Icons.shopping_bag_outlined, _roleFilter == 'Customer', () {
            setState(() { _roleFilter = 'Customer'; _statusFilter = 'All'; _currentPage = 0; });
          }, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          _kpiPill("Merchants", merchants, Icons.storefront_rounded, _roleFilter == 'Merchant', () {
            setState(() { _roleFilter = 'Merchant'; _statusFilter = 'All'; _currentPage = 0; });
          }, color: const Color(0xFFD97706)),
          const SizedBox(width: 8),
          _kpiPill("Staff Team", staff, Icons.shield_rounded, _roleFilter == 'Staff', () {
            setState(() { _roleFilter = 'Staff'; _statusFilter = 'All'; _currentPage = 0; });
          }, color: AppTheme.charcoal),
          const SizedBox(width: 8),
          _kpiPill("Suspended", suspended, Icons.block_rounded, _statusFilter == 'Suspended', () {
            setState(() { _statusFilter = 'Suspended'; _roleFilter = 'All'; _currentPage = 0; });
          }, color: AppTheme.errorRed),
        ],
      ),
    );
  }

  Widget _kpiPill(String title, int count, IconData icon, bool isActive, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : context.borderColor,
            width: isActive ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? color : context.textSecondary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? color : context.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? color : context.borderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(List<AppUser> filteredUsers) {
    final hasSelection = _selectedUserIds.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search or Selection
          if (hasSelection)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${_selectedUserIds.length} Selected", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => setState(() => _selectedUserIds.clear()),
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BulkActionButton(
                    label: "Send Voucher",
                    icon: Icons.confirmation_number_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sending bulk vouchers to ${_selectedUserIds.length} users...")));
                    },
                  ),
                  const SizedBox(width: 12),
                  _BulkActionButton(
                    label: "Suspend All",
                    icon: Icons.block_rounded,
                    color: AppTheme.errorRed,
                    onPressed: () {
                      for (var id in _selectedUserIds) {
                        ref.read(appStateProvider.notifier).toggleUserSuspension(id);
                      }
                      setState(() => _selectedUserIds.clear());
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                onChanged: (v) => setState(() { _query = v; _currentPage = 0; }),
                style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Search name, email...",
                  hintStyle: TextStyle(fontSize: 12.5, color: context.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Filters and Actions (Wrapped)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterDropdown("Role", _roleFilter, ['All', 'Customer', 'Merchant', 'Staff'], (v) {
                setState(() { _roleFilter = v!; _currentPage = 0; });
              }),
              _buildFilterDropdown("Status", _statusFilter, ['All', 'Active', 'Suspended'], (v) {
                setState(() { _statusFilter = v!; _currentPage = 0; });
              }),
              _ExportButton(
                label: "Export Users",
                onPressed: () => _exportToCSV(filteredUsers),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateStaffDialog(context),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text("New Staff", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        if (hasSelection) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Text("${_selectedUserIds.length} Selected", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() => _selectedUserIds.clear()),
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BulkActionButton(
            label: "Send Voucher",
            icon: Icons.confirmation_number_rounded,
            onPressed: () {
              // Open bulk voucher dialog
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sending bulk vouchers to ${_selectedUserIds.length} users...")));
            },
          ),
          const SizedBox(width: 12),
          _BulkActionButton(
            label: "Suspend All",
            icon: Icons.block_rounded,
            color: AppTheme.errorRed,
            onPressed: () {
               for (var id in _selectedUserIds) {
                 ref.read(appStateProvider.notifier).toggleUserSuspension(id);
               }
               setState(() => _selectedUserIds.clear());
            },
          ),
        ] else ...[
          // Search
          Expanded(
            flex: 3,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                onChanged: (v) => setState(() { _query = v; _currentPage = 0; }),
                style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Search name, email...",
                  hintStyle: TextStyle(fontSize: 12.5, color: context.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 16),
        // Role Filter
        _buildFilterDropdown("Role", _roleFilter, ['All', 'Customer', 'Merchant', 'Staff'], (v) {
          setState(() { _roleFilter = v!; _currentPage = 0; });
        }),
        const SizedBox(width: 12),
        // Status Filter
        _buildFilterDropdown("Status", _statusFilter, ['All', 'Active', 'Suspended'], (v) {
          setState(() { _statusFilter = v!; _currentPage = 0; });
        }),
        const Spacer(),
        _ExportButton(
          label: "Export Users",
          onPressed: () => _exportToCSV(filteredUsers),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showCreateStaffDialog(context),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text("New Staff", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return AdminDropdown<String>(
      label: label,
      value: value,
      items: options,
      onChanged: onChanged,
    );
  }

  Widget _buildTableHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 900) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: context.cardAltColor,
      child: Row(
        children: [
          const SizedBox(width: 56), // Multi-select Checkbox column offset
          Expanded(flex: 3, child: Text("USER IDENTITY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5))),
          Expanded(flex: 2, child: Text("ROLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5))),
          Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5))),
          Expanded(flex: 2, child: Text("POINTS & WALLET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5))),
          SizedBox(width: 200, child: Text("ACTIONS", textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.textSecondary, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Showing ${_currentPage * _itemsPerPage + 1} to ${(_currentPage + 1) * _itemsPerPage} of records", style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Text("Page ${_currentPage + 1} of $totalPages", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserDetails(AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserDetailDrawer(user: user),
    );
  }

  void _exportToCSV(List<AppUser> users) {
    final buffer = StringBuffer();
    buffer.writeln("ID,Name,Email,Role,Status,Points,Credit,Joined");
    for (var u in users) {
      buffer.writeln("${u.id},${u.name},${u.email},${u.role},${u.isSuspended ? 'Suspended' : 'Active'},${u.dreamPoints},${u.referralCredit},${u.createdAt}");
    }

    try {
      downloadFile(
        content: buffer.toString(),
        fileName: "users_export_${DateTime.now().millisecondsSinceEpoch}.csv",
        mimeType: 'text/csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to trigger download: $e")));
      }
    }
  }

  void _showCreateStaffDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Map of privilege keys to display labels
    final Map<String, String> privLabels = {
      'analytics': 'Analytics Hub',
      'approvals': 'Merchant Approvals',
      'directory': 'User Directory',
      'ledger': 'System Ledger',
      'vouchers': 'Promo Vouchers',
      'disputes': 'Dispute Center',
      'support': 'Support Desk',
      'map': 'Operational Map',
      'broadcasts': 'Global Broadcasts',
      'config': 'Infrastructure Config',
      'audit': 'Audit Trail',
      'pulse': 'Real-time Activity',
      'seed': 'Database Seed',
    };

    // Predefined roles templates
    final Map<String, List<String>> roleTemplates = {
      'Administrator': privLabels.keys.toList(),
      'Operations': ['analytics', 'approvals', 'map', 'broadcasts'],
      'Support Desk Agent': ['directory', 'disputes', 'support'],
      'Financial Controller': ['analytics', 'ledger', 'vouchers'],
      'Custom': [],
    };

    String selectedRole = 'Operations';
    Set<String> selectedPrivs = Set.from(roleTemplates['Operations']!);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppTheme.primaryGreen),
                  SizedBox(width: 12),
                  Text("Add New Staff Account", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Staff Details", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, fontSize: 11, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            hintText: "e.g., Kofi Mensah",
                            prefixIcon: const Icon(Icons.person_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            hintText: "e.g., kofi@dreameats.app",
                            prefixIcon: const Icon(Icons.email_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Email is required";
                            if (!val.contains('@')) return "Enter a valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Temporary Password",
                            hintText: "At least 8 characters",
                            prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.length < 8 ? "Password must be at least 8 chars" : null,
                        ),
                        const SizedBox(height: 24),
                        const Text("Role & Access Permissions", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, fontSize: 11, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            labelText: "Staff Role Preset",
                            prefixIcon: const Icon(Icons.work_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: roleTemplates.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedRole = val;
                              if (val != 'Custom') {
                                selectedPrivs = Set.from(roleTemplates[val]!);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text("Allowed App Sections", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView(
                            shrinkWrap: true,
                            children: privLabels.entries.map((entry) {
                              final key = entry.key;
                              final label = entry.value;
                              return CheckboxListTile(
                                activeColor: AppTheme.primaryGreen,
                                dense: true,
                                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                value: selectedPrivs.contains(key),
                                onChanged: (checked) {
                                  setModalState(() {
                                    selectedRole = 'Custom';
                                    if (checked == true) {
                                      selectedPrivs.add(key);
                                    } else {
                                      selectedPrivs.remove(key);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedPrivs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select at least one permission section."), backgroundColor: AppTheme.errorRed),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final error = await ref.read(appStateProvider.notifier).createStaffAccount(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                privileges: selectedPrivs.toList(),
                              );
                          if (context.mounted) {
                            setModalState(() => isSaving = false);
                            if (error == null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("✅ Staff account created successfully!"), backgroundColor: AppTheme.primaryGreen),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $error"), backgroundColor: AppTheme.errorRed),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Create Staff Account", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ExportButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.download_rounded, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        foregroundColor: AppTheme.charcoal,
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _BulkActionButton({required this.label, required this.icon, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.charcoal;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: c.withValues(alpha: 0.1),
        foregroundColor: c,
        minimumSize: const Size(120, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  final AppUser user;
  final VoidCallback onView;
  final bool isSuperAdmin;
  final String? currentAdminId;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;

  const _UserRow({
    required this.user,
    required this.onView,
    required this.isSuperAdmin,
    this.currentAdminId,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSelf = user.id == currentAdminId;
    final bool isStaff = user.role == 'admin' || user.role == 'super_admin';
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: context.isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Name, Email, Checkbox
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isStaff ? AppTheme.primaryGreen : context.cardSubtleColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isStaff ? Colors.white : context.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.textPrimary)),
                      const SizedBox(height: 2),
                      Text(user.email, style: TextStyle(fontSize: 11.5, color: context.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (!isSelf)
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelectChanged,
                    activeColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.mutedGrey.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(8)),
                    child: const Text("ME", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Badges Bar (Role + Status + Points)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardAltColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtleColor),
              ),
              child: Row(
                children: [
                  _RoleBadge(role: user.role),
                  const Spacer(),
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: user.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isSuspended ? "Suspended" : "Active",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: user.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen),
                  ),
                  if (user.dreamPoints > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "⭐ ${user.dreamPoints} pts",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Row 3: Admin Controls & Action
            Row(
              children: [
                if (!isSelf && isSuperAdmin) ...[
                  Expanded(
                    child: _RoleSwitcher(
                      currentRole: user.role,
                      onChanged: (newRole) => ref.read(appStateProvider.notifier).updateUserRole(user.id, newRole),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (!isSelf) ...[
                  Row(
                    children: [
                      Text(user.isSuspended ? "Unblock:" : "Active:", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                      const SizedBox(width: 4),
                      Switch(
                        value: !user.isSuspended,
                        activeThumbColor: AppTheme.primaryGreen,
                        onChanged: (v) => ref.read(appStateProvider.notifier).toggleUserSuspension(user.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filledTonal(
                  onPressed: onView,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: AppTheme.charcoal,
                    padding: const EdgeInsets.all(8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Multi-select Checkbox
          if (!isSelf)
            Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              activeColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.mutedGrey.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 8),

          // Identity
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isStaff ? AppTheme.primaryGreen : context.cardSubtleColor,
                  child: Text(user.name[0].toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isStaff ? Colors.white : context.textPrimary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                      Text(user.email, style: TextStyle(fontSize: 11, color: context.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Role
          Expanded(flex: 2, child: _RoleBadge(role: user.role)),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: user.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen),
                ),
                const SizedBox(width: 8),
                Text(user.isSuspended ? "Suspended" : "Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: user.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen)),
              ],
            ),
          ),
          // Points & Wallet
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (user.dreamPoints > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "⭐ ${user.dreamPoints} pts",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  )
                else
                  Text(
                    "0 pts",
                    style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                  ),
                const SizedBox(width: 8),
                Text(
                  "GH₵ ${user.referralCredit.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSelf && isSuperAdmin)
                  _RoleSwitcher(
                    currentRole: user.role,
                    onChanged: (newRole) => ref.read(appStateProvider.notifier).updateUserRole(user.id, newRole),
                  ),
                const SizedBox(width: 8),
                if (!isSelf)
                  Switch(
                    value: !user.isSuspended,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (v) => ref.read(appStateProvider.notifier).toggleUserSuspension(user.id),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                    child: const Text("ME", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.mutedGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDetailDrawer extends ConsumerWidget {
  final AppUser user;
  const _UserDetailDrawer({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    // Find current updated user from state if available
    final currentUser = state.users.firstWhere((u) => u.id == user.id, orElse: () => user);
    final isSelf = currentUser.id == state.currentUser?.id;

    void copyText(String label, String text) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Copied $label: $text"),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Account Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  SizedBox(height: 2),
                  Text("User details and access permissions", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(backgroundColor: context.cardAltColor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Card Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardAltColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentUser.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                              child: const Text("YOU", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () => copyText("Email", currentUser.email),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                currentUser.email,
                                style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 12, color: AppTheme.mutedGrey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoleBadge(role: currentUser.role),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentUser.isSuspended ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentUser.isSuspended ? "Suspended" : "Active",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Suspension Toggle Row
          if (!isSelf)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: currentUser.isSuspended ? AppTheme.errorRed.withValues(alpha: 0.06) : AppTheme.primaryGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: currentUser.isSuspended ? AppTheme.errorRed.withValues(alpha: 0.2) : AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    currentUser.isSuspended ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                    color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.isSuspended ? "Account is Suspended" : "Account is Active",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          currentUser.isSuspended ? "Tap toggle to unblock this user" : "User can place orders and log in",
                          style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !currentUser.isSuspended,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (v) => ref.read(appStateProvider.notifier).toggleUserSuspension(currentUser.id),
                  ),
                ],
              ),
            ),

          // Details List
          _detailRow(context, "User ID", currentUser.id, Icons.fingerprint_rounded, onCopy: () => copyText("User ID", currentUser.id)),
          _detailRow(context, "Phone Number", currentUser.phone ?? "Not Provided", Icons.phone_rounded, onCopy: currentUser.phone != null ? () => copyText("Phone", currentUser.phone!) : null),
          _detailRow(context, "Date Joined", DateFormat('MMM d, yyyy').format(currentUser.createdAt), Icons.calendar_today_rounded),
          _detailRow(context, "Referral Code", currentUser.referralCode, Icons.qr_code_rounded, onCopy: () => copyText("Referral Code", currentUser.referralCode)),
          _detailRow(context, "DreamPoints", "${currentUser.dreamPoints} pts", Icons.eco_rounded),
          _detailRow(context, "Wallet Balance", "GH₵ ${currentUser.referralCredit.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded),

          const SizedBox(height: 24),
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
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, IconData icon, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.cardAltColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: context.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 0.5)),
                Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.textPrimary)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 15, color: AppTheme.mutedGrey),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case 'super_admin':
        color = const Color(0xFFDC2626);
        label = '👑 Super Admin';
        break;
      case 'admin':
        color = AppTheme.primaryGreen;
        label = '🛡️ Staff Admin';
        break;
      case 'merchant':
        color = const Color(0xFFD97706);
        label = '🏪 Merchant';
        break;
      default:
        color = const Color(0xFF059669);
        label = '🛍️ Customer';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2),
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final String currentRole;
  final ValueChanged<String> onChanged;

  const _RoleSwitcher({required this.currentRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: currentRole,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      color: context.cardColor,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.15),
      onSelected: onChanged,
      itemBuilder: (context) => [
        _roleItem(context, 'customer', 'Customer', Icons.person_outline_rounded, Colors.blue),
        _roleItem(context, 'merchant', 'Merchant Hub', Icons.storefront_rounded, AppTheme.warningOrange),
        _roleItem(context, 'admin', 'Staff Admin', Icons.shield_outlined, AppTheme.primaryGreen),
        _roleItem(context, 'super_admin', 'Super Admin', Icons.admin_panel_settings_rounded, AppTheme.errorRed),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: context.cardAltColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_rounded, size: 15, color: context.textPrimary),
            const SizedBox(width: 6),
            Text("Role", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textPrimary)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _roleItem(BuildContext context, String value, String label, IconData icon, Color color) {
    final isSelected = currentRole == value;
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? color : context.textPrimary),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
