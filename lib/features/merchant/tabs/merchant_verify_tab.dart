import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

class MerchantVerifyTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final bool autoOpen;

  const MerchantVerifyTab({super.key, required this.business, this.autoOpen = false});

  @override
  ConsumerState<MerchantVerifyTab> createState() => _MerchantVerifyTabState();
}

class _MerchantVerifyTabState extends ConsumerState<MerchantVerifyTab> {
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _tap(String v) {
    if (_code.text.length >= 8) return;
    setState(() {
      _code.text += v;
      _error = null;
    });
    _formKey.currentState?.validate();
  }

  void _backspace() {
    if (_code.text.isEmpty) return;
    setState(() {
      _code.text = _code.text.substring(0, _code.text.length - 1);
      _error = null;
    });
  }

  Future<void> _verify(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter or scan the customer code first.');
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
        setState(() => _error = 'No order with code $code at ${widget.business.name}.');
        return;
      }
      final order = found;

      if (order.status == 'collected') {
        if (!mounted) return;
        await showMResult(
          context,
          title: 'Already collected',
          message: '${order.customerName} already picked this up ${MK.ago(order.timestamp)}.',
          ok: false,
          actionLabel: 'Got it',
        );
        _code.clear();
        return;
      }
      if (order.status == 'cancelled' || order.status == 'expired') {
        setState(() => _error = 'This reservation is ${order.status} and cannot be collected.');
        return;
      }

      await notifier.confirmCollection(order.id);
      _code.clear();
      if (!mounted) return;
      await showMResult(
        context,
        title: 'Collection verified',
        message: '${orderTitle(order)} handed to ${order.customerName}. Payout queued.',
        actionLabel: 'Next customer',
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Order? _find(List<Order> orders, String code) {
    for (final o in orders) {
      if (o.businessId == widget.business.id && o.collectionCode.toUpperCase() == code) return o;
    }
    return null;
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
          title: const Text('Scan customer QR', style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
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
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  border: Border.all(color: MK.brandGlow, width: 3),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Point the camera at the QR on the customer screen',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) await _verify(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final awaiting = state.orders
        .where((o) =>
            o.businessId == widget.business.id &&
            (o.status == 'reserved' || o.status == 'preparing' || o.status == 'ready' || o.status == 'out_for_delivery'))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final wide = useSideNav(context);
    final isTabletOrDesktop = MediaQuery.sizeOf(context).width >= 720;

    final keypadCard = MReveal(
      delay: 60,
      child: MCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _code,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6, color: MK.ink),
                decoration: InputDecoration(
                  hintText: '----',
                  hintStyle: TextStyle(color: MK.inkSoft.withValues(alpha: 0.4), letterSpacing: 6),
                  enabled: !_checking,
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: 74,
              decoration: BoxDecoration(color: _error != null ? MK.danger : MK.brand, borderRadius: BorderRadius.circular(4)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: MK.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 11.5, color: MK.danger, fontWeight: FontWeight.w800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _Keypad(onTap: _tap, onBackspace: _backspace),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MButton(
                    'Scan QR',
                    icon: Icons.qr_code_scanner_rounded,
                    kind: MKind.soft,
                    onPressed: _checking ? null : _scan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: MButton(
                    'Verify collection',
                    icon: Icons.check_circle_outline_rounded,
                    loading: _checking,
                    onPressed: _checking ? null : () => _verify(_code.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final awaitingCard = MReveal(
      delay: 110,
      child: MCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MSectionHeader(
              title: 'Waiting for hand-over',
              icon: Icons.hourglass_top_rounded,
              iconColor: MK.amber,
            ),
            const SizedBox(height: 8),
            if (awaiting.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No open orders. Verified pickups show a tick here automatically.',
                  style: TextStyle(fontSize: 12, color: MK.inkSoft, height: 1.45),
                ),
              )
            else
              ...awaiting.take(6).map(
                    (o) => InkWell(
                      onTap: () {
                        _code.text = o.collectionCode;
                        setState(() => _error = null);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 74,
                              child: Text(
                                o.collectionCode,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: MK.brand, letterSpacing: 1.1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderTitle(o),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: MK.ink),
                                  ),
                                  Text(
                                    '${o.customerName} · ${MK.ago(o.timestamp)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10.5, color: MK.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                            MPill(
                              OrderStatuses.of(o.status).shortLabel,
                              color: OrderStatuses.of(o.status).color,
                              fontSize: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );

    return ResponsiveCenter(
      maxWidth: isTabletOrDesktop ? 1080 : 560,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 14, wide ? 24 : 16, wide ? 28 : 110),
        children: [
          MReveal(
            child: Column(
              children: [
                const Text(
                  'Verify a pickup',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  awaiting.isEmpty
                      ? 'Nothing is waiting to be collected right now.'
                      : '${awaiting.length} order${awaiting.length == 1 ? "" : "s"} waiting for hand-over.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: MK.inkSoft, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isTabletOrDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: keypadCard),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: awaitingCard),
              ],
            )
          else ...[
            keypadCard,
            const SizedBox(height: 18),
            awaitingCard,
          ],
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onTap;
  final VoidCallback onBackspace;

  const _Keypad({required this.onTap, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: row.map((k) => Expanded(child: _Key(k, onTap: () => onTap(k)))).toList()),
          ),
        ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              child: _Key('0', onTap: () => onTap('0')),
            ),
            Expanded(
              child: MPressable(
                onTap: onBackspace,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace_outlined, size: 22, color: MK.inkSoft),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Key(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MPressable(
          onTap: onTap,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MK.line),
            ),
            child: Text(label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: MK.ink)),
          ),
        ),
      );
}
