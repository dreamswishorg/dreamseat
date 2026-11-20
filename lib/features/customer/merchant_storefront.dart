import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'deal_detail_screen.dart';

/// A single merchant: cover, identity, real numbers, and its live deals.
class MerchantStorefrontScreen extends ConsumerStatefulWidget {
  final BusinessProfile business;

  const MerchantStorefrontScreen({super.key, required this.business});

  @override
  ConsumerState<MerchantStorefrontScreen> createState() => _MerchantStorefrontScreenState();
}

class _MerchantStorefrontScreenState extends ConsumerState<MerchantStorefrontScreen> {
  String _selectedCategory = 'All';

  void _openDeal(FoodDeal deal) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal)));
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final deals = ref.watch(appStateProvider.select(
      (s) => s.deals.where((d) => d.businessId == business.id).toList(),
    ));
    final isFavorite = ref.watch(
      appStateProvider.select((s) => s.favoriteBusinessIds.contains(business.id)),
    );

    final categories = <String>['All'];
    for (final d in deals) {
      final c = d.category.trim();
      if (c.isNotEmpty && !categories.contains(c)) categories.add(c);
    }
    final selected = categories.contains(_selectedCategory) ? _selectedCategory : 'All';
    final visible = selected == 'All'
        ? deals
        : deals.where((d) => d.category.trim() == selected).toList();

    // Best savings: the deepest real discounts, only when there is something to compare.
    final bestSavings = [...deals.where((d) => d.percentageSaved >= 20)]
      ..sort((a, b) => b.percentageSaved.compareTo(a.percentageSaved));
    final topSavings = bestSavings.take(6).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: ResponsiveCenter(
        maxWidth: 900,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHero(context, business, isFavorite),
                SliverToBoxAdapter(child: _buildIdentity(business, deals)),
                if (topSavings.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: DsSectionHeader(
                      title: 'Best Savings',
                      subtitle: 'The deepest discounts from this kitchen',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 262,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                        itemCount: topSavings.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
                        itemBuilder: (_, i) {
                          final deal = topSavings[i];
                          return DsDealTile(
                            deal: deal,
                            distance: business.distance,
                            isFavorite: isFavorite,
                            width: 196,
                            onTap: () => _openDeal(deal),
                            onFavorite: () =>
                                ref.read(appStateProvider.notifier).toggleFavorite(business.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: DsSectionHeader(
                    title: 'Available Now',
                    subtitle: deals.isEmpty
                        ? null
                        : '${deals.length} ${deals.length == 1 ? 'deal' : 'deals'} to rescue today',
                  ),
                ),
                if (categories.length > 2)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                        itemBuilder: (_, i) => DsFilterChip(
                          label: categories[i],
                          selected: categories[i] == selected,
                          onTap: () => setState(() => _selectedCategory = categories[i]),
                        ),
                      ),
                    ),
                  ),
                if (categories.length > 2) const SliverToBoxAdapter(child: SizedBox(height: AppSpace.md)),
                if (visible.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(deals.isEmpty))
                else if (wide)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpace.md,
                        mainAxisSpacing: AppSpace.md,
                        mainAxisExtent: 128,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _DealRow(deal: visible[i], onTap: () => _openDeal(visible[i])),
                        childCount: visible.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                      itemBuilder: (_, i) => _DealRow(deal: visible[i], onTap: () => _openDeal(visible[i])),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpace.x3)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.xs),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, BusinessProfile business, bool isFavorite) {
    final image = business.coverUrl.isNotEmpty ? business.coverUrl : business.logoUrl;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.deepGreen,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: _circleButton(
        icon: Icons.arrow_back_rounded,
        label: 'Back',
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _circleButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: isFavorite ? 'Remove from favourites' : 'Save to favourites',
          color: isFavorite ? AppTheme.errorRed : Colors.white,
          onTap: () => ref.read(appStateProvider.notifier).toggleFavorite(business.id),
        ),
        const SizedBox(width: AppSpace.xs),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppTheme.deepGreen),
                errorWidget: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.heroGradient),
                ),
              )
            else
              const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.heroGradient)),
            const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.scrimGradient)),
            // Cream sheet edge that rounds into the page.
            const Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: AppRadius.lg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity(BusinessProfile business, List<FoodDeal> deals) {
    final bestOff = deals.isEmpty
        ? 0
        : deals.map((d) => d.percentageSaved).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (business.category.isNotEmpty)
                DsPill(label: business.category, icon: dsCategoryIcon(business.category)),
              if (business.isApproved)
                const DsPill(label: 'Verified Partner', icon: Icons.verified_rounded, tone: DsTone.info),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Semantics(
            header: true,
            child: Text(
              business.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
          ),
          if (business.location.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 16, color: AppTheme.mutedGrey),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    business.distance > 0
                        ? '${business.location} · ${business.distance.toStringAsFixed(1)} km away'
                        : business.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
          if (business.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              business.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.charcoal, fontSize: 14, height: 1.5),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: DsStatTile(
                  label: 'Rating',
                  value: business.rating > 0 ? business.rating.toStringAsFixed(1) : 'New',
                  icon: Icons.star_rounded,
                  tone: DsTone.warn,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: DsStatTile(
                  label: 'Live Deals',
                  value: '${deals.length}',
                  icon: Icons.local_offer_rounded,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: DsStatTile(
                  label: 'Top Saving',
                  value: bestOff > 0 ? '$bestOff%' : '—',
                  icon: Icons.savings_rounded,
                  tone: DsTone.deal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool noDealsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DsIconBadge(icon: Icons.inventory_2_outlined, size: 64),
            const SizedBox(height: AppSpace.lg),
            Text(
              noDealsAtAll ? 'No Deals Right Now' : 'Nothing in This Category',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              noDealsAtAll
                  ? 'This kitchen has no surplus listed at the moment. Check back later today.'
                  : 'Try another category to see more from this kitchen.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// One deal in the storefront list: photo, title, price, window, stock.
class _DealRow extends StatelessWidget {
  final FoodDeal deal;
  final VoidCallback onTap;

  const _DealRow({required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final soldOut = deal.quantityRemaining <= 0;
    final low = !soldOut && deal.quantityRemaining <= 3;
    return DsCard(
      onTap: soldOut ? null : onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DsMedia(
                  url: deal.imageUrl,
                  category: deal.category,
                  height: 96,
                  borderRadius: AppRadius.rMd,
                ),
                if (deal.percentageSaved > 0 && !soldOut)
                  Positioned(
                    top: AppSpace.xs,
                    left: AppSpace.xs,
                    child: DsPill(label: '-${deal.percentageSaved}%', tone: DsTone.deal, solid: true, compact: true),
                  ),
                if (soldOut)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: AppRadius.rMd,
                      ),
                      child: const Center(
                        child: Text(
                          'Sold Out',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  deal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.charcoal,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      dsPrice(deal.discountedPrice),
                      style: const TextStyle(
                        color: AppTheme.deepGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (deal.originalPrice > deal.discountedPrice) ...[
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        dsPrice(deal.originalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.mutedGrey,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.mutedGrey),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        deal.pickupWindow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5),
                      ),
                    ),
                    if (low) ...[
                      const SizedBox(width: AppSpace.sm),
                      DsPill(label: '${deal.quantityRemaining} left', tone: DsTone.danger, compact: true),
                    ],
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
