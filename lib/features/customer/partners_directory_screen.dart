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
    final allBusinesses = ref.watch(appStateProvider).businesses;

    // Filter businesses by search query & category
    final filtered = allBusinesses.where((b) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.location.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
      return matchesSearch && _matchesCategory(b.category, _selectedCategory);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: Navigator.canPop(context) ? dsScreenBar(context, title: 'Our Partners') : null,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1100,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!Navigator.canPop(context)) ...[
                      const Text(
                        'Our Partners',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.6),
                      ),
                      const SizedBox(height: AppSpace.xs),
                    ],
                    const Text(
                      'Discover restaurants, bakeries & supermarkets rescuing food across Ghana.',
                      style: TextStyle(fontSize: 14, color: AppTheme.mutedGrey, height: 1.4),
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
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? const BrandedEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No partners found',
                        description: 'Try searching with a different keyword or category.',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 640;
                          if (isWide) {
                            final cols = constraints.maxWidth >= 960 ? 3 : 2;
                            return GridView.builder(
                              padding: const EdgeInsets.all(AppSpace.gutter),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: AppSpace.lg,
                                mainAxisSpacing: AppSpace.lg,
                                mainAxisExtent: 124,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _PartnerCard(partner: filtered[index]),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.all(AppSpace.gutter),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                            itemBuilder: (context, index) => _PartnerCard(partner: filtered[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final BusinessProfile partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MerchantStorefrontScreen(business: partner)),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      radius: AppRadius.md,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ClipOval(
              child: DsMedia(url: partner.logoUrl, category: partner.category, height: 64),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: DsPill(label: partner.category, compact: true)),
                    const SizedBox(width: AppSpace.sm),
                    const Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 18),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      partner.rating > 0 ? partner.rating.toStringAsFixed(1) : 'New',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  partner.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.3),
                ),
                const SizedBox(height: AppSpace.xxs),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.mutedGrey, size: 16),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        partner.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey, size: 22),
        ],
      ),
    );
  }
}
