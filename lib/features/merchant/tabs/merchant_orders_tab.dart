import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../merchant_kit.dart';
import '../services/merchant_export_service.dart';

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
  bool _kanbanMode = false;
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

    final wide = useSideNav(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = screenWidth >= 760;

    final today = all.where((o) => DateUtils.isSameDay(o.timestamp, DateTime.now())).toList();
    final todayRevenue = today.where((o) => o.status == 'collected').fold<double>(0, (s, o) => s + o.price);

    return ResponsiveCenter(
      maxWidth: 1320,
      child: Column(
        children: [
          // ── Tablet / PC KPI Summary Strip ──
          if (isTabletOrDesktop)
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 14, wide ? 24 : 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    _OrderKpiItem(
                      label: 'NEEDS ACTION',
                      count: all.where((o) => o.status == 'reserved').length,
                      color: const Color(0xFFF97316),
                    ),
                    _vDivider(),
                    _OrderKpiItem(
                      label: 'IN KITCHEN',
                      count: all.where((o) => o.status == 'preparing').length,
                      color: const Color(0xFFD97706),
                    ),
                    _vDivider(),
                    _OrderKpiItem(
                      label: 'READY AT COUNTER',
                      count: all.where((o) => o.status == 'ready').length,
                      color: MK.brand,
                    ),
                    _vDivider(),
                    _OrderKpiItem(
                      label: 'TOTAL ORDERS',
                      count: all.length,
                      color: MK.ink,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: MK.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 16, color: MK.brandDeep),
                          const SizedBox(width: 8),
                          Text(
                            'Collected today: ${MK.money(todayRevenue)}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.brandDeep),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Search & Controls Toolbar ──
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 14 : 10, wide ? 24 : 16, 8),
            child: Row(
              children: [
                Expanded(
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
                if (isTabletOrDesktop) ...[
                  const SizedBox(width: 10),
                  // Kanban vs Grid View Toggle
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Card Grid View',
                          child: InkWell(
                            onTap: () => setState(() => _kanbanMode = false),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: !_kanbanMode ? MK.brand.withValues(alpha: 0.12) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: !_kanbanMode ? MK.brandDeep : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        Tooltip(
                          message: 'Kitchen Kanban (KDS)',
                          child: InkWell(
                            onTap: () => setState(() => _kanbanMode = true),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _kanbanMode ? MK.brand.withValues(alpha: 0.12) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.view_kanban_rounded,
                                    size: 18,
                                    color: _kanbanMode ? MK.brandDeep : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'KDS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: _kanbanMode ? MK.brandDeep : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                SizedBox(
                  width: 46,
                  child: MIconButton(
                    icon: Icons.upload_file_rounded,
                    tooltip: 'Export orders report',
                    color: MK.sky,
                    size: 46,
                    onPressed: all.isEmpty ? null : () => _exportOrders(all),
                  ),
                ),
              ],
            ),
          ),

          if (!_kanbanMode || !isTabletOrDesktop)
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
                  : (_kanbanMode && isTabletOrDesktop)
                      ? _OrdersKanbanBoard(
                          allOrders: all,
                          busy: _busy,
                          onAdvance: _advance,
                          onCollect: _collect,
                          onDetails: (o) => showOrderDetailSheet(context, ref, o),
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
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isMultiCol = constraints.maxWidth >= 640;
                                if (isMultiCol) {
                                  return GridView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 8, wide ? 24 : 16, wide ? 24 : 110),
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 580,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      mainAxisExtent: 248,
                                    ),
                                    itemCount: visible.length,
                                    itemBuilder: (_, i) => MReveal(
                                      delay: (i * 35).clamp(0, 320),
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
                                  );
                                }
                                return ListView.separated(
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
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        height: 28,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0xFFE2E8F0),
      );

  void _exportOrders(List<Order> orders) {
    if (orders.isEmpty) {
      MToast.info(context, 'No orders available to export');
      return;
    }
    final headers = [
      'Order ID',
      'Pickup Code',
      'Food Deal',
      'Customer',
      'Status',
      'Fulfilment',
      'Price (GHS)',
      'Placed Date',
      'Payout Status',
    ];
    final rows = orders.map((o) => [
      o.id.substring(0, 8).toUpperCase(),
      o.collectionCode,
      o.dealTitle,
      o.customerName,
      o.status.toUpperCase(),
      o.fulfillmentType,
      o.price,
      o.timestamp,
      o.payoutStatus.toUpperCase(),
    ]).toList();

    final dataset = ExportDataset(
      title: 'Kitchen Orders Master Report',
      merchantName: widget.business.name,
      fileNamePrefix: 'kitchen_orders',
      headers: headers,
      rows: rows,
      summaryMetrics: {
        'Total Orders': '${orders.length}',
        'Active Pipeline': '${orders.where((o) => o.status == 'reserved' || o.status == 'preparing' || o.status == 'ready').length}',
        'Handed Over': '${orders.where((o) => o.status == 'collected').length}',
      },
    );

    MerchantExportService.showExportDialog(context, dataset: dataset);
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

class _OrderKpiItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _OrderKpiItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _OrdersKanbanBoard extends StatelessWidget {
  final List<Order> allOrders;
  final Set<String> busy;
  final Function(Order, String, String) onAdvance;
  final Function(Order) onCollect;
  final Function(Order) onDetails;

  const _OrdersKanbanBoard({
    required this.allOrders,
    required this.busy,
    required this.onAdvance,
    required this.onCollect,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final reserved = allOrders.where((o) => o.status == 'reserved').toList();
    final preparing = allOrders.where((o) => o.status == 'preparing').toList();
    final ready = allOrders.where((o) => o.status == 'ready').toList();
    final completed = allOrders.where((o) => o.status == 'out_for_delivery' || o.status == 'collected').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _KanbanColumn(
              title: 'New Orders',
              count: reserved.length,
              color: const Color(0xFFF97316),
              icon: Icons.inbox_rounded,
              orders: reserved,
              busy: busy,
              actionLabel: 'Start prep',
              onAction: (o) => onAdvance(o, 'preparing', 'Preparing'),
              onDetails: onDetails,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KanbanColumn(
              title: 'In Kitchen',
              count: preparing.length,
              color: const Color(0xFFD97706),
              icon: Icons.soup_kitchen_rounded,
              orders: preparing,
              busy: busy,
              actionLabel: 'Mark ready',
              onAction: (o) => onAdvance(o, 'ready', 'Ready'),
              onDetails: onDetails,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KanbanColumn(
              title: 'Ready for Counter',
              count: ready.length,
              color: MK.brand,
              icon: Icons.shopping_bag_rounded,
              orders: ready,
              busy: busy,
              actionLabel: 'Hand over',
              onAction: onCollect,
              onDetails: onDetails,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KanbanColumn(
              title: 'Dispatched & Done',
              count: completed.length,
              color: MK.sky,
              icon: Icons.check_circle_outline_rounded,
              orders: completed,
              busy: busy,
              actionLabel: null,
              onAction: (_) {},
              onDetails: onDetails,
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final List<Order> orders;
  final Set<String> busy;
  final String? actionLabel;
  final Function(Order) onAction;
  final Function(Order) onDetails;

  const _KanbanColumn({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.orders,
    required this.busy,
    required this.actionLabel,
    required this.onAction,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 2)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: MK.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column Cards List
          SizedBox(
            height: 580,
            child: orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No tickets in this stage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      final isBusy = busy.contains(o.id);
                      final isDelivery = o.fulfillmentType == 'delivery';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MK.brand.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${o.collectionCode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: MK.brandDeep,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDelivery ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isDelivery ? 'DELIVERY' : 'PICKUP',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: isDelivery ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  MK.money(o.price),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: MK.ink),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              orderTitle(o),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MK.ink, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${o.customerName} · ${MK.ago(o.timestamp)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => onDetails(o),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF475569)),
                                  ),
                                ),
                                const Spacer(),
                                if (actionLabel != null && o.status != 'collected' && o.status != 'cancelled')
                                  MButton(
                                    actionLabel!,
                                    height: 32,
                                    loading: isBusy,
                                    onPressed: isBusy ? null : () => onAction(o),
                                  )
                                else
                                  Text(
                                    o.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: color,
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
