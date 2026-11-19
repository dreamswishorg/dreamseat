import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import 'deal_detail_screen.dart';
import 'search_filter_screen.dart';
import 'merchant_storefront.dart';
import 'partners_directory_screen.dart';
import 'home_shimmer.dart';
import 'order_track_screen.dart';
import 'order_history_screen.dart';

class UserLocation {
  final String address;
  final Position? position;
  final bool isDefaultSet;

  UserLocation({
    required this.address,
    this.position,
    this.isDefaultSet = false,
  });
}

class UserLocationNotifier extends Notifier<UserLocation> {
  static const String _prefKeyAddress = 'user_default_address';
  static const String _prefKeyLat = 'user_default_lat';
  static const String _prefKeyLng = 'user_default_lng';
  static const String _prefKeyIsSet = 'user_location_set';

  @override
  UserLocation build() {
    _loadInitialSavedLocation();
    return UserLocation(address: "Accra, Ghana", isDefaultSet: false);
  }

  Future<void> _loadInitialSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString(_prefKeyAddress);
      final savedLat = prefs.getDouble(_prefKeyLat);
      final savedLng = prefs.getDouble(_prefKeyLng);
      final isSet = prefs.getBool(_prefKeyIsSet) ?? false;

      if (savedAddress != null && savedAddress.isNotEmpty) {
        Position? pos;
        if (savedLat != null && savedLng != null) {
          pos = Position(
            latitude: savedLat,
            longitude: savedLng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        state = UserLocation(address: savedAddress, position: pos, isDefaultSet: isSet);
      }
    } catch (_) {}
  }

  Future<void> loadSavedLocation() => _loadInitialSavedLocation();

