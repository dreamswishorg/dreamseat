import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../services/supabase_service.dart';
import 'session_history_screen.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isTwoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _loadTwoFactorStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final error = await ref.read(appStateProvider.notifier).updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $error"),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Profile updated successfully"),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadTwoFactorStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final mfa = user.userMetadata!['mfa_enabled'];
      setState(() {
        _isTwoFactorEnabled = mfa == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).currentUser;
    final isSuperAdmin = user?.role == 'super_admin';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Staff Settings",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppTheme.charcoal,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HERO USER BANNER
                _buildHeroProfileCard(user, isSuperAdmin, isMobile),
                const SizedBox(height: 24),

                // 2. MAIN CONTENT (Responsive: 1-col on mobile, 2-col on desktop)
                if (isMobile) ...[
                  _buildPersonalInfoCard(isMobile),
                  const SizedBox(height: 20),
                  _buildSecurityCard(isMobile),
                  const SizedBox(height: 20),
                  _buildDangerZoneCard(isMobile),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildPersonalInfoCard(isMobile),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSecurityCard(isMobile),
                            const SizedBox(height: 24),
                            _buildDangerZoneCard(isMobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroProfileCard(dynamic user, bool isSuperAdmin, bool isMobile) {
    final initial = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A';

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: isSuperAdmin
                      ? AppTheme.errorRed.withValues(alpha: 0.15)
                      : AppTheme.lightGreenBg,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBadge(
                      label: isSuperAdmin ? "👑 SUPER ADMIN" : "🛡️ STAFF ADMIN",
                      color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                    ),
                    _buildBadge(
                      label: "VERIFIED ACCOUNT",
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: isSuperAdmin
                      ? AppTheme.errorRed.withValues(alpha: 0.15)
                      : AppTheme.lightGreenBg,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Admin',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.charcoal,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(
                            label: isSuperAdmin ? "👑 SUPER ADMIN" : "🛡️ STAFF ADMIN",
                            color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 6),
                          const Text(
                            "Verified Staff Account",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(width: 20),
                          const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.mutedGrey),
                          const SizedBox(width: 6),
                          Text(
                            "Member since ${user != null ? '${user.createdAt.year}' : '2024'}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.3,
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _buildField("Legal Full Name", _nameController, Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildField("Official Email", _emailController, Icons.email_outlined, enabled: false),
          const SizedBox(height: 16),
          _buildField("Contact Number", _phoneController, Icons.phone_outlined),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text("Discard", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.mutedGrey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled && _isEditing,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppTheme.charcoal),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19, color: (enabled && _isEditing) ? AppTheme.primaryGreen : AppTheme.mutedGrey),
            filled: true,
            fillColor: (enabled && _isEditing) ? Colors.white : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Security",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.charcoal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          _buildActionTile(
            title: "Change Security Key",
            subtitle: "Update account master password",
            icon: Icons.lock_outline_rounded,
            onTap: _onChangeSecurityKey,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildActionTile(
            title: "Two-Factor Authentication",
            subtitle: _isTwoFactorEnabled ? "Active & Protected" : "Not configured",
            icon: Icons.shield_outlined,
            onTap: _onTwoFactorAuth,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isTwoFactorEnabled
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isTwoFactorEnabled ? "ENABLED" : "DISABLED",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _isTwoFactorEnabled ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                ),
              ),
            ),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildActionTile(
            title: "Active Session History",
            subtitle: "View devices and IP addresses",
            icon: Icons.devices_rounded,
            onTap: _onSessionHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorRed.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.errorRed),
              ),
              const SizedBox(width: 10),
              const Text(
                "Danger Zone",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.errorRed,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: "Deactivate Session",
            subtitle: "Sign out and revoke staff credentials",
            icon: Icons.logout_rounded,
            onTap: _onDeactivateAccess,
            color: AppTheme.errorRed,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    final titleColor = color ?? AppTheme.charcoal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.charcoal).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color ?? AppTheme.charcoal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _onChangeSecurityKey() async {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Security Key', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your new secure password below.', style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmController.text) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.errorRed),
                );
                return;
              }
              final error = await SupabaseService().updatePassword(newPasswordController.text);
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: AppTheme.errorRed));
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('🔒 Security key updated successfully'), backgroundColor: AppTheme.primaryGreen),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _onTwoFactorAuth() async {
    final enabled = !_isTwoFactorEnabled;
    final messenger = ScaffoldMessenger.of(context);
    final error = await SupabaseService().toggleTwoFactor(enabled);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: AppTheme.errorRed));
    } else {
      setState(() => _isTwoFactorEnabled = enabled);
      messenger.showSnackBar(
        SnackBar(
          content: Text(enabled ? '✅ 2FA enabled' : 'ℹ️ 2FA disabled'),
          backgroundColor: enabled ? AppTheme.primaryGreen : AppTheme.charcoal,
        ),
      );
    }
  }

  void _onSessionHistory() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SessionHistoryScreen()));
  }

  void _onDeactivateAccess() async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out / Deactivate Session', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to sign out and end your active staff session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService().signOut();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
