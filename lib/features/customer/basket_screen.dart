import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'modern_checkout_screen.dart';

class BasketScreen extends ConsumerStatefulWidget {
  final bool isStandalone;
  const BasketScreen({super.key, this.isStandalone = false});

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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        foregroundColor: AppTheme.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (widget.isStandalone && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ref.read(customerTabProvider.notifier).state = 0;
            }
          },
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
                  borderRadius: BorderRadius.circular(24),
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
      onAction: () {
        if (widget.isStandalone && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ref.read(customerTabProvider.notifier).state = 0;
      },
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
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.md),
            itemCount: basket.length,
            separatorBuilder: (context, i) => const SizedBox(height: AppSpace.md),
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
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(top: BorderSide(color: AppTheme.hairline)),
        boxShadow: [BoxShadow(color: Color(0x120F172A), blurRadius: 24, offset: Offset(0, -8))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Order Summary',
              style: TextStyle(
                color: AppTheme.charcoal,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          _summaryRow('Subtotal', 'GHS ${total.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpace.sm),
          _summaryRow(
            'Platform Fee (0%)',
            'GHS 0.00',
            valueColor: AppTheme.primaryGreen,
            badge: 'FREE',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: DashedDivider(
              color: AppTheme.hairline,
              height: 1,
              dashWidth: 6,
              dashSpace: 4,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: AppTheme.charcoal, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'GHS ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Eco note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: AppTheme.lightGreenBg,
              borderRadius: AppRadius.rSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'You\'re rescuing $totalMeals meal${totalMeals == 1 ? '' : 's'} from going to waste',
                    style: const TextStyle(
                      color: AppTheme.deepGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.lg),

          DsButton(
            label: 'Proceed to Checkout',
            icon: Icons.lock_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModernCheckoutScreen()),
              );
            },
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
          style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            if (badge != null) ...[
              DsPill(label: badge, tone: DsTone.brand, solid: true, compact: true),
              const SizedBox(width: AppSpace.sm),
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
      child: DsCard(
        padding: const EdgeInsets.all(AppSpace.md),
        radius: AppRadius.md,
        child: Row(
          children: [
            // Deal image / icon
            SizedBox(
              width: 72,
              height: 72,
              child: DsMedia(
                url: item.deal.imageUrl,
                category: item.deal.category,
                borderRadius: AppRadius.rSm,
              ),
            ),
            const SizedBox(width: AppSpace.md),

            // Deal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.deal.title,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    item.deal.businessName,
                    style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'GHS ${AppTheme.formatPrice(item.deal.discountedPrice)}',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          'GHS ${AppTheme.formatPrice(item.deal.originalPrice)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.mutedGrey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),

            // Quantity stepper
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: AppRadius.rPill,
                border: Border.all(color: AppTheme.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyButton(
                    icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                    color: item.quantity == 1 ? AppTheme.errorRed : AppTheme.charcoal,
                    label: item.quantity == 1 ? 'Remove ${item.deal.title}' : 'Decrease quantity',
                    onTap: onDecrement,
                  ),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.charcoal, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                  _qtyButton(
                    icon: Icons.add_rounded,
                    color: AppTheme.primaryGreen,
                    label: 'Increase quantity',
                    onTap: onIncrement,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: DsPressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _swipeBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorRed,
        borderRadius: AppRadius.rMd,
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