  Future<void> setAddress(String address, [Position? position]) async {
    Position? resolvedPos = position;
    resolvedPos ??= await LocationService().getLatLngFromAddress(address);
    state = UserLocation(address: address, position: resolvedPos, isDefaultSet: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAddress, address);
      await prefs.setBool(_prefKeyIsSet, true);
      if (resolvedPos != null) {
        await prefs.setDouble(_prefKeyLat, resolvedPos.latitude);
        await prefs.setDouble(_prefKeyLng, resolvedPos.longitude);
      }
    } catch (_) {}
  }

  Future<LocationStatusResult> fetchCurrentLocation({bool saveAsDefault = true}) async {
    final loc = LocationService();
    final res = await loc.getPositionWithStatus();
    if (res.status == 'success' && res.position != null) {
      final addr = await loc.getAddressFromLatLng(res.position!);
      final displayAddr = addr ?? "Current Location";
      state = UserLocation(address: displayAddr, position: res.position, isDefaultSet: true);
      if (saveAsDefault) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKeyAddress, displayAddr);
          await prefs.setBool(_prefKeyIsSet, true);
          await prefs.setDouble(_prefKeyLat, res.position!.latitude);
          await prefs.setDouble(_prefKeyLng, res.position!.longitude);
        } catch (_) {}
      }
    }
    return res;
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocation>(() {
  return UserLocationNotifier();
});

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String _selectedCategory = 'All';
  String _selectedQuickFilter = 'Pickup';
  String _priceSort = 'none'; // 'none', 'asc', 'desc'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(userLocationProvider.notifier).loadSavedLocation();
      final userLoc = ref.read(userLocationProvider);
      if (!userLoc.isDefaultSet) {
        // Prompt first-time users to set their default location
        _showAddressSelectionBottomSheet(isInitialSetup: true);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(appStateProvider.select((s) => s.deals));
    final businesses = ref.watch(appStateProvider.select((s) => s.businesses));
    final userLocation = ref.watch(userLocationProvider);

    // Dynamic Distance Sorting
    final sortedDeals = List<FoodDeal>.from(deals);
    if (userLocation.position != null) {
      sortedDeals.sort((a, b) {
        try {
          final bizA = businesses.firstWhere((biz) => biz.id == a.businessId);
          final bizB = businesses.firstWhere((biz) => biz.id == b.businessId);

          final distA = Geolocator.distanceBetween(userLocation.position!.latitude, userLocation.position!.longitude, bizA.latitude, bizA.longitude);
          final distB = Geolocator.distanceBetween(userLocation.position!.latitude, userLocation.position!.longitude, bizB.latitude, bizB.longitude);

          return distA.compareTo(distB);
        } catch (_) {
          return 0;
        }
      });
    }

    final isLoading = ref.watch(appStateProvider.select((s) => s.isLoading));
    final favoriteIds =
        ref.watch(appStateProvider.select((s) => s.favoriteBusinessIds));
    final customerName =
        ref.watch(appStateProvider.select((s) => s.currentUser?.name));
    final basketCount =
        ref.watch(appStateProvider.select((s) => s.basketItemCount));
    final orders =
        ref.watch(appStateProvider.select((s) => s.orders));
    final activeOrders = orders.where((o) => o.status == 'confirmed' || o.status == 'ready' || o.status == 'pending').toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeBg = isDark ? const Color(0xFF0F172A) : AppTheme.cream;
    final primaryText = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final wide = useSideNav(context);

    if (isLoading && deals.isEmpty) {
      return Scaffold(
        backgroundColor: homeBg,
        appBar: wide
            ? buildCustomerAppBar(
                context: context,
                ref: ref,
                title: Text('DREAMEATS',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryText)),
              )
            : null,
        body: const HomeShimmer(),
      );
    }

    final filteredDeals = sortedDeals.where((deal) {
      if (deal.quantityRemaining <= 0 || !deal.isActive) return false;

      // Category matching
      if (_selectedCategory != 'All') {
        final catQuery = _selectedCategory.toLowerCase();
        final dealCat = deal.category.toLowerCase();
        final dealTitle = deal.title.toLowerCase();
        final dealDesc = deal.description.toLowerCase();
        final matchCategory = dealCat.contains(catQuery) ||
            dealTitle.contains(catQuery) ||
            dealDesc.contains(catQuery) ||
            (catQuery == 'meals' && (dealCat.contains('restaurant') || dealCat.contains('meal'))) ||
            (catQuery == 'bakery' && (dealCat.contains('baker') || dealCat.contains('pastry') || dealCat.contains('cake') || dealTitle.contains('cake') || dealTitle.contains('pastry'))) ||
            (catQuery == 'grocery' && (dealCat.contains('grocer') || dealCat.contains('fruit') || dealCat.contains('bundle'))) ||
            (catQuery == 'fast food' && (dealTitle.contains('burger') || dealTitle.contains('pizza') || dealCat.contains('fast'))) ||
            (catQuery == 'desserts' && (dealTitle.contains('cake') || dealCat.contains('dessert') || dealTitle.contains('sweet'))) ||
            (catQuery == 'buffets' && dealCat.contains('buffet'));
        if (!matchCategory) return false;
      }

      // Quick filter matching
      if (_selectedQuickFilter == '4.5+ Rating') {
        return deal.originalPrice > 0;
      } else if (_selectedQuickFilter == '50%+ Off' || _selectedQuickFilter == 'Offers') {
        return deal.discountedPrice <= deal.originalPrice * 0.6;
      } else if (_selectedQuickFilter == 'Under 30 min') {
        final dist = _distanceTo(deal, businesses, userLocation);
        return dist <= 3.5;
      }

      return true;
    }).toList();

    if (_priceSort == 'asc') {
      filteredDeals.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
    } else if (_priceSort == 'desc') {
      filteredDeals.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
    }

    return Scaffold(
      backgroundColor: homeBg,
      appBar: wide
          ? buildCustomerAppBar(
              context: context,
              ref: ref,
              title: Row(
                children: [
                  Text(
                    'Explore Deals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          userLocation.address,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(appStateProvider.notifier).refreshOrders(),
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ResponsiveCenter(
            maxWidth: 1200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!wide) ...[
                  _buildModernGreenHeader(context, userLocation, basketCount, customerName),
                  if (activeOrders.isNotEmpty) _buildActiveOrderCourierBanner(context, activeOrders.first),
                  const SizedBox(height: AppSpace.xl),
                  _buildStoryCategoriesRow(),
                  const SizedBox(height: AppSpace.lg),
                  _buildQuickFilterPillsRow(),
                  const SizedBox(height: AppSpace.xl),
                  const _PromoBanner(),
                  const SizedBox(height: AppSpace.xxl),
                  _buildPopularNowSection(context, filteredDeals, businesses, favoriteIds, userLocation),
                  const SizedBox(height: AppSpace.xxl),
                  if (businesses.isNotEmpty) ...[
                    DsSectionHeader(
                      title: 'Featured Kitchens & Bakeries',
                      actionLabel: 'See All',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartnersDirectoryScreen()),
                      ),
                      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
                    ),
                    _FeaturedPartners(businesses: businesses),
                    const SizedBox(height: AppSpace.xxl),
                  ],
                ],

                if (wide) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_getGreeting()}, ${customerName?.split(' ').first ?? 'Friend'}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: primaryText,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Find and rescue surplus food packages from top local kitchens",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        const SizedBox(
                          width: 320,
                          child: _SearchTrigger(isCompact: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                    child: Text("Categories",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            letterSpacing: -0.2)),
                  ),
                  const SizedBox(height: 10),
                  _CategoriesRow(
                    selectedCategory: _selectedCategory,
                    onSelected: (cat) => setState(() => _selectedCategory = cat),
                    isWide: wide,
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: _PromoBanner(isWide: true),
                  ),
                  const SizedBox(height: 20),
                  if (businesses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                      child: Text("Featured Partners",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                              letterSpacing: -0.2)),
                    ),
                    const SizedBox(height: 10),
                    _FeaturedPartners(businesses: businesses),
                    const SizedBox(height: 20),
                  ],
                ],

                // Deals list header
                DsSectionHeader(
                  title: _selectedCategory == 'All' ? 'Active Surplus Packs' : '$_selectedCategory Packs',
                  subtitle: '${filteredDeals.length} packs',
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
                ),

                if (filteredDeals.isEmpty)
                  const _EmptyDeals()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                    child: Builder(
                      builder: (context) {
                        const gap = 16.0;
                        final screenW = MediaQuery.sizeOf(context).width;
                        final availableW = (screenW > 1200 ? 1200.0 : screenW) - 40;
                        final columns = availableW >= 1100 ? 4 : (availableW >= 780 ? 3 : (availableW >= 500 ? 2 : 1));
                        final itemWidth = (availableW - gap * (columns - 1)) / columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final deal in filteredDeals)
                              SizedBox(
                                width: itemWidth,
                                child: _DealCard(
                                  deal: deal,
                                  isFavorite: favoriteIds.contains(deal.businessId),
                                  distance: _distanceTo(deal, businesses, userLocation),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceSearchModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.mic_rounded, color: AppTheme.primaryGreen, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Listening for cravings...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 6),
              const Text(
                'Say or tap what you want to eat right now',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Cheese Burger',
                  'Gourmet Pizza',
                  'Seafood Soup',
                  'Strawberry Cake',
                  'Jollof Rice',
                ].map((s) {
                  return ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 14, color: AppTheme.primaryGreen),
                    label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchFilterScreen(),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernGreenHeader(BuildContext context, UserLocation userLocation, int basketCount, String? customerName) {
    final activeOrders = ref.watch(appStateProvider.select((s) => s.orders.where((o) => o.status == 'confirmed' || o.status == 'ready' || o.status == 'pending').toList()));
    final firstName = customerName?.trim().split(' ').first;
    final hasName = firstName != null && firstName.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          MediaQuery.paddingOf(context).top + AppSpace.md,
          AppSpace.gutter,
          AppSpace.xl,
        ),
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Location pill
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: true,
                      label: 'Delivery location ${userLocation.address}. Tap to change',
                      child: DsPressable(
                        onTap: _showAddressSelectionBottomSheet,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44, maxWidth: 220),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: AppRadius.rPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppTheme.limeAccent, size: 18),
                              const SizedBox(width: AppSpace.xs),
                              Flexible(
                                child: Text(
                                  userLocation.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                // Orders button with live-order badge
                Semantics(
                  button: true,
                  label: activeOrders.isEmpty ? 'Orders' : 'Orders, ${activeOrders.length} active',
                  child: DsPressable(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 21),
                          ),
                          if (activeOrders.isNotEmpty)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.dealOrange,
                                  borderRadius: AppRadius.rPill,
                                  border: Border.all(color: AppTheme.deepGreen, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${activeOrders.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // Avatar with account menu
                buildCustomerAvatarMenuAnchor(
                  context: context,
                  ref: ref,
                  radius: 20,
                  showRing: true,
                  ringColor: AppTheme.limeAccent,
                  alignmentOffset: const Offset(-180, 8),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              _getGreeting(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Semantics(
              header: true,
              child: Text(
                hasName ? '$firstName, rescue a\ngreat meal today' : 'Rescue a great\nmeal today',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.12,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            // Search
            Semantics(
              button: true,
              label: 'Search food, groceries and drinks',
              child: DsPressable(
                pressedScale: 0.985,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                ),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.only(left: AppSpace.lg, right: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.rMd,
                    boxShadow: AppTheme.clientElevatedShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.mutedGrey, size: 22),
                      const SizedBox(width: AppSpace.md),
                      const Expanded(
                        child: Text(
                          'Search Food, Groceries, Drinks etc...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 14.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Voice search',
                        child: DsPressable(
                          onTap: _showVoiceSearchModal,
                          pressedScale: 0.9,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
                            child: const Icon(Icons.mic_rounded, color: AppTheme.primaryGreen, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCourierBanner(BuildContext context, Order activeOrder) {
    final ready = activeOrder.status == 'ready';
    final headline = activeOrder.dealTitle.isNotEmpty
        ? '${activeOrder.dealTitle} is ${ready ? "ready for pickup" : "being prepared"}!'
        : 'Active Order #${activeOrder.id.substring(0, activeOrder.id.length > 5 ? 5 : activeOrder.id.length)} is on the way!';
    final status = activeOrder.status.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
      child: DsCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderTrackScreen()),
        ),
        padding: const EdgeInsets.all(AppSpace.md),
        radius: AppRadius.md,
        child: Row(
          children: [
            DsIconBadge(icon: ready ? Icons.shopping_bag_rounded : Icons.soup_kitchen_rounded, tone: DsTone.brand, size: 44),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    '${activeOrder.businessName} • Status: $status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            const DsPill(label: 'Track Live', icon: Icons.arrow_forward_rounded, tone: DsTone.brand, solid: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCategoriesRow() {
    final stateCategories = ref.watch(appStateProvider).categories;
    final categories = stateCategories.isNotEmpty
        ? stateCategories.map((c) => {'label': c.name, 'img': c.imageUrl}).toList()
        : [
            {'label': 'All', 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&auto=format&fit=crop'},
            {'label': 'Meals', 'img': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200&auto=format&fit=crop'},
            {'label': 'Bakery', 'img': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop'},
            {'label': 'Grocery', 'img': 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=200&auto=format&fit=crop'},
            {'label': 'Fast Food', 'img': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&auto=format&fit=crop'},
            {'label': 'Desserts', 'img': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200&auto=format&fit=crop'},
            {'label': 'Buffets', 'img': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&auto=format&fit=crop'},
          ];

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, idx) {
          final cat = categories[idx];
          final label = cat['label'] as String;
          final isSelected = _selectedCategory == label;
          return _buildStoryCircle(
            label: label,
            imageUrl: cat['img'] as String,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategory = label;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({
    required String label,
    required String imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : Colors.black.withValues(alpha: 0.12),
                width: isSelected ? 2.8 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.lightGreenBg,
                  child: const Icon(Icons.fastfood_rounded, color: AppTheme.primaryGreen, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterPillsRow() {
    final priceLabel = _priceSort == 'asc'
        ? 'Price: Low'
        : _priceSort == 'desc'
            ? 'Price: High'
            : 'Price';

    final pills = <(String, IconData)>[
      ('Pickup', Icons.directions_walk_rounded),
      ('Delivery', Icons.two_wheeler_rounded),
      ('Under 30 min', Icons.schedule_rounded),
      ('4.5+ Rating', Icons.star_rounded),
      ('50%+ Off', Icons.sell_rounded),
      (priceLabel, Icons.swap_vert_rounded),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: pills.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, idx) {
          final (pill, icon) = pills[idx];
          final isPricePill = pill == priceLabel;
          final isSelected = isPricePill ? _priceSort != 'none' : _selectedQuickFilter == pill;

          return DsFilterChip(
            label: pill,
            icon: icon,
            selected: isSelected,
            onTap: () {
              setState(() {
                if (isPricePill) {
                  if (_priceSort == 'none') {
                    _priceSort = 'asc';
                  } else if (_priceSort == 'asc') {
                    _priceSort = 'desc';
                  } else {
                    _priceSort = 'none';
                  }
                } else {
                  _selectedQuickFilter = _selectedQuickFilter == pill ? 'Pickup' : pill;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPopularNowSection(
    BuildContext context,
    List<FoodDeal> deals,
    List<BusinessProfile> businesses,
    Set<String> favoriteIds,
    UserLocation userLocation,
  ) {
    if (deals.isEmpty) return const SizedBox.shrink();
    final popularList = deals.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsSectionHeader(
          title: 'Popular Now',
          actionLabel: 'See All',
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.sm, AppSpace.md),
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
          ),
        ),
        SizedBox(
          height: 272,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            itemCount: popularList.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, idx) {
              final deal = popularList[idx];
              return DsDealTile(
                deal: deal,
                distance: _distanceTo(deal, businesses, userLocation),
                isFavorite: favoriteIds.contains(deal.businessId),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal)),
                ),
                onFavorite: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
              );
            },
          ),
        ),
      ],
    );
  }

  double _distanceTo(FoodDeal deal, List<BusinessProfile> businesses, UserLocation userLocation) {
    double distance = 1.5;
    try {
      final biz = businesses.firstWhere((b) => b.id == deal.businessId);
      // Fall back to central Accra when the user has not shared a location,
      // since BusinessProfile.distance is not stored in the database.
      final fromLat = userLocation.position?.latitude ?? 5.6037;
      final fromLng = userLocation.position?.longitude ?? -0.1870;
      distance = Geolocator.distanceBetween(
            fromLat,
            fromLng,
            biz.latitude,
            biz.longitude,
          ) /
          1000;
    } catch (_) {}
    return distance;
  }

  /// Location notice styled like the biometric (Face ID) linking sheet.
  void _showLocationNoticeSheet({
    required String title,
    required String message,
    required bool openAppSettings,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? AppTheme.charcoal : Colors.white;
        final textCol = isDark ? Colors.white : AppTheme.charcoal;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  openAppSettings
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  size: 36,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (openAppSettings) {
                      Geolocator.openAppSettings();
                    } else {
                      Geolocator.openLocationSettings();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Open Settings",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddressSelectionBottomSheet();
                },
                child: const Text(
                  "Enter Manually",
                  style: TextStyle(
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddressSelectionBottomSheet({bool isInitialSetup = false}) {
    final currentAddress = ref.read(userLocationProvider).address;
    final textController = TextEditingController(
        text: (currentAddress == "Accra, Ghana" || currentAddress == "Osu, Accra")
            ? ""
            : currentAddress);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.charcoal : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final inputBg = isDark ? const Color(0xFF0F172A) : AppTheme.cream;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.charcoal.withValues(alpha: 0.06);

    List<PredictedAddress> predictions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (dialogCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top drag indicator
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : AppTheme.charcoal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (isInitialSetup) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Set Your Location",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  color: primaryTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Choose your area to discover food deals near you",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Location",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Search field
                  TextField(
                    controller: textController,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                      fontSize: 15,
                    ),
                    onChanged: (query) async {
                      final trimmed = query.trim();
                      if (trimmed.length >= 3) {
                        setSheetState(() => isSearching = true);
                        final results = await LocationService().searchPredictiveAddresses(trimmed);
                        setSheetState(() {
                          predictions = results;
                          isSearching = false;
                        });
                      } else {
                        setSheetState(() {
                          predictions = [];
                          isSearching = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Enter street, neighborhood or city...",
                      hintStyle: TextStyle(
                        color: secondaryTextColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                              ),
                            )
                          : textController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    textController.clear();
                                    setSheetState(() => predictions = []);
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: inputBg,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) async {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty) {
                        Navigator.pop(bottomSheetContext);
                        await ref.read(userLocationProvider.notifier).setAddress(trimmed);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Location set to $trimmed")),
                                ],
                              ),
                              backgroundColor: AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  // Predictive results list
                  if (predictions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: predictions.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: borderColor),
                        itemBuilder: (itemCtx, idx) {
                          final p = predictions[idx];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_rounded, color: AppTheme.primaryGreen, size: 18),
                            title: Text(
                              p.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              Navigator.pop(bottomSheetContext);
                              await ref.read(userLocationProvider.notifier).setAddress(
                                    p.displayName,
                                    p.toPosition(),
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text("Location set to ${p.displayName}")),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Use current location tile
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        final res = await ref
                            .read(userLocationProvider.notifier)
                            .fetchCurrentLocation();
                        if (mounted) {
                          if (res.status == 'success') {
                            final newAddr = ref.read(userLocationProvider).address;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text("Location updated to $newAddr")),
                                  ],
                                ),
                                backgroundColor: AppTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else if (res.status == 'gps_disabled') {
                            _showLocationNoticeSheet(
                              title: "Location Services Turned Off",
                              message: "Device location is currently switched off on your phone. Turn on Location Services in settings to pinpoint nearby stores, or type your address manually.",
                              openAppSettings: false,
                            );
                          } else if (res.status == 'permission_denied_forever') {
                            _showLocationNoticeSheet(
                              title: "Location Permission Restricted",
                              message: "Location permission was previously restricted. You can enable it in phone settings or continue entering your address manually.",
                              openAppSettings: true,
                            );
                          } else if (res.status == 'permission_denied') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Location access was not granted. You can search or select your address below."),
                                backgroundColor: AppTheme.charcoal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.my_location_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Use my current location",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Find nearby stores and fill in your address faster",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mutedGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.primaryGreen, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Popular areas header
                  Row(
                    children: [
                      Icon(Icons.near_me_rounded, size: 15, color: secondaryTextColor),
                      const SizedBox(width: 6),
                      Text(
                        "Popular Ghana Neighborhoods",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: primaryTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Wrap of popular areas
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      "East Legon",
                      "Airport Residential",
                      "Cantonments",
                      "Osu",
                      "Labone",
                      "Spintex",
                      "Dzorwulu",
                      "Madina",
                      "Tema",
                      "Kumasi Central",
                    ].map((area) {
                      return InkWell(
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final fullName = area == "Kumasi Central"
                              ? "Kumasi, Ghana"
                              : "$area, Accra";
                          await ref
                              .read(userLocationProvider.notifier)
                              .setAddress(fullName);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text("Location set to $fullName")),
                                  ],
                                ),
                                backgroundColor: AppTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F1F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: borderColor),
                          ),
                          child: Text(
                            area,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE SUB-WIDGETS (Optimization: Minimize Rebuilds)
// ═══════════════════════════════════════════════════════════════════════════


class _SearchTrigger extends StatelessWidget {
  final bool isCompact;
  const _SearchTrigger({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: isCompact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(20.0, 0, 20.0, 16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SearchFilterScreen())),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.charcoal : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.charcoal.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x08000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search food packs, restaurants...",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.tune_rounded, color: AppTheme.primaryGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onSelected;
  final bool isWide;
  const _CategoriesRow({required this.selectedCategory, required this.onSelected, this.isWide = false});

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Restaurant Meal', 'icon': Icons.restaurant_rounded},
    {'name': 'Bakery Pack', 'icon': Icons.bakery_dining_rounded},
    {'name': 'Grocery Bundle', 'icon': Icons.local_grocery_store_rounded},
    {'name': 'Fruit & Vegetable Pack', 'icon': Icons.eco_rounded},
    {'name': 'Hotel Buffet', 'icon': Icons.room_service_rounded},
    {'name': 'Snacks & Drinks', 'icon': Icons.local_cafe_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((cat) {
            final name = cat['name'] as String;
            final icon = cat['icon'] as IconData;
            final isSelected = selectedCategory == name;

            String displayLabel = name;
            if (name.contains('Meal')) displayLabel = 'Meals';
            if (name.contains('Pack')) displayLabel = 'Bakery';
            if (name.contains('Bundle')) displayLabel = 'Grocery';
            if (name.contains('Vegetable')) displayLabel = 'Fruits';
            if (name.contains('Buffet')) displayLabel = 'Buffets';
            if (name.contains('Drinks')) displayLabel = 'Drinks';

            return InkWell(
              onTap: () => onSelected(name),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : (isDark ? AppTheme.charcoal : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.hairline),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryGreen),
                    const SizedBox(width: 7),
                    Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.charcoal),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final name = cat['name'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = selectedCategory == name;

          String displayLabel = name;
          if (name.contains('Meal')) displayLabel = 'Meals';
          if (name.contains('Pack')) displayLabel = 'Bakery';
          if (name.contains('Bundle')) displayLabel = 'Grocery';
          if (name.contains('Vegetable')) displayLabel = 'Fruits';
          if (name.contains('Buffet')) displayLabel = 'Buffets';
          if (name.contains('Drinks')) displayLabel = 'Drinks';

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onSelected(name),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : (isDark ? AppTheme.charcoal : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.charcoal.withValues(alpha: 0.06)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : (isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final bool isWide;
  const _PromoBanner({this.isWide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isWide ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      constraints: const BoxConstraints(minHeight: 132),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.rLg,
        gradient: const LinearGradient(
          colors: [AppTheme.mintGreen, AppTheme.lightGreenBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -36,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.limeAccent.withValues(alpha: 0.55),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const DsPill(label: '70% OFF DEAL', tone: DsTone.dark, solid: true, compact: true),
                      const SizedBox(height: AppSpace.md),
                      const Text(
                        'Save Delicious Surplus Food Near You',
                        style: TextStyle(
                          color: AppTheme.deepGreen,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.lg),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppTheme.deepGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.delivery_dining_rounded, color: AppTheme.limeAccent, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPartners extends StatelessWidget {
  final List<BusinessProfile> businesses;
  const _FeaturedPartners({required this.businesses});

  @override
  Widget build(BuildContext context) {
    final featured = businesses.take(12).toList();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featured.length,
        itemBuilder: (context, index) {
          final partner = featured[index];
          return _PartnerCircleCard(partner: partner);
        },
      ),
    );
  }
}

class _PartnerCircleCard extends StatelessWidget {
  final BusinessProfile partner;
  const _PartnerCircleCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantStorefrontScreen(business: partner),
          ),
        );
      },
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.charcoal.withValues(alpha: 0.08), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: partner.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: partner.logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                        errorWidget: (context, url, error) => _FallbackPartnerIcon(category: partner.category),
                      )
                    : _FallbackPartnerIcon(category: partner.category),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              partner.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppTheme.charcoal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 10),
                const SizedBox(width: 2),
                Text(
                  partner.rating > 0 ? partner.rating.toStringAsFixed(1) : "New",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mutedGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackPartnerIcon extends StatelessWidget {
  final String category;
  const _FallbackPartnerIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightGreenBg,
      child: Center(
        child: Icon(
          _getIcon(category),
          color: AppTheme.primaryGreen,
          size: 24,
        ),
      ),
    );
  }

  IconData _getIcon(String cat) {
    if (cat.contains('Bakery')) return Icons.bakery_dining_rounded;
    if (cat.contains('Grocery')) return Icons.local_grocery_store_rounded;
    if (cat.contains('Fruit')) return Icons.eco_rounded;
    if (cat.contains('Hotel')) return Icons.room_service_rounded;
    return Icons.fastfood_rounded;
  }
}

class _DealCard extends ConsumerWidget {
  final FoodDeal deal;
  final bool isFavorite;
  final double distance;
  const _DealCard({required this.deal, required this.isFavorite, required this.distance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DsDealCard(
      deal: deal,
      distance: distance,
      isFavorite: isFavorite,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal)),
      ),
      onFavorite: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
    );
  }
}

class _EmptyDeals extends StatelessWidget {
  const _EmptyDeals();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(40),
      child: BrandedEmptyState(
          title: "No deals found",
          description: "Try changing your category or search.",
          icon: Icons.search_off_rounded));
}
