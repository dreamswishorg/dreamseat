import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
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
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Success! GHS 5.00 credit added to your account + 50 DreamPoints!"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _codeController.clear();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Invalid or already redeemed referral code."),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _redeemRewardItem(int pointsCost, String rewardName) async {
    final stateVal = ref.read(appStateProvider);
    if (stateVal.customerDreamPoints >= pointsCost) {
      final success = await ref.read(appStateProvider.notifier).redeemReward(pointsCost, rewardName);
      if (success) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: AppTheme.primaryGreen, size: 54),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Reward Claimed!",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.charcoal, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You unlocked $rewardName.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.mutedGrey, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Text("YOUR VOUCHER CODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedGrey, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        const Text(
                          "DE-VOUCH-7842",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Show this code at checkout on your next meal order.", style: TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("EXCELLENT", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      final deficit = pointsCost - stateVal.customerDreamPoints;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🔒 Need $deficit more points to claim this reward! Rescue more meals to earn points."),
          backgroundColor: AppTheme.warningOrange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'Rewards & Referrals',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 1080,
        child: Column(
          children: [
          // ── Custom Segmented Controller ──────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEFEF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.mutedGrey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, size: 18),
                      SizedBox(width: 6),
                      Text("Redeem"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_rounded, size: 18),
                      SizedBox(width: 6),
                      Text("Refer"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Views ───────────────────────────────────────────
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
        final voucherCards = [
          _buildVoucherCard(
            currentPoints: state.customerDreamPoints,
            pointsCost: 100,
            title: "GHS 10 Discount Voucher",
            subtitle: "Instant GHS 10.00 discount off any food package at checkout.",
            icon: Icons.discount_rounded,
            badgeColor: AppTheme.primaryGreen,
          ),
          _buildVoucherCard(
            currentPoints: state.customerDreamPoints,
            pointsCost: 150,
            title: "Free Bakery Rescue Pack",
            subtitle: "Exchangeable for a fresh surprise bakery box at participating vendors.",
            icon: Icons.bakery_dining_rounded,
            badgeColor: const Color(0xFFE65100),
          ),
          _buildVoucherCard(
            currentPoints: state.customerDreamPoints,
            pointsCost: 200,
            title: "Luxury Hotel Mystery Buffet Box",
            subtitle: "Exclusive surplus gourmet meals from high-profile partner hotels.",
            icon: Icons.workspace_premium_rounded,
            badgeColor: AppTheme.goldAccent,
            isMystery: true,
          ),
        ];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildWalletCard(state),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildPerksCard(),
                    ),
                  ],
                )
              else
                _buildWalletCard(state),
              const SizedBox(height: 28),

              // ── Catalog Title ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Available Rewards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.4)),
                  Text("Tap card to claim", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.mutedGrey)),
                ],
              ),
              const SizedBox(height: 14),

              // ── Reward Cards ────────────────────────────────────────
              if (isWide)
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final cols = gridConstraints.maxWidth >= 920 ? 3 : 2;
                    const gap = 16.0;
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
                      if (i < voucherCards.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(AppState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E7D32),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x4000E676), Color(0x0000E676)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFFB9F6CA), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "ECO HERO TIER",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "YOUR DREAMPOINTS",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${state.customerDreamPoints}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "PTS",
                        style: TextStyle(
                          color: Color(0xFFB9F6CA),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.eco_rounded, color: Color(0xFFB9F6CA), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Earn 10 DreamPoints for every GHS 1.00 saved on rescued food packages!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
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
    );
  }

  Widget _buildPerksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: AppTheme.charcoal.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "MEMBER BENEFITS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPerkRow(Icons.bolt_rounded, "Fast Points Earning", "10 DreamPoints for every GHS 1.00 saved"),
          const SizedBox(height: 12),
          _buildPerkRow(Icons.card_giftcard_rounded, "Instant Food Vouchers", "Redeem instant discounts at local restaurants"),
          const SizedBox(height: 12),
          _buildPerkRow(Icons.eco_rounded, "Verified Impact", "Help stop food waste in Accra & earn green badges"),
        ],
      ),
    );
  }

  Widget _buildPerkRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.charcoal)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey, height: 1.25)),
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
    required Color badgeColor,
    bool isMystery = false,
  }) {
    final bool canClaim = currentPoints >= pointsCost;
    final int deficit = pointsCost - currentPoints;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: canClaim ? badgeColor.withValues(alpha: 0.3) : AppTheme.charcoal.withValues(alpha: 0.06), width: canClaim ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(color: AppTheme.charcoal.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _redeemRewardItem(pointsCost, title),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: badgeColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMystery)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("🌟 EXCLUSIVE MYSTERY", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                            ),
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.06)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.stars_rounded, color: canClaim ? AppTheme.primaryGreen : AppTheme.mutedGrey, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                "$pointsCost PTS",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: canClaim ? AppTheme.charcoal : AppTheme.mutedGrey),
                              ),
                            ],
                          ),
                          if (!canClaim) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Need $deficit more pts",
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppTheme.errorRed),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canClaim)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text("CLAIM NOW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.mutedGrey),
                            SizedBox(width: 4),
                            Text("LOCKED", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: AppTheme.mutedGrey)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: REFER & EARN
  // ===========================================================================
  Widget _buildReferralTab(AppState state) {
    final referralCode = state.currentUser?.referralCode ?? "RESCUE-5GHS";

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
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heroCard,
                      const SizedBox(height: 24),
                      stepsCard,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      inviteCard,
                      const SizedBox(height: 24),
                      claimCard,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heroCard,
              const SizedBox(height: 28),
              stepsCard,
              const SizedBox(height: 28),
              inviteCard,
              const SizedBox(height: 28),
              claimCard,
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E7D32),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x4000E676), Color(0x0000E676)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Give GHS 5.00, Get GHS 5.00",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Invite your friends to rescue surplus food with DreamEats. Once they order their first rescue package, both of you earn GHS 5.00 credit!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("How It Works", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildStepMiniCard("1", "Share", "Send your code to friends"),
            const SizedBox(width: 10),
            _buildStepMiniCard("2", "Rescue", "Friend orders 1st meal"),
            const SizedBox(width: 10),
            _buildStepMiniCard("3", "Earn", "Both get GHS 5 credit!"),
          ],
        ),
      ],
    );
  }

  Widget _buildInviteCodeCard(String referralCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Invite Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(color: AppTheme.charcoal.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      referralCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Code copied to clipboard!"), backgroundColor: AppTheme.primaryGreen),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(8)),
                        child: const Text("COPY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: "Join DreamEats with my code $referralCode and get GHS 5.00 off your first food rescue package!"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🚀 Invite message copied! Ready to paste in WhatsApp."), backgroundColor: AppTheme.primaryGreen),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text("SHARE INVITE LINK", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimCodeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Have a Friend's Code?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
          ),
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    decoration: InputDecoration(
                      hintText: "Enter code e.g. RESCUE-5GHS",
                      hintStyle: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13, fontWeight: FontWeight.normal),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (val) => val!.trim().isEmpty ? 'Enter code' : null,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(90, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _claimReferral,
                  child: const Text("APPLY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepMiniCard(String number, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(number, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.charcoal)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey, height: 1.25)),
          ],
        ),
      ),
    );
  }
}
