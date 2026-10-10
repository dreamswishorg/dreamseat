import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

class MerchantReviewsTab extends ConsumerWidget {
  final BusinessProfile business;

  const MerchantReviewsTab({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final reviews = state.reviews.where((r) => r.businessId == business.id).toList();

    final rating = business.rating > 0 ? business.rating : 5.0;
    final totalCount = reviews.length;

    return ResponsiveCenter(
      maxWidth: 1100,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // ── Rating Overview Card ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.charcoal,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppTheme.goldAccent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalCount ${totalCount == 1 ? "Review" : "Reviews"}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 90, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, totalCount > 0 ? 0.85 : 1.0),
                      _buildRatingBar(4, totalCount > 0 ? 0.12 : 0.0),
                      _buildRatingBar(3, totalCount > 0 ? 0.03 : 0.0),
                      _buildRatingBar(2, 0.0),
                      _buildRatingBar(1, 0.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section Title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CUSTOMER FEEDBACK',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppTheme.mutedGrey,
                ),
              ),
              Text(
                '$totalCount Total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Review Cards ──
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_outline_rounded, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text('No Customer Reviews Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text(
                    'As customers collect their rescue packs, their ratings and reviews will be displayed here.',
                    style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...reviews.map((rev) {
              final dateStr = DateFormat('MMM d, yyyy').format(rev.createdAt);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.lightGreenBg,
                              radius: 16,
                              child: Text(
                                rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'C',
                                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rev.userName.isNotEmpty ? rev.userName : 'Food Rescuer',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal),
                                ),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rev.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppTheme.goldAccent,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rev.comment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        rev.comment,
                        style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: AppTheme.goldAccent),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
