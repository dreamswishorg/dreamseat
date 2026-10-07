import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'checkout_screen.dart';

class BasketScreen extends ConsumerStatefulWidget {
  const BasketScreen({super.key});

  @override
  ConsumerState<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends ConsumerState<BasketScreen> {
  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'restaurant':
      case 'local food':
        return Icons.restaurant_rounded;
      case 'grocery':
      case 'supermarket':
        return Icons.local_grocery_store_rounded;
      case 'cafe':
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'sushi':
        return Icons.set_meal_rounded;
      case 'dessert':
      case 'pastry':
        return Icons.icecream_rounded;
      case 'juice':
      case 'smoothie':
        return Icons.local_drink_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(appStateProvider.select((s) => s.basket));
    final itemCount = ref.watch(appStateProvider.select((s) => s.basketItemCount));
    final total = ref.watch(appStateProvider.select((s) => s.basketTotal));
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        foregroundColor: AppTheme.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Basket',
              style: TextStyle(
                color: AppTheme.charcoal,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (itemCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.charcoal.withValues(alpha: 0.07),
            height: 1,
          ),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 760,
        child: basket.isEmpty
            ? _buildEmptyState(context)
            : _buildBasketContent(context, basket, notifier, total),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return BrandedEmptyState(
      title: "Your basket is empty",
      description: "You haven't added any rescue deals yet. Start exploring to save food and money!",
      icon: Icons.shopping_basket_rounded,
      actionLabel: "Explore Deals",
      onAction: () => Navigator.pop(context),
    );
  }

  // ─── Basket Content ─────────────────────────────────────────────────────────

  Widget _buildBasketContent(
    BuildContext context,
    List<BasketItem> basket,
    AppStateManager notifier,
    double total,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: basket.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = basket[index];
              return _BasketItemCard(
                item: item,
                categoryIcon: _categoryIcon(item.deal.category),
                onIncrement: () =>
                    notifier.updateBasketQuantity(item.deal.id, item.quantity + 1),
                onDecrement: () {
                  if (item.quantity > 1) {
                    notifier.updateBasketQuantity(item.deal.id, item.quantity - 1);
                  } else {
                    notifier.removeFromBasket(item.deal.id);
                  }
                },
                onDismiss: () => notifier.removeFromBasket(item.deal.id),
              );
            },
          ),
        ),
        _buildOrderSummary(context, basket, total),
      ],
    );
  }

  // ─── Order Summary Panel ────────────────────────────────────────────────────

  Widget _buildOrderSummary(
    BuildContext context,
    List<BasketItem> basket,
    double total,
  ) {
    final totalMeals = basket.fold<int>(0, (sum, i) => sum + i.quantity);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Order Summary',
            style: TextStyle(
              color: AppTheme.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          _summaryRow('Subtotal', 'GHS ${total.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow(
            'Platform Fee (0%)',
            'GHS 0.00',
            valueColor: AppTheme.primaryGreen,
            badge: 'FREE',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: DashedDivider(
              color: AppTheme.charcoal.withValues(alpha: 0.12),
              height: 1,
              dashWidth: 6,
              dashSpace: 4,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'GHS ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Eco note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lightGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re rescuing $totalMeals meal${totalMeals == 1 ? '' : 's'} from going to waste 🌿',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Proceed button
          ElevatedButton(
            onPressed: () {
              // Pass the first deal as a representative; CheckoutScreen reads
              // the full basket from state internally for basket-mode checkout.
              final firstDeal = basket.first.deal;
              Navigator.push(
                context,
                _createCheckoutRoute(firstDeal),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: AppTheme.pureWhite, size: 18),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    String? badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 14),
        ),
        Row(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.charcoal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Route _createCheckoutRoute(FoodDeal deal) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CheckoutScreen(deal: deal),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.95;
        const end = 1.0;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Basket Item Card ───────────────────────────────────────────────────────────

class _BasketItemCard extends StatelessWidget {
  final BasketItem item;
  final IconData categoryIcon;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDismiss;

  const _BasketItemCard({
    required this.item,
    required this.categoryIcon,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.deal.id),
      direction: DismissDirection.endToStart,
      background: _swipeBackground(),
      confirmDismiss: (_) async {
        onDismiss();
        return false;
      },
      child: _HoverLift(
        child: Container(
          decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.charcoal.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppTheme.charcoal.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Deal Image/Icon Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.deal.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.deal.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppTheme.lightGrey),
                        )
                      : Icon(categoryIcon, color: AppTheme.primaryGreen, size: 28),
                ),
              ),
              const SizedBox(width: 14),

              // Deal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.deal.title,
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.deal.businessName,
                      style: const TextStyle(
                        color: AppTheme.mutedGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'GHS ${item.deal.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GHS ${item.deal.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.mutedGrey.withValues(alpha: 0.6),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Quantity adjuster
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyButton(
                          icon: item.quantity == 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                          color: item.quantity == 1
                              ? AppTheme.errorRed
                              : AppTheme.charcoal,
                          onTap: onDecrement,
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _qtyButton(
                          icon: Icons.add_rounded,
                          color: AppTheme.primaryGreen,
                          onTap: onIncrement,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _swipeBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorRed,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

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
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
