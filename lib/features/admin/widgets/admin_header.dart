import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';

class AdminHeader extends ConsumerWidget {
  const AdminHeader({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final isSuperAdmin = state.currentUser?.role == 'super_admin';
    final user = state.currentUser;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/images/logo.jpg', height: 28, width: 28, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                // Role tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSuperAdmin ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSuperAdmin ? 'SUPERADMIN' : 'OPERATIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSuperAdmin ? AppTheme.errorRed : AppTheme.primaryGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Avatar dropdown
                PopupMenuButton<int>(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.lightGreenBg,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                    ),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0, child: Text('Profile')),
                    PopupMenuItem(value: 1, child: Text('Settings')),
                    PopupMenuItem(value: 2, child: Text('Logout')),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 0:
                        Navigator.of(context).pushNamed('/admin/profile');
                        break;
                      case 1:
                        Navigator.of(context).pushNamed('/admin/settings');
                        break;
                      case 2:
                        onLogout();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
