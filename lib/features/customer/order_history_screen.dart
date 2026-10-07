import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../core/branded_empty_state.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(appStateProvider.select((s) => s.currentUser?.id ?? ''));
    final allMyOrders = ref.watch(appStateProvider.select((s) =>
      s.orders.where((o) => o.customerId == currentUserId).toList()
    ));

    // Pagination
    final totalPages = (allMyOrders.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    
    final paginatedOrders = allMyOrders.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
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
        maxWidth: 850,
        child: allMyOrders.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: paginatedOrders.length,
                      itemBuilder: (context, index) {
                        final order = paginatedOrders[index];
                        return _HoverLift(
                          child: _buildOrderCard(context, ref, order),
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

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Order order) {
    final dateStr = DateFormat('EEE, MMM dd, yyyy • hh:mm a').format(order.timestamp);
    
    Color statusColor;
    String statusText;
    Color statusBg;
    IconData statusIcon;
    
    switch (order.status) {
      case 'reserved':
        statusColor = const Color(0xFF16A34A); // Premium Green
        statusText = 'Ready for Pickup';
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.stars_rounded;
        break;
      case 'collected':
        statusColor = const Color(0xFF475569); // Slate Grey
        statusText = 'Rescued';
        statusBg = const Color(0xFFF1F5F9);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
      default:
        statusColor = const Color(0xFFEF4444); // Premium Red
        statusText = 'Cancelled';
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel_rounded;
        break;
    }

    final isReserved = order.status == 'reserved';
    final isCollected = order.status == 'collected';
    final canRate = isCollected && !order.isRated;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Premium Header)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                statusText.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Business name
                        Text(
                          order.businessName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedGrey,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Deal Title
                        Text(
                          order.dealTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.charcoal,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // App Brand Logo Asset
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time & Pricing Info Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.mutedGrey),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "GHS ${order.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (order.originalPrice > order.price)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Saved ${(100 - (order.price / order.originalPrice * 100)).round()}%",
                            style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildTicketSeparator(),

            // Ticket Bottom Info Block
            if (isReserved) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      // QR Code area
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: order.collectionCode,
                          version: QrVersions.auto,
                          size: 72.0,
                          gapless: false,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.charcoal),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.charcoal),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RESCUE CODE",
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.mutedGrey,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              order.collectionCode,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGreen,
                                letterSpacing: 3.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Present this code at store to collect",
                              style: TextStyle(fontSize: 10, color: AppTheme.mutedGrey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "No Cancellation Policy: Claims on surplus meals are final.",
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Completed / Cancelled Actions block
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ORDER ID",
                          style: TextStyle(fontSize: 9, color: AppTheme.mutedGrey.withValues(alpha: 0.6), fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        Text(
                          "#${order.id.substring(0, 8).toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedGrey,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (canRate)
                          ElevatedButton.icon(
                            onPressed: () => _showRatingDialog(context, ref, order),
                            icon: const Icon(Icons.star_rounded, size: 14),
                            label: const Text("Rate Meal", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        if (isCollected || order.status == 'cancelled') ...[
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => _showDisputeDialog(context, ref, order),
                            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.mutedGrey, size: 22),
                            tooltip: "Help / Report Issue",
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                        color: Color(0xFFEF4444),
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
                            color: isSelected ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            issue,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected ? const Color(0xFFEF4444) : AppTheme.charcoal,
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
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.charcoal, width: 1.5)),
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
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isSaving ? null : () async {
                            final detail = issueController.text.trim();
                            if (detail.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("⚠️ Please provide some details!"), backgroundColor: AppTheme.errorRed),
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
                                  content: Text("✅ Issue reported. Our support team will review it shortly."),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text("❌ Failed to report issue: $e"), backgroundColor: AppTheme.errorRed),
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
                      child: const Text(
                        "😋",
                        style: TextStyle(fontSize: 32),
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
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.charcoal, width: 1.5)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                    content: Text("✅ Thank you for rating your rescue meal!"),
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

  Widget _buildTicketSeparator() {
    return Row(
      children: [
        const SizedBox(
          width: 8,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
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
                  (index) => const SizedBox(
                    width: 5,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x1A000000),
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
              color: AppTheme.lightGrey,
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
