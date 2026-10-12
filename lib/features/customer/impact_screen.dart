import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';

class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final userStats = appState.customerStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.charcoal;

    // Derived eco metrics
    final validOrders = appState.orders.where((o) => o.status != 'cancelled').toList();
    final ordersSpent = validOrders.fold<double>(0.0, (sum, o) => sum + o.price);
    final moneySpent = userStats.moneySpent > 0 ? userStats.moneySpent : ordersSpent;
    final mealsCount = userStats.mealsRescued > 0 ? userStats.mealsRescued : validOrders.length;
    final co2Kg = userStats.co2Saved > 0 ? userStats.co2Saved : (mealsCount * 2.5);
    final treesEquivalent = (co2Kg / 10.0).clamp(0.0, 999.0);
    final waterSavedLiters = mealsCount * 350; // avg 350L virtual water saved per meal

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Food Rescue Impact',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Referral & Earn Points',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share_rounded, color: AppTheme.primaryGreen, size: 18),
            ),
            onPressed: () => _showReferralShareSheet(context, ref, appState, mealsCount, co2Kg),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Sustainability Banner ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Earth Guardian Level',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              mealsCount >= 10
                                  ? 'Eco Champion 🌿'
                                  : mealsCount >= 3
                                      ? 'Waste Warrior 🌱'
                                      : 'Seedling Rescuer 🌱',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$mealsCount Meals',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Primary 3 Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStatItem(
                          icon: Icons.restaurant_rounded,
                          label: 'Rescued',
                          value: '$mealsCount',
                          unit: 'meals',
                        ),
                      ),
                      Container(width: 1, height: 44, color: Colors.white24),
                      Expanded(
                        child: _HeroStatItem(
                          icon: Icons.cloud_done_rounded,
                          label: 'CO₂ Avoided',
                          value: co2Kg.toStringAsFixed(1),
                          unit: 'kg',
                        ),
                      ),
                      Container(width: 1, height: 44, color: Colors.white24),
                      Expanded(
                        child: _HeroStatItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Spent',
                          value: 'GH₵${moneySpent.toStringAsFixed(moneySpent % 1 == 0 ? 0 : 2)}',
                          unit: 'cash',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Real World Equivalents ───────────────────────────────────────
            Text(
              'Your Environmental Footprint',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EquivTile(
                    cardBg: cardBg,
                    textColor: textColor,
                    icon: Icons.forest_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: AppTheme.lightGreenBg,
                    title: 'Tree Equivalent',
                    value: '${treesEquivalent.toStringAsFixed(1)} trees',
                    subtitle: 'Carbon absorbed/yr',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EquivTile(
                    cardBg: cardBg,
                    textColor: textColor,
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    title: 'Water Conserved',
                    value: '$waterSavedLiters L',
                    subtitle: 'Saved from waste',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Milestones & Badges ──────────────────────────────────────────
            Text(
              'Milestones & Eco Badges',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _BadgeRow(
                    isUnlocked: mealsCount >= 1,
                    title: 'First Rescue Pioneer',
                    desc: 'Saved your very first surplus food pack',
                    icon: Icons.emoji_events_rounded,
                    color: Colors.amber,
                  ),
                  const Divider(height: 24),
                  _BadgeRow(
                    isUnlocked: mealsCount >= 5,
                    title: 'Neighborhood Hero',
                    desc: 'Rescued 5+ meals from local eateries',
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                  ),
                  const Divider(height: 24),
                  _BadgeRow(
                    isUnlocked: mealsCount >= 10,
                    title: 'Zero Waste Champion',
                    desc: 'Prevented 10+ meals and 25kg+ CO₂ emissions',
                    icon: Icons.workspace_premium_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Community Collective Counter ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.public_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Collective Power',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Together, our Ghana food rescue community has saved over 12,500+ meals!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action CTA Button ───────────────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                // Switch back to Explore / Home tab
                ref.read(customerTabProvider.notifier).state = 0;
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Rescue Another Meal Today',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showReferralShareSheet(context, ref, appState, mealsCount, co2Kg),
              icon: const Icon(Icons.card_giftcard_rounded, size: 20),
              label: const Text(
                'Invite Friends & Earn Dream Points',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReferralShareSheet(BuildContext context, WidgetRef ref, AppState appState, int mealsCount, double co2Kg) {
    final user = appState.currentUser;
    final referralCode = (user != null && user.referralCode.isNotEmpty)
        ? user.referralCode
        : 'REF-${user?.id.substring(0, 6).toUpperCase() ?? "DREAM"}';

    final inviteMessage = "🌱 I've rescued $mealsCount surplus meals and saved ${co2Kg.toStringAsFixed(1)}kg CO₂ on DreamEats Ghana! Join the movement and get 50 Dream Points + GH₵15 credit on your first meal rescue with my referral code: $referralCode\n\nhttps://dreameats.app";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : AppTheme.charcoal;

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(modalContext).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Icon Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.loyalty_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Your Impact & Earn Points',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Invite friends to rescue surplus meals! When someone uses your referral code, they receive 50 Dream Points + GH₵15 credit, and you earn 100 Dream Points! 🌱✨',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppTheme.mutedGrey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Referral Code Display Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR REFERRAL CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        HapticFeedback.lightImpact();
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text('Referral code "$referralCode" copied!'),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // WhatsApp Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(modalContext);
                    final waUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(inviteMessage)}');
                    try {
                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } else {
                        await Clipboard.setData(ClipboardData(text: inviteMessage));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Invite message copied to clipboard!'),
                              backgroundColor: AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    } catch (_) {
                      await Clipboard.setData(ClipboardData(text: inviteMessage));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Invite message copied to clipboard!'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text(
                    'Share on WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Copy Full Invite Message Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteMessage));
                    HapticFeedback.lightImpact();
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🎉 Full impact invite message copied to clipboard!'),
                        backgroundColor: AppTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Copy Full Invite Message',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _HeroStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EquivTile extends StatelessWidget {
  final Color cardBg;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;

  const _EquivTile({
    required this.cardBg,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: AppTheme.mutedGrey.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final bool isUnlocked;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _BadgeRow({
    required this.isUnlocked,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isUnlocked ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? AppTheme.charcoal : AppTheme.mutedGrey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isUnlocked)
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUnlocked ? AppTheme.lightGreenBg : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isUnlocked ? 'Earned' : 'Locked',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppTheme.primaryGreen : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
