import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'merchant_storefront.dart';

/// Kitchens the customer has hearted, with how many deals each has live.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds));
    final businesses = ref.watch(appStateProvider.select((s) => s.businesses));
    final deals = ref.watch(appStateProvider.select((s) => s.deals));

    final saved = businesses.where((b) => favoriteIds.contains(b.id)).toList();
    int liveDeals(BusinessProfile b) =>
        deals.where((d) => d.businessId == b.id && d.quantityRemaining > 0).length;
    final totalLive = saved.fold<int>(0, (sum, b) => sum + liveDeals(b));

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        title: const Text('My Favorites'),
        centerTitle: true,
      ),
      body: saved.isEmpty
          ? const BrandedEmptyState(
              title: 'No Favorites Yet',
              description:
                  'Tap the heart on any kitchen to keep it here and see its latest rescue deals.',
              icon: Icons.favorite_rounded,
              accentColor: AppTheme.errorRed,
            )
          : ResponsiveCenter(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.x4),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${saved.length} saved ${saved.length == 1 ? 'kitchen' : 'kitchens'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      DsPill(
                        label: '$totalLive live ${totalLive == 1 ? 'deal' : 'deals'}',
                        icon: Icons.local_offer_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  for (final biz in saved) ...[
                    _FavoriteRow(business: biz, liveDeals: liveDeals(biz)),
                    const SizedBox(height: AppSpace.md),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FavoriteRow extends ConsumerWidget {
  final BusinessProfile business;
  final int liveDeals;

  const _FavoriteRow({required this.business, required this.liveDeals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = business.logoUrl.isNotEmpty ? business.logoUrl : business.coverUrl;
    return DsCard(
      padding: const EdgeInsets.all(AppSpace.md),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MerchantStorefrontScreen(business: business)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.rMd,
            child: SizedBox(
              width: 72,
              height: 72,
              child: image.isEmpty
                  ? Container(
                      color: AppTheme.lightGreenBg,
                      child: Icon(dsCategoryIcon(business.category), color: AppTheme.primaryGreen, size: 30),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: AppTheme.lightGreenBg,
                        child: Icon(dsCategoryIcon(business.category), color: AppTheme.primaryGreen, size: 30),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                ),
                const SizedBox(height: AppSpace.xxs),
                Row(
                  children: [
                    if (business.rating > 0) ...[
                      const Icon(Icons.star_rounded, size: 15, color: AppTheme.warningOrange),
                      const SizedBox(width: AppSpace.xxs),
                      Text(
                        business.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        [
                          if (business.category.isNotEmpty) business.category,
                          if (business.distance > 0) '${business.distance.toStringAsFixed(1)} km',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                DsPill(
                  label: liveDeals > 0 ? '$liveDeals live ${liveDeals == 1 ? 'deal' : 'deals'}' : 'No deals right now',
                  tone: liveDeals > 0 ? DsTone.brand : DsTone.neutral,
                  compact: true,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from favourites',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.favorite_rounded, color: AppTheme.errorRed),
            onPressed: () => ref.read(appStateProvider.notifier).toggleFavorite(business.id),
          ),
        ],
      ),
    );
  }
}
