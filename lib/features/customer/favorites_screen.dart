import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'deal_detail_screen.dart';

// ─── Business Deals Bottom Sheet ──────────────────────────────────────────

class _BusinessDealsSheet extends ConsumerWidget {
  final BusinessProfile business;

  const _BusinessDealsSheet({required this.business});

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Bakery Pack':
        return Icons.bakery_dining_rounded;
      case 'Restaurant Meal':
        return Icons.restaurant_rounded;
      case 'Fruit & Vegetable Pack':
        return Icons.shopping_basket_rounded;
      case 'Hotel Buffet':
        return Icons.room_service_rounded;
      case 'Grocery Bundle':
        return Icons.local_grocery_store_rounded;
      case 'Snacks & Drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Bakery Pack':
        return const Color(0xFF8D6E63);
      case 'Restaurant Meal':
        return AppTheme.primaryGreen;
      case 'Fruit & Vegetable Pack':
        return const Color(0xFF4CAF50);
      case 'Hotel Buffet':
        return const Color(0xFFFF9800);
      case 'Grocery Bundle':
        return const Color(0xFF00ACC1);
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final deals = state.deals
        .where((d) => d.businessId == business.id && d.quantityRemaining > 0)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Business Header Card
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _categoryColor(business.category).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _iconForCategory(business.category),
                    size: 26,
                    color: _categoryColor(business.category),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.mutedGrey),
                        const SizedBox(width: 3),
                        Text(
                          business.location,
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me_rounded, size: 12, color: AppTheme.mutedGrey),
                        const SizedBox(width: 2),
                        Text(
                          '${business.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.mutedGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppTheme.warningOrange),
                    const SizedBox(width: 3),
                    Text(
                      business.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Text(
            deals.isEmpty ? 'No active deals' : '${deals.length} active rescues',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.mutedGrey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          if (deals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.no_food_rounded,
                      size: 48,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check back soon for new surplus packs!',
                      style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: deals.length,
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  final double percentage = deal.quantityTotal > 0 
                      ? deal.quantityRemaining / deal.quantityTotal 
                      : 0.0;
                  return _buildDealListItem(context, deal, percentage);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDealListItem(BuildContext context, FoodDeal deal, double percentage) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.primaryGreen),
                      const SizedBox(width: 3),
                      Text(
                        deal.pickupWindow,
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 3,
                        backgroundColor: Colors.white,
                        color: deal.quantityRemaining <= 3
                            ? AppTheme.warningOrange
                            : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${deal.percentageSaved}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'GHS ${deal.originalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.mutedGrey, fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GHS ${deal.discountedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favorites Screen ─────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Bakery Pack':
        return Icons.bakery_dining_rounded;
      case 'Restaurant Meal':
        return Icons.restaurant_rounded;
      case 'Fruit & Vegetable Pack':
        return Icons.shopping_basket_rounded;
      case 'Hotel Buffet':
        return Icons.room_service_rounded;
      case 'Grocery Bundle':
        return Icons.local_grocery_store_rounded;
      case 'Snacks & Drinks':
        return Icons.local_cafe_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Bakery Pack':
        return const Color(0xFF8D6E63);
      case 'Restaurant Meal':
        return AppTheme.primaryGreen;
      case 'Fruit & Vegetable Pack':
        return const Color(0xFF4CAF50);
      case 'Hotel Buffet':
        return const Color(0xFFFF9800);
      case 'Grocery Bundle':
        return const Color(0xFF00ACC1);
      default:
        return AppTheme.primaryGreen;
    }
  }

  void _openBusinessDeals(BuildContext context, BusinessProfile business) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BusinessDealsSheet(business: business),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const BrandedEmptyState(
      title: "No favorites yet",
      description: "Heart your favorite restaurants and bakeries to keep track of their latest rescue deals here.",
      icon: Icons.favorite_rounded,
      accentColor: AppTheme.errorRed,
    );
  }

  Widget _buildBusinessCard(
    BuildContext context,
    WidgetRef ref,
    BusinessProfile biz,
    List<FoodDeal> bizDeals,
  ) {
    final isFav = ref.watch(appStateProvider).favoriteBusinessIds.contains(biz.id);
    final catColor = _categoryColor(biz.category);

    return _HoverLift(
      onTap: () => _openBusinessDeals(context, biz),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Hero Area
            Stack(
              children: [
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.08),
                    gradient: LinearGradient(
                      colors: [
                        catColor.withValues(alpha: 0.15),
                        catColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconForCategory(biz.category),
                      size: 40,
                      color: catColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                // Heart Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(appStateProvider.notifier).toggleFavorite(biz.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFav ? AppTheme.errorRed : AppTheme.mutedGrey,
                      ),
                    ),
                  ),
                ),

                // Active Deals Badge
                if (bizDeals.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${bizDeals.length} pack${bizDeals.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    biz.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: AppTheme.mutedGrey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          biz.location,
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Distance / Rating
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded, size: 11, color: AppTheme.mutedGrey),
                      const SizedBox(width: 2),
                      Text(
                        '${biz.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 10.5, color: AppTheme.mutedGrey),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 12, color: AppTheme.warningOrange),
                      const SizedBox(width: 2),
                      Text(
                        biz.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteBusinessIds = ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds));
    final favBusinesses = ref.watch(appStateProvider.select((s) =>
      s.businesses.where((b) => favoriteBusinessIds.contains(b.id)).toList()
    ));
    final deals = ref.watch(appStateProvider.select((s) => s.deals));

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: favBusinesses.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Summary Bar
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${favBusinesses.length} saved spot${favBusinesses.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tap any card to browse active deals',
                                style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreenBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.eco_rounded, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 5),
                              Text(
                                '${deals.where((d) => favBusinesses.any((b) => b.id == d.businessId) && d.quantityRemaining > 0).length} active',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final biz = favBusinesses[index];
                        final bizDeals = deals
                            .where((d) => d.businessId == biz.id && d.quantityRemaining > 0)
                            .toList();
                        return _buildBusinessCard(context, ref, biz, bizDeals);
                      },
                      childCount: favBusinesses.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverLift({required this.child, this.onTap});

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
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
