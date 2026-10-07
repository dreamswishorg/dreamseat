import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'deal_detail_screen.dart';

class MerchantStorefrontScreen extends ConsumerWidget {
  final BusinessProfile business;

  const MerchantStorefrontScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(appStateProvider.select((s) => s.deals.where((d) => d.businessId == business.id).toList()));
    final isFavorite = ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds.contains(business.id)));

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final cols = constraints.maxWidth >= 900 ? 3 : 2;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildMerchantInfo()),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      "Active Deals",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                  ),
                ),
                deals.isEmpty
                    ? _buildEmptyDeals()
                    : isWide
                        ? SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 280,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final deal = deals[index];
                                  return _buildDealCard(context, ref, deal, isFavorite);
                                },
                                childCount: deals.length,
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final deal = deals[index];
                                  return _buildDealCard(context, ref, deal, isFavorite);
                                },
                                childCount: deals.length,
                              ),
                            ),
                          ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Icon(
                  _getIconForCategory(business.category),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            if (business.logoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: business.logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppTheme.lightGrey),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantInfo() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      business.rating > 0 ? business.rating.toStringAsFixed(1) : "New",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            business.category,
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            business.description,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.mutedGrey, size: 16),
              const SizedBox(width: 6),
              Text(business.location, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.directions_walk_rounded, color: AppTheme.mutedGrey, size: 16),
              const SizedBox(width: 4),
              Text("${business.distance.toStringAsFixed(1)} km away", style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, FoodDeal deal, bool isFavorite) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(12)),
              child: deal.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: deal.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                        errorWidget: (context, url, error) => Icon(_getIconForCategory(deal.category), color: AppTheme.primaryGreen),
                      ),
                    )
                  : Icon(_getIconForCategory(deal.category), color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("GHS ${deal.discountedPrice.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Text("GHS ${deal.originalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.mutedGrey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(8)),
                    child: Text(deal.pickupWindow, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? AppTheme.errorRed : AppTheme.mutedGrey),
              onPressed: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDeals() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.mutedGrey),
            SizedBox(height: 16),
            Text("No active deals right now", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
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
}
