import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import 'checkout_screen.dart';
import 'basket_screen.dart';
import 'merchant_storefront.dart';

class DealDetailScreen extends ConsumerWidget {
  final FoodDeal deal;
  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(appStateProvider.select((s) {
      for (final b in s.businesses) {
        if (b.id == deal.businessId) return b;
      }
      return null;
    }));

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.charcoal,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.lightGreenBg, Color(0xFFE8F5E9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'deal-image-${deal.id}',
                      child: _buildHeroVisual(
                        imageUrl: deal.imageUrl,
                        category: deal.category,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.12), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 92,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        deal.category,
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorRed.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Text(
                        "SAVE ${deal.percentageSaved}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and business info
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () {
                      if (business != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MerchantStorefrontScreen(business: business),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          deal.businessName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.mutedGrey, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          "${business?.rating ?? 4.5}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.directions_walk_rounded, color: AppTheme.mutedGrey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${business?.distance ?? 1.5} km",
                          style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(color: AppTheme.charcoal.withValues(alpha: 0.05)),
                  const SizedBox(height: 18),

                  // Prices & Inventory Remaining
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Rescue Price",
                                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "GHS ${deal.discountedPrice.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "GHS ${deal.originalPrice.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppTheme.mutedGrey.withValues(alpha: 0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "-${deal.percentageSaved}%",
                                style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: AppTheme.charcoal.withValues(alpha: 0.05)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildMiniInfo(Icons.access_time_filled_rounded, deal.pickupWindow, "Pickup Window"),
                            const SizedBox(width: 24),
                            _buildMiniInfo(Icons.inventory_2_rounded, "${deal.quantityRemaining} left", "Availability"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dietary Tags
                  if (deal.dietaryTags.isNotEmpty) ...[
                    const Text(
                      "Dietary Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: deal.dietaryTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.primaryGreen),
                            const SizedBox(width: 6),
                            Text(
                              tag,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Description
                  const Text(
                    "What's in the pack?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deal.description,
                    style: const TextStyle(
                      color: AppTheme.mutedGrey,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Pickup Instructions
                  const Text(
                    "Pickup Instructions & Location",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Window: ${deal.pickupWindow}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: AppTheme.charcoal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                business?.location ?? "Accra, Ghana",
                                style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                        const SizedBox(height: 10),
                        const Text(
                          "Guideline: Please do not go to the merchant outside the pickup window. Bring your phone and show the Collection Code to the shop assistant to verify before taking your food package.",
                          style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _launchDirections(context, business),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text("Get Directions", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 110), // padding to scroll above the fixed reserve button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.charcoal.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(appStateProvider.notifier).addToBasket(deal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Added to basket!'),
                        backgroundColor: AppTheme.primaryGreen,
                        action: SnackBarAction(
                          label: 'View Basket',
                          textColor: Colors.white,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BasketScreen()),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_basket_rounded, size: 18),
                  label: const Text('Add to Basket', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                    foregroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(deal: deal),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text('GHS ${deal.discountedPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroVisual({required String imageUrl, required String category}) {
    final hasImage = imageUrl.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.lightGreenBg, const Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(color: AppTheme.lightGrey),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  _getIconForCategory(category),
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
              ),
            )
          : Center(
              child: Icon(
                _getIconForCategory(category),
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: AppTheme.charcoal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.charcoal)),
                Text(label, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
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

  Future<void> _launchDirections(BuildContext context, BusinessProfile? business) async {
    final destLat = business?.latitude ?? 5.6037;
    final destLng = business?.longitude ?? -0.1870;
    final destName = business?.name ?? 'Partner Location';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text("Getting route from your location..."),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final userPos = await LocationService().getCurrentPosition();
    Uri mapUrl;

    if (userPos != null) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        mapUrl = Uri.parse('https://maps.apple.com/?saddr=${userPos.latitude},${userPos.longitude}&daddr=$destLat,$destLng&dirflg=d');
      } else {
        mapUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${userPos.latitude},${userPos.longitude}&destination=$destLat,$destLng&travelmode=driving');
      }
    } else {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        mapUrl = Uri.parse('https://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d');
      } else {
        mapUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving');
      }
    }

    try {
      if (await canLaunchUrl(mapUrl)) {
        await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open maps for $destName: $e")),
        );
      }
    }
  }
}
