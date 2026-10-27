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
                // Super Admin Avatar Dropdown with Customer Portal Design & Bells/Whistles
                _buildAdminAvatarMenu(context, user, onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminAvatarMenu(BuildContext context, dynamic user, VoidCallback onLogout) {
    final initials = (user?.name != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'A';
    final menuCtrl = MenuController();

    return MenuAnchor(
      controller: menuCtrl,
      alignmentOffset: const Offset(-180, 10),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(16),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        Container(
          width: 230,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.lightGreenBg,
                      child: Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Admin',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.mutedGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Super Admin Role Badge Pill
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppTheme.primaryGreen, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      user?.role == 'super_admin' ? "Super Administrator" : "Platform Staff",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Menu Items
              _adminMenuItem(
                icon: Icons.person_outline_rounded,
                title: "Admin Profile",
                onTap: () {
                  menuCtrl.close();
                  Navigator.of(context).pushNamed('/admin/profile');
                },
              ),
              _adminMenuItem(
                icon: Icons.tune_rounded,
                title: "Settings & Config",
                onTap: () {
                  menuCtrl.close();
                  Navigator.of(context).pushNamed('/admin/settings');
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              _adminMenuItem(
                icon: Icons.logout_rounded,
                title: "Log Out",
                color: AppTheme.errorRed,
                onTap: () {
                  menuCtrl.close();
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color ?? AppTheme.charcoal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppTheme.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
