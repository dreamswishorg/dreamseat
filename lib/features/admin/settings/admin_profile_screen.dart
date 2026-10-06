import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../services/supabase_service.dart';
import '../widgets/admin_components.dart';
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
          SnackBar(content: Text("Error: $error"), backgroundColor: AppTheme.errorRed),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully"), backgroundColor: AppTheme.primaryGreen),
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

  // Placeholder methods removed; real implementations defined later.

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Staff Account Settings", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.lightGreenBg,
                      child: Text(
                        user?.name[0].toUpperCase() ?? 'A',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user?.name ?? 'Admin', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VERIFIED STAFF',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              const Text("Verified Account", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                              const SizedBox(width: 24),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.mutedGrey),
                              const SizedBox(width: 8),
                              Text("Member since ${user != null ? '${user.createdAt.year}' : '2024'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Settings Sections
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Fields
                    Expanded(
                      flex: 3,
                      child: ContentBox(
                        title: "Personal Information",
                        child: Column(
                          children: [
                            _buildField("Legal Full Name", _nameController, Icons.person_outline_rounded),
                            const SizedBox(height: 20),
                            _buildField("Official Email", _emailController, Icons.email_outlined, enabled: false),
                            const SizedBox(height: 20),
                            _buildField("Contact Number", _phoneController, Icons.phone_outlined),
                            const SizedBox(height: 32),
                            if (_isEditing)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _isEditing = false),
                                      child: const Text("Discard"),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      child: _isSaving
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text("Save Changes"),
                                    ),
                                  ),
                                ],
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _isEditing = true),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text("Edit Profile"),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Security & Privacy
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          ContentBox(
                            title: "Account Security",
                            child: Column(
                              children: [
                                _buildActionTile("Change Security Key", Icons.lock_outline_rounded, _onChangeSecurityKey),
                                const Divider(height: 32),
                                _buildActionTile("Two-Factor Auth", Icons.app_registration_rounded, _onTwoFactorAuth, trailing: _isTwoFactorEnabled ? "Enabled" : "Disabled"),
                                const Divider(height: 32),
                                _buildActionTile("Session History", Icons.devices_rounded, _onSessionHistory),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ContentBox(
                            title: "Danger Zone",
                            child: _buildActionTile("Deactivate Access", Icons.no_accounts_rounded, _onDeactivateAccess, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled && _isEditing,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: (enabled && _isEditing) ? Colors.white : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );

  }

  // Action handlers
  void _onChangeSecurityKey() async {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Security Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new password'),
            TextField(controller: newPasswordController, obscureText: true),
            const SizedBox(height: 8),
            const Text('Confirm new password'),
            TextField(controller: confirmController, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmController.text) {
                messenger.showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              final error = await SupabaseService().updatePassword(newPasswordController.text);
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $error')));
              } else {
                messenger.showSnackBar(const SnackBar(content: Text('🔒 Security key updated')));
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(ctx, true);
            },
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
      messenger.showSnackBar(SnackBar(content: Text('Error: $error')));
    } else {
      setState(() {
        _isTwoFactorEnabled = enabled;
      });
      messenger.showSnackBar(SnackBar(content: Text(enabled ? '2FA enabled' : '2FA disabled')));
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
        title: const Text('Deactivate Access'),
        content: const Text('Are you sure you want to sign out and deactivate your session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService().signOut();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }


  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {Color? color, String? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.charcoal),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? AppTheme.charcoal))),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold))
          else
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.mutedGrey),
        ],
      ),
    );
  }
}
