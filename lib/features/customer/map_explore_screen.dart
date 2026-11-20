import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'merchant_storefront.dart';

class MapExploreScreen extends ConsumerStatefulWidget {
  const MapExploreScreen({super.key});

  @override
  ConsumerState<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends ConsumerState<MapExploreScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _selectedIndex = 0;

  // Center position (Accra, Ghana)
  static final LatLng _kAccra = LatLng(5.6037, -0.1870);

  final List<String> _quickFilters = [
    'All',
    '4 Stars and up',
    'Bakery',
    'Meals',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  void _onMarkerTapped(int index, BusinessProfile biz) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppMotion.slow,
      curve: AppMotion.enter,
    );
    _mapController.move(LatLng(biz.latitude, biz.longitude), 14.8);
  }

  @override
  Widget build(BuildContext context) {
    final allBusinesses = ref.watch(appStateProvider.select((s) => s.businesses));
    final favoriteIds = ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds));

    // Filter businesses based on search & filters
    final filteredBusinesses = allBusinesses.where((biz) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!biz.name.toLowerCase().contains(q) && !biz.category.toLowerCase().contains(q)) return false;
      }
      if (_selectedFilter == '4 Stars and up' && biz.rating < 4.0) return false;
      if (_selectedFilter == 'Bakery' && !biz.category.toLowerCase().contains('bakery')) return false;
      if (_selectedFilter == 'Meals' && !biz.category.toLowerCase().contains('restaurant')) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Stack(
        children: [
          // ── 1. MAP ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _kAccra, initialZoom: 13.5, maxZoom: 18, minZoom: 10),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.dreameats.dreameats',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              MarkerLayer(
                markers: List.generate(filteredBusinesses.length, (idx) {
                  final biz = filteredBusinesses[idx];
                  final isSelected = idx == _selectedIndex;
                  return Marker(
                    point: LatLng(biz.latitude, biz.longitude),
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 52 : 44,
                    child: Semantics(
                      button: true,
                      label: biz.name,
                      child: GestureDetector(
                        onTap: () => _onMarkerTapped(idx, biz),
                        child: AnimatedContainer(
                          duration: AppMotion.base,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.pureWhite,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? AppTheme.pureWhite : AppTheme.primaryGreen, width: 2.5),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: isSelected ? AppTheme.pureWhite : AppTheme.primaryGreen,
                              size: isSelected ? 22 : 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          // ── 2. FLOATING CONTROLS: back + search, then filters ─────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: AppTheme.pureWhite, shape: BoxShape.circle, boxShadow: AppTheme.softShadow),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Back to Home',
                          onPressed: () {
                            try {
                              _mapController.move(_kAccra, 13.5);
                            } catch (_) {}
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              ref.read(customerTabProvider.notifier).state = 0;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(borderRadius: AppRadius.rMd, boxShadow: AppTheme.softShadow),
                          child: DsSearchField(
                            controller: _searchController,
                            hint: 'Search for food, store, and restaurants',
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
                    itemCount: _quickFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                    itemBuilder: (context, idx) {
                      final f = _quickFilters[idx];
                      return DsFilterChip(
                        label: f,
                        selected: _selectedFilter == f,
                        onTap: () => setState(() => _selectedFilter = f),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── 3. PREVIEW CARD ───────────────────────────────────────────
          if (_selectedIndex >= 0 && _selectedIndex < filteredBusinesses.length)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + AppSpace.lg,
              left: AppSpace.lg,
              right: AppSpace.lg,
              child: _buildTopRestaurantCard(
                filteredBusinesses[_selectedIndex],
                favoriteIds.contains(filteredBusinesses[_selectedIndex].id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopRestaurantCard(BusinessProfile biz, bool isFavorite) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppTheme.hairline),
        boxShadow: AppTheme.clientElevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.rMd,
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildStoreThumbnail(biz),
                      Positioned(
                        bottom: AppSpace.xs,
                        left: AppSpace.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.charcoal.withValues(alpha: 0.8), borderRadius: AppRadius.rXs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 13),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                biz.rating > 0 ? biz.rating.toStringAsFixed(1) : 'New',
                                style: const TextStyle(color: AppTheme.pureWhite, fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            biz.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.3),
                          ),
                        ),
                        IconButton(
                          tooltip: isFavorite ? 'Remove from favourites' : 'Save to favourites',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => ref.read(appStateProvider.notifier).toggleFavorite(biz.id),
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppTheme.errorRed : AppTheme.mutedGrey,
                            size: 22,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _selectedIndex = -1),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.mutedGrey, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      children: [
                        Flexible(child: DsPill(label: biz.category, compact: true)),
                        const SizedBox(width: AppSpace.sm),
                        const Icon(Icons.near_me_rounded, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          '${biz.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    if (biz.location.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        biz.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          DsButton(
            label: 'View menu & rescue food',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MerchantStorefrontScreen(business: biz)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreThumbnail(BusinessProfile biz) {
    // 1. Check if biz has coverUrl or logoUrl
    String candidateUrl = biz.coverUrl.trim();
    if (candidateUrl.isEmpty) {
      candidateUrl = biz.logoUrl.trim();
    }

    // 2. Fallback to any food deal image belonging to this business
    if (candidateUrl.isEmpty) {
      final allDeals = ref.watch(appStateProvider).deals;
      for (final d in allDeals) {
        if (d.businessId == biz.id && d.imageUrl.trim().isNotEmpty) {
          candidateUrl = d.imageUrl.trim();
          break;
        }
      }
    }

    // 3. Fallback to appetizing photography matching business category and name
    if (candidateUrl.isEmpty) {
      candidateUrl = _getCategoryDefaultImage(biz.category, biz.name);
    }

    return CachedNetworkImage(
      imageUrl: candidateUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.lightGrey,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl: _getCategoryDefaultImage(biz.category, biz.name),
        fit: BoxFit.cover,
        errorWidget: (context, url, err) => _buildFallbackCover(),
      ),
    );
  }

  String _getCategoryDefaultImage(String category, String name) {
    final combined = '$category $name'.toLowerCase();
    if (combined.contains('bakery') || combined.contains('pastry') || combined.contains('bread') || combined.contains('cake')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80';
    } else if (combined.contains('cafe') || combined.contains('coffee')) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80';
    } else if (combined.contains('grocery') || combined.contains('market') || combined.contains('supermarket')) {
      return 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80';
    } else if (combined.contains('burger') || combined.contains('fast') || combined.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80';
    } else if (combined.contains('jollof') || combined.contains('ghana') || combined.contains('local') || combined.contains('african')) {
      return 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?auto=format&fit=crop&w=600&q=80';
    }
    // High-end restaurant dining & gourmet food (e.g. Chez Ami)
    return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80';
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppTheme.lightGreenBg,
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: AppTheme.primaryGreen, size: 32),
      ),
    );
  }
}
