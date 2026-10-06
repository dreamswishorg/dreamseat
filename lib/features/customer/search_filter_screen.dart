import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
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

  Widget _buildChipRow({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedGrey,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, i) {
              final opt = options[i];
              final isSelected = selected == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelected(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppTheme.charcoal.withValues(alpha: 0.08),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.charcoal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoal.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (_hasActiveFilters()) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_activeFilterCount()} active',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: _hasActiveFilters() ? _resetFilters : null,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    foregroundColor: AppTheme.errorRed,
                    disabledForegroundColor: AppTheme.mutedGrey.withValues(alpha: 0.35),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildChipRow(
            label: 'DISTANCE',
            options: _distanceOptions,
            selected: _selectedDistance,
            onSelected: (v) => setState(() => _selectedDistance = v),
          ),
          const SizedBox(height: 14),
          _buildChipRow(
            label: 'PRICE RANGE',
            options: _priceOptions,
            selected: _selectedPrice,
            onSelected: (v) => setState(() => _selectedPrice = v),
          ),
          const SizedBox(height: 14),
          _buildChipRow(
            label: 'CATEGORY',
            options: _categoryOptions,
            selected: _selectedCategory,
            onSelected: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 14),
          _buildChipRow(
            label: 'PICKUP WINDOW',
            options: _pickupOptions,
            selected: _selectedPickup,
            onSelected: (v) => setState(() => _selectedPickup = v),
          ),
          const SizedBox(height: 14),
          _buildMultiSelectChipRow(
            label: 'DIETARY PREFERENCES',
            options: _dietaryOptions,
            selected: _selectedDietary,
            onSelected: (tag) {
              setState(() {
                if (_selectedDietary.contains(tag)) {
                  _selectedDietary.remove(tag);
                } else {
                  _selectedDietary.add(tag);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectChipRow({
    required String label,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedGrey,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, i) {
              final opt = options[i];
              final isSelected = selected.contains(opt);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelected(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppTheme.charcoal.withValues(alpha: 0.08),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.charcoal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDealCard(BuildContext context, FoodDeal deal, bool isFavorite, double distance) {
    final double percentage = deal.quantityTotal > 0 
        ? deal.quantityRemaining / deal.quantityTotal 
        : 0.0;
        
    return _HoverLift(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealDetailScreen(deal: deal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.charcoal.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Image / Thumbnail
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreenBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              _iconForCategory(deal.category),
                              size: 36,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        // Discount Badge
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorRed,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              "${deal.percentageSaved}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Right Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business Name
                          Padding(
                            padding: const EdgeInsets.only(right: 28), // Space for favorite heart
                            child: Text(
                              deal.businessName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.mutedGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Title
                          Text(
                            deal.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Stock Gauge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 4,
                                  backgroundColor: AppTheme.lightGrey,
                                  color: deal.quantityRemaining <= 3
                                      ? AppTheme.warningOrange
                                      : AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    deal.quantityRemaining <= 3 
                                        ? "Selling out! Only ${deal.quantityRemaining} left"
                                        : "${deal.quantityRemaining} packs remaining",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: deal.quantityRemaining <= 3
                                          ? AppTheme.warningOrange
                                          : AppTheme.mutedGrey,
                                    ),
                                  ),
                                  Text(
                                    "${distance.toStringAsFixed(1)} km away",
                                    style: const TextStyle(fontSize: 10, color: AppTheme.mutedGrey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Pricing & Pickup Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    deal.pickupWindow,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "GHS ${deal.originalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.mutedGrey,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "GHS ${deal.discountedPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Floating Heart Toggle Button
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? AppTheme.errorRed : AppTheme.mutedGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Text(
              count == 0
                  ? 'No results'
                  : '$count deal${count == 1 ? '' : 's'} found',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco_rounded, size: 12, color: AppTheme.primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'Save up to 70%',
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No deals match your search',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try different keywords or adjust your filters.'
                    : 'Adjust the filters above to discover food deals.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.mutedGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (_hasActiveFilters())
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final filteredDeals = _applyFilters(state);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.charcoal,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search restaurants, bakeries, deals…',
              hintStyle: const TextStyle(
                color: AppTheme.mutedGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.mutedGrey,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.lightGrey,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
            textInputAction: TextInputAction.search,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.charcoal.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildFiltersSection()),
          _buildResultsHeader(filteredDeals.length),
          if (filteredDeals.isEmpty)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final deal = filteredDeals[index];
                    double distance = 1.5;
                    try {
                      distance = state.businesses
                          .firstWhere((b) => b.id == deal.businessId)
                          .distance;
                    } catch (_) {}
                    final isFav = state.favoriteBusinessIds.contains(deal.businessId);
                    return _buildDealCard(context, deal, isFav, distance);
                  },
                  childCount: filteredDeals.length,
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
