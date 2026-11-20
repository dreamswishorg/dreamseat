import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/branded_empty_state.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'merchant_storefront.dart';

class PartnersDirectoryScreen extends ConsumerStatefulWidget {
  const PartnersDirectoryScreen({super.key});

  @override
  ConsumerState<PartnersDirectoryScreen> createState() => _PartnersDirectoryScreenState();
}

class _PartnersDirectoryScreenState extends ConsumerState<PartnersDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _sort = 0; // 0 nearest, 1 top rated, 2 most deals

  final List<String> _categories = [
    'All',
    'Restaurant',
    'Bakery',
    'Supermarket',
    'Hotel',
    'Grocery',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(String bizCat, String filterCat) {
    if (filterCat == 'All') return true;
    final b = bizCat.toLowerCase();
    final f = filterCat.toLowerCase();
    
    if (b.contains(f)) return true;
    
    if (f == 'grocery') {
      return b.contains('grocery') || b.contains('fruit') || b.contains('produce');
    }
    if (f == 'supermarket') {
      return b.contains('wholesale') || b.contains('grocery');
    }
    if (f == 'restaurant') {
      return b.contains('restaurant') || b.contains('buffet') || b.contains('snacks');
    }
    if (f == 'hotel') {
      return b.contains('hotel') || b.contains('buffet');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final allBusinesses = state.businesses;

    // Live deals per partner, so each card can say what's on offer right now.
    final dealCounts = <String, int>{};
    for (final d in state.deals) {
      if (d.quantityRemaining > 0) dealCounts[d.businessId] = (dealCounts[d.businessId] ?? 0) + 1;
    }

    final filtered = allBusinesses.where((b) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.location.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
      return matchesSearch && _matchesCategory(b.category, _selectedCategory);
    }).toList()
      ..sort((a, b) {
        switch (_sort) {
          case 1:
            return b.rating.compareTo(a.rating);
          case 2:
            return (dealCounts[b.id] ?? 0).compareTo(dealCounts[a.id] ?? 0);
          default:
            return a.distance.compareTo(b.distance);
        }
      });

    final openDeals = dealCounts.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: Navigator.canPop(context) ? dsScreenBar(context, title: 'Our Partners') : null,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1100,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Headline summary
                      DsHeroCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!Navigator.canPop(context))
                                    const Text(
                                      'Our Partners',
                                      style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                                    )
                                  else
                                    const Text(
                                      'Food rescue, near you',
                                      style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                    ),
                                  const SizedBox(height: AppSpace.xs),
                                  const Text(
                                    'Restaurants, bakeries & supermarkets rescuing food across Ghana.',
                                    style: TextStyle(color: AppTheme.mintGreen, fontSize: 14, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.lg),
                            Column(
                              children: [
                                _heroNumber('${allBusinesses.length}', 'partners'),
                                const SizedBox(height: AppSpace.sm),
                                _heroNumber('$openDeals', 'open deals'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      DsSearchField(
                        controller: _searchController,
                        hint: 'Search partner name, category, location...',
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: AppSpace.md),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                          itemBuilder: (context, idx) {
                            final cat = _categories[idx];
                            return DsFilterChip(
                              label: cat,
                              selected: cat == _selectedCategory,
                              onTap: () => setState(() => _selectedCategory = cat),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          Text(
                            filtered.length == 1 ? '1 partner' : '${filtered.length} partners',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      DsSegmented(
                        labels: const ['Nearest', 'Top rated', 'Most deals'],
                        selected: _sort,
                        onChanged: (i) => setState(() => _sort = i),
                      ),
                      const SizedBox(height: AppSpace.lg),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: BrandedEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No partners found',
                    description: 'Try searching with a different keyword or category.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.x4),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 960 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
                        const gap = AppSpace.lg;
                        final w = (c.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final b in filtered)
                              SizedBox(width: w, child: _PartnerCard(partner: b, deals: dealCounts[b.id] ?? 0)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroNumber(String value, String label) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      decoration: BoxDecoration(color: AppTheme.pureWhite.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
          Text(label, style: const TextStyle(color: AppTheme.mintGreen, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final BusinessProfile partner;
  final int deals;
  const _PartnerCard({required this.partner, required this.deals});

  @override
  Widget build(BuildContext context) {
    final cover = partner.coverUrl.trim().isNotEmpty ? partner.coverUrl : partner.logoUrl;
    return DsPressable(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MerchantStorefrontScreen(business: partner)),
      ),
      pressedScale: 0.985,
      semanticLabel: '${partner.name}, ${partner.category}, '
          '${deals == 0 ? 'no deals right now' : '$deals deals available'}',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppTheme.hairline),
          boxShadow: AppTheme.clientCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with category, rating and the partner's logo
            Stack(
              clipBehavior: Clip.none,
              children: [
                DsMedia(
                  url: cover,
                  category: partner.category,
                  height: 112,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
                Positioned(
                  top: AppSpace.md,
                  left: AppSpace.md,
                  right: 80,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DsPill(label: partner.category, solid: true, compact: true, tone: DsTone.dark),
                  ),
                ),
                Positioned(
                  top: AppSpace.md,
                  right: AppSpace.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: AppRadius.rPill, boxShadow: AppTheme.softShadow),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 16),
                        const SizedBox(width: AppSpace.xxs),
                        Text(
                          partner.rating > 0 ? partner.rating.toStringAsFixed(1) : 'New',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpace.lg,
                  bottom: -28,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pureWhite,
                      border: Border.all(color: AppTheme.pureWhite, width: 3),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: ClipOval(child: DsMedia(url: partner.logoUrl, category: partner.category, height: 50)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.x4 - AppSpace.xs, AppSpace.lg, AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.mutedGrey, size: 16),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          partner.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      const Icon(Icons.near_me_rounded, color: AppTheme.primaryGreen, size: 14),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '${partner.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: deals > 0
                              ? DsPill(
                                  label: deals == 1 ? '1 deal available' : '$deals deals available',
                                  icon: Icons.local_offer_rounded,
                                  tone: DsTone.deal,
                                )
                              : const DsPill(label: 'No deals right now', tone: DsTone.neutral),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      const Text('View menu', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryGreen, size: 20),
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
}
