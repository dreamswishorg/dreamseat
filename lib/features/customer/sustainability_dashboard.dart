import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';

class SustainabilityDashboardScreen extends ConsumerWidget {
  const SustainabilityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final stats = state.customerStats;
    final globalStats = state.globalStats;

    // Calculate tree equivalent: 1 tree absorbs ~22 kg CO2 per year
    final double treesEquivalent = stats.co2Saved / 22.0;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'Sustainability Impact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: ResponsiveCenter(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Hero card showing eco score (Mesh gradient + Glowing border + Metallic badge)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Base emerald gradient
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F5B3C), Color(0xFF003D27)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    // Mesh light glow 1 (Neon Mint/Emerald)
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E676).withValues(alpha: 0.35),
                              const Color(0xFF00E676).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Mesh light glow 2 (Teal)
                    Positioned(
                      bottom: -50,
                      left: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00BFA5).withValues(alpha: 0.3),
                              const Color(0xFF00BFA5).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                              ),
                              _buildMetallicBadge(stats.mealsRescued),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "YOUR GREEN SCORE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(stats.mealsRescued * 100).toStringAsFixed(0)} Points",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _getSaverTierText(stats.mealsRescued),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
            ),
            const SizedBox(height: 28),

            // Statistics Row
            const Text(
              "Your Personal Contribution",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatBox(
                  context,
                  "Money Saved",
                  "GHS ${stats.moneySaved.toStringAsFixed(0)}",
                  Icons.account_balance_wallet_rounded,
                  AppTheme.primaryGreen,
                ),
                const SizedBox(width: 14),
                _buildStatBox(
                  context,
                  "Money Spent",
                  "GHS ${stats.moneySpent.toStringAsFixed(0)}",
                  Icons.shopping_bag_rounded,
                  Colors.orange[800]!,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatBox(
                  context,
                  "Meals Rescued",
                  "${stats.mealsRescued}",
                  Icons.restaurant_rounded,
                  const Color(0xFF059669),
                ),
                const SizedBox(width: 14),
                _buildStatBox(
                  context,
                  "CO₂ Prevented",
                  "${stats.co2Saved.toStringAsFixed(1)} kg",
                  Icons.cloud_done_rounded,
                  Colors.blue[700]!,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatBox(
                  context,
                  "Trees Equivalent",
                  treesEquivalent.toStringAsFixed(2),
                  Icons.park_rounded,
                  Colors.green[700]!,
                ),
                const SizedBox(width: 14),
                _buildStatBox(
                  context,
                  "DreamPoints",
                  "${state.customerDreamPoints} pts",
                  Icons.stars_rounded,
                  Colors.amber[800]!,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Global platform statistics
            const Text(
              "DreamEats Ghana Impact",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.charcoal.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildGlobalImpactRow(
                    "Total Meals Rescued in Ghana",
                    "${globalStats.mealsRescued}",
                    Icons.fastfood_rounded,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildGlobalImpactRow(
                    "Revenue Recovered by Vendors",
                    "GHS ${globalStats.moneySaved.toStringAsFixed(0)}",
                    Icons.monetization_on_rounded,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildGlobalImpactRow(
                    "CO₂ Emissions Prevented",
                    "${globalStats.co2Saved.toStringAsFixed(0)} kg",
                    Icons.forest_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Achievements & Badges Section
            const Text(
              "Badges & Milestones",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _achievements.length,
                separatorBuilder: (context, i) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final badge = _achievements[index];
                  final bool isUnlocked = stats.mealsRescued >= badge.target;
                  return _buildAchievementCard(badge, isUnlocked);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: _HoverLift(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.charcoal.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalImpactRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildMetallicBadge(int rescued) {
    final bool isGold = rescued >= 15;
    final bool isSilver = rescued >= 5 && rescued < 15;

    final String label = isGold ? "GOLD TIER" : (isSilver ? "SILVER TIER" : "BRONZE TIER");
    final List<Color> metallicColors = isGold
        ? [const Color(0xFFFFE082), const Color(0xFFFFB300), const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
        : isSilver
            ? [const Color(0xFFECEFF1), const Color(0xFFB0BEC5), const Color(0xFFCFD8DC), const Color(0xFF78909C)]
            : [const Color(0xFFFFCC80), const Color(0xFFCA8A04), const Color(0xFFFFB74D), const Color(0xFFA16207)];

    final Color textColor = isGold
        ? const Color(0xFF5F4B00)
        : isSilver
            ? const Color(0xFF263238)
            : const Color(0xFF3E2723);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: metallicColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getSaverTierText(int rescued) {
    if (rescued >= 30) return "Top 1% Global Saver 👑";
    if (rescued >= 15) return "Top 5% Eco Saver Accra 🏆";
    if (rescued >= 5) return "Top 15% Food Rescuer Ghana 🌟";
    return "Eco Explorer Rising Star 🌱";
  }

  Widget _buildAchievementCard(_Achievement badge, bool isUnlocked) {
    return _HoverLift(
      child: Container(
        width: 135,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnlocked ? null : Colors.white,
          gradient: isUnlocked
              ? LinearGradient(
                  colors: badge.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withValues(alpha: 0.15)
                : AppTheme.charcoal.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: badge.gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppTheme.charcoal.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppTheme.lightGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge.icon,
                    color: isUnlocked ? Colors.white : AppTheme.mutedGrey,
                    size: 28,
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.mutedGrey,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isUnlocked ? Colors.white : AppTheme.charcoal,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked ? "UNLOCKED" : "Requires ${badge.target}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white70 : AppTheme.mutedGrey,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final int target;
  final IconData icon;
  final List<Color> gradientColors;

  const _Achievement({
    required this.title,
    required this.description,
    required this.target,
    required this.icon,
    required this.gradientColors,
  });
}

const _achievements = [
  _Achievement(
    title: "First Bite",
    description: "Rescue your 1st meal",
    target: 1,
    icon: Icons.storefront_rounded,
    gradientColors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
  ),
  _Achievement(
    title: "Eco Ally",
    description: "Rescue 5 meals",
    target: 5,
    icon: Icons.spa_rounded,
    gradientColors: [Color(0xFF81C784), Color(0xFF2E7D32)],
  ),
  _Achievement(
    title: "Carbon Crusader",
    description: "Rescue 15 meals",
    target: 15,
    icon: Icons.energy_savings_leaf_rounded,
    gradientColors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
  ),
  _Achievement(
    title: "Zero Waste Hero",
    description: "Rescue 30 meals",
    target: 30,
    icon: Icons.auto_awesome_rounded,
    gradientColors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
  ),
  _Achievement(
    title: "Planet Savior",
    description: "Rescue 50 meals",
    target: 50,
    icon: Icons.public_rounded,
    gradientColors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
  ),
];

class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
