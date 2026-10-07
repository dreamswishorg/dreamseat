import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../core/config.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final FoodDeal deal;
  const CheckoutScreen({super.key, required this.deal});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedProvider = 'MTN MoMo';
  bool _isProcessing = false;
  String _statusMessage = '';

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'MTN MoMo',
      'subtitle': 'Instant USSD Prompt',
      'color': const Color(0xFFFFCC00),
      'icon': Icons.phone_android_rounded,
      'logo_asset': 'assets/icons/mtn_momo.png',
      'bg_tint': const Color(0xFFFFFBEB),
      'border_color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Telecel Cash',
      'subtitle': 'Vodafone Cash Prompt',
      'color': const Color(0xFFDC2626),
      'icon': Icons.phone_iphone_rounded,
      'logo_asset': 'assets/icons/telecel_cash.png',
      'bg_tint': const Color(0xFFFEF2F2),
      'border_color': const Color(0xFFEF4444),
    },
    {
      'name': 'AirtelTigo Money',
      'subtitle': 'AT Money Prompt',
      'color': const Color(0xFF1D4ED8),
      'icon': Icons.smartphone_rounded,
      'logo_asset': 'assets/icons/airteltigo_money.png',
      'bg_tint': const Color(0xFFEFF6FF),
      'border_color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Visa / Mastercard',
      'subtitle': 'Secured Card Gateway',
      'color': const Color(0xFF0F172A),
      'icon': Icons.credit_card_rounded,
      'logo_asset': 'assets/icons/visa_mastercard.jpg',
      'bg_tint': const Color(0xFFF8FAFC),
      'border_color': const Color(0xFF334155),
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser;
    if (user != null && user.phone != null) {
      _phoneController.text = user.phone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final isCard = _selectedProvider == 'Visa / Mastercard';

    // For production "embedded" feel, we handle MoMo directly.
    // Cards still require a secure redirect for PCI compliance.
    if (isCard) {
      _processCardPayment();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initiating transaction...';
    });

    final stateVal = ref.read(appStateProvider);
    final user = stateVal.currentUser;
    final email = user?.email ?? 'customer@dreameats.com.gh';
    final double amount = widget.deal.discountedPrice;
    final String reference = 'DE-${DateTime.now().millisecondsSinceEpoch}';

    // Map display names to Paystack provider codes
    String providerCode = 'mtn';
    if (_selectedProvider == 'Telecel Cash') providerCode = 'vod';
    if (_selectedProvider == 'AirtelTigo Money') providerCode = 'tgo';

    final Map<String, dynamic> metadata = {
      "deal_id": widget.deal.id,
      "deal_title": widget.deal.title,
      "business_id": widget.deal.businessId,
      "business_name": widget.deal.businessName,
      "customer_id": user?.id,
      "customer_name": user?.name,
    };

    try {
      final response = await SupabaseService().initiatePaystackCharge(
        email: email,
        amount: amount,
        phone: _phoneController.text.trim(),
        provider: providerCode,
        metadata: metadata,
        reference: reference,
      );

      if (response['status'] == false) {
        throw Exception(response['message'] ?? 'Failed to initiate charge');
      }

      final status = response['data']?['status'];

      if (status == 'send_otp') {
        _handleOtpRequirement(reference, response['data']?['display_text'] ?? 'Enter OTP');
        return;
      }

      // ── Wait for Webhook ───────────────────────────────────────────────
      setState(() => _statusMessage = 'Waiting for authorization on your phone...');

      Order? order;
      // MoMo can take a while for the user to type PIN.
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 2));
        order = await _findOrder(reference);
        if (order != null) break;
      }

      if (order == null) {
        final verified = await SupabaseService().verifyPaystackPayment(reference);
        if (verified) {
          order = await ref.read(appStateProvider.notifier).purchase(
                widget.deal,
                _selectedProvider,
                reference,
              );
        } else {
          try {
            order = await ref.read(appStateProvider.notifier).purchase(
                  widget.deal,
                  _selectedProvider,
                  reference,
                );
          } catch (_) {}
        }
      }

      if (order != null) {
        setState(() => _isProcessing = false);
        _onSuccess(order);
      } else {
        throw Exception('Payment timeout. Please check your phone for the MoMo prompt or your transaction history.');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _processCardPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening secure card payment...';
    });

    final stateVal = ref.read(appStateProvider);
    final user = stateVal.currentUser;
    final email = user?.email ?? 'customer@dreameats.com.gh';
    final double amount = widget.deal.discountedPrice;
    final int amountInPesewas = (amount * 100).toInt();
    final String reference = 'DE-${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> metadata = {
      "deal_id": widget.deal.id,
      "deal_title": widget.deal.title,
      "business_id": widget.deal.businessId,
      "business_name": widget.deal.businessName,
      "customer_id": user?.id ?? 'anonymous',
      "customer_name": user?.name ?? 'Guest Customer',
      "channels": ["card"],
    };

    try {
      bool paystackSuccess = false;

      await FlutterPaystackPlus.openPaystackPopup(
        context: context,
        publicKey: AppConfig.paystackPublicKey,
        secretKey: AppConfig.paystackSecretKey,
        customerEmail: email,
        amount: amountInPesewas.toString(),
        reference: reference,
        currency: 'GHS',
        metadata: metadata,
        onClosed: () {
          if (mounted) setState(() => _isProcessing = false);
        },
        onSuccess: () {
          paystackSuccess = true;
        },
      );


      if (!paystackSuccess) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      setState(() => _statusMessage = 'Confirming reservation...');

      Order? order;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(seconds: 1));
        order = await _findOrder(reference);
        if (order != null) break;
      }

      order ??= await ref.read(appStateProvider.notifier).purchase(
            widget.deal,
            'Card',
            reference,
          );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (order != null) _onSuccess(order);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  void _handleOtpRequirement(String reference, String message) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('OTP Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter OTP'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              Navigator.pop(context);
              if (otp.isNotEmpty) {
                setState(() => _statusMessage = 'Submitting authorization code...');
                await SupabaseService().submitPaystackOtp(reference: reference, otp: otp);
              }
              _waitForOrder(reference);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _waitForOrder(String reference) async {
    setState(() => _statusMessage = 'Finalizing reservation...');
    Order? order;
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(seconds: 2));
      order = await _findOrder(reference);
      if (order != null) break;
    }

    if (order == null) {
      final verified = await SupabaseService().verifyPaystackPayment(reference);
      if (verified) {
        order = await ref.read(appStateProvider.notifier).purchase(
              widget.deal,
              _selectedProvider.isNotEmpty ? _selectedProvider : 'MoMo / Card',
              reference,
            );
      } else {
        try {
          order = await ref.read(appStateProvider.notifier).purchase(
                widget.deal,
                _selectedProvider.isNotEmpty ? _selectedProvider : 'MoMo / Card',
                reference,
              );
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      if (order != null) {
        _onSuccess(order);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processing. Your reservation will appear in My Orders shortly.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }

  Future<Order?> _findOrder(String reference) async {
    try {
      final orders = ref.read(appStateProvider).orders;
      return orders.firstWhere((o) => o.paymentReference == reference);
    } catch (_) {
      // Re-hydrate state to check server
      await ref.read(appStateProvider.notifier).refreshOrders();
      final orders = ref.read(appStateProvider).orders;
      try {
        return orders.firstWhere((o) => o.paymentReference == reference);
      } catch (_) {
        return null;
      }
    }
  }

  void _onSuccess(Order order) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Sleek slate light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Secure Checkout',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.charcoal.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Bottom padding for sticky bar
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Order Card ──────────────────────────────────────
                  _buildHeroSummaryCard(),
                  const SizedBox(height: 28),

                  // ── Payment Method Header ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.charcoal,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose your preferred instant payment gateway',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: AppTheme.primaryGreen),
                            SizedBox(width: 4),
                            Text(
                              'PCI DSS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Interactive Payment Grid ─────────────────────────────
                  _buildPaymentGrid(),
                  const SizedBox(height: 28),

                  // ── Mobile Money / Card Details Section ──────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedProvider == 'Visa / Mastercard'
                        ? _buildCardInfoBanner()
                        : _buildMoMoInputSection(),
                  ),
                  const SizedBox(height: 24),

                  // ── Cancellation Policy Alert ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.errorRed, size: 18),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No Cancellation Policy: Once confirmed, surplus food reservations cannot be cancelled or refunded.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.bold,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Security & Trust Badges ──────────────────────────────
                  _buildTrustBadges(),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Pay Bar ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard() {
    final savings = widget.deal.originalPrice - widget.deal.discountedPrice;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background glow
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Restaurant Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.deal.businessName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.deal.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Celebration Savings Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You save GHS ${savings.toStringAsFixed(2)} & rescue fresh surplus food!',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  DashedDivider(
                    color: Colors.white.withValues(alpha: 0.15),
                    height: 1,
                    dashWidth: 6,
                    dashSpace: 4,
                  ),
                  const SizedBox(height: 18),

                  // Price Breakdown
                  _receiptRow('Original Price', 'GHS ${widget.deal.originalPrice.toStringAsFixed(2)}', isLineThrough: true, labelColor: Colors.white70, valueColor: Colors.white54),
                  const SizedBox(height: 8),
                  _receiptRow('Surplus Discount', '- GHS ${savings.toStringAsFixed(2)}', labelColor: Colors.white70, valueColor: AppTheme.primaryGreen),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'GHS ${widget.deal.discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGreen,
                          letterSpacing: -0.5,
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
    );
  }

  Widget _buildPaymentGrid() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _providers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _providers[index];
        final isSelected = _selectedProvider == p['name'];
        final color = p['color'] as Color;
        final bgTint = p['bg_tint'] as Color;
        final borderColor = p['border_color'] as Color;

        return _HoverLift(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedProvider = p['name'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? bgTint : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? borderColor : AppTheme.charcoal.withValues(alpha: 0.1),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  if (p.containsKey('logo_asset'))
                    Container(
                      width: 64,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.08)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          p['logo_asset'] as String,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              Icon(p['icon'] as IconData, color: color, size: 22),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p['icon'] as IconData, color: color, size: 22),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? AppTheme.charcoal.withValues(alpha: 0.7) : AppTheme.mutedGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? borderColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? borderColor : AppTheme.charcoal.withValues(alpha: 0.25),
                        width: isSelected ? 0 : 1.8,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoMoInputSection() {
    return Column(
      key: const ValueKey('momo_input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.phone_android_rounded, size: 18, color: AppTheme.charcoal),
            const SizedBox(width: 8),
            const Text(
              'Mobile Money Phone Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            Text(
              _selectedProvider,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal, letterSpacing: 1),
          decoration: InputDecoration(
            hintText: '024 123 4567',
            hintStyle: TextStyle(color: AppTheme.mutedGrey.withValues(alpha: 0.5), fontWeight: FontWeight.normal, letterSpacing: 0),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                border: Border(right: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08))),
              ),
              child: const Text(
                '+233 🇬🇭',
                style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().length < 9) {
              return 'Please enter a valid 10-digit Ghanaian phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5), // Soft emerald tint
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Instant USSD payment prompt will appear on your phone. Simply enter your MoMo PIN to complete reservation.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardInfoBanner() {
    return Container(
      key: const ValueKey('card_info'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '256-Bit SSL Secured Card Gateway',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                SizedBox(height: 4),
                Text(
                  'You will be securely redirected to Paystack to enter your Visa or Mastercard details. No card data touches our servers.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 6),
        const Text(
          '100% Encrypted & Secured by Paystack Ghana',
          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.05)),
        ),
      ),
      child: SafeArea(
        child: _isProcessing
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'GHS ${widget.deal.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.charcoal,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Confirm & Pay',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isLineThrough = false, Color? labelColor, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: labelColor ?? AppTheme.mutedGrey, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? AppTheme.charcoal,
            fontWeight: FontWeight.w800,
            decoration: isLineThrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
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

