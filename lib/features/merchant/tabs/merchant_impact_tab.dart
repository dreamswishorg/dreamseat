import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

class MerchantImpactTab extends ConsumerWidget {
  final BusinessProfile business;

  const MerchantImpactTab({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final allMerchantOrders = state.orders.where((o) => o.businessId == business.id).toList();
    final collected = allMerchantOrders.where((o) => o.status == 'collected').toList();

    final int mealsSaved = collected.length;
    final double wasteReducedKg = mealsSaved * 0.8;
    final double co2AvoidedKg = mealsSaved * 2.5;
    final double waterSavedLitres = mealsSaved * 800.0;
    final double communitySavings = collected.fold(0.0, (sum, o) => sum + (o.originalPrice - o.price));

    return ResponsiveCenter(
      maxWidth: 1100,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // ── Hero Banner ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ESG ENVIRONMENTAL IMPACT',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '$mealsSaved Meals Rescued',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                ),
                Text(
                  '${business.name} is leading Accra in sustainable food diversion.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Waste Diverted', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${wasteReducedKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CO₂ Avoided', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${co2AvoidedKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Water Saved', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${(waterSavedLitres / 1000).toStringAsFixed(1)}k L', style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Detailed ESG Stat Cards ──
          Row(
            children: [
              Expanded(
                child: _buildEsgCard(
                  title: 'Landfill Diversion',
                  value: '${wasteReducedKg.toStringAsFixed(1)} kg',
                  subtitle: 'Organic matter kept out of municipal landfills',
                  icon: Icons.delete_outline_rounded,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildEsgCard(
                  title: 'Clean Water Conserved',
                  value: '${waterSavedLitres.toStringAsFixed(0)} L',
                  subtitle: 'Agricultural irrigation water preserved',
                  icon: Icons.water_drop_outlined,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildEsgCard(
                  title: 'Carbon Footprint Off-Set',
                  value: '${co2AvoidedKg.toStringAsFixed(1)} kg CO₂',
                  subtitle: 'Methane and greenhouse emissions prevented',
                  icon: Icons.cloud_outlined,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildEsgCard(
                  title: 'Community Value Saved',
                  value: 'GHS ${communitySavings.toStringAsFixed(2)}',
                  subtitle: 'Discounts given to local food rescue heroes',
                  icon: Icons.favorite_border_rounded,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Green Partner Certificate ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryGreen, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Sustainability Partner',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${business.name} is officially certified under the DreamEats Ghana Green Hospitality initiative.',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsgCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
          ),
        ],
      ),
    );
  }
}
