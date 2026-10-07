import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import '../providers/app_state.dart';
import '../features/customer/customer_profile.dart';
import '../features/customer/customer_settings_screen.dart';
import '../features/common/notification_screen.dart';
import '../features/common/help_support_screen.dart';

/// Shared, premium AppBar for all customer tab screens.
/// Features a leading hamburger menu to open the drawer,
/// a centered/left title widget, and a notification bell with
/// the user's initials/avatar on the right-hand side.
AppBar buildCustomerAppBar({
  required BuildContext context,
  required Widget title,
  required WidgetRef ref,
  List<Widget>? extraActions,
}) {
  final state = ref.watch(appStateProvider);
  final initials = state.currentUser?.name.isNotEmpty == true 
      ? state.currentUser!.name[0].toUpperCase() 
      : '';
  final avatarUrl = state.currentUser?.avatarUrl;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final appBarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
  final menuBg = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textColor = isDark ? Colors.white : AppTheme.charcoal;
  final subtextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
  final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.charcoal.withValues(alpha: 0.08);

  return AppBar(
    backgroundColor: appBarBg,
    elevation: 0,
    title: title,
    actions: [
      ...?extraActions,
      buildNotificationMenuAnchor(context, ref),
      MenuAnchor(
        alignmentOffset: const Offset(-185, 8),
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(menuBg),
          elevation: WidgetStateProperty.all(12),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor),
            ),
          ),
        ),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 6.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : AppTheme.lightGreenBg,
                  radius: 18,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl != null
                      ? null
                      : initials.isNotEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : const Icon(Icons.person,
                              color: AppTheme.primaryGreen, size: 16),
                ),
              ),
            ),
          );
        },
        menuChildren: [
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Block (Compact)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: avatarUrl == null
                              ? const LinearGradient(
                                  colors: [Color(0xFF0F5B3C), Color(0xFF003D27)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.currentUser?.name ?? 'Guest',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              state.currentUser?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: subtextColor,
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

                // DreamPoints Compact Pill
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F291E) : AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars_rounded,
                              color: AppTheme.primaryGreen, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Points Balance",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${state.customerDreamPoints}p",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                    height: 1,
                    color: borderColor),
                const SizedBox(height: 4),

                _buildMenuItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: "Profile",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerProfileScreen())),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.tune_rounded,
                  label: "Settings",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerSettingsScreen())),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.headset_mic_outlined,
                  label: "Support",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen())),
                ),

                const SizedBox(height: 4),
                Divider(
                    height: 1,
                    color: AppTheme.charcoal.withValues(alpha: 0.08)),
                const SizedBox(height: 4),

                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  label: "Log Out",
                  color: AppTheme.errorRed,
                  onTap: () => showModernLogoutConfirmDialog(context, () => ref.read(appStateProvider.notifier).signOut()),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.charcoal.withValues(alpha: 0.05),
      ),
    ),
  );
}

Widget buildNotificationMenuAnchor(BuildContext context, WidgetRef ref, {Color? iconColor}) {
  final state = ref.watch(appStateProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final menuBg = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textColor = isDark ? Colors.white : AppTheme.charcoal;
  final subtextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
  final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.charcoal.withValues(alpha: 0.08);

  return MenuAnchor(
    alignmentOffset: const Offset(-185, 8),
    style: MenuStyle(
      backgroundColor: WidgetStateProperty.all(menuBg),
      elevation: WidgetStateProperty.all(12),
      padding: WidgetStateProperty.all(EdgeInsets.zero),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
    ),
    builder: (BuildContext context, MenuController controller, Widget? child) {
      final unreadCount = state.unreadNotificationCount;
      final effectiveIconColor = iconColor ?? textColor;
      return IconButton(
        icon: unreadCount > 0
            ? Badge(
                backgroundColor: AppTheme.errorRed,
                textColor: Colors.white,
                label: Text("$unreadCount", style: const TextStyle(fontSize: 9)),
                child: Icon(Icons.notifications_none_rounded, color: effectiveIconColor, size: 26),
              )
            : Icon(Icons.notifications_none_rounded, color: effectiveIconColor, size: 26),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      );
    },
    menuChildren: [
      Container(
        width: 230,
        constraints: const BoxConstraints(maxHeight: 275),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F291E) : AppTheme.lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryGreen, size: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Recent Alerts",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  if (state.notifications.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () => ref.read(appStateProvider.notifier).markAllNotificationsAsRead(),
                      child: const Text(
                        "Mark all read",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
              if (state.notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No recent alerts",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                )
              else
                ...state.notifications.take(3).map((n) => Column(
                      children: [
                        _buildNotificationItem(
                          title: n.title,
                          desc: n.body,
                          isRead: n.isRead,
                          time: _formatTime(n.createdAt),
                          textColor: textColor,
                          subtextColor: subtextColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                      ],
                    )),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF0F1F3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "View All Notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}

Widget _buildMenuItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color? color,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final defaultColor = isDark ? Colors.white : AppTheme.charcoal;

  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? defaultColor.withValues(alpha: 0.75)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: color ?? defaultColor,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: color?.withValues(alpha: 0.6) ?? (isDark ? const Color(0xFF64748B) : AppTheme.mutedGrey),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNotificationItem({
  required String title,
  required String desc,
  required String time,
  required bool isRead,
  Color? textColor,
  Color? subtextColor,
  bool isDark = false,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isRead
          ? Colors.transparent
          : AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.04),
      borderRadius: BorderRadius.circular(14),
      border: isRead
          ? null
          : const Border(
              left: BorderSide(
                color: AppTheme.primaryGreen,
                width: 3.5,
              ),
            ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? const Color(0xFF334155) : const Color(0xFFF0F1F3))
                : (isDark ? const Color(0xFF0F291E) : AppTheme.lightGreenBg),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRead
                ? Icons.notifications_none_rounded
                : Icons.notifications_active_rounded,
            color: isRead
                ? (isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey)
                : AppTheme.primaryGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                  fontSize: 13,
                  color: textColor ?? (isDark ? Colors.white : AppTheme.charcoal),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtextColor ?? (isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  color: isRead
                      ? (subtextColor ?? (isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey))
                      : AppTheme.primaryGreen,
                  fontSize: 9.5,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

/// A modern, professional software-developer quality confirmation popup for logging out.
void showModernLogoutConfirmDialog(BuildContext context, VoidCallback onConfirm) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textColor = isDark ? Colors.white : AppTheme.charcoal;
  final subtextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
  final cancelBorder = isDark ? Colors.white.withValues(alpha: 0.15) : AppTheme.charcoal.withValues(alpha: 0.15);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  "Log out",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to log out of your DreamEats account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: cancelBorder, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          "Log out",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
        child: Opacity(
          opacity: anim1.value,
          child: child,
        ),
      );
    },
  );
}
