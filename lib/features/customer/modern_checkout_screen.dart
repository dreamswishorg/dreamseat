import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'order_track_screen.dart';
import 'order_confirmation_screen.dart';

class ModernCheckoutScreen extends ConsumerStatefulWidget {
  final FoodDeal? directDeal; // Single deal direct checkout or full basket checkout

  const ModernCheckoutScreen({super.key, this.directDeal});

  @override
  ConsumerState<ModernCheckoutScreen> createState() => _ModernCheckoutScreenState();
}

class _ModernCheckoutScreenState extends ConsumerState<ModernCheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();
  String _appliedPromoCode = '';
  double _discountAmount = 0.0;
  bool _isProcessing = false;

  final List<String> _suggestedVouchers = [
    'WELCOME20',
    'RESCUE10',
    'FREEDEL',
  ];

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    if (cleanCode == 'WELCOME20') {
      setState(() {
        _appliedPromoCode = cleanCode;
        _discountAmount = 20.00;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 WELCOME20 applied: Saved GHS 20.00!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else if (cleanCode == 'RESCUE10') {
      setState(() {
        _appliedPromoCode = cleanCode;
        _discountAmount = 10.00;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌱 RESCUE10 applied: Saved GHS 10.00!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else if (cleanCode == 'FREEDEL') {
      setState(() {
        _appliedPromoCode = cleanCode;
        _discountAmount = 5.00;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛵 Free Delivery Voucher applied!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code. Try WELCOME20 or RESCUE10'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _onCheckoutPressed(double finalTotal, List<BasketItem> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your basket is empty')),
      );
      return;
    }

    // Show Payment Provider Selection Sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 14),
              _buildPaymentOption(
                ctx,
                name: 'MTN Mobile Money',
                subtitle: 'Instant USSD Prompt',
                color: const Color(0xFFFFCC00),
                icon: Icons.phone_android_rounded,
                onTap: () => _completePayment(ctx, 'MTN MoMo', finalTotal, items),
              ),
              _buildPaymentOption(
                ctx,
                name: 'Telecel Cash',
                subtitle: 'Vodafone Cash Direct Prompt',
                color: const Color(0xFFDC2626),
                icon: Icons.phone_iphone_rounded,
                onTap: () => _completePayment(ctx, 'Telecel Cash', finalTotal, items),
              ),
              _buildPaymentOption(
                ctx,
                name: 'Visa / Mastercard',
                subtitle: 'Secured Card Gateway',
                color: const Color(0xFF0F172A),
                icon: Icons.credit_card_rounded,
                onTap: () => _completePayment(ctx, 'Visa/Card', finalTotal, items),
              ),
              _buildPaymentOption(
                ctx,
                name: 'Cash on Pickup',
                subtitle: 'Pay directly at restaurant counter',
                color: const Color(0xFF16A34A),
                icon: Icons.payments_rounded,
                onTap: () => _completePayment(ctx, 'Cash on Pickup', finalTotal, items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String name,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.mutedGrey),
        onTap: onTap,
      ),
    );
  }

  Future<void> _completePayment(
    BuildContext modalCtx,
    String method,
    double total,
    List<BasketItem> items,
  ) async {
    Navigator.pop(modalCtx); // Close payment sheet
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(appStateProvider.notifier);
      final refCode = 'DE-${DateTime.now().millisecondsSinceEpoch}';

      // Purchase the first item (or all items)
      Order? createdOrder;
      for (final item in items) {
        createdOrder = await notifier.purchase(item.deal, method, refCode);
      }
      notifier.clearBasket();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Offer direct live tracking or order confirmation!
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Order Confirmed! 🚀',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            'Your rescue order has been placed. Courier Rober Jr. is preparing for pickup!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Track Live Route (Order Track)'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackScreen(order: createdOrder),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (createdOrder != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(order: createdOrder!),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('View Pickup Voucher / Code'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(appStateProvider.select((s) => s.basket));
    final notifier = ref.read(appStateProvider.notifier);

    // If directDeal is provided and basket is empty, create a single item representation
    List<BasketItem> displayItems = List.from(basket);
    if (widget.directDeal != null && displayItems.isEmpty) {
      displayItems = [BasketItem(deal: widget.directDeal!, quantity: 1)];
    }

    final double subtotal = displayItems.fold(
      0.0,
      (sum, item) => sum + (item.deal.discountedPrice * item.quantity),
    );
    final double finalTotal = (subtotal - _discountAmount).clamp(0.0, 999999.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF22C55E)),
                  SizedBox(height: 16),
                  Text('Confirming rescue order with kitchen...'),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ResponsiveCenter(
                maxWidth: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── ITEMS LIST (Mockup 1 Left) ─────────────────────────
                    if (displayItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text('Your cart is empty. Add deals to checkout!'),
                        ),
                      )
                    else
                      ...displayItems.map((item) {
                        final itemSubtotal = item.deal.discountedPrice * item.quantity;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Food Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 68,
                                  height: 68,
                                  child: item.deal.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.deal.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                                          errorWidget: (context, url, error) => _buildFallbackThumbnail(),
                                        )
                                      : _buildFallbackThumbnail(),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item Title & Price Equation ($10.00 x 2)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.deal.title,
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
                                      'GHS ${item.deal.discountedPrice.toStringAsFixed(2)} × ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.mutedGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Stepper [-] qty [+] with Red Trash Icon at qty == 1
                                    Row(
                                      children: [
                                        _buildStepperButton(
                                          isTrash: item.quantity <= 1,
                                          icon: item.quantity <= 1
                                              ? Icons.delete_outline_rounded
                                              : Icons.remove_rounded,
                                          color: item.quantity <= 1
                                              ? const Color(0xFFEF4444)
                                              : AppTheme.charcoal,
                                          onTap: () {
                                            if (item.quantity > 1) {
                                              notifier.updateBasketQuantity(item.deal.id, item.quantity - 1);
                                            } else {
                                              notifier.removeFromBasket(item.deal.id);
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.charcoal,
                                            ),
                                          ),
                                        ),
                                        _buildStepperButton(
                                          isTrash: false,
                                          icon: Icons.add_rounded,
                                          color: AppTheme.charcoal,
                                          onTap: () {
                                            notifier.updateBasketQuantity(item.deal.id, item.quantity + 1);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Total Price for this item
                              Text(
                                'GHS ${itemSubtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // ── PROMO CODE SECTION (Mockup 1 Left) ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Enter Promo Code',
                                hintStyle: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => _applyPromo(_promoController.text),
                            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Suggested Voucher Chips
                    Wrap(
                      spacing: 8,
                      children: _suggestedVouchers.map((v) {
                        return ActionChip(
                          avatar: const Icon(Icons.local_offer_rounded, size: 12, color: Color(0xFF16A34A)),
                          label: Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFDCFCE7),
                          onPressed: () {
                            _promoController.text = v;
                            _applyPromo(v);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── FINANCIAL BREAKDOWN (Mockup 1 Left) ─────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildCostRow('Subtotal for Products', 'GHS ${subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 10),
                          _buildCostRow('Delivery fee', 'Free', isFree: true),
                          if (_discountAmount > 0) ...[
                            const SizedBox(height: 10),
                            _buildCostRow(
                              'Discount Vouchers ($_appliedPromoCode)',
                              '-GHS ${_discountAmount.toStringAsFixed(2)}',
                              isDiscount: true,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              Text(
                                'GHS ${finalTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── BIG GREEN CHECKOUT BUTTON (Mockup 1 Left) ───────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () => _onCheckoutPressed(finalTotal, displayItems),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepperButton({
    required bool isTrash,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isTrash ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.mutedGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isFree
                ? const Color(0xFF16A34A)
                : isDiscount
                    ? const Color(0xFFEF4444)
                    : AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      color: const Color(0xFFDCFCE7),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Color(0xFF16A34A), size: 28),
      ),
    );
  }
}
