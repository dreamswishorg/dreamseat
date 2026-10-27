import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../widgets/admin_components.dart';

class TabAccounts extends ConsumerStatefulWidget {
  const TabAccounts({super.key});

  @override
  ConsumerState<TabAccounts> createState() => _TabAccountsState();
}

class _TabAccountsState extends ConsumerState<TabAccounts> {
  String _searchQuery = '';
  String _roleFilter = 'All'; // 'All', 'Customer', 'Merchant', 'Staff'
  int _currentPage = 0;
  static const int _itemsPerPage = 15;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final users = state.users;

    // Counts
    final totalCount = users.length;
    final customerCount = users.where((u) => u.role == 'customer').length;
    final merchantCount = users.where((u) => u.role == 'merchant').length;
    final staffCount = users.where((u) => u.role == 'admin' || u.role == 'super_admin').length;

    // Filtered
    final filteredUsers = users.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _roleFilter == 'All' ||
          (_roleFilter == 'Staff'
              ? (u.role == 'admin' || u.role == 'super_admin')
              : u.role == _roleFilter.toLowerCase());

      return matchesSearch && matchesRole;
    }).toList();

    // Pagination
    final totalPages = (filteredUsers.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final paginatedUsers = filteredUsers.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Control Bar ─────────────────────────────────────────
          _buildControlHeader(
            filteredUsers: filteredUsers,
            totalCount: totalCount,
            customerCount: customerCount,
            merchantCount: merchantCount,
            staffCount: staffCount,
            isMobile: isMobile,
          ),
          const SizedBox(height: 18),

          // ── Member Directory Roster ─────────────────────────────────
          Expanded(
            child: paginatedUsers.isEmpty
                ? const NoDataState(
                    msg: "No accounts match your current filters.",
                    icon: Icons.people_outline_rounded,
                  )
                : ListView.separated(
                    itemCount: paginatedUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final u = paginatedUsers[i];
                      return _MemberCard(
                        user: u,
                        currentAdminId: state.currentUser?.id,
                        isSuperAdmin: state.currentUser?.role == 'super_admin',
                        onInspect: () => _showUserDetails(u),
                        onToggleSuspension: () => _toggleSuspensionWithFeedback(u),
                        onUpdateRole: (newRole) => ref.read(appStateProvider.notifier).updateUserRole(u.id, newRole),
                      );
                    },
                  ),
          ),

          // ── Pagination Footer ───────────────────────────────────────
          if (totalPages > 1) _buildPaginationBar(totalPages, filteredUsers.length),
        ],
      ),
    );
  }

  Widget _buildControlHeader({
    required List<AppUser> filteredUsers,
    required int totalCount,
    required int customerCount,
    required int merchantCount,
    required int staffCount,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Search bar + Action buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.clientShadow,
                ),
                child: TextField(
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _currentPage = 0;
                  }),
                  style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: "Search accounts by name, email, or user ID...",
                    hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _showCreateStaffDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isMobile ? "Staff" : "Add Staff",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Streamlined Clean Role Filters under Search Bar
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _rolePill("All Accounts", totalCount, 'All', Icons.group_rounded, AppTheme.primaryGreen),
            _rolePill("Customers", customerCount, 'Customer', Icons.shopping_bag_outlined, const Color(0xFF2563EB)),
            _rolePill("Merchants", merchantCount, 'Merchant', Icons.storefront_rounded, const Color(0xFFD97706)),
            _rolePill("Staff", staffCount, 'Staff', Icons.shield_rounded, AppTheme.charcoal),
          ],
        ),
      ],
    );
  }

  Widget _rolePill(String title, int count, String roleValue, IconData icon, Color color) {
    final isSelected = _roleFilter == roleValue;
    return InkWell(
      onTap: () => setState(() {
        _roleFilter = roleValue;
        _currentPage = 0;
      }),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : AppTheme.charcoal,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar(int totalPages, int totalRecords) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "Showing ${_currentPage * _itemsPerPage + 1} - ${((_currentPage + 1) * _itemsPerPage).clamp(0, totalRecords)} of $totalRecords accounts",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Text(
                "Page ${_currentPage + 1} of $totalPages",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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

  Future<void> _toggleSuspensionWithFeedback(AppUser u) async {
    final willSuspend = !u.isSuspended;
    final error = await ref.read(appStateProvider.notifier).toggleUserSuspension(u.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error toggling suspension: $error"),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(willSuspend
              ? "🚫 Account for ${u.name} has been suspended."
              : "✅ Account for ${u.name} is now active."),
          backgroundColor: willSuspend ? AppTheme.charcoal : AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _showCreateStaffDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

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

    final Map<String, List<String>> roleTemplates = {
      'Administrator': privLabels.keys.toList(),
      'Operations': ['analytics', 'approvals', 'map', 'broadcasts'],
      'Support Desk Agent': ['directory', 'disputes', 'support'],
      'Financial Controller': ['analytics', 'ledger', 'vouchers'],
      'Custom': [],
    };

    final Map<String, IconData> roleIcons = {
      'Administrator': Icons.admin_panel_settings_rounded,
      'Operations': Icons.storefront_rounded,
      'Support Desk Agent': Icons.support_agent_rounded,
      'Financial Controller': Icons.account_balance_wallet_rounded,
      'Custom': Icons.tune_rounded,
    };

    String selectedRole = 'Operations';
    Set<String> selectedPrivs = Set.from(roleTemplates['Operations']!);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(28, 26, 28, 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 28),
              actionsPadding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add New Staff Account",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Provision administrative credentials and granular access privileges",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width * 0.94).clamp(320.0, 540.0),
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        const Text(
                          "CREDENTIALS",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mutedGrey,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            hintText: "e.g., Kwame Mensah",
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 19, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                          decoration: InputDecoration(
                            labelText: "Work Email",
                            hintText: "e.g., staff@dreameats.app",
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 19, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Email is required";
                            if (!val.contains('@')) return "Enter a valid email address";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                          decoration: InputDecoration(
                            labelText: "Temporary Password",
                            hintText: "At least 8 characters",
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8)),
                          ),
                          validator: (val) => val == null || val.length < 8 ? "Password must be at least 8 characters" : null,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "SELECT ROLE PRESET",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.mutedGrey,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roleTemplates.keys.map((role) {
                            final isSel = selectedRole == role;
                            final icon = roleIcons[role] ?? Icons.security_rounded;
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedRole = role;
                                  if (role != 'Custom') {
                                    selectedPrivs = Set.from(roleTemplates[role]!);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primaryGreen.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
                                    width: isSel ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 15,
                                      color: isSel ? AppTheme.primaryGreen : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isSel ? AppTheme.primaryGreen : AppTheme.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "MODULE PRIVILEGES",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.mutedGrey,
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${selectedPrivs.length} assigned",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 190),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: privLabels.entries.map((entry) {
                                final key = entry.key;
                                final label = entry.value;
                                final isChecked = selectedPrivs.contains(key);
                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryGreen,
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12.5,
                                      color: isChecked ? AppTheme.charcoal : const Color(0xFF64748B),
                                    ),
                                  ),
                                  value: isChecked,
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
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.mutedGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedPrivs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select at least one permission."), backgroundColor: AppTheme.errorRed),
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
                          if (ctx.mounted) {
                            setModalState(() => isSaving = false);
                            if (error == null) {
                              Navigator.pop(ctx);
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
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Create Staff Account", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unique Member Card Design
// ─────────────────────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final AppUser user;
  final String? currentAdminId;
  final bool isSuperAdmin;
  final VoidCallback onInspect;
  final VoidCallback onToggleSuspension;
  final ValueChanged<String> onUpdateRole;

  const _MemberCard({
    required this.user,
    required this.currentAdminId,
    required this.isSuperAdmin,
    required this.onInspect,
    required this.onToggleSuspension,
    required this.onUpdateRole,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = user.id == currentAdminId;
    final isStaff = user.role == 'admin' || user.role == 'super_admin';
    final avatarColor = isStaff
        ? AppTheme.primaryGreen
        : (user.role == 'merchant' ? const Color(0xFFD97706) : const Color(0xFF2563EB));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isSuspended ? AppTheme.errorRed.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Avatar + Identity + Role
                Row(
                  children: [
                    _buildAvatar(avatarColor, 18),
                    const SizedBox(width: 12),
                    Expanded(child: _buildIdentity(isSelf)),
                    _RoleBadge(role: user.role),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                // Bottom: Balances + Actions
                Row(
                  children: [
                    Expanded(child: _buildLoyaltyAndWallet()),
                    const SizedBox(width: 10),
                    _buildStatusChip(),
                    const SizedBox(width: 10),
                    if (!isSelf)
                      Switch(
                        value: !user.isSuspended,
                        activeThumbColor: AppTheme.primaryGreen,
                        onChanged: (_) => onToggleSuspension(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey),
                      onPressed: onInspect,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            );
          }

          // Desktop Spacious Roster Row
          return Row(
            children: [
              // Avatar with active pulse
              _buildAvatar(avatarColor, 20),
              const SizedBox(width: 14),

              // User Identity
              Expanded(
                flex: 3,
                child: _buildIdentity(isSelf),
              ),

              // Role
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RoleBadge(role: user.role),
                ),
              ),

              // DreamPoints & Wallet
              Expanded(
                flex: 2,
                child: _buildLoyaltyAndWallet(),
              ),

              // Status indicator
              Expanded(
                flex: 2,
                child: _buildStatusChip(),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelf && isSuperAdmin) ...[
                    _RoleSwitcher(currentRole: user.role, onChanged: onUpdateRole),
                    const SizedBox(width: 8),
                  ],
                  if (!isSelf) ...[
                    Tooltip(
                      message: user.isSuspended ? "Unblock account" : "Suspend account",
                      child: Switch(
                        value: !user.isSuspended,
                        activeThumbColor: AppTheme.primaryGreen,
                        onChanged: (_) => onToggleSuspension(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  OutlinedButton.icon(
                    onPressed: onInspect,
                    icon: const Icon(Icons.manage_accounts_rounded, size: 14),
                    label: const Text("Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(Color color, double radius) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w900, color: color),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: user.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentity(bool isSelf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                user.name.isNotEmpty ? user.name : "Unnamed User",
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppTheme.charcoal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(4)),
                child: const Text("YOU", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey),
        ),
      ],
    );
  }

  Widget _buildLoyaltyAndWallet() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user.dreamPoints > 0)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "⭐ ${user.dreamPoints} pts",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
              ),
            ),
          ),
        if (user.dreamPoints > 0) const SizedBox(width: 8),
        Flexible(
          child: Text(
            "GH₵ ${user.referralCredit.toStringAsFixed(2)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    final isLive = !user.isSuspended;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isLive ? AppTheme.primaryGreen : AppTheme.errorRed).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLive ? AppTheme.primaryGreen : AppTheme.errorRed,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? "ACTIVE" : "SUSPENDED",
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: isLive ? AppTheme.primaryGreen : AppTheme.errorRed,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Detail Bottom Sheet Drawer
// ─────────────────────────────────────────────────────────────────────────────
class _UserDetailDrawer extends ConsumerWidget {
  final AppUser user;
  const _UserDetailDrawer({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final currentUser = state.users.firstWhere((u) => u.id == user.id, orElse: () => user);
    final isSelf = currentUser.id == state.currentUser?.id;
    final isMobileDrawer = MediaQuery.sizeOf(context).width < 600;

    void copyText(String label, String text) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Copied $label to clipboard!"),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isMobileDrawer ? 20 : 28, 20, isMobileDrawer ? 20 : 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Account Profile", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                    SizedBox(height: 2),
                    Text("Identity, security & balance overview", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () => copyText("Email", currentUser.email),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(currentUser.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 11, color: AppTheme.mutedGrey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoleBadge(role: currentUser.role),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentUser.isSuspended ? "SUSPENDED" : "ACTIVE",
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                              ),
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
          const SizedBox(height: 16),

          // Details List
          _detailRow("User ID", currentUser.id, Icons.fingerprint_rounded, onCopy: () => copyText("User ID", currentUser.id)),
          _detailRow("Phone Number", currentUser.phone ?? "Not Provided", Icons.phone_rounded, onCopy: currentUser.phone != null ? () => copyText("Phone", currentUser.phone!) : null),
          _detailRow("Date Joined", DateFormat('MMM d, yyyy').format(currentUser.createdAt), Icons.calendar_today_rounded),
          _detailRow("Referral Code", currentUser.referralCode, Icons.qr_code_rounded, onCopy: () => copyText("Referral Code", currentUser.referralCode)),
          _detailRow("DreamPoints", "${currentUser.dreamPoints} pts", Icons.eco_rounded),
          _detailRow("Wallet Balance", "GH₵ ${currentUser.referralCredit.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded),

          if (!isSelf) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  const Text("Role Permission:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: ['customer', 'merchant', 'rider', 'admin', 'super_admin'].contains(currentUser.role) ? currentUser.role : 'customer',
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 12.5),
                    items: ['customer', 'merchant', 'rider', 'admin', 'super_admin'].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.toUpperCase()));
                    }).toList(),
                    onChanged: (newRole) async {
                      if (newRole != null && newRole != currentUser.role) {
                        await ref.read(appStateProvider.notifier).adminUpdateUserRole(currentUser.id, newRole);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("User role successfully updated to ${newRole.toUpperCase()}"), backgroundColor: AppTheme.primaryGreen),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    currentUser.isSuspended ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                    color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentUser.isSuspended ? "Account is currently suspended" : "Account is active and verified",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: currentUser.isSuspended ? AppTheme.errorRed : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  Switch(
                    value: !currentUser.isSuspended,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (v) async {
                      final willSuspend = !currentUser.isSuspended;
                      final error = await ref.read(appStateProvider.notifier).toggleUserSuspension(currentUser.id);
                      if (context.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $error"), backgroundColor: AppTheme.errorRed),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(willSuspend ? "🚫 Account suspended" : "✅ Account activated"),
                              backgroundColor: willSuspend ? AppTheme.charcoal : AppTheme.primaryGreen,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey)),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.mutedGrey),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Badge & Switcher
// ─────────────────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
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
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 12,
      onSelected: onChanged,
      itemBuilder: (context) => [
        _roleItem('customer', 'Customer', Icons.person_outline_rounded, Colors.blue),
        _roleItem('merchant', 'Merchant Hub', Icons.storefront_rounded, AppTheme.warningOrange),
        _roleItem('admin', 'Staff Admin', Icons.shield_outlined, AppTheme.primaryGreen),
        _roleItem('super_admin', 'Super Admin', Icons.admin_panel_settings_rounded, AppTheme.errorRed),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_rounded, size: 14, color: AppTheme.charcoal),
            SizedBox(width: 4),
            Text("Role", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.charcoal)),
            SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: AppTheme.mutedGrey),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _roleItem(String value, String label, IconData icon, Color color) {
    final isSelected = currentRole == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? color : AppTheme.charcoal),
            ),
          ),
          if (isSelected) Icon(Icons.check_rounded, size: 15, color: color),
        ],
      ),
    );
  }
}
