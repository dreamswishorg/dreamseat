import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

class FriendsFeedScreen extends ConsumerStatefulWidget {
  const FriendsFeedScreen({super.key});

  @override
  ConsumerState<FriendsFeedScreen> createState() => _FriendsFeedScreenState();
}

class _FriendsFeedScreenState extends ConsumerState<FriendsFeedScreen> {
  final List<Map<String, dynamic>> _socialActivities = [
    {
      'friendName': 'Sarah Mensah',
      'avatar': '👩🏽',
      'tag': '#Sarah just ordered this',
      'dish': 'Creamy Shrimp Soup & Garlic Baguette',
      'restaurant': 'Ocean Basket Kitchen',
      'timeAgo': '2 hours ago',
      'rating': 4.8,
      'reviews': 124,
      'deliveryFee': 'GHS 8.50',
      'eta': '25 min',
      'image': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop',
      'co2Saved': '1.8 kg',
      'amountSaved': 'GHS 35.00',
    },
    {
      'friendName': 'Alfikri Adams',
      'avatar': '👨🏾',
      'tag': '#Alfikri just ordered this',
      'dish': 'Crispy Gourmet Brioche Burger',
      'restaurant': 'Burger Lounge Ghana',
      'timeAgo': '3 hours ago',
      'rating': 4.9,
      'reviews': 210,
      'deliveryFee': 'GHS 6.00',
      'eta': '20 min',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
      'co2Saved': '2.4 kg',
      'amountSaved': 'GHS 42.00',
    },
    {
      'friendName': 'Kofi Osei',
      'avatar': '👨🏿',
      'tag': '#Kofi rescued this',
      'dish': 'Wood-fired Pepperoni & Basil Pizza',
      'restaurant': 'Bella Roma Bistro',
      'timeAgo': '4 hours ago',
      'rating': 4.7,
      'reviews': 89,
      'deliveryFee': 'GHS 10.00',
      'eta': '30 min',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop',
      'co2Saved': '3.1 kg',
      'amountSaved': 'GHS 50.00',
    },
    {
      'friendName': 'Ama Darko',
      'avatar': '👩🏿',
      'tag': '#Ama just ordered this',
      'dish': 'Artisan Strawberry Cream Tart & Croissant',
      'restaurant': 'Le Petit Paris Pastries',
      'timeAgo': '5 hours ago',
      'rating': 5.0,
      'reviews': 342,
      'deliveryFee': 'GHS 7.00',
      'eta': '15 min',
      'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop',
      'co2Saved': '1.2 kg',
      'amountSaved': 'GHS 28.00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(appStateProvider.select((s) => s.deals));
    final user = ref.watch(appStateProvider.select((s) => s.currentUser));
    final referralCode = user?.referralCode.isNotEmpty == true
        ? user!.referralCode
        : 'DREAM-CHEF';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Friends & Community',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Invite Friends',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎁 Share link copied! Referral Code: $referralCode'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── COMMUNITY IMPACT HERO BANNER ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🥗', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Circle Saved 142 Meals!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Prevented 355 kg CO₂ and saved GHS 4,200 together 🌿',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION: FRIENDS ARE EATING (Mockup 2 Left) ───────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Friends are eating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGreen, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal list of social cards
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _socialActivities.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final item = _socialActivities[idx];
                return _buildSocialEatingCard(context, item, deals);
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── SECTION: RECENT COMMUNITY RESCUES FEED ───────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Live Community Activity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.charcoal,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _socialActivities.map((act) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(act['avatar'] as String, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppTheme.charcoal,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: act['friendName'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: ' rescued '),
                                  TextSpan(
                                    text: act['dish'] as String,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' from '),
                                  TextSpan(
                                    text: act['restaurant'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  act['timeAgo'] as String,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreenBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Saved ${act['amountSaved']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSocialEatingCard(
    BuildContext context,
    Map<String, dynamic> item,
    List<FoodDeal> deals,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Social Badge Tag (#Sarah just ordered this)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: item['image'] as String,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.lightGreenBg,
                      child: const Center(
                        child: Icon(Icons.fastfood_rounded, color: AppTheme.primaryGreen, size: 36),
                      ),
                    ),
                  ),
                ),
              ),

              // Green Social Badge Tag across top of image (Mockup 2 Left)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['tag'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Favorite Heart Icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_border_rounded, size: 16, color: AppTheme.charcoal),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['dish'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['deliveryFee']} Delivery fee • Ordered ${item['timeAgo']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.mutedGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${item['rating']} (${item['reviews']})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppTheme.mutedGrey)),
                    const SizedBox(width: 6),
                    Text(
                      item['eta'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
