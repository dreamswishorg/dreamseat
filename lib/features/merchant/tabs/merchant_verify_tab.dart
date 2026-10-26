import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';
import '../theme/merchant_theme.dart';

class MerchantVerifyTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final bool autoOpen;

  const MerchantVerifyTab({super.key, required this.business, this.autoOpen = false});

  @override
  ConsumerState<MerchantVerifyTab> createState() => _MerchantVerifyTabState();
}

class _MerchantVerifyTabState extends ConsumerState<MerchantVerifyTab> {
  final _code = TextEditingController();
  final _queueSearch = TextEditingController();
  bool _checking = false;
  String? _error;
  Order? _selectedOrder;
  int _mobileTab = 0; // 0: Verify Console, 1: Waiting Queue

  @override
  void dispose() {
    _code.dispose();
    _queueSearch.dispose();
    super.dispose();
  }

  void _tap(String v) {
    if (_code.text.length >= 8) return;
    HapticFeedback.lightImpact();
    setState(() {
      _code.text += v;
      _error = null;
      _matchOrder(_code.text);
    });
  }

  void _backspace() {
    if (_code.text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _code.text = _code.text.substring(0, _code.text.length - 1);
      _error = null;
      _matchOrder(_code.text);
    });
  }

  void _clearCode() {
    setState(() {
      _code.clear();
      _selectedOrder = null;
      _error = null;
    });
  }

  void _selectFromQueue(Order order) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOrder = order;
      _code.text = order.collectionCode.toUpperCase();
      _error = null;
      _mobileTab = 0; // Switch to verify console on mobile
    });
  }

  void _matchOrder(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      _selectedOrder = null;
      return;
    }
    final orders = ref.read(appStateProvider).orders;
    _selectedOrder = _find(orders, code);
  }

  Order? _find(List<Order> orders, String code) {
    for (final o in orders) {
      if (o.businessId == widget.business.id &&
          (o.collectionCode.toUpperCase() == code ||
              o.id.toUpperCase().endsWith(code) ||
              o.id.toUpperCase() == code)) {
        return o;
      }
    }
    return null;
  }

  Future<void> _verify([String? overrideCode]) async {
    final code = (overrideCode ?? _code.text).trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter customer pickup code or select an order.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final notifier = ref.read(appStateProvider.notifier);
      var state = ref.read(appStateProvider);
      Order? found = _find(state.orders, code);

      if (found == null) {
        await notifier.refreshOrders();
        state = ref.read(appStateProvider);
        found = _find(state.orders, code);
      }

      if (found == null) {
        setState(() => _error = 'No order found with code “$code” at ${widget.business.name}.');
        return;
      }
      final order = found;

      if (order.status == 'collected') {
        if (!mounted) return;
        await showMResult(
          context,
          title: 'Already Handed Over',
          message:
              'Order for ${order.customerName} was already collected ${MK.ago(order.timestamp)}. Duplicate pickups are prevented.',
          ok: false,
          actionLabel: 'Got it',
        );
        _clearCode();
        return;
      }

      if (order.status == 'cancelled' || order.status == 'expired') {
        setState(() => _error = 'This order is ${order.status} and cannot be handed over.');
        return;
      }

      // Authoritative backend confirmation
      await notifier.confirmCollection(order.id);
      _clearCode();

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await showMResult(
        context,
        title: 'Handover Verified! ✅',
        message: '“${order.dealTitle}” handed to ${order.customerName}. Payment settlement queued.',
        actionLabel: 'Next Customer',
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _scan() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Scan Customer QR', style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              onDetect: (capture) {
                final value = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                if (value != null && value.isNotEmpty) Navigator.pop(ctx, value);
              },
            ),
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: MerchantTheme.brandSoftGreen, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Align customer redemption QR inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _code.text = scanned.trim().toUpperCase();
        _error = null;
        _matchOrder(_code.text);
      });
      await _verify(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final allMerchantOrders = state.orders.where((o) => o.businessId == widget.business.id).toList();

    final now = DateTime.now();
    final verifiedToday = allMerchantOrders
        .where((o) => o.status == 'collected' && DateUtils.isSameDay(o.timestamp, now))
        .length;

    // Active queue: Orders ready or reserved/preparing for pickup
    final waitingQueue = allMerchantOrders
        .where((o) => o.status == 'ready' || o.status == 'reserved' || o.status == 'preparing')
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first for staff priority!

    final query = _queueSearch.text.trim().toLowerCase();
    final filteredQueue = waitingQueue.where((o) {
      if (query.isEmpty) return true;
      return o.customerName.toLowerCase().contains(query) ||
          o.dealTitle.toLowerCase().contains(query) ||
          o.collectionCode.toLowerCase().contains(query) ||
          o.id.toLowerCase().contains(query);
    }).toList();

    final isWide = useSideNav(context);

    return ResponsiveCenter(
      maxWidth: 1320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Executive Operational Strip ──
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 14, isWide ? 24 : 16, 12),
            child: _buildOperationalMetricsStrip(
              awaitingCount: waitingQueue.length,
              verifiedTodayCount: verifiedToday,
              readyCount: waitingQueue.where((o) => o.status == 'ready').length,
            ),
          ),

          // ── Mobile Sub-tabs (when on small screen) ──
          if (!isWide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: MK.lineSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mobileTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _mobileTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mobileTab == 0 ? MerchantTheme.cardElevation : null,
                          ),
                          child: const Center(
                            child: Text(
                              'Verify Console',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: MerchantTheme.textDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mobileTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _mobileTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mobileTab == 1 ? MerchantTheme.cardElevation : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Waiting Queue',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: MerchantTheme.textDark),
                                ),
                                if (waitingQueue.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: MerchantTheme.amberWarning,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${waitingQueue.length}',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Workspace Content: Side-by-Side (Desktop/Tablet) or Tabbed (Mobile) ──
          Expanded(
            child: isWide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Verification Console
                        Expanded(
                          flex: 11,
                          child: SingleChildScrollView(
                            child: _buildVerificationConsole(),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Column: Waiting for Handover Queue
                        Expanded(
                          flex: 10,
                          child: _buildWaitingQueueCard(filteredQueue, totalCount: waitingQueue.length),
                        ),
                      ],
                    ),
                  )
                : (_mobileTab == 0
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _buildVerificationConsole(),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _buildWaitingQueueCard(filteredQueue, totalCount: waitingQueue.length),
                      )),
          ),
        ],
      ),
    );
  }

  // ── Executive Operational Metrics Strip ──
  Widget _buildOperationalMetricsStrip({
    required int awaitingCount,
    required int verifiedTodayCount,
    required int readyCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final items = [
          _buildKpiCard(
            label: 'Awaiting Handover',
            value: '$awaitingCount',
            subtext: awaitingCount == 0 ? 'Queue clear' : 'Orders waiting collection',
            icon: Icons.timer_outlined,
            color: awaitingCount > 0 ? MerchantTheme.amberWarning : MerchantTheme.brandGreen,
          ),
          _buildKpiCard(
            label: 'Ready on Counter',
            value: '$readyCount',
            subtext: 'Packed & ready for pickup',
            icon: Icons.shopping_bag_outlined,
            color: MerchantTheme.skyInfo,
          ),
          _buildKpiCard(
            label: 'Verified Today',
            value: '$verifiedTodayCount',
            subtext: 'Completed redemptions',
            icon: Icons.check_circle_outline_rounded,
            color: MerchantTheme.brandGreen,
          ),
        ];

        if (isCompact) {
          return Column(
            children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: item)).toList(),
          );
        }

        return Row(
          children: items
              .map((item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: item,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MerchantTheme.cardBorder),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: MerchantTheme.textDark,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: MerchantTheme.textDark),
                ),
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 10, color: MerchantTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Verification Console ──
  Widget _buildVerificationConsole() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MerchantTheme.cardBorder),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MerchantTheme.brandTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: MerchantTheme.brandGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify a Pickup',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MerchantTheme.textDark),
                    ),
                    Text(
                      'Enter customer redemption code or scan their QR badge',
                      style: TextStyle(fontSize: 11.5, color: MerchantTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: MerchantTheme.brandGreen),
                tooltip: 'Scan QR Camera',
                onPressed: _scan,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Code Input Box with Scan Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: MK.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _error != null ? MerchantTheme.roseDanger : MerchantTheme.cardBorder,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: MerchantTheme.textDark,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ENTER CODE',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: MK.inkSoft,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _error = null;
                        _matchOrder(v);
                      });
                    },
                  ),
                ),
                if (_code.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: MerchantTheme.textMuted),
                    onPressed: _clearCode,
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantTheme.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Scan QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _scan,
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: MerchantTheme.roseDanger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MerchantTheme.roseDanger),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Numeric Keypad
          _buildNumericKeypad(),

          const SizedBox(height: 16),

          // Order Match Card (when matched)
          if (_selectedOrder != null)
            _buildMatchedOrderCard(_selectedOrder!)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MK.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MerchantTheme.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: MerchantTheme.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: Select an order from the waiting queue or enter code to inspect contents before handing over.',
                      style: TextStyle(fontSize: 11.5, color: MerchantTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Matched Order Card ──
  Widget _buildMatchedOrderCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantTheme.brandTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.brandGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: MerchantTheme.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: MerchantTheme.brandDeepGreen),
                    ),
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()} · Code: ${order.collectionCode}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MerchantTheme.brandDeepGreen),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: MerchantTheme.brandGreen),
                    SizedBox(width: 4),
                    Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: MerchantTheme.brandGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: MK.brandTint),
          const SizedBox(height: 10),

          // Items summary
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: MerchantTheme.brandDeepGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.dealTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MerchantTheme.textDark),
                ),
              ),
              Text(
                'GHS ${order.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: MerchantTheme.brandDeepGreen),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Button: Confirm Handover
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantTheme.brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _checking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.thumb_up_rounded, size: 18),
              label: Text(
                _checking ? 'Verifying with Backend…' : 'Confirm Handover & Release Food',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _checking ? null : () => _verify(order.collectionCode),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tactile Numeric Keypad ──
  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: MK.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              _buildKey('C', isAction: true, onTap: _clearCode),
              _buildKey('0'),
              _buildKey('⌫', isAction: true, onTap: _backspace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {bool isAction = false, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isAction ? MK.surfaceAlt : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap ?? () => _tap(label),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MK.line),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isAction ? MerchantTheme.textMuted : MerchantTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Waiting for Handover Queue Card ──
  Widget _buildWaitingQueueCard(List<Order> queue, {required int totalCount}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MerchantTheme.cardBorder),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MerchantTheme.amberLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_outline_rounded, color: MerchantTheme.amberWarning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waiting for Handover',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MerchantTheme.textDark),
                      ),
                      Text(
                        '$totalCount active order${totalCount == 1 ? '' : 's'} awaiting collection',
                        style: const TextStyle(fontSize: 11.5, color: MerchantTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Queue Filter Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _queueSearch,
              decoration: InputDecoration(
                hintText: 'Filter queue by customer or item…',
                hintStyle: const TextStyle(fontSize: 12, color: MerchantTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: MerchantTheme.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: MK.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: MerchantTheme.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: MerchantTheme.cardBorder)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: MerchantTheme.cardBorder),

          // Queue List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: MerchantTheme.brandTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.task_alt_rounded, size: 32, color: MerchantTheme.brandGreen),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All Caught Up!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: MerchantTheme.textDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No customer orders waiting for pickup right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: MerchantTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: queue.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final order = queue[i];
                      final isSelected = _selectedOrder?.id == order.id;
                      final isReady = order.status == 'ready';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectFromQueue(order),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? MerchantTheme.brandTint : MK.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MerchantTheme.brandGreen : MerchantTheme.cardBorder,
                                width: isSelected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isReady
                                        ? MerchantTheme.brandGreen.withValues(alpha: 0.12)
                                        : MerchantTheme.amberWarning.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isReady ? Icons.shopping_bag_rounded : Icons.soup_kitchen_rounded,
                                      size: 18,
                                      color: isReady ? MerchantTheme.brandGreen : MerchantTheme.amberWarning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order.customerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MerchantTheme.textDark),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isReady ? MK.brandTint : MK.goldTint,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isReady ? 'READY' : 'PREPARING',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: isReady ? MK.brand : MK.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        order.dealTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11.5, color: MerchantTheme.textMuted),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: MK.line,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'CODE: ${order.collectionCode}',
                                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: MerchantTheme.textDark),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            MK.ago(order.timestamp),
                                            style: const TextStyle(fontSize: 10, color: MerchantTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: MerchantTheme.textMuted, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
