import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../core/ds_kit.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import 'order_track_screen.dart';

enum _OrderFilter { all, active, past }

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  _OrderFilter _filter = _OrderFilter.all;

  static bool _isActive(Order o) => o.status != 'collected' && o.status != 'cancelled';

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(appStateProvider.select((s) => s.currentUser?.id ?? ''));
    final allMyOrders = ref.watch(appStateProvider.select((s) =>
      s.orders.where((o) => o.customerId == currentUserId).toList()
    ));

    final activeCount = allMyOrders.where(_isActive).length;
    final rescued = allMyOrders.where((o) => o.status == 'collected').toList();
    final saved = rescued.fold<double>(0, (s, o) => s + (o.originalPrice - o.price).clamp(0, double.infinity));

    final filtered = allMyOrders.where((o) {
      switch (_filter) {
        case _OrderFilter.active:
          return _isActive(o);
        case _OrderFilter.past:
          return !_isActive(o);
        case _OrderFilter.all:
          return true;
      }
    }).toList();

    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final paginatedOrders = filtered.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: buildCustomerAppBar(
        context: context,
        ref: ref,
        title: const Text(
          'Order History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ResponsiveCenter(
        maxWidth: 1080,
        child: allMyOrders.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, 0),
                    child: Row(
                      children: [
                        Expanded(child: DsStatTile(icon: Icons.receipt_long_rounded, value: '${allMyOrders.length}', label: 'Orders')),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(child: DsStatTile(icon: Icons.volunteer_activism_rounded, value: '${rescued.length}', label: 'Rescued')),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(child: DsStatTile(icon: Icons.savings_rounded, value: AppTheme.formatPrice(saved), label: 'GHS saved')),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.sm),
                      children: [
                        DsFilterChip(
                          label: 'All (${allMyOrders.length})',
                          selected: _filter == _OrderFilter.all,
                          onTap: () => setState(() { _filter = _OrderFilter.all; _currentPage = 0; }),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        DsFilterChip(
                          label: 'Active ($activeCount)',
                          selected: _filter == _OrderFilter.active,
                          onTap: () => setState(() { _filter = _OrderFilter.active; _currentPage = 0; }),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        DsFilterChip(
                          label: 'Past (${allMyOrders.length - activeCount})',
                          selected: _filter == _OrderFilter.past,
                          onTap: () => setState(() { _filter = _OrderFilter.past; _currentPage = 0; }),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _filter == _OrderFilter.active ? 'No active orders right now.' : 'No past orders yet.',
                              style: const TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 720;
                              if (isWide) {
                                const gap = 16.0;
                                final cardWidth = (constraints.maxWidth - 40 - gap) / 2;
                                return ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                                  children: [
                                    Wrap(
                                      spacing: gap,
                                      runSpacing: gap,
                                      children: paginatedOrders.map((order) {
                                        return SizedBox(
                                          width: cardWidth,
                                          child: _HoverLift(
                                            child: _buildOrderCard(context, ref, order, isWide: true),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                );
                              }
                              return ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                                itemCount: paginatedOrders.length,
                                itemBuilder: (context, index) => _HoverLift(
                                  child: _buildOrderCard(context, ref, paginatedOrders[index]),
                                ),
                              );
                            },
                          ),
                  ),
                  if (totalPages > 1) _buildPagination(totalPages),
                ],
              ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 16),
          Text(
            "Page ${_currentPage + 1} of $totalPages",
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Order order, {bool isWide = false}) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(order.timestamp);

    final DsTone tone;
    final String statusText;
    final IconData statusIcon;
    switch (order.status) {
      case 'preparing':
        tone = DsTone.warn;
        statusText = 'Preparing';
        statusIcon = Icons.soup_kitchen_rounded;
        break;
      case 'ready':
      case 'reserved':
        tone = DsTone.brand;
        statusText = 'Ready for pickup';
        statusIcon = Icons.stars_rounded;
        break;
      case 'out_for_delivery':
        tone = DsTone.info;
        statusText = 'Out for delivery';
        statusIcon = Icons.two_wheeler_rounded;
        break;
      case 'collected':
        tone = DsTone.neutral;
        statusText = 'Rescued';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
      default:
        tone = DsTone.danger;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel_rounded;
        break;
    }

    final isActive = _isActive(order);
    final canRate = order.status == 'collected' && !order.isRated;
    final saving = order.originalPrice - order.price;

    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 0 : AppSpace.sm),
      child: DsCard(
        padding: const EdgeInsets.all(AppSpace.md),
        onTap: () => isActive
            ? Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackScreen(order: order)))
            : _showPickupCodeSheet(context, order),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.w700),
                  ),
                ),
                DsPill(label: statusText, icon: statusIcon, tone: tone, compact: true),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.dealTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal, height: 1.25),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dsPrice(order.price),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen),
                    ),
                    if (saving > 0)
                      Text(
                        'Saved ${dsPrice(saving)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.mutedGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isActive)
                  Text(
                    '#${order.collectionCode}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: 0.8),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                if (isActive) ...[
                  Expanded(
                    child: DsButton(
                      label: 'View code',
                      icon: Icons.qr_code_rounded,
                      variant: DsButtonVariant.secondary,
                      onPressed: () => _showPickupCodeSheet(context, order),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: DsButton(
                      label: 'Track',
                      icon: Icons.navigation_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackScreen(order: order)),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: DsButton(
                      label: 'Receipt',
                      icon: Icons.receipt_long_rounded,
                      variant: DsButtonVariant.secondary,
                      onPressed: () => _showPickupCodeSheet(context, order),
                    ),
                  ),
                  if (canRate) ...[
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: DsButton(
                        label: 'Rate',
                        icon: Icons.star_rounded,
                        onPressed: () => _showRatingDialog(context, ref, order),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpace.xs),
                  IconButton(
                    onPressed: () => _showDisputeDialog(context, ref, order),
                    icon: const Icon(Icons.help_outline_rounded, size: 20, color: AppTheme.mutedGrey),
                    tooltip: 'Report an issue',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPickupCodeSheet(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                order.dealTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 4),
              Text(
                'at ${order.businessName}',
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.hairline),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: order.collectionCode,
                  version: QrVersions.auto,
                  size: 140.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.charcoal),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.charcoal),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'COLLECTION CODE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              SelectableText(
                '#${order.collectionCode}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show this code or QR at the store counter upon arrival.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, WidgetRef ref, Order order) {
    final issueController = TextEditingController();
    final List<String> commonIssues = [
      "Merchant was closed",
      "Food not as described",
      "Wrong quantity",
      "Quality concerns",
      "Other"
    ];
    String selectedIssue = commonIssues[0];
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2), // Soft Red Bg
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: AppTheme.errorRed,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Report an Issue",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "We're sorry something went wrong. Select a category below and provide details to help our team resolve it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    "WHAT HAPPENED?",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.mutedGrey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  
                  // Wrap with clean visual selection chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonIssues.map((issue) {
                      final isSelected = selectedIssue == issue;
                      return GestureDetector(
                        onTap: isSaving ? null : () => setDialogState(() => selectedIssue = issue),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.cream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.errorRed : AppTheme.hairline,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            issue,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected ? AppTheme.errorRed : AppTheme.charcoal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    "ADDITIONAL DETAILS",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.mutedGrey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: issueController,
                    enabled: !isSaving,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Tell us more (e.g. order details, response)...",
                      hintStyle: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12),
                      filled: true,
                      fillColor: AppTheme.cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.hairline)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.hairline)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.charcoal, width: 1.5)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text("Go Back", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isSaving ? null : () async {
                            final detail = issueController.text.trim();
                            if (detail.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please provide some details!"), backgroundColor: AppTheme.errorRed),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final fullDescription = "[$selectedIssue] $detail";

                            try {
                              String merchantProfileId = order.businessId;
                              final businesses = ref.read(appStateProvider).businesses;
                              final match = businesses.where((b) => b.id == order.businessId || b.name == order.businessName).toList();
                              if (match.isNotEmpty) {
                                merchantProfileId = match.first.ownerId;
                              }

                              await ref.read(appStateProvider.notifier).createDispute(
                                orderId: order.id,
                                merchantId: merchantProfileId,
                                issueDescription: fullDescription,
                              );
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Issue reported. Our support team will review it shortly."),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text("Failed to report issue: $e"), backgroundColor: AppTheme.errorRed),
                              );
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Submit Report", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, Order order) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Visual Header Emoji/Shield
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sentiment_very_satisfied_rounded,
                        size: 36,
                        color: AppTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Rate ${order.businessName}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.charcoal, letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "How was the rescue quality? Your feedback helps prevent food waste and guides the community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    
                    // Golden Stars Selection Block
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final ratingValue = index + 1;
                        final isSelected = ratingValue <= selectedRating;
                        return IconButton(
                          icon: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
                            size: 40,
                          ),
                          onPressed: () => setDialogState(() => selectedRating = ratingValue),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedRating == 5
                          ? "EXCELLENT RESCUE!"
                          : selectedRating == 4
                              ? "Very Good"
                              : selectedRating == 3
                                  ? "Good / Fair"
                                  : selectedRating == 2
                                      ? "Disappointing"
                                      : "Poor Experience",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.mutedGrey, letterSpacing: 1),
                    ),
                    const SizedBox(height: 24),
                    
                    // Comment input
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "Add specific comments (freshness, service)...",
                        hintStyle: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.hairline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.hairline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.charcoal, width: 1.5)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Maybe Later", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              try {
                                await ref.read(appStateProvider.notifier).submitReview(
                                  orderId: order.id,
                                  businessId: order.businessId,
                                  rating: selectedRating,
                                  comment: commentController.text.trim(),
                                );
                                navigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text("Thank you for rating your rescue meal!"),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to submit rating: $e"),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            },
                            child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildEmptyState() {
    return const BrandedEmptyState(
      title: "No reservations yet",
      description: "Your surplus meal claims and active rescue codes will appear here once you've made your first rescue.",
      icon: Icons.receipt_long_rounded,
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
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
