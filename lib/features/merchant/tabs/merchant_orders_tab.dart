import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';

class MerchantOrdersTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final String? initialFilter;
  final bool autoOpen;

  const MerchantOrdersTab({
    super.key,
    required this.business,
    this.initialFilter,
    this.autoOpen = false,
  });

  @override
  ConsumerState<MerchantOrdersTab> createState() => _MerchantOrdersTabState();
}

class _MerchantOrdersTabState extends ConsumerState<MerchantOrdersTab> {
  static const _filters = <String>[
    'all',
    'reserved',
    'preparing',
    'ready',
    'out_for_delivery',
    'collected',
    'closed',
  ];
  static const _filterLabels = <String>[
    'All',
    'New',
    'Preparing',
    'Ready',
    'On the way',
    'Completed',
    'Closed',
  ];

  String _filter = 'all';
  final _search = TextEditingController();
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? 'all';
  }

  @override
  void didUpdateWidget(MerchantOrdersTab old) {
    super.didUpdateWidget(old);
    if (old.initialFilter != widget.initialFilter && widget.initialFilter != null) {
      setState(() => _filter = widget.initialFilter!);
    }
  }

  bool _matches(Order o) {
    switch (_filter) {
      case 'all':
        break;
      case 'closed':
        if (o.status != 'cancelled' && o.status != 'expired') return false;
        break;
      default:
        if (o.status != _filter) return false;
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return o.collectionCode.toLowerCase().contains(q) ||
        o.customerName.toLowerCase().contains(q) ||
        o.dealTitle.toLowerCase().contains(q);
  }

  Future<void> _advance(Order order, String next, String label) async {
    setState(() => _busy.add(order.id));
    try {
      await ref.read(appStateProvider.notifier).updateMerchantOrderStatus(
            orderId: order.id,
            status: next,
            fulfillmentType: order.fulfillmentType,
          );
      if (mounted) MToast.ok(context, '#${order.collectionCode} → $label');
    } catch (e) {
      if (mounted) MToast.err(context, 'Could not update: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _collect(Order order) async {
    final ok = await showMConfirm(
      context,
      title: 'Hand over order?',
      message: 'Confirm the customer code matches #${order.collectionCode} before completing this rescue.',
      confirmLabel: 'Mark collected',
      code: order.collectionCode,
    );
    if (!ok) return;
    setState(() => _busy.add(order.id));
    try {
      await ref.read(appStateProvider.notifier).confirmCollection(order.id);
      if (mounted) MToast.ok(context, '#${order.collectionCode} collected');
    } catch (e) {
      if (mounted) MToast.err(context, 'Could not verify: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _remind(Order order) async {
    setState(() => _busy.add(order.id));
    try {
      await ref.read(appStateProvider.notifier).sendOrderReminder(order);
      if (mounted) MToast.ok(context, 'Reminder sent to ${order.customerName}');
    } catch (e) {
      if (mounted) MToast.err(context, 'Reminder failed: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final all = state.orders.where((o) => o.businessId == widget.business.id).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final visible = all.where(_matches).toList();
    int countOf(String f) {
      if (f == 'all') return all.length;
      if (f == 'closed') return all.where((o) => o.status == 'cancelled' || o.status == 'expired').length;
      return all.where((o) => o.status == f).length;
    }

    return ResponsiveCenter(
      maxWidth: 980,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: MSearchField(
              controller: _search,
              hint: 'Search code, customer or pack…',
              onChanged: (_) => setState(() {}),
              onClear: _search.text.isEmpty
                  ? null
                  : () {
                      _search.clear();
                      setState(() {});
                    },
            ),
          ),
          MChipRow(
            items: _filterLabels,
            values: _filters,
            value: _filter,
            countOf: countOf,
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await notifier.refreshOrders();
                await notifier.loadMerchantDeals();
              },
              child: all.isEmpty
                  ? ListView(
                      children: const [
                        MFeedbackBlock(
                          icon: Icons.receipt_long_rounded,
                          title: 'No orders yet',
                          message: 'When a customer reserves one of your packs it appears here in real time.',
                        ),
                      ],
                    )
                  : visible.isEmpty
                      ? ListView(
                          children: [
                            MFeedbackBlock(
                              icon: Icons.filter_alt_off_rounded,
                              title: 'No orders in this view',
                              message: _search.text.trim().isEmpty
                                  ? 'Switch filter to “All” to see your other orders.'
                                  : 'No order matches “${_search.text.trim()}”.',
                              actionLabel: 'Show all orders',
                              onAction: () {
                                _search.clear();
                                setState(() {
                                  _filter = 'all';
                                });
                              },
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => MReveal(
                            delay: (i * 45).clamp(0, 360),
                            child: _OrderCard(
                              order: visible[i],
                              busy: _busy.contains(visible[i].id),
                              onAdvance: () {
                                final meta = OrderStatuses.of(visible[i].status);
                                if (meta.next == null) return;
                                _advance(visible[i], meta.next!, meta.nextLabel);
                              },
                              onCollect: () => _collect(visible[i]),
                              onRemind: () => _remind(visible[i]),
                              onDetails: () => showOrderDetailSheet(context, ref, visible[i]),
                              onTracking: () => showTrackingSheet(context, ref, visible[i], _clean),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool busy;
  final VoidCallback onAdvance;
  final VoidCallback onCollect;
  final VoidCallback onRemind;
  final VoidCallback onDetails;
  final VoidCallback onTracking;

  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onAdvance,
    required this.onCollect,
    required this.onRemind,
    required this.onDetails,
    required this.onTracking,
  });

  @override
  Widget build(BuildContext context) {
    final meta = OrderStatuses.of(order.status);
    final closed = meta.isClosed;
    final delivery = order.fulfillmentType == 'delivery';

    return MCard(
      onTap: busy ? null : onDetails,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            orderTitle(order),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MPill(
                          delivery ? 'DELIVERY' : 'PICKUP',
                          color: delivery ? MK.sky : MK.inkSoft,
                          fontSize: 8.5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.customerName} · ${MK.ago(order.timestamp)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MK.money(order.price),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: MK.ink),
                  ),
                  const SizedBox(height: 4),
                  MPill(meta.shortLabel, color: meta.color, pulse: !closed && order.status == 'reserved', fontSize: 8.5),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          MStatusTimeline(status: order.status),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 15, color: MK.brand),
                const SizedBox(width: 8),
                Text(
                  order.collectionCode,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: 1.2),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_rounded, size: 14, color: MK.inkSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.trackingNotes?.isNotEmpty == true
                        ? order.trackingNotes!
                        : 'Pickup window on the deal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (order.courierName?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.two_wheeler_rounded, size: 14, color: MK.sky),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.courierName}${order.courierPhone?.isNotEmpty == true ? ' · ${order.courierPhone}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MK.sky),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              MIconButton(icon: Icons.tune_rounded, onPressed: busy ? null : onTracking, tooltip: 'Status & tracking'),
              const SizedBox(width: 8),
              MIconButton(icon: Icons.notifications_active_outlined, onPressed: busy ? null : onRemind, color: MK.amber, tooltip: 'Remind customer'),
              const SizedBox(width: 8),
              MIconButton(icon: Icons.info_outline_rounded, onPressed: busy ? null : onDetails, color: MK.grape, tooltip: 'Details'),
              const Spacer(),
              if (!closed)
                MButton(
                  order.status == 'ready' || order.status == 'out_for_delivery' ? 'Hand over' : meta.nextLabel,
                  icon: order.status == 'ready' || order.status == 'out_for_delivery'
                      ? Icons.check_circle_rounded
                      : meta.next == 'collected'
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                  loading: busy,
                  height: 40,
                  onPressed: busy
                      ? null
                      : (order.status == 'ready' || order.status == 'out_for_delivery')
                          ? onCollect
                          : onAdvance,
                )
              else
                Text(
                  order.payoutStatus == 'paid' ? 'SETTLED' : 'PAYOUT PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: order.payoutStatus == 'paid' ? MK.brand : MK.amber,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status + courier editor. Errors surface instead of hanging on a spinner.
Future<void> showTrackingSheet(
  BuildContext context,
  WidgetRef ref,
  Order order,
  String Function(Object) clean,
) async {
  await showMSheet<void>(
    context,
    title: 'Status & tracking',
    child: _TrackingForm(order: order, ref: ref, clean: clean),
  );
}

class _TrackingForm extends ConsumerStatefulWidget {
  final Order order;
  final WidgetRef ref;
  final String Function(Object) clean;

  const _TrackingForm({required this.order, required this.ref, required this.clean});

  @override
  ConsumerState<_TrackingForm> createState() => _TrackingFormState();
}

class _TrackingFormState extends ConsumerState<_TrackingForm> {
  late String _status = widget.order.status;
  late String _fulfilment = widget.order.fulfillmentType;
  late final _courier = TextEditingController(text: widget.order.courierName ?? '');
  late final _phone = TextEditingController(text: widget.order.courierPhone ?? '');
  late final _notes = TextEditingController(text: widget.order.trackingNotes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _courier.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(appStateProvider.notifier).updateMerchantOrderStatus(
            orderId: widget.order.id,
            status: _status,
            fulfillmentType: _fulfilment,
            courierName: _courier.text.trim().isEmpty ? null : _courier.text.trim(),
            courierPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            trackingNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      MToast.ok(context, '#${widget.order.collectionCode} updated · customer notified');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        MToast.err(context, widget.clean(e));
      }
    }
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.brand, width: 1.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Label('FULFILMENT STATUS'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrderStatuses.all
              .where((m) => m.key != 'expired')
              .map((m) => MPressable(
                    onTap: () => setState(() => _status = m.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: _status == m.key ? m.color.withValues(alpha: 0.14) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _status == m.key ? m.color : MK.line, width: _status == m.key ? 1.6 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.icon, size: 15, color: _status == m.key ? m.color : MK.inkSoft),
                          const SizedBox(width: 7),
                          Text(
                            m.shortLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _status == m.key ? m.color : MK.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        const _Label('HOW IS IT GETTING TO THE CUSTOMER'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Choice(
                label: 'Store pickup',
                icon: Icons.shopping_bag_rounded,
                selected: _fulfilment == 'pickup',
                onTap: () => setState(() => _fulfilment = 'pickup'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                label: 'Delivery',
                icon: Icons.two_wheeler_rounded,
                selected: _fulfilment == 'delivery',
                onTap: () => setState(() => _fulfilment = 'delivery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Label('COURIER DETAILS (OPTIONAL)'),
        const SizedBox(height: 8),
        TextField(controller: _courier, decoration: _field('Rider name', Icons.person_outline_rounded)),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _field('Rider phone', Icons.phone_outlined),
        ),
        const SizedBox(height: 20),
        const _Label('PICKUP / HANDOVER NOTES'),
        const SizedBox(height: 8),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: _field('e.g. shelf #3, ask Ama', Icons.edit_note_rounded),
        ),
        const SizedBox(height: 20),
        MButton(
          'Save & notify customer',
          icon: Icons.send_rounded,
          expanded: true,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: MK.inkSoft, letterSpacing: 0.9),
      );
}

class _Choice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => MPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: selected ? MK.brand.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(MK.rSm),
            border: Border.all(color: selected ? MK.brand : MK.line, width: selected ? 1.6 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? MK.brand : MK.inkSoft),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: selected ? MK.brand : MK.ink),
              ),
            ],
          ),
        ),
      );
}

Future<void> showOrderDetailSheet(BuildContext context, WidgetRef ref, Order order) async {
  await showMSheet<void>(
    context,
    title: 'Order details',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                orderTitle(order),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.4),
              ),
            ),
            MPill(OrderStatuses.of(order.status).shortLabel, color: OrderStatuses.of(order.status).color),
          ],
        ),
        const SizedBox(height: 14),
        MStatusTimeline(status: order.status),
        const SizedBox(height: 16),
        const Divider(color: MK.line),
        MDetailRow(label: 'Customer', value: order.customerName, icon: Icons.person_outline_rounded),
        MDetailRow(label: 'Rescue code', value: order.collectionCode, icon: Icons.confirmation_number_outlined),
        MDetailRow(label: 'Placed', value: DateFormat('d MMM yyyy • h:mm a').format(order.timestamp), icon: Icons.schedule_rounded),
        MDetailRow(label: 'Fulfilment', value: order.fulfillmentType == 'delivery' ? 'Delivery' : 'Store pickup', icon: Icons.local_shipping_outlined),
        MDetailRow(label: 'Paid', value: MK.money(order.price), icon: Icons.payments_outlined),
        MDetailRow(
          label: 'Was worth',
          value: MK.money(order.originalPrice),
          icon: Icons.sell_outlined,
          valueColor: MK.inkSoft,
        ),
        MDetailRow(
          label: 'Saved by customer',
          value: '${(((order.originalPrice - order.price) / (order.originalPrice == 0 ? 1 : order.originalPrice)) * 100).round()}%',
          icon: Icons.eco_rounded,
          valueColor: MK.brand,
        ),
        MDetailRow(label: 'Payment', value: order.paymentMethod, icon: Icons.credit_card_outlined),
        MDetailRow(
          label: 'Payout',
          value: order.payoutStatus == 'paid' ? 'Settled' : 'Pending',
          valueColor: order.payoutStatus == 'paid' ? MK.brand : MK.amber,
          icon: Icons.account_balance_wallet_outlined,
        ),
        if (order.courierName?.isNotEmpty == true)
          MDetailRow(label: 'Courier', value: '${order.courierName} · ${order.courierPhone ?? ''}', icon: Icons.two_wheeler_rounded),
        if (order.deliveryAddress?.isNotEmpty == true)
          MDetailRow(label: 'Deliver to', value: order.deliveryAddress!, icon: Icons.place_outlined),
        if (order.trackingNotes?.isNotEmpty == true)
          MDetailRow(label: 'Notes', value: order.trackingNotes!, icon: Icons.sticky_note_2_outlined),
        const SizedBox(height: 6),
        Text(
          'Order ID ${order.id}',
          style: const TextStyle(fontSize: 10, color: MK.inkSoft, fontFamily: 'monospace'),
        ),
      ],
    ),
  );
}

/// Confirmation dialog with a big code readback so the merchant can eyeball it.
Future<bool> showMConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String code,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MK.ink)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: MK.inkSoft, height: 1.45)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(
                color: MK.brand.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MK.brand.withValues(alpha: 0.3)),
              ),
              child: Text(
                code,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: MK.brandDeep, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MButton('Cancel', kind: MKind.ghost, onPressed: () => Navigator.pop(ctx, false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MButton(confirmLabel, icon: Icons.check_rounded, onPressed: () => Navigator.pop(ctx, true)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
