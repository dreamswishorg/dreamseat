import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import 'deal_detail_screen.dart';
import 'search_filter_screen.dart';
import 'merchant_storefront.dart';
import 'home_shimmer.dart';

class UserLocation {
  final String address;
  final Position? position;

  UserLocation({required this.address, this.position});
}

class UserLocationNotifier extends Notifier<UserLocation> {
  @override
  UserLocation build() => UserLocation(address: "Osu, Accra");

  void setAddress(String address) {
    state = UserLocation(address: address, position: null);
  }

  Future<LocationStatusResult> fetchCurrentLocation() async {
    final loc = LocationService();
    final res = await loc.getPositionWithStatus();
    if (res.status == 'success' && res.position != null) {
      final addr = await loc.getAddressFromLatLng(res.position!);
      state = UserLocation(address: addr ?? "Current Location", position: res.position);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userLocationProvider.notifier).fetchCurrentLocation();
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
    final customerStats =
        ref.watch(appStateProvider.select((s) => s.customerStats));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FA);
    final primaryText = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;

    if (isLoading && deals.isEmpty) {
      return Scaffold(
        backgroundColor: homeBg,
        appBar: buildCustomerAppBar(
          context: context,
          ref: ref,
          title: Text('DREAMEATS',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText)),
        ),
        body: const HomeShimmer(),
      );
    }

    final filteredDeals = sortedDeals.where((deal) {
      final matchesCategory =
          _selectedCategory == 'All' || deal.category == _selectedCategory;
      return matchesCategory && deal.quantityRemaining > 0 && deal.isActive;
    }).toList();

    return Scaffold(
      backgroundColor: homeBg,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: useSideNav(context)
            ? Row(
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
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 28,
                      width: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'DREAM',
                          style: TextStyle(color: AppTheme.primaryGreen),
                        ),
                        TextSpan(
                          text: 'EATS',
                          style: TextStyle(color: Color(0xFFFFB300)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
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
              // Welcome Greeting & Location row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_getGreeting()},",
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerName?.split(' ').first ?? 'Friend 👋',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: primaryText,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _LocationBadge(userLocation: userLocation, onTap: _showAddressSelectionBottomSheet),
                    ),
                  ],
                ),
              ),

              const _SearchTrigger(),

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
              ),
              const SizedBox(height: 20),

              const _PromoBanner(),
              const SizedBox(height: 14),

              _ImpactCard(stats: customerStats),
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

              // Deals list
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Active Surplus Packs",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: primaryText,
                            letterSpacing: -0.3)),
                    Text("${filteredDeals.length} packs",
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5)),
                  ],
                ),
              ),

              if (filteredDeals.isEmpty)
                const _EmptyDeals()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 16.0;
                      final w = constraints.maxWidth;
                      final columns = w >= 1100 ? 4 : (w >= 780 ? 3 : (w >= 500 ? 2 : 1));
                      final itemWidth = (w - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
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

  double _distanceTo(FoodDeal deal, List<BusinessProfile> businesses, UserLocation userLocation) {
    double distance = 1.5;
    try {
      final biz = businesses.firstWhere((b) => b.id == deal.businessId);
      if (userLocation.position != null) {
        distance = Geolocator.distanceBetween(
              userLocation.position!.latitude,
              userLocation.position!.longitude,
              biz.latitude,
              biz.longitude,
            ) /
            1000;
      } else {
        distance = biz.distance;
      }
    } catch (_) {}
    return distance;
  }

  void _showAddressSelectionBottomSheet() {
    final textController = TextEditingController(
        text: ref.read(userLocationProvider).address == "Osu, Accra"
            ? ""
            : ref.read(userLocationProvider).address);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FA);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.charcoal.withValues(alpha: 0.06);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                "Select Location",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: primaryTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: textController,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: "Enter street, area or city...",
                  hintStyle: TextStyle(
                    color: secondaryTextColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.primaryGreen, size: 22),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen, size: 24),
                    onPressed: () {
                      final val = textController.text.trim();
                      if (val.isNotEmpty) {
                        ref.read(userLocationProvider.notifier).setAddress(val);
                        Navigator.pop(context);
                      }
                    },
                  ),
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
                onSubmitted: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isNotEmpty) {
                    ref.read(userLocationProvider.notifier).setAddress(trimmed);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Use current location tile
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("📍 Pinpointing your GPS location..."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final res = await ref
                        .read(userLocationProvider.notifier)
                        .fetchCurrentLocation();
                    if (context.mounted) {
                      if (res.status == 'success') {
                        final newAddr = ref.read(userLocationProvider).address;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✅ Location updated to: $newAddr"),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      } else if (res.status == 'gps_disabled') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("⚠️ Your phone's GPS/Location is turned OFF. Please turn it ON."),
                            backgroundColor: AppTheme.warningOrange,
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'SETTINGS',
                              textColor: Colors.white,
                              onPressed: () => Geolocator.openLocationSettings(),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("❌ Location permission denied. Tap Settings to allow permission."),
                            backgroundColor: AppTheme.errorRed,
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'PERMISSIONS',
                              textColor: Colors.white,
                              onPressed: () => Geolocator.openAppSettings(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
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
                                "Use Current Location",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Pinpoint your delivery location using GPS",
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
              const SizedBox(height: 24),

              // Popular areas header
              const Text(
                "Popular Neighborhoods",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Wrap of popular areas
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "East Legon",
                  "Osu",
                  "Airport Residential",
                  "Cantonments",
                  "Labone",
                  "Spintex",
                  "Madina"
                ].map((area) {
                  return InkWell(
                    onTap: () {
                      ref
                          .read(userLocationProvider.notifier)
                          .setAddress("$area, Accra");
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.charcoal.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        area,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE SUB-WIDGETS (Optimization: Minimize Rebuilds)
// ═══════════════════════════════════════════════════════════════════════════

class _LocationBadge extends StatelessWidget {
  final UserLocation userLocation;
  final VoidCallback onTap;
  const _LocationBadge({required this.userLocation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lightGreenBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppTheme.primaryGreen, size: 14),
            const SizedBox(width: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                userLocation.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primaryGreen, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SearchFilterScreen())),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
  const _CategoriesRow({required this.selectedCategory, required this.onSelected});

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
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
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
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5B3C), Color(0xFF003D27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x262E7D32),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x4000E676), Color(0x0000E676)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "70% OFF DEAL",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Save Delicious Surplus Food Near You",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(Icons.delivery_dining_rounded,
                          color: Colors.white, size: 36),
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
}

class _ImpactCard extends StatelessWidget {
  final SustainabilityStats stats;
  const _ImpactCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
                child: const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Your Food Rescue Impact",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.3),
              ),
            ],
          ),
          // 2 Grid Cards: Money Saved & Money Spent
          Row(
            children: [
              Expanded(
                child: _ImpactTileCard(
                  title: "Money Saved",
                  value: "GHS ${stats.moneySaved.toStringAsFixed(2)}",
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactTileCard(
                  title: "Money Spent",
                  value: "GHS ${stats.moneySpent.toStringAsFixed(2)}",
                  icon: Icons.shopping_bag_rounded,
                  iconColor: Colors.orange[800]!,
                  bgColor: const Color(0xFFFFF7ED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2 Grid Cards: Meals Rescued & CO2 Saved
          Row(
            children: [
              Expanded(
                child: _ImpactTileCard(
                  title: "Meals Rescued",
                  value: "${stats.mealsRescued}",
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactTileCard(
                  title: "CO₂ Saved",
                  value: "${stats.co2Saved.toStringAsFixed(1)} kg",
                  icon: Icons.cloud_done_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactTileCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _ImpactTileCard({required this.title, required this.value, required this.icon, required this.iconColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: iconColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.4),
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
    final featured = businesses.take(6).toList();
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
                  partner.rating.toStringAsFixed(1),
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
    final discountPercent =
        (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.charcoal.withValues(alpha: 0.06);
    final badgeBg = isDark ? const Color(0xFF334155) : const Color(0xFFF0F1F3);

    return _HoverScale(
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DealDetailScreen(deal: deal))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x08000000),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _DealMedia(url: deal.imageUrl, category: deal.category, isFullCard: true),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$discountPercent% OFF",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ExpiryBadge(window: deal.pickupWindow),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () => ref.read(appStateProvider.notifier).toggleFavorite(deal.businessId),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? AppTheme.errorRed : secondaryTextColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            deal.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.primaryGreen, size: 12),
                            const SizedBox(width: 2),
                            Text("${distance.toStringAsFixed(1)} km", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(deal.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: primaryTextColor, letterSpacing: -0.4)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("GHS ${deal.discountedPrice.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 19)),
                                const SizedBox(width: 8),
                                Text("GHS ${deal.originalPrice.toStringAsFixed(0)}", style: TextStyle(decoration: TextDecoration.lineThrough, color: secondaryTextColor, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text("Only ${deal.quantityRemaining} left", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: primaryTextColor, size: 12),
                              const SizedBox(width: 6),
                              Text(deal.pickupWindow, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final String window;
  const _ExpiryBadge({required this.window});

  @override
  Widget build(BuildContext context) {
    // Determine if urgency needed
    bool isUrgent = window.toLowerCase().contains("minutes") || window.toLowerCase().contains("pm") && DateTime.now().hour >= 17;

    if (!isUrgent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.goldAccent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            "CLOSING SOON",
            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _DealMedia extends StatelessWidget {
  final String url;
  final String category;
  final bool isFullCard;
  const _DealMedia({required this.url, required this.category, this.isFullCard = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppTheme.lightGreenBg,
        borderRadius: isFullCard ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(16),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: isFullCard ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                errorWidget: (context, url, error) => _FallbackIcon(category: category),
              ),
            )
          : _FallbackIcon(category: category),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final String category;
  const _FallbackIcon({required this.category});
  @override
  Widget build(BuildContext context) => Center(child: Icon(_getIcon(category), color: AppTheme.primaryGreen, size: 40));

  IconData _getIcon(String cat) {
    if (cat.contains('Bakery')) return Icons.bakery_dining_rounded;
    if (cat.contains('Grocery')) return Icons.local_grocery_store_rounded;
    if (cat.contains('Fruit')) return Icons.eco_rounded;
    if (cat.contains('Hotel')) return Icons.room_service_rounded;
    return Icons.fastfood_rounded;
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

class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedScale(
          scale: _h ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child));
}
