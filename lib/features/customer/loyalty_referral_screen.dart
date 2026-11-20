import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';

class LoyaltyReferralScreen extends ConsumerStatefulWidget {
  const LoyaltyReferralScreen({super.key});

  @override
  ConsumerState<LoyaltyReferralScreen> createState() => _LoyaltyReferralScreenState();
}

class _LoyaltyReferralScreenState extends ConsumerState<LoyaltyReferralScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _claimReferral() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(appStateProvider.notifier).applyReferral(_codeController.text);
      if (!mounted) return;
      if (success) {
        AppToast.success(context, 'Success! Referral credit added to your account + 50 DreamPoints!');
        _codeController.clear();
      } else {
        AppToast.error(context, 'Invalid or already redeemed referral code.');
      }
    }
  }

  /// [discount] set  -> a real single-use voucher code is issued by the server.
  /// [discount] null -> a physical reward: points are deducted and a support
  ///                    request is opened so the team can arrange it.
  void _redeemRewardItem(int pointsCost, String rewardName, {double? discount}) async {
    final notifier = ref.read(appStateProvider.notifier);
    final points = ref.read(appStateProvider).customerDreamPoints;
    if (points < pointsCost) {
      AppToast.info(context, 'Need ${pointsCost - points} more points to claim this reward! Rescue more meals to earn points.');
      return;
    }

    if (discount != null) {
      final res = await notifier.redeemRewardVoucher(pointsCost: pointsCost, rewardName: rewardName, discount: discount);
      if (!mounted) return;
      if (res.status == 'issued' && res.code != null) {
        _showRewardDialog(rewardName, code: res.code);
        return;
      }
      if (res.status == 'insufficient') {
        AppToast.info(context, 'You don\'t have enough points for this reward yet.');
        return;
      }
      // Server vouchers aren't set up yet: fall through to a manual claim.
    }

    final success = await notifier.redeemReward(pointsCost, rewardName);
    if (!mounted) return;
    if (!success) {
      AppToast.error(context, 'We couldn\'t redeem that reward. Please try again.');
      return;
    }
    var ticketOpened = true;
    try {
      await notifier.createSupportTicket(
        subject: 'Reward claim: $rewardName',
        message: 'I redeemed $pointsCost DreamPoints for "$rewardName". Please arrange my reward.',
      );
    } catch (_) {
      ticketOpened = false;
    }
    if (!mounted) return;
    _showRewardDialog(rewardName, ticketOpened: ticketOpened);
  }

  void _showRewardDialog(String rewardName, {String? code, bool ticketOpened = true}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: DsIconBadge(icon: Icons.stars_rounded, size: 72)),
              const SizedBox(height: AppSpace.xl),
              const Text(
                'Reward Claimed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.charcoal, letterSpacing: -0.5),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'You redeemed $rewardName.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppTheme.mutedGrey, height: 1.4),
              ),
              const SizedBox(height: AppSpace.xl),
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(color: AppTheme.mintGreen),
                ),
                child: code != null
                    ? Column(
                        children: [
                          const Text('Your voucher code', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.mutedGrey)),
                          const SizedBox(height: AppSpace.xs),
                          SelectableText(
                            code,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, letterSpacing: 2),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          const Text(
                            'Single use, valid for 30 days. Enter it at checkout.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4),
                          ),
                        ],
                      )
                    : Text(
                        ticketOpened
                            ? 'We\'ve opened a support request for this reward. Our team will be in touch. You can follow it in Help & Support.'
                            : 'Your points were redeemed. Please open a ticket in Help & Support so our team can arrange your reward.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppTheme.charcoal, height: 1.45),
                      ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (code != null) ...[
                DsButton(
                  label: 'Copy code',
                  icon: Icons.copy_rounded,
                  variant: DsButtonVariant.secondary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    AppToast.success(context, 'Code copied');
                  },
                ),
                const SizedBox(height: AppSpace.md),
              ],
              DsButton(label: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'Rewards & Referrals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.charcoal, letterSpacing: -0.5),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 1080,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.sm),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) => DsSegmented(
                  labels: const ['Redeem', 'Refer'],
                  selected: _tabController.animation!.value.round(),
                  onChanged: (i) => _tabController.animateTo(i),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRewardsTab(state),
                  _buildReferralTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: REWARDS STORE
  // ===========================================================================
  Widget _buildRewardsTab(AppState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final points = state.customerDreamPoints;
        final voucherCards = [
          _buildVoucherCard(
            currentPoints: points,
            pointsCost: 100,
            title: 'GHS 10 Discount Voucher',
            subtitle: 'Instant GHS 10.00 discount off any food package at checkout.',
            icon: Icons.discount_rounded,
            tone: DsTone.brand,
            discount: 10,
          ),
          _buildVoucherCard(
            currentPoints: points,
            pointsCost: 150,
            title: 'Free Bakery Rescue Pack',
            subtitle: 'Exchangeable for a fresh surprise bakery box at participating vendors.',
            icon: Icons.bakery_dining_rounded,
            tone: DsTone.deal,
          ),
          _buildVoucherCard(
            currentPoints: points,
            pointsCost: 200,
            title: 'Luxury Hotel Mystery Buffet Box',
            subtitle: 'Exclusive surplus gourmet meals from high-profile partner hotels.',
            icon: Icons.workspace_premium_rounded,
            tone: DsTone.warn,
            isMystery: true,
          ),
        ];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildWalletCard(points)),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(flex: 4, child: _buildPerksCard()),
                  ],
                )
              else
                _buildWalletCard(points),

              // ── Catalog ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text(
                        'Available Rewards',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.5, height: 1.2),
                      ),
                    ),
                    const Text('Tap a card to claim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
                  ],
                ),
              ),
              if (isWide)
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final cols = gridConstraints.maxWidth >= 920 ? 3 : 2;
                    const gap = AppSpace.lg;
                    final cardW = (gridConstraints.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: voucherCards.map((c) => SizedBox(width: cardW, child: c)).toList(),
                    );
                  },
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < voucherCards.length; i++) ...[
                      voucherCards[i],
                      if (i < voucherCards.length - 1) const SizedBox(height: AppSpace.lg),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(int points) {
    return DsHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your DreamPoints',
            style: TextStyle(color: AppTheme.mintGreen, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$points',
                style: const TextStyle(color: AppTheme.pureWhite, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.1),
              ),
              const SizedBox(width: AppSpace.sm),
              const Text('pts', style: TextStyle(color: AppTheme.limeAccent, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withValues(alpha: 0.10),
              borderRadius: AppRadius.rMd,
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_rounded, color: AppTheme.limeAccent, size: 20),
                SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    'Earn 10 DreamPoints for every GHS 1.00 saved on rescued food packages!',
                    style: TextStyle(color: AppTheme.pureWhite, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerksCard() {
    return DsCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member benefits',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.3),
          ),
          const SizedBox(height: AppSpace.lg),
          _buildPerkRow(Icons.bolt_rounded, 'Fast Points Earning', '10 DreamPoints for every GHS 1.00 saved'),
          const SizedBox(height: AppSpace.md),
          _buildPerkRow(Icons.card_giftcard_rounded, 'Instant Food Vouchers', 'Redeem instant discounts at local restaurants'),
          const SizedBox(height: AppSpace.md),
          _buildPerkRow(Icons.eco_rounded, 'Verified Impact', 'Help stop food waste in Accra & earn green badges'),
        ],
      ),
    );
  }

  Widget _buildPerkRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsIconBadge(icon: icon, size: 32),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal)),
              const SizedBox(height: AppSpace.xxs),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard({
    required int currentPoints,
    required int pointsCost,
    required String title,
    required String subtitle,
    required IconData icon,
    required DsTone tone,
    double? discount,
    bool isMystery = false,
  }) {
    final bool canClaim = currentPoints >= pointsCost;
    final int deficit = pointsCost - currentPoints;

    return DsCard(
      onTap: () => _redeemRewardItem(pointsCost, title, discount: discount),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIconBadge(icon: icon, tone: tone, size: 52),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMystery) ...[
                      const DsPill(label: 'Exclusive mystery', tone: DsTone.warn, compact: true),
                      const SizedBox(height: AppSpace.xs),
                    ],
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppTheme.charcoal, letterSpacing: -0.3, height: 1.25),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(subtitle, style: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const Divider(),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: canClaim ? AppTheme.primaryGreen : AppTheme.mutedGrey, size: 22),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        '$pointsCost pts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: canClaim ? AppTheme.charcoal : AppTheme.mutedGrey),
                      ),
                    ),
                  ],
                ),
              ),
              if (canClaim)
                const DsPill(label: 'Claim now', icon: Icons.arrow_forward_rounded, solid: true)
              else
                const DsPill(label: 'Locked', icon: Icons.lock_outline_rounded, tone: DsTone.neutral),
            ],
          ),
          if (!canClaim) ...[
            const SizedBox(height: AppSpace.md),
            ClipRRect(
              borderRadius: AppRadius.rPill,
              child: LinearProgressIndicator(value: (currentPoints / pointsCost).clamp(0.0, 1.0), minHeight: 6),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Need $deficit more pts',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.dealOrange),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: REFER & EARN
  // ===========================================================================
  Widget _buildReferralTab(AppState state) {
    final referralCode = state.currentUser?.referralCode ?? 'RESCUE-5GHS';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final heroCard = _buildReferralHeroCard();
        final stepsCard = _buildHowItWorksCard();
        final inviteCard = _buildInviteCodeCard(referralCode);
        final claimCard = _buildClaimCodeCard();

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.x4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [heroCard, const SizedBox(height: AppSpace.xxl), stepsCard],
                  ),
                ),
                const SizedBox(width: AppSpace.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [inviteCard, const SizedBox(height: AppSpace.xxl), claimCard],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heroCard,
              const SizedBox(height: AppSpace.xxl),
              stepsCard,
              const SizedBox(height: AppSpace.xxl),
              inviteCard,
              const SizedBox(height: AppSpace.xxl),
              claimCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralHeroCard() {
    return const DsHeroCard(
      child: Column(
        children: [
          DsIconBadge(icon: Icons.card_giftcard_rounded, tone: DsTone.dark, size: 64),
          SizedBox(height: AppSpace.lg),
          Text(
            'Share & Earn Dream Points',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
          ),
          SizedBox(height: AppSpace.sm),
          Text(
            'Invite your friends to rescue surplus food with DreamEats. When they sign up with your code, they get 50 Dream Points + credit, and you earn 100 Dream Points!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mintGreen, fontSize: 14.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DsSectionHeader(
          title: 'How It Works',
          padding: EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.md),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepMiniCard('1', 'Share', 'Send code to friends'),
              const SizedBox(width: AppSpace.md),
              _buildStepMiniCard('2', 'Rescue', 'Friend joins & orders'),
              const SizedBox(width: AppSpace.md),
              _buildStepMiniCard('3', 'Earn', 'Both get Dream Points!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeCard(String referralCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DsSectionHeader(
          title: 'Your Invite Code',
          padding: EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.md),
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(color: AppTheme.mintGreen),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        referralCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    DsButton(
                      label: 'Copy',
                      icon: Icons.copy_rounded,
                      expand: false,
                      variant: DsButtonVariant.dark,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        AppToast.success(context, 'Code copied to clipboard!');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              DsButton(
                label: 'Share invite link',
                icon: Icons.share_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'Join DreamEats with my code $referralCode to get 50 Dream Points + discount on your first food rescue package!\nhttps://dreameats.app',
                  ));
                  AppToast.success(context, 'Invite message copied! Ready to paste in WhatsApp.');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimCodeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DsSectionHeader(
          title: "Have a Friend's Code?",
          padding: EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.md),
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsTextField(
                  controller: _codeController,
                  label: 'Referral code',
                  hint: 'e.g. RESCUE-5GHS',
                  icon: Icons.card_giftcard_rounded,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _claimReferral(),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter code' : null,
                ),
                const SizedBox(height: AppSpace.lg),
                DsButton(label: 'Apply code', onPressed: _claimReferral),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepMiniCard(String number, String title, String subtitle) {
    return Expanded(
      child: DsCard(
        padding: const EdgeInsets.all(AppSpace.md),
        radius: AppRadius.md,
        elevated: false,
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(number, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 14)),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppTheme.charcoal)),
            const SizedBox(height: AppSpace.xxs),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
