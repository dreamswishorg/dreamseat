import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../features/customer/deal_detail_screen.dart';
import '../../features/customer/order_track_screen.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appStateProvider).notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Activity & Alerts",
          style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.4),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sleek Status Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.06))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: unreadCount > 0 ? AppTheme.warningOrange.withValues(alpha: 0.12) : AppTheme.lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unreadCount > 0 ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
                        color: unreadCount > 0 ? AppTheme.warningOrange : AppTheme.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      unreadCount > 0 ? "$unreadCount unread alerts" : "All caught up!",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: unreadCount > 0 ? AppTheme.charcoal : AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                if (unreadCount > 0)
                  Material(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => ref.read(appStateProvider.notifier).markAllNotificationsAsRead(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          "Mark all read",
                          style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationTile(notification: notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 56, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text("No Recent Activity", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal)),
            const SizedBox(height: 8),
            const Text(
              "We'll notify you when new surplus meal packs are listed, collection codes are issued, or your support tickets update.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(appStateProvider.notifier).markNotificationAsRead(notification.id);
          }
          final target = _targetScreen(ref);
          if (target != null && context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => target));
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF2FDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead ? AppTheme.charcoal.withValues(alpha: 0.05) : AppTheme.primaryGreen.withValues(alpha: 0.25),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.charcoal.withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification.isRead ? const Color(0xFFF1F5F9) : AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIcon(notification.screen),
                  color: notification.isRead ? AppTheme.mutedGrey : AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14.5,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: notification.isRead ? AppTheme.mutedGrey : AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead ? AppTheme.mutedGrey : AppTheme.charcoal.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _targetScreen(WidgetRef ref) {
    final id = notification.dataId;
    if (id == null) return null;
    final state = ref.read(appStateProvider);
    switch (notification.screen) {
      case 'track_order':
        for (final o in state.orders) {
          if (o.id == id) return OrderTrackScreen(order: o);
        }
        break;
      case 'deal_detail':
        for (final d in state.deals) {
          if (d.id == id) return DealDetailScreen(deal: d);
        }
        break;
    }
    return null;
  }

  IconData _getIcon(String? screen) {
    switch (screen) {
      case 'orders':
        return Icons.shopping_bag_rounded;
      case 'deal_detail':
        return Icons.local_offer_rounded;
      case 'merchant_dashboard':
        return Icons.storefront_rounded;
      case 'loyalty':
        return Icons.stars_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
