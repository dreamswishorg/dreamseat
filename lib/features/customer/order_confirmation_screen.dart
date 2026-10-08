import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import 'order_track_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTicketSeparator() {
    return Row(
      children: [
        const SizedBox(
          width: 8,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.pureWhite, // matches the page background color
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => SizedBox(
                    width: 5,
                    height: 1.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(
          width: 8,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.pureWhite, // matches the page background color
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
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
    final shortId = order.id.length > 12 ? order.id.substring(0, 12) : order.id;

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ResponsiveCenter(
            maxWidth: 680,
            child: Column(
              children: [
              const SizedBox(height: 12),

              // ── Animated Success Circle (Compact) ─────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.16),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Title ────────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value * 0.5),
                    child: child,
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Order Placed!',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your rescue pack is reserved and confirmed!',
                        style: TextStyle(
                          color: AppTheme.mutedGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Pickup Code Box (Logo in Corner) ──────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value * 0.7),
                    child: child,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Logo in the top-right corner
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.eco_rounded,
                                  color: AppTheme.primaryGreen,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                              child: Column(
                                children: [
                                  const Text(
                                    'YOUR PICKUP CODE',
                                    style: TextStyle(
                                      color: AppTheme.mutedGrey,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.collectionCode,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildTicketSeparator(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.charcoal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Present this code at the counter to collect your food.',
                                      style: TextStyle(
                                        color: AppTheme.charcoal.withValues(alpha: 0.75),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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

              const SizedBox(height: 24),

              // ── Details Card ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _slideAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value * 1.6),
                    child: child,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.charcoal.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.charcoal.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            color: AppTheme.charcoal,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          icon: Icons.storefront_rounded,
                          label: 'Business',
                          value: order.businessName,
                        ),
                        _detailRow(
                          icon: Icons.local_dining_rounded,
                          label: 'Item',
                          value: order.dealTitle,
                        ),
                        _detailRow(
                          icon: Icons.payment_rounded,
                          label: 'Payment',
                          value: _formatPaymentMethod(order.paymentMethod),
                        ),
                        _detailRow(
                          icon: Icons.attach_money_rounded,
                          label: 'Amount Paid',
                          value: 'GHS ${order.price.toStringAsFixed(2)}',
                          valueStyle: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _detailRow(
                          icon: Icons.tag_rounded,
                          label: 'Order ID',
                          value: shortId.toUpperCase(),
                          isLast: true,
                          valueStyle: const TextStyle(
                            color: AppTheme.mutedGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Eco Impact Note ──────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You just rescued a meal! Every rescue helps reduce Ghana\'s food waste.',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Action Buttons (Squeezed to prevent scrolling) ────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: Text(
                        order.fulfillmentType == 'delivery'
                            ? 'Track Delivery'
                            : 'Track Order Status',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                            label: const Text('Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                              foregroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            icon: const Icon(Icons.explore_rounded, size: 16),
                            label: const Text('Continue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              backgroundColor: AppTheme.lightGrey,
                              foregroundColor: AppTheme.charcoal,
                              elevation: 0,
                              side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 13,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: valueStyle ??
                      const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: AppTheme.charcoal.withValues(alpha: 0.06),
            thickness: 1,
            height: 1,
          ),
      ],
    );
  }
}
