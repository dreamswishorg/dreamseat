import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/branded_empty_state.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
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
    final unread = notifications.where((n) => !n.isRead).toList();
    final earlier = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: dsScreenBar(context, title: 'Activity & Alerts'),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: notifications.isEmpty
            ? const BrandedEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No Recent Activity',
                description:
                    "We'll notify you when new surplus meal packs are listed, collection codes are issued, or your support tickets update.",
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.x4),
                children: [
                  // ── Status strip ────────────────────────────────────────
                  DsCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                    radius: AppRadius.md,
                    elevated: false,
                    child: Row(
                      children: [
                        DsIconBadge(
                          icon: unread.isNotEmpty ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
                          tone: unread.isNotEmpty ? DsTone.deal : DsTone.brand,
                          size: 40,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            unread.isNotEmpty
                                ? (unread.length == 1 ? '1 unread alert' : '${unread.length} unread alerts')
                                : 'All caught up!',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.2),
                          ),
                        ),
                        if (unread.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 132),
                            child: TextButton(
                              onPressed: () => ref.read(appStateProvider.notifier).markAllNotificationsAsRead(),
                              child: const Text('Mark all read', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── New ─────────────────────────────────────────────────
                  if (unread.isNotEmpty) ...[
                    const DsSectionHeader(
                      title: 'New',
                      padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xl, AppSpace.xs, AppSpace.md),
                    ),
                    for (final n in unread) _NotificationTile(notification: n),
                  ],

                  // ── Earlier ─────────────────────────────────────────────
                  if (earlier.isNotEmpty) ...[
                    const DsSectionHeader(
                      title: 'Earlier',
                      padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xl, AppSpace.xs, AppSpace.md),
                    ),
                    for (final n in earlier) _NotificationTile(notification: n),
                  ],
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
    final unread = !notification.isRead;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: DsCard(
        color: unread ? AppTheme.lightGreenBg : AppTheme.pureWhite,
        elevated: !unread,
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpace.lg),
        onTap: () async {
          if (unread) {
            await ref.read(appStateProvider.notifier).markNotificationAsRead(notification.id);
          }
          final target = _targetScreen(ref);
          if (target != null && context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => target));
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unread)
              // The card itself is tinted green, so the badge goes white to stay visible.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(44 * 0.34)),
                child: Icon(_getIcon(notification.screen), size: 22, color: AppTheme.primaryGreen),
              )
            else
              DsIconBadge(icon: _getIcon(notification.screen), tone: DsTone.neutral, size: 44),
            const SizedBox(width: AppSpace.md),
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
                            fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 15.5,
                            color: AppTheme.charcoal,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: unread ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: unread ? AppTheme.charcoal : AppTheme.mutedGrey,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: AppSpace.sm),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: AppSpace.xs),
                decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
              ),
            ],
          ],
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
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
