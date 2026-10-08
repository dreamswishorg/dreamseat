import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final mealsCount = userStats.mealsRescued;
    final moneySaved = userStats.moneySaved;
    final co2Kg = userStats.co2Saved;
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
            tooltip: 'Share Your Impact',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share_rounded, color: AppTheme.primaryGreen, size: 18),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Your eco impact card is ready to share!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
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
                          label: 'Saved',
                          value: 'GH₵${moneySaved.toStringAsFixed(0)}',
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
          ],
        ),
      ),
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
