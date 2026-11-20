import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/branded_empty_state.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'deal_detail_screen.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchFilterScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  late TextEditingController _searchController;
  late String _searchQuery;

  String _selectedDistance = 'All';
  String _selectedPrice = 'Any';
  String _selectedCategory = 'All';
  String _selectedPickup = 'Any';
  final List<String> _selectedDietary = [];
  bool _filtersOpen = false;

  static const _distanceOptions = ['All', '<1km', '<5km', '<10km', '10km+'];
  static const _priceOptions = ['Any', 'Under GHS 20', 'GHS 20-50', 'GHS 50+'];
  static const _categoryOptions = [
    'All',
    'Restaurant Meal',
    'Bakery Pack',
    'Grocery Bundle',
    'Fruit & Vegetable Pack',
    'Hotel Buffet',
  ];
  static const _dietaryOptions = ['Vegetarian', 'Vegan', 'Halal', 'Gluten-Free', 'Dairy-Free'];
  static const _pickupOptions = ['Any', 'Ends Soon (< 2hrs)', 'Afternoon', 'Evening'];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedDistance = 'All';
      _selectedPrice = 'Any';
      _selectedCategory = 'All';
      _selectedPickup = 'Any';
      _selectedDietary.clear();
    });
  }

  bool _hasActiveFilters() =>
      _selectedDistance != 'All' ||
      _selectedPrice != 'Any' ||
      _selectedCategory != 'All' ||
      _selectedPickup != 'Any' ||
      _selectedDietary.isNotEmpty;

  int _activeFilterCount() {
    return [
      _selectedDistance != 'All',
      _selectedPrice != 'Any',
      _selectedCategory != 'All',
      _selectedPickup != 'Any',
      _selectedDietary.isNotEmpty,
    ].where((v) => v).length;
  }

  List<FoodDeal> _applyFilters(AppState state) {
    return state.deals.where((deal) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = deal.title.toLowerCase().contains(q) ||
            deal.businessName.toLowerCase().contains(q) ||
            deal.category.toLowerCase().contains(q);
        if (!match) return false;
      }

      // Category
      if (_selectedCategory != 'All' && deal.category != _selectedCategory) {
        return false;
      }

      // Distance
      if (_selectedDistance != 'All') {
        double dist = 1.5;
        try {
          dist = state.businesses.firstWhere((b) => b.id == deal.businessId).distance;
        } catch (_) {}
        switch (_selectedDistance) {
          case '<1km':
            if (dist >= 1.0) return false;
            break;
          case '<5km':
            if (dist >= 5.0) return false;
            break;
          case '<10km':
            if (dist >= 10.0) return false;
            break;
          case '10km+':
            if (dist < 10.0) return false;
            break;
        }
      }

      // Price
      if (_selectedPrice != 'Any') {
        final p = deal.discountedPrice;
        switch (_selectedPrice) {
          case 'Under GHS 20':
            if (p >= 20) return false;
            break;
          case 'GHS 20-50':
            if (p < 20 || p > 50) return false;
            break;
          case 'GHS 50+':
            if (p <= 50) return false;
            break;
        }
      }

      // Pickup time
      if (_selectedPickup != 'Any') {
        final pw = deal.pickupWindow.toLowerCase();
        switch (_selectedPickup) {
          case 'Ends Soon (< 2hrs)':
            final hasSoon = pw.contains('now') ||
                pw.contains('soon') ||
                pw.contains('hour');
            if (!hasSoon) return false;
            break;
          case 'Afternoon':
            final hasAft = pw.contains('pm') &&
                RegExp(r'(1[2-7]|[1-5])\s*pm').hasMatch(pw);
            if (!hasAft) return false;
            break;
          case 'Evening':
            final hasEve = pw.contains('pm') &&
                RegExp(r'(6|7|8|9|10)\s*pm').hasMatch(pw);
            if (!hasEve) return false;
            break;
        }
      }

      // Dietary tags
      if (_selectedDietary.isNotEmpty) {
        if (!_selectedDietary.every((tag) => deal.dietaryTags.contains(tag))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _chipRow({
    required String label,
    required List<String> options,
    required bool Function(String) isSelected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
            itemBuilder: (context, i) => DsFilterChip(
              label: options[i],
              selected: isSelected(options[i]),
              onTap: () => onSelected(options[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(int count) {
    final active = _activeFilterCount();
    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: Row(
              children: [
                DsFilterChip(
                  label: active > 0 ? 'Filters · $active' : 'Filters',
                  icon: Icons.tune_rounded,
                  selected: _filtersOpen || active > 0,
                  onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                ),
                if (active > 0)
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                    child: const Text('Reset'),
                  ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    count == 0 ? 'No results' : '$count deal${count == 1 ? '' : 's'}',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: !_filtersOpen
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _spacedRows([
                        _chipRow(
                          label: 'Distance',
                          options: _distanceOptions,
                          isSelected: (o) => _selectedDistance == o,
                          onSelected: (v) => setState(() => _selectedDistance = v),
                        ),
                        _chipRow(
                          label: 'Price range',
                          options: _priceOptions,
                          isSelected: (o) => _selectedPrice == o,
                          onSelected: (v) => setState(() => _selectedPrice = v),
                        ),
                        _chipRow(
                          label: 'Category',
                          options: _categoryOptions,
                          isSelected: (o) => _selectedCategory == o,
                          onSelected: (v) => setState(() => _selectedCategory = v),
                        ),
                        _chipRow(
                          label: 'Pickup window',
                          options: _pickupOptions,
                          isSelected: (o) => _selectedPickup == o,
                          onSelected: (v) => setState(() => _selectedPickup = v),
                        ),
                        _chipRow(
                          label: 'Dietary preferences',
                          options: _dietaryOptions,
                          isSelected: (o) => _selectedDietary.contains(o),
                          onSelected: (tag) => setState(() {
                            if (_selectedDietary.contains(tag)) {
                              _selectedDietary.remove(tag);
                            } else {
                              _selectedDietary.add(tag);
                            }
                          }),
                        ),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _spacedRows(List<Widget> rows) => [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.lg),
          rows[i],
        ],
      ];

  double _distanceFor(AppState state, FoodDeal deal) {
    for (final b in state.businesses) {
      if (b.id == deal.businessId) return b.distance;
    }
    return 1.5;
  }

  Widget _dealCard(AppState state, FoodDeal deal) {
    return DsDealCard(
      deal: deal,
      distance: _distanceFor(state, deal),
      isFavorite: state.favoriteBusinessIds.contains(deal.businessId),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))),
      onFavorite: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final filteredDeals = _applyFilters(state);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        toolbarHeight: 68,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpace.lg),
          child: DsSearchField(
            controller: _searchController,
            autofocus: true,
            hint: 'Search restaurants, bakeries, deals…',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.hairline),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 1100,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cols = width >= 960 ? 3 : (width >= 640 ? 2 : 1);
            const gap = AppSpace.lg;
            final cardW = (width - AppSpace.gutter * 2 - gap * (cols - 1)) / cols;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildFilterBar(filteredDeals.length)),
                if (filteredDeals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: BrandedEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No deals match your search',
                      description: _searchQuery.isNotEmpty
                          ? 'Try different keywords or adjust your filters.'
                          : 'Adjust the filters above to discover food deals.',
                      actionLabel: _hasActiveFilters() ? 'Reset Filters' : null,
                      onAction: _hasActiveFilters() ? _resetFilters : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.x4),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: gap,
                        children: [
                          for (final deal in filteredDeals) SizedBox(width: cardW, child: _dealCard(state, deal)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
