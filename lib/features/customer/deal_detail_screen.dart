import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
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
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final saved = (deal.originalPrice - deal.discountedPrice).clamp(0, double.infinity);
    final lowStock = deal.quantityRemaining <= 3;
    const heroHeight = 340.0;

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Stack(
        children: [
          // Fixed hero image; the content sheet scrolls over it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'deal-image-${deal.id}',
                  child: _buildHeroVisual(imageUrl: deal.imageUrl, category: deal.category),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x59000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ResponsiveCenter(
              maxWidth: 800,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: heroHeight - AppRadius.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xxl, AppSpace.gutter, 0),
                    decoration: const BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.sm,
                          children: [
                            DsPill(label: deal.category, tone: DsTone.neutral),
                            if (deal.percentageSaved > 0)
                              DsPill(label: 'SAVE ${deal.percentageSaved}%', tone: DsTone.deal, solid: true),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        Semantics(
                          header: true,
                          child: Text(
                            deal.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.8,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),

                        // Merchant row
                        DsPressable(
                          onTap: business == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MerchantStorefrontScreen(business: business)),
                                  ),
                          semanticLabel: 'Open ${deal.businessName} storefront',
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                            decoration: BoxDecoration(
                              color: AppTheme.cream,
                              borderRadius: AppRadius.rMd,
                              border: Border.all(color: AppTheme.hairline),
                            ),
                            child: Row(
                              children: [
                                const DsIconBadge(icon: Icons.storefront_rounded, size: 36),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Text(
                                    deal.businessName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                                  ),
                                ),
                                if (business != null) ...[
                                  const Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 18),
                                  const SizedBox(width: AppSpace.xs),
                                  Text(
                                    business.rating > 0 ? business.rating.toStringAsFixed(1) : 'New',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.charcoal),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                ],
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),

                        // Price + savings
                        DsCard(
                          padding: const EdgeInsets.all(AppSpace.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Rescue Price',
                                          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              'GHS ${AppTheme.formatPrice(deal.discountedPrice)}',
                                              style: const TextStyle(
                                                color: AppTheme.primaryGreen,
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1.2,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpace.sm),
                                            Flexible(
                                              child: Text(
                                                'GHS ${AppTheme.formatPrice(deal.originalPrice)}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: AppTheme.mutedGrey,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (saved > 0) ...[
                                const SizedBox(height: AppSpace.md),
                                DsPill(label: 'You save GHS ${AppTheme.formatPrice(saved)}', icon: Icons.savings_rounded, tone: DsTone.deal),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                                child: Divider(),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMiniInfo(Icons.schedule_rounded, deal.pickupWindow, 'Pickup Window'),
                                  const SizedBox(width: AppSpace.lg),
                                  _buildMiniInfo(
                                    Icons.inventory_2_rounded,
                                    lowStock ? 'Only ${deal.quantityRemaining} left' : '${deal.quantityRemaining} available',
                                    'Availability',
                                    tone: lowStock ? DsTone.deal : DsTone.neutral,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.x3),

                        // Dietary
                        if (deal.dietaryTags.isNotEmpty) ...[
                          _sectionTitle('Dietary Information'),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              for (final tag in deal.dietaryTags)
                                DsPill(label: tag, icon: Icons.check_circle_rounded, tone: DsTone.brand),
                            ],
                          ),
                          const SizedBox(height: AppSpace.x3),
                        ],

                        // Description
                        if (deal.description.trim().isNotEmpty) ...[
                          _sectionTitle("What's in the pack?"),
                          Text(
                            deal.description,
                            style: const TextStyle(color: AppTheme.charcoal, fontSize: 15.5, height: 1.6, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: AppSpace.x3),
                        ],

                        // Pickup
                        _sectionTitle('Pickup Instructions & Location'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpace.lg),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreenBg,
                            borderRadius: AppRadius.rMd,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, color: AppTheme.primaryGreen, size: 20),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Text(
                                      'Window: ${deal.pickupWindow}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.deepGreen, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.place_rounded, color: AppTheme.deepGreen, size: 20),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Text(
                                      business?.location ?? 'Accra, Ghana',
                                      style: const TextStyle(fontSize: 14, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.lg),
                              const Text(
                                'Guideline: Please do not go to the merchant outside the pickup window. Bring your phone and show the Collection Code to the shop assistant to verify before taking your food package.',
                                style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: AppSpace.lg),
                              DsButton(
                                label: 'Get Directions',
                                icon: Icons.directions_rounded,
                                variant: DsButtonVariant.secondary,
                                onPressed: () => _launchDirections(context, business),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 120 + bottomInset),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating back button
          Positioned(
            top: topInset + AppSpace.sm,
            left: AppSpace.md,
            child: Semantics(
              button: true,
              label: 'Back',
              child: DsPressable(
                onTap: () => Navigator.pop(context),
                pressedScale: 0.9,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.charcoal),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.md + bottomInset),
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          border: Border(top: BorderSide(color: AppTheme.hairline)),
          boxShadow: [BoxShadow(color: Color(0x0F0F172A), blurRadius: 20, offset: Offset(0, -6))],
        ),
        child: ResponsiveCenter(
          maxWidth: 800,
          child: DsButton(
            label: 'Add to Basket',
            icon: Icons.shopping_basket_rounded,
            onPressed: () {
              ref.read(appStateProvider.notifier).addToBasket(deal);
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Added to basket!'),
                  duration: const Duration(seconds: 3),
                  margin: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 96 + bottomInset),
                  action: SnackBarAction(
                    label: 'View Basket',
                    textColor: AppTheme.limeAccent,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BasketScreen(isStandalone: true)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.4),
          ),
        ),
      );

  Widget _buildHeroVisual({required String imageUrl, required String category}) {
    return DsMedia(url: imageUrl.trim(), category: category);
  }

  Widget _buildMiniInfo(IconData icon, String value, String label, {DsTone tone = DsTone.neutral}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconBadge(icon: icon, tone: tone, size: 36),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal)),
                const SizedBox(height: AppSpace.xxs),
                Text(label, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
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
