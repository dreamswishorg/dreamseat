import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../common/help_support_screen.dart';
import 'avatar_picker.dart';
import 'customer_settings_screen.dart';
import 'favorites_screen.dart';
import 'loyalty_referral_screen.dart';
import 'order_history_screen.dart';
import 'privacy_security_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  final bool isStandalone;
  const CustomerProfileScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _isUploadingAvatar = false;
  Uint8List? _localAvatarBytes; // shown immediately while the upload finishes

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _goBack() {
    if (widget.isStandalone && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ref.read(customerTabProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider.select((s) => s.currentUser));
    final orderCount = ref.watch(appStateProvider.select(
      (s) => s.orders.where((o) => o.customerId == (s.currentUser?.id ?? '')).length,
    ));
    final points = user?.dreamPoints ?? 0;
    final referral = user?.referralCode.isNotEmpty == true ? user!.referralCode : '—';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: dsScreenBar(context, title: 'My Profile', onBack: _goBack),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Who you are, and what you've earned ──────────────────────
              DsHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        DsAvatar(
                          name: user?.name ?? '',
                          url: user?.avatarUrl,
                          bytes: _localAvatarBytes,
                          size: 72,
                          busy: _isUploadingAvatar,
                          onEdit: () => changeProfilePhoto(
                            context,
                            ref,
                            onBusy: (v) {
                              if (mounted) setState(() => _isUploadingAvatar = v);
                            },
                            onPreview: (b) {
                              if (mounted) setState(() => _localAvatarBytes = b);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User Account',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.pureWhite,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.mintGreen, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.10),
                        borderRadius: AppRadius.rMd,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _heroStat('Dream points', '$points', CrossAxisAlignment.start)),
                          Container(width: 1, height: 36, color: AppTheme.pureWhite.withValues(alpha: 0.18)),
                          Expanded(child: _heroStat('Referral code', referral, CrossAxisAlignment.end, spaced: true)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // ── Shortcuts ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Orders',
                      detail: orderCount == 1 ? '1 order' : '$orderCount orders',
                      onTap: () => _open(const OrderHistoryScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.favorite_rounded,
                      label: 'Favorites',
                      detail: 'Saved spots',
                      tone: DsTone.danger,
                      onTap: () => _open(const FavoritesScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Rewards',
                      detail: '$points pts',
                      tone: DsTone.deal,
                      onTap: () => _open(const LoyaltyReferralScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              // ── Account ──────────────────────────────────────────────────
              DsMenuGroup(
                title: 'Account',
                children: [
                  DsMenuTile(
                    icon: Icons.settings_outlined,
                    label: 'Account Settings',
                    subtitle: 'Edit name, phone, preferences',
                    onTap: () => _open(const CustomerSettingsScreen()),
                  ),
                  DsMenuTile(
                    icon: Icons.security_rounded,
                    label: 'Privacy & Security',
                    subtitle: 'Password, data, permissions',
                    tone: DsTone.info,
                    onTap: () => _open(const PrivacySecurityScreen()),
                  ),
                  DsMenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    subtitle: 'FAQs, contact, report issue',
                    tone: DsTone.warn,
                    onTap: () => _open(const HelpSupportScreen()),
                  ),
                ],
              ),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  DsMenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    subtitle: 'Sign out of your DreamEats account',
                    tone: DsTone.danger,
                    onTap: () => showModernLogoutConfirmDialog(
                      context,
                      () => ref.read(appStateProvider.notifier).signOut(),
                    ),
                  ),
                  DsMenuTile(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    subtitle: 'Permanently remove your account and data',
                    tone: DsTone.danger,
                    onTap: () => showModernDeleteAccountConfirmDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, CrossAxisAlignment align, {bool spaced = false}) {
    return Padding(
      padding: EdgeInsets.only(left: align == CrossAxisAlignment.end ? AppSpace.md : 0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.mintGreen, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.pureWhite,
              fontSize: spaced ? 17 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: spaced ? 1.5 : -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable shortcut card: icon, label, one line of live detail.
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final DsTone tone;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.tone = DsTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconBadge(icon: icon, tone: tone, size: 40),
          const SizedBox(height: AppSpace.md),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.2),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey),
          ),
        ],
      ),
    );
  }
}
