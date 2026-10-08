import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
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

  bool _isDelivery = true; // Delivery vs Pickup toggle
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _selectedIndex = 0;

  // Center position (Accra, Ghana)
  static final LatLng _kAccra = LatLng(5.6037, -0.1870);

  final List<String> _quickFilters = [
    'All',
    'Open now',
    '★ 4 Stars and up',
    'Offers',
    'Bakery',
    'Meals',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCardSwiped(int index, List<BusinessProfile> businesses) {
    if (index >= 0 && index < businesses.length) {
      setState(() => _selectedIndex = index);
      final biz = businesses[index];
      _mapController.move(LatLng(biz.latitude, biz.longitude), 14.8);
    }
  }

  void _onMarkerTapped(int index, BusinessProfile biz) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
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
        final matchesName = biz.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCat = biz.category.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesName && !matchesCat) return false;
      }
      if (_selectedFilter == '★ 4 Stars and up' && biz.rating < 4.0) {
        return false;
      }
      if (_selectedFilter == 'Bakery' && !biz.category.toLowerCase().contains('bakery')) {
        return false;
      }
      if (_selectedFilter == 'Meals' && !biz.category.toLowerCase().contains('restaurant')) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 1. MAP VIEW ───────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kAccra,
              initialZoom: 13.5,
              maxZoom: 18,
              minZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.dreameats.dreameats',
                tileProvider: CancellableNetworkTileProvider(),
              ),

              // Restaurant Markers
              MarkerLayer(
                markers: List.generate(filteredBusinesses.length, (idx) {
                  final biz = filteredBusinesses[idx];
                  final isSelected = idx == _selectedIndex;

                  return Marker(
                    point: LatLng(biz.latitude, biz.longitude),
                    width: isSelected ? 52 : 42,
                    height: isSelected ? 52 : 42,
                    child: GestureDetector(
                      onTap: () => _onMarkerTapped(idx, biz),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : AppTheme.primaryGreen,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.45)
                                  : const Color(0x1A000000),
                              blurRadius: isSelected ? 14 : 8,
                              offset: const Offset(0, 4),
                            ),
                            if (!isSelected)
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: isSelected ? Colors.white : AppTheme.primaryGreen,
                            size: isSelected ? 22 : 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          // ── 2. TOP FLOATING CONTROLS (Toggle, Search & Filters) ────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delivery / Pickup Toggle Pill & Back/Info Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.charcoal),
                          tooltip: 'Back to Home',
                          onPressed: () {
                            // Reset map zoom
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
                      const Spacer(),

                      // Delivery vs Pickup Pill Switch (Mockup 2 Center)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isDelivery = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _isDelivery ? AppTheme.primaryGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isDelivery ? Colors.white : AppTheme.charcoal,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isDelivery = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: !_isDelivery ? AppTheme.primaryGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Pickup',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: !_isDelivery ? Colors.white : AppTheme.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search for food, store, and restaurants',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.mutedGrey, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Filter Chips Row
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _quickFilters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final f = _quickFilters[idx];
                      final isSelected = _selectedFilter == f;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.charcoal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.charcoal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── 3. BOTTOM SWIPEABLE RESTAURANT CAROUSEL (Mockup 2 Center) ─
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SizedBox(
              height: 128,
              child: filteredBusinesses.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('No restaurants match this filter'),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: filteredBusinesses.length,
                      onPageChanged: (idx) => _onCardSwiped(idx, filteredBusinesses),
                      itemBuilder: (context, index) {
                        final biz = filteredBusinesses[index];
                        final isFavorite = favoriteIds.contains(biz.id);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MerchantStorefrontScreen(business: biz),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 96,
                                    height: 104,
                                    child: _buildStoreThumbnail(biz),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        biz.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isDelivery
                                            ? 'GHS 8.50 Delivery fee • 25-35 min'
                                            : 'Free Pickup • Ready in 15 min',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.mutedGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${biz.rating.toStringAsFixed(1)} (120+)',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.charcoal,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text('•', style: TextStyle(color: AppTheme.mutedGrey)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${biz.distance.toStringAsFixed(1)} km',
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

                                // Heart Icon
                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFavorite ? const Color(0xFFEF4444) : AppTheme.mutedGrey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ref.read(appStateProvider.notifier).toggleFavorite(biz.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
        color: const Color(0xFFF1F5F9),
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
