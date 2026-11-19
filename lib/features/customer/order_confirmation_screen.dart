import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import 'order_track_screen.dart';

/// Shown right after a successful checkout: a green hero with the pickup
/// code on a "ticket", then the receipt and the next steps.
class OrderConfirmationScreen extends StatefulWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "reduce motion": show the finished state straight away.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatPaymentMethod(String raw) {
    switch (raw.toLowerCase()) {
      case 'momo':
        return 'MTN Mobile Money';
      case 'cash':
        return 'Cash on Pickup';
      case 'card':
        return 'Card Payment';
      case 'dream_points':
        return 'DreamPoints';
      default:
        return raw
            .split('_')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDelivery = order.fulfillmentType == 'delivery';
    final saved = (order.originalPrice - order.price).clamp(0, double.infinity);
    final code = isDelivery && order.deliveryPin.isNotEmpty ? order.deliveryPin : order.collectionCode;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          // Green hero behind the ticket.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.heroGradient),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xxl),
              child: ResponsiveCenter(
                maxWidth: 560,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpace.md),
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.limeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppTheme.deepGreen, size: 36),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    FadeTransition(
                      opacity: _reveal,
                      child: Column(
                        children: [
                          const Text(
                            'Order Placed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            isDelivery
                                ? 'A rider will bring your rescue pack to you.'
                                : 'Your rescue pack is reserved and waiting.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    FadeTransition(
                      opacity: _reveal,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_reveal),
                        child: Column(
                          children: [
                            _CodeTicket(
                              label: isDelivery && order.deliveryPin.isNotEmpty ? 'Delivery PIN' : 'Pickup Code',
                              code: code,
                              hint: isDelivery
                                  ? 'Give this PIN to your rider when they arrive.'
                                  : 'Show this code at the counter to collect your food.',
                            ),
                            const SizedBox(height: AppSpace.lg),
                            DsCard(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      color: AppTheme.charcoal,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  _row('Business', order.businessName),
                                  _row('Item', order.dealTitle),
                                  _row('Payment', _formatPaymentMethod(order.paymentMethod)),
                                  _row('Order ID', order.id.shortId(12).toUpperCase(), mono: true),
                                  const Divider(height: AppSpace.xl, color: AppTheme.hairline),
                                  Row(
                                    children: [
                                      const Text(
                                        'Amount Paid',
                                        style: TextStyle(
                                          color: AppTheme.charcoal,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dsPrice(order.price),
                                        style: const TextStyle(
                                          color: AppTheme.deepGreen,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (saved > 0) ...[
                                    const SizedBox(height: AppSpace.sm),
                                    DsPill(
                                      label: 'You saved ${dsPrice(saved.toDouble())}',
                                      icon: Icons.savings_rounded,
                                      tone: DsTone.deal,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreenBg,
                                borderRadius: AppRadius.rMd,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.eco_rounded, size: 22, color: AppTheme.primaryGreen),
                                  SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Text(
                                      'You rescued a meal. Every rescue helps cut food waste in Ghana.',
                                      style: TextStyle(
                                        color: AppTheme.deepGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            DsButton(
                              label: isDelivery ? 'Track Delivery' : 'Track Order Status',
                              icon: Icons.navigation_rounded,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => OrderTrackScreen(order: order)),
                              ),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: DsButton(
                                    label: 'My Orders',
                                    icon: Icons.receipt_long_rounded,
                                    variant: DsButtonVariant.secondary,
                                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: DsButton(
                                    label: 'Keep Browsing',
                                    icon: Icons.explore_rounded,
                                    variant: DsButtonVariant.ghost,
                                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.charcoal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The big pickup code, on a card with ticket notches, tap to copy.
class _CodeTicket extends StatelessWidget {
  final String label;
  final String code;
  final String hint;

  const _CodeTicket({required this.label, required this.code, required this.hint});

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  label: '$label $code',
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: AppTheme.deepGreen,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _notch(left: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      (c.maxWidth / 10).floor(),
                      (_) => const SizedBox(
                        width: 5,
                        height: 1.5,
                        child: DecoratedBox(decoration: BoxDecoration(color: AppTheme.hairline)),
                      ),
                    ),
                  ),
                ),
              ),
              _notch(left: false),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.md),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 22, color: AppTheme.charcoal),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5, height: 1.4),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryGreen),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notch({required bool left}) => SizedBox(
        width: 10,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.horizontal(
              left: left ? Radius.zero : const Radius.circular(10),
              right: left ? const Radius.circular(10) : Radius.zero,
            ),
          ),
        ),
      );
}
