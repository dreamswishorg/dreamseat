import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import 'customer_settings_screen.dart';
import 'privacy_security_screen.dart';
import '../common/help_support_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends ConsumerState<CustomerProfileScreen> {
  bool _isUploadingAvatar = false;
  Uint8List? _localAvatarBytes; // shown immediately while upload finishes

  // ─── Avatar Picker ──────────────────────────────────────────────────────────

  Future<void> _pickAvatar(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _localAvatarBytes = bytes;
      _isUploadingAvatar = true;
    });

    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final url = await SupabaseService().uploadAvatar(
        fileBytes: bytes,
        fileName: fileName,
      );
      await SupabaseService().updateProfile(avatarUrl: url);
      // Refresh user state so the avatar propagates everywhere
      await ref.read(appStateProvider.notifier).refreshCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString().replaceAll('Exception: ', '');
        final lower = errMsg.toLowerCase();
        if (lower.contains('bucket not found')) {
          errMsg = "⚠️ Supabase Bucket Missing:\nIn your Supabase Dashboard, go to Storage -> New Bucket -> Name it 'user-avatars' and toggle Public.";
        } else if (lower.contains('violates row-level security') || lower.contains('403') || lower.contains('unauthorized')) {
          errMsg = "🔒 Supabase Storage RLS Policy Blocked Upload:\nPlease open your Supabase Dashboard SQL Editor and run the script located at 'supabase/storage_policies.sql' to allow file uploads.";
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.security_rounded, color: AppTheme.errorRed),
                  SizedBox(width: 8),
                  Text("Storage Permission Error", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
              content: const Text(
                "Your Supabase database has Row Level Security (RLS) enabled on Storage, blocking profile picture uploads (Status 403).\n\nTo fix this permanently:\n1. Open your Supabase Dashboard -> SQL Editor.\n2. Copy and execute the script inside 'supabase/storage_policies.sql'.",
                style: TextStyle(height: 1.4, fontSize: 13.5),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Got It", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg, style: const TextStyle(fontWeight: FontWeight.bold, height: 1.3)),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 8),
          ),
        );
        setState(() => _localAvatarBytes = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you\'d like to add your photo',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.mutedGrey.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AvatarOptionTile(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    color: AppTheme.primaryGreen,
                    onTap: () => _pickAvatar(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AvatarOptionTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF5C6BC0),
                    onTap: () => _pickAvatar(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final user = state.currentUser;
    final initials = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '';
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: ResponsiveCenter(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // ── Avatar + Account Info ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppTheme.charcoal.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.charcoal.withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tappable avatar with upload overlay
                  GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.20),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.charcoal.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.lightGreenBg,
                            backgroundImage: _localAvatarBytes != null
                                ? MemoryImage(_localAvatarBytes!)
                                : (avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null) as ImageProvider?,
                            child: (_localAvatarBytes == null &&
                                    avatarUrl == null)
                                ? (initials.isNotEmpty
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        color: AppTheme.primaryGreen,
                                        size: 32))
                                : null,
                          ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? "User Account",
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? "",
                          style: const TextStyle(
                            color: AppTheme.mutedGrey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Text(
                            'Change profile photo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Premium Digital Pass ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wallet_rounded,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "DREAMEATS PASS",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DREAM POINTS',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user?.dreamPoints ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'REFERRAL CODE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.referralCode.isNotEmpty == true
                                  ? user!.referralCode
                                  : '---',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Settings ─────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.charcoal.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.settings_outlined,
                    label: 'Account Settings',
                    subtitle: 'Edit name, phone, preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerSettingsScreen()),
                    ),
                  ),
                  _Divider(),
                  _ProfileTile(
                    icon: Icons.security_rounded,
                    label: 'Privacy & Security',
                    subtitle: 'Password, data, permissions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacySecurityScreen()),
                    ),
                  ),
                  _Divider(),
                  _ProfileTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    subtitle: 'FAQs, contact, report issue',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Danger Zone ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.charcoal.withValues(alpha: 0.05)),
              ),
              child: _ProfileTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                subtitle: 'Sign out of your DreamEats account',
                color: AppTheme.errorRed,
                onTap: () {
                  showModernLogoutConfirmDialog(context, () => ref.read(appStateProvider.notifier).signOut());
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 56,
        endIndent: 20,
        color: AppTheme.charcoal.withValues(alpha: 0.06),
      );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.charcoal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryGreen)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: c)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.mutedGrey,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: color?.withValues(alpha: 0.5) ?? AppTheme.mutedGrey),
          ],
        ),
      ),
    );
  }
}

class _AvatarOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AvatarOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
