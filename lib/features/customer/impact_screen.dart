import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';

/// WhatsApp's own brand green — it has no equivalent in the DreamEats theme.
const Color _whatsappGreen = Color(0xFF25D366);

/// Meals needed for each rescuer level.
const int _warriorMeals = 3;
const int _championMeals = 10;

class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final userStats = appState.customerStats;

    // Derived eco metrics
    final validOrders = appState.orders.where((o) => o.status != 'cancelled').toList();
    final ordersSpent = validOrders.fold<double>(0.0, (sum, o) => sum + o.price);
    final moneySpent = userStats.moneySpent > 0 ? userStats.moneySpent : ordersSpent;
    final mealsCount = userStats.mealsRescued > 0 ? userStats.mealsRescued : validOrders.length;
    final co2Kg = userStats.co2Saved > 0 ? userStats.co2Saved : (mealsCount * 2.5);
    final treesEquivalent = (co2Kg / 10.0).clamp(0.0, 999.0);
    final waterSavedLiters = mealsCount * 350; // avg 350L virtual water saved per meal

    final levelName = mealsCount >= _championMeals
        ? 'Eco Champion'
        : mealsCount >= _warriorMeals
            ? 'Waste Warrior'
            : 'Seedling Rescuer';
    final int? nextTarget = mealsCount >= _championMeals
        ? null
        : (mealsCount >= _warriorMeals ? _championMeals : _warriorMeals);
    final nextName = nextTarget == _championMeals ? 'Eco Champion' : 'Waste Warrior';
    final toGo = nextTarget == null ? 0 : nextTarget - mealsCount;

    const sectionPad = EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'Food Rescue Impact',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.charcoal, letterSpacing: -0.5),
        ),
        extraActions: [
          IconButton(
            tooltip: 'Share referral & earn points',
            icon: const Icon(Icons.share_rounded, size: 22),
            onPressed: () => _showReferralShareSheet(context, ref, appState, mealsCount, co2Kg),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Level + headline numbers ────────────────────────────────
              DsHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(alpha: 0.12),
                            borderRadius: AppRadius.rSm,
                          ),
                          child: const Icon(Icons.eco_rounded, color: AppTheme.limeAccent, size: 26),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Earth Guardian Level',
                                style: TextStyle(color: AppTheme.mintGreen, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                levelName,
                                style: const TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    if (nextTarget != null) ...[
                      ClipRRect(
                        borderRadius: AppRadius.rPill,
                        child: LinearProgressIndicator(
                          value: (mealsCount / nextTarget).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: AppTheme.limeAccent,
                          backgroundColor: AppTheme.pureWhite.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        toGo == 1 ? '1 more meal to reach $nextName' : '$toGo more meals to reach $nextName',
                        style: const TextStyle(color: AppTheme.mintGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ] else
                      const Text(
                        'Top level reached. Thank you for rescuing food!',
                        style: TextStyle(color: AppTheme.mintGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: AppSpace.xl),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.lg),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.10),
                        borderRadius: AppRadius.rMd,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _heroStat(Icons.restaurant_rounded, 'Meals rescued', '$mealsCount')),
                          Container(width: 1, height: 52, color: AppTheme.pureWhite.withValues(alpha: 0.18)),
                          Expanded(child: _heroStat(Icons.cloud_done_rounded, 'CO₂ avoided', '${co2Kg.toStringAsFixed(1)} kg')),
                          Container(width: 1, height: 52, color: AppTheme.pureWhite.withValues(alpha: 0.18)),
                          Expanded(
                            child: _heroStat(
                              Icons.account_balance_wallet_rounded,
                              'Spent',
                              'GH₵${moneySpent.toStringAsFixed(moneySpent % 1 == 0 ? 0 : 2)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Real-world equivalents ──────────────────────────────────
              const DsSectionHeader(title: 'Your Environmental Footprint', padding: sectionPad),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _EquivTile(
                        icon: Icons.forest_rounded,
                        title: 'Tree equivalent',
                        value: '${treesEquivalent.toStringAsFixed(1)} trees',
                        subtitle: 'Carbon absorbed per year',
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: _EquivTile(
                        icon: Icons.water_drop_rounded,
                        tone: DsTone.info,
                        title: 'Water conserved',
                        value: '$waterSavedLiters L',
                        subtitle: 'Saved from waste',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Badges ──────────────────────────────────────────────────
              const DsSectionHeader(title: 'Milestones & Eco Badges', padding: sectionPad),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  _badge(
                    unlocked: mealsCount >= 1,
                    title: 'First Rescue Pioneer',
                    desc: 'Saved your very first surplus food pack',
                    icon: Icons.emoji_events_rounded,
                    tone: DsTone.warn,
                  ),
                  _badge(
                    unlocked: mealsCount >= 5,
                    title: 'Neighborhood Hero',
                    desc: 'Rescued 5+ meals from local eateries',
                    icon: Icons.local_fire_department_rounded,
                    tone: DsTone.deal,
                  ),
                  _badge(
                    unlocked: mealsCount >= 10,
                    title: 'Zero Waste Champion',
                    desc: 'Prevented 10+ meals and 25kg+ CO₂ emissions',
                    icon: Icons.workspace_premium_rounded,
                    tone: DsTone.brand,
                  ),
                ],
              ),

              // ── Community ───────────────────────────────────────────────
              const SizedBox(height: AppSpace.xl),
              DsCard(
                color: AppTheme.lightGreenBg,
                elevated: false,
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.public_rounded, color: AppTheme.pureWhite, size: 24),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community Collective Power',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.deepGreen),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            appState.globalStats.mealsRescued > 0
                                ? 'Together, the DreamEats community has rescued ${appState.globalStats.mealsRescued} meals so far.'
                                : 'Every rescue you make adds to the community total.',
                            style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Actions ─────────────────────────────────────────────────
              const SizedBox(height: AppSpace.xxl),
              DsButton(
                label: 'Rescue another meal today',
                icon: Icons.search_rounded,
                onPressed: () => ref.read(customerTabProvider.notifier).state = 0,
              ),
              const SizedBox(height: AppSpace.md),
              DsButton(
                label: 'Invite friends & earn Dream Points',
                icon: Icons.card_giftcard_rounded,
                variant: DsButtonVariant.secondary,
                onPressed: () => _showReferralShareSheet(context, ref, appState, mealsCount, co2Kg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _heroStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.limeAccent, size: 20),
        const SizedBox(height: AppSpace.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.mintGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  static Widget _badge({
    required bool unlocked,
    required String title,
    required String desc,
    required IconData icon,
    required DsTone tone,
  }) {
    return DsMenuTile(
      icon: icon,
      tone: unlocked ? tone : DsTone.neutral,
      label: title,
      subtitle: desc,
      trailing: DsPill(
        label: unlocked ? 'Earned' : 'Locked',
        icon: unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
        tone: unlocked ? DsTone.brand : DsTone.neutral,
        compact: true,
      ),
    );
  }

  void _showReferralShareSheet(BuildContext context, WidgetRef ref, AppState appState, int mealsCount, double co2Kg) {
    final user = appState.currentUser;
    final referralCode = (user != null && user.referralCode.isNotEmpty)
        ? user.referralCode
        : 'REF-${user?.id.shortId(6).toUpperCase() ?? "DREAM"}';

    final inviteMessage =
        "🌱 I've rescued $mealsCount surplus meals and saved ${co2Kg.toStringAsFixed(1)}kg CO₂ on DreamEats Ghana! Join the movement and get 50 Dream Points + GH₵15 credit on your first meal rescue with my referral code: $referralCode\n\nhttps://dreameats.app";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpace.xxl, AppSpace.md, AppSpace.xxl, AppSpace.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.hairline, borderRadius: AppRadius.rPill),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                const Center(child: DsIconBadge(icon: Icons.loyalty_rounded, size: 64)),
                const SizedBox(height: AppSpace.lg),
                const Text(
                  'Share Your Impact & Earn Points',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.5),
                ),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  'Invite friends to rescue surplus meals! When someone uses your referral code, they receive 50 Dream Points + GH₵15 credit, and you earn 100 Dream Points!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedGrey, height: 1.45),
                ),
                const SizedBox(height: AppSpace.xl),
                DsCard(
                  color: AppTheme.lightGreenBg,
                  elevated: false,
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your referral code',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            SelectableText(
                              referralCode,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      DsButton(
                        label: 'Copy',
                        icon: Icons.copy_rounded,
                        expand: false,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          HapticFeedback.lightImpact();
                          Navigator.pop(modalContext);
                          AppToast.success(context, 'Referral code "$referralCode" copied!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _whatsappGreen, foregroundColor: AppTheme.pureWhite),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(modalContext);
                    final waUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(inviteMessage)}');
                    try {
                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                        return;
                      }
                    } catch (_) {
                      // fall through to the clipboard fallback
                    }
                    await Clipboard.setData(ClipboardData(text: inviteMessage));
                    if (context.mounted) AppToast.success(context, 'Invite message copied to clipboard!');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Share on WhatsApp'),
                ),
                const SizedBox(height: AppSpace.md),
                DsButton(
                  label: 'Copy full invite message',
                  icon: Icons.share_rounded,
                  variant: DsButtonVariant.outline,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteMessage));
                    HapticFeedback.lightImpact();
                    Navigator.pop(modalContext);
                    AppToast.success(context, 'Full impact invite message copied to clipboard!');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EquivTile extends StatelessWidget {
  final IconData icon;
  final DsTone tone;
  final String title;
  final String value;
  final String subtitle;

  const _EquivTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.tone = DsTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconBadge(icon: icon, tone: tone, size: 40),
          const SizedBox(height: AppSpace.md),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.4),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey)),
        ],
      ),
    );
  }
}
