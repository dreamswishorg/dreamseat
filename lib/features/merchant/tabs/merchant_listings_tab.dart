import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../../../services/supabase_service.dart';
import '../merchant_kit.dart';
import '../services/merchant_export_service.dart';
import '../theme/merchant_theme.dart';

class MerchantListingsTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final bool composeNew;

  const MerchantListingsTab({
    super.key,
    required this.business,
    this.composeNew = false,
  });

  @override
  ConsumerState<MerchantListingsTab> createState() =>
      _MerchantListingsTabState();
}

enum _ListingSort {
  recent,
  priceAsc,
  priceDesc,
  stockAsc,
  stockDesc,
  discountDesc,
}

class _MerchantListingsTabState extends ConsumerState<MerchantListingsTab> {
  static const _statusFilters = ['all', 'live', 'soldout'];
  static const _statusLabels = [
    'All Items',
    'Live & Selling',
    'Sold Out',
  ];

  String _statusFilter = 'all';
  _ListingSort _sort = _ListingSort.recent;
  bool _isTableView = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.composeNew) _compose();
    });
  }

  @override
  void didUpdateWidget(MerchantListingsTab old) {
    super.didUpdateWidget(old);
    if (!old.composeNew && widget.composeNew) _compose();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _bucketOf(FoodDeal d) {
    if (!d.isActive) return 'paused';
    if (d.quantityRemaining == 0) return 'soldout';
    if (d.quantityRemaining <= 2) return 'low';
    return 'live';
  }

  Future<void> _compose([
    FoodDeal? existing,
    Map<String, dynamic>? template,
  ]) async {
    await showMSheet<void>(
      context,
      title: existing == null
          ? (template != null ? 'Use Pack Template' : 'Publish a Surplus Pack')
          : 'Edit Listing',
      maxWidth: 680,
      child: _DealForm(
        business: widget.business,
        existing: existing,
        presetTemplate: template,
      ),
    );
  }

  void _openTemplates() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickTemplatesSheet(
        onSelect: (tpl) {
          Navigator.pop(ctx);
          _compose(null, tpl);
        },
      ),
    );
  }

  Future<void> _toggle(FoodDeal deal, bool activate) async {
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(appStateProvider.notifier)
          .toggleDealStatus(deal.id, activate);
      if (mounted) {
        MToast.ok(
          context,
          '“${deal.title}” is now ${activate ? 'live & discoverable' : 'paused'}',
        );
      }
    } catch (e) {
      if (mounted)
        MToast.err(
          context,
          'Could not update: ${e.toString().replaceFirst('Exception: ', '')}',
        );
    }
  }

  Future<void> _quickStockAdjust(FoodDeal deal, int delta) async {
    final newRemaining = (deal.quantityRemaining + delta).clamp(0, 999);
    final newTotal = (deal.quantityTotal + (delta > 0 ? delta : 0)).clamp(
      newRemaining,
      999,
    );
    if (newRemaining == deal.quantityRemaining) return;

    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(appStateProvider.notifier)
          .updateDeal(
            dealId: deal.id,
            title: deal.title,
            description: deal.description,
            category: deal.category,
            originalPrice: deal.originalPrice,
            discountedPrice: deal.discountedPrice,
            pickupWindow: deal.pickupWindow,
            quantity: newTotal,
            imageUrl: deal.imageUrl,
          );
      if (mounted) {
        MToast.ok(context, 'Updated ${deal.title}: $newRemaining packs left');
      }
    } catch (e) {
      if (mounted) MToast.err(context, 'Stock adjust failed: $e');
    }
  }

  Future<void> _duplicateDeal(FoodDeal deal) async {
    HapticFeedback.mediumImpact();
    try {
      final notifier = ref.read(appStateProvider.notifier);
      await notifier.addDeal(
        title: '${deal.title} (Copy)',
        description: deal.description,
        category: deal.category,
        originalPrice: deal.originalPrice,
        discountedPrice: deal.discountedPrice,
        pickupWindow: deal.pickupWindow,
        quantity: deal.quantityTotal > 0 ? deal.quantityTotal : 5,
        imageUrl: deal.imageUrl,
      );
      if (mounted) {
        MToast.ok(context, 'Duplicated “${deal.title}” successfully');
      }
    } catch (e) {
      if (mounted) MToast.err(context, 'Duplicate failed: $e');
    }
  }

  Future<void> _restock(FoodDeal deal) async {
    final qty = await askNumber(
      context,
      title: 'Restock “${deal.title}”',
      hint: 'New total number of units',
      initial: (deal.quantityTotal + 5).toString(),
      validate: (v) {
        final n = int.tryParse(v.trim());
        if (n == null || n <= 0) return 'Enter a number above zero';
        if (n < deal.quantityTotal - deal.quantityRemaining)
          return 'Total cannot be below units already sold';
        return null;
      },
    );
    if (qty == null) return;
    try {
      await ref
          .read(appStateProvider.notifier)
          .updateDeal(
            dealId: deal.id,
            title: deal.title,
            description: deal.description,
            category: deal.category,
            originalPrice: deal.originalPrice,
            discountedPrice: deal.discountedPrice,
            pickupWindow: deal.pickupWindow,
            quantity: int.parse(qty),
            imageUrl: deal.imageUrl,
          );
      if (mounted)
        MToast.ok(context, 'Stock updated to $qty units · visible immediately');
    } catch (e) {
      if (mounted)
        MToast.err(
          context,
          'Restock failed: ${e.toString().replaceFirst('Exception: ', '')}',
        );
    }
  }

  Future<void> _delete(FoodDeal deal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: MerchantTheme.roseLightBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 28,
                  color: MerchantTheme.roseDanger,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete this listing?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: MerchantTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '“${deal.title}” will immediately be removed from consumer discovery. Existing customer orders for this item remain safe in your Orders tab.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: MerchantTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Keep Listing',
                        style: TextStyle(
                          color: MerchantTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MerchantTheme.roseDanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(appStateProvider.notifier).deleteDeal(deal.id);
      if (mounted) MToast.ok(context, 'Listing removed successfully');
    } catch (e) {
      if (mounted)
        MToast.err(
          context,
          'Delete failed: ${e.toString().replaceFirst('Exception: ', '')}',
        );
    }
  }

  void _triggerExport(List<FoodDeal> deals) {
    if (deals.isEmpty) {
      MToast.info(context, 'No listings available to export');
      return;
    }

    final headers = [
      'Listing Title',
      'Category',
      'Regular Price (GHS)',
      'Deal Price (GHS)',
      'Savings %',
      'Stock Total',
      'Stock Remaining',
      'Units Rescued',
      'Status',
      'Pickup Window',
    ];

    int totalLive = 0;
    int totalRescued = 0;
    double totalValue = 0;

    final rows = deals.map((d) {
      final rescued = d.quantityTotal - d.quantityRemaining;
      if (d.isActive && d.quantityRemaining > 0) totalLive++;
      totalRescued += rescued;
      totalValue += (d.discountedPrice * rescued);

      return [
        d.title,
        d.category,
        d.originalPrice,
        d.discountedPrice,
        '${d.percentageSaved}%',
        d.quantityTotal,
        d.quantityRemaining,
        rescued,
        _bucketOf(d).toUpperCase(),
        d.pickupWindow,
      ];
    }).toList();

    final dataset = ExportDataset(
      title: 'Surplus Food Inventory Statement',
      merchantName: widget.business.name,
      fileNamePrefix: 'inventory_report',
      headers: headers,
      rows: rows,
      summaryMetrics: {
        'Total Listings': '${deals.length}',
        'Live Active Deals': '$totalLive',
        'Lifetime Rescued Packs': '$totalRescued',
        'Rescued Value Generated': 'GHS ${totalValue.toStringAsFixed(2)}',
      },
    );

    MerchantExportService.showExportDialog(context, dataset: dataset);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final deals = state.merchantDeals;

    final q = _search.text.trim().toLowerCase();
    var filtered = deals.where((d) {
      final matchesStatus =
          _statusFilter == 'all' || _bucketOf(d) == _statusFilter;
      final matchesQuery =
          q.isEmpty ||
          d.title.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();

    // Sort
    switch (_sort) {
      case _ListingSort.recent:
        filtered.sort(
          (a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0),
        );
        break;
      case _ListingSort.priceAsc:
        filtered.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case _ListingSort.priceDesc:
        filtered.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case _ListingSort.stockAsc:
        filtered.sort(
          (a, b) => a.quantityRemaining.compareTo(b.quantityRemaining),
        );
        break;
      case _ListingSort.stockDesc:
        filtered.sort(
          (a, b) => b.quantityRemaining.compareTo(a.quantityRemaining),
        );
        break;
      case _ListingSort.discountDesc:
        filtered.sort((a, b) => b.percentageSaved.compareTo(a.percentageSaved));
        break;
    }

    final isWide = useSideNav(context);

    // Everything scrolls as one page: a fixed Column chrome used to consume the
    // whole phone viewport and squeeze the listing grid out of view.
    return ResponsiveCenter(
      maxWidth: 1320,
      child: RefreshIndicator(
        color: MerchantTheme.brandGreen,
        onRefresh: () => notifier.loadMerchantDeals(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 0, 0, isWide ? 24 : 96),
          children: [
            // ── Non-blocking Verification Review Notice ──
            if (!widget.business.isApproved)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16,
                  12,
                  isWide ? 24 : 16,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: MK.amberTint,
                    borderRadius: BorderRadius.circular(MK.rSm),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: MK.gold,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Compliance Status: Document Verification in Review · You have full access to create, edit, restock and manage your surplus packs. Items will be visible to nearby rescuers as soon as verification completes.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MK.gold,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Executive Hero Command Banner ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                12,
                isWide ? 24 : 16,
                4,
              ),
              child: _SurplusHeroHeader(
                business: widget.business,
                deals: deals,
                onNewPack: () => _compose(),
                onQuickTemplates: _openTemplates,
                isWide: isWide,
              ),
            ),

            // ── Search & Filter Controls ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                8,
                isWide ? 24 : 16,
                4,
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Input
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 380 : double.infinity,
                    ),
                    child: MSearchField(
                      controller: _search,
                      hint: 'Search pack title, dishes, category…',
                      onChanged: (_) => setState(() {}),
                      onClear: _search.text.isEmpty
                          ? null
                          : () {
                              _search.clear();
                              setState(() {});
                            },
                    ),
                  ),

                  // Controls: Sort, View Switcher, Export
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Sort Dropdown
                      SizedBox(
                        width: 168,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MerchantTheme.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_ListingSort>(
                              value: _sort,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.sort_rounded,
                                size: 18,
                                color: MerchantTheme.textMuted,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MerchantTheme.textDark,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: _ListingSort.recent,
                                  child: Text('Sort: Default'),
                                ),
                                DropdownMenuItem(
                                  value: _ListingSort.priceAsc,
                                  child: Text('Price: Low to High'),
                                ),
                                DropdownMenuItem(
                                  value: _ListingSort.priceDesc,
                                  child: Text('Price: High to Low'),
                                ),
                                DropdownMenuItem(
                                  value: _ListingSort.stockAsc,
                                  child: Text('Stock: Lowest First'),
                                ),
                                DropdownMenuItem(
                                  value: _ListingSort.stockDesc,
                                  child: Text('Stock: Highest First'),
                                ),
                                DropdownMenuItem(
                                  value: _ListingSort.discountDesc,
                                  child: Text('Discount: High to Low'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sort = v);
                              },
                            ),
                          ),
                        ),
                      ),

                      // Grid / Table Switcher
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MerchantTheme.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 19,
                                color: !_isTableView
                                    ? MerchantTheme.brandGreen
                                    : MerchantTheme.textMuted,
                              ),
                              tooltip: 'Cards View',
                              onPressed: () =>
                                  setState(() => _isTableView = false),
                              visualDensity: VisualDensity.compact,
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: MerchantTheme.cardBorder,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.table_rows_rounded,
                                size: 19,
                                color: _isTableView
                                    ? MerchantTheme.brandGreen
                                    : MerchantTheme.textMuted,
                              ),
                              tooltip: 'Table View',
                              onPressed: () =>
                                  setState(() => _isTableView = true),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      // Export Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: MerchantTheme.textDark,
                          side: const BorderSide(
                            color: MerchantTheme.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                          color: MerchantTheme.textMuted,
                        ),
                        label: const Text(
                          'Export',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _triggerExport(deals),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status Filter Pills ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                4,
                isWide ? 24 : 16,
                6,
              ),
              child: Row(
                children: [
                  ...List.generate(_statusFilters.length, (i) {
                    final key = _statusFilters[i];
                    final isSel = _statusFilter == key;
                    final count = key == 'all'
                        ? deals.length
                        : deals.where((d) => _bucketOf(d) == key).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (key == 'live') ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: MK.brand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(_statusLabels[i]),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSel ? MK.brand : MK.line,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSel
                                      ? Colors.white
                                      : MerchantTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: isSel,
                        selectedColor: MerchantTheme.brandTint,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSel
                                ? MerchantTheme.brandGreen
                                : MerchantTheme.cardBorder,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? MerchantTheme.brandDeepGreen
                              : MerchantTheme.textMuted,
                        ),
                        onSelected: (_) => setState(() => _statusFilter = key),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Main Content: Grid vs Table ──
            if (state.isLoadingMerchantDeals && deals.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: MerchantTheme.brandGreen,
                  ),
                ),
              )
            else if (deals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: MFeedbackBlock(
                  icon: Icons.storefront_outlined,
                  title: 'No surplus packs published yet',
                  message:
                      'Start rescuing food and turning potential kitchen loss into high-margin revenue. Publish your first pack in 60 seconds.',
                  actionLabel: 'Publish First Deal',
                  onAction: () => _compose(),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: MFeedbackBlock(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'No listings match criteria',
                  message:
                      'Try clearing your search query or choosing another category or status pill.',
                  actionLabel: 'Reset Filters',
                  onAction: () {
                    _search.clear();
                    setState(() {
                      _statusFilter = 'all';
                    });
                  },
                ),
              )
            else if (_isTableView)
              _buildTableView(filtered, isWide)
            else
              _buildGridView(filtered, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<FoodDeal> visible, bool isWide) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 6, isWide ? 24 : 16, 8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isWide ? 440 : 390,
        mainAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) => _ListingCard(
        deal: visible[i],
        bucket: _bucketOf(visible[i]),
        onEdit: () => _compose(visible[i]),
        onToggle: () => _toggle(visible[i], !visible[i].isActive),
        onRestock: () => _restock(visible[i]),
        onQuickAdjust: (delta) => _quickStockAdjust(visible[i], delta),
        onDuplicate: () => _duplicateDeal(visible[i]),
        onDelete: () => _delete(visible[i]),
      ),
    );
  }

  Widget _buildTableView(List<FoodDeal> visible, bool isWide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 6, isWide ? 24 : 16, 8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 720),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MerchantTheme.cardBorder),
          boxShadow: MerchantTheme.cardElevation,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DataTable(
            horizontalMargin: 16,
            columnSpacing: 20,
            headingRowHeight: 46,
            dataRowMaxHeight: 68,
            dataRowMinHeight: 64,
            headingRowColor: WidgetStateProperty.all(MK.surfaceAlt),
            columns: const [
              DataColumn(
                label: Text(
                  'Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Price',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Stock',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Pickup Window',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
            rows: visible.map((deal) {
              final bucket = _bucketOf(deal);
              final meta = _ListingCard._bucketMeta[bucket]!;

              return DataRow(
                cells: [
                  // Product Thumbnail & Title
                  DataCell(
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: MK.lineSoft,
                            child: deal.imageUrl.isNotEmpty
                                ? Image.network(
                                    deal.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, err, stack) => const Icon(
                                      Icons.restaurant_rounded,
                                      size: 20,
                                      color: MerchantTheme.brandGreen,
                                    ),
                                  )
                                : const Icon(
                                    Icons.restaurant_rounded,
                                    size: 20,
                                    color: MerchantTheme.brandGreen,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                deal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: MerchantTheme.textDark,
                                ),
                              ),
                              if (deal.description.isNotEmpty)
                                Text(
                                  deal.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MerchantTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: MK.lineSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${categoryEmoji(deal.category)} ${deal.category}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MerchantTheme.textDark,
                        ),
                      ),
                    ),
                  ),

                  // Price
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GHS ${deal.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: MerchantTheme.brandGreen,
                          ),
                        ),
                        Text(
                          'GHS ${deal.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: MerchantTheme.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stock with Quick Adjust Stepper
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                          color: MerchantTheme.textMuted,
                          onPressed: () => _quickStockAdjust(deal, -1),
                        ),
                        Text(
                          '${deal.quantityRemaining}/${deal.quantityTotal}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: meta.color,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                          color: MerchantTheme.brandGreen,
                          onPressed: () => _quickStockAdjust(deal, 1),
                        ),
                      ],
                    ),
                  ),

                  // Status
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meta.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: meta.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Pickup Window
                  DataCell(
                    Text(
                      deal.pickupWindow.isEmpty ? 'Not set' : deal.pickupWindow,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: MerchantTheme.textMuted,
                      ),
                    ),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: MerchantTheme.goldAccent,
                          ),
                          tooltip: 'Edit listing',
                          onPressed: () => _compose(deal),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: MerchantTheme.skyInfo,
                          ),
                          tooltip: 'Duplicate deal',
                          onPressed: () => _duplicateDeal(deal),
                        ),
                        IconButton(
                          icon: Icon(
                            deal.isActive
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 18,
                            color: deal.isActive
                                ? MerchantTheme.amberWarning
                                : MerchantTheme.brandGreen,
                          ),
                          tooltip: deal.isActive ? 'Pause' : 'Go Live',
                          onPressed: () => _toggle(deal, !deal.isActive),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: MerchantTheme.roseDanger,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _delete(deal),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Executive green hero command header (customer portal gradient) with live pulse, stats and quick action triggers.
class _SurplusHeroHeader extends StatelessWidget {
  final BusinessProfile business;
  final List<FoodDeal> deals;
  final VoidCallback onNewPack;
  final VoidCallback onQuickTemplates;
  final bool isWide;

  const _SurplusHeroHeader({
    required this.business,
    required this.deals,
    required this.onNewPack,
    required this.onQuickTemplates,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    int live = 0;
    int low = 0;
    int unitsLeft = 0;
    int rescued = 0;
    double rescuedValue = 0;

    for (final d in deals) {
      if (d.isActive && d.quantityRemaining > 0) {
        live++;
        if (d.quantityRemaining <= 2) low++;
      }
      unitsLeft += d.quantityRemaining;
      final packRescued = (d.quantityTotal - d.quantityRemaining);
      rescued += packRescued;
      rescuedValue += (packRescued * d.discountedPrice);
    }

    final heroDecoration = BoxDecoration(
      gradient: MK.heroGradient,
      borderRadius: BorderRadius.circular(MK.rHero),
      boxShadow: MK.brandShadow(),
    );

    // Phone: one compact bar so the listing grid keeps the screen.
    if (!isWide) {
      return Container(
        decoration: heroDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Surplus Inventory',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$live live · $low low stock · $unitsLeft units left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _HeroIconButton(
              icon: Icons.bolt_rounded,
              tooltip: 'Pack templates',
              onTap: onQuickTemplates,
            ),
            const SizedBox(width: 8),
            _HeroIconButton(
              icon: Icons.add_rounded,
              tooltip: 'New surplus pack',
              onTap: onNewPack,
              filled: true,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: heroDecoration,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Title, Live Beacon & Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(MK.rXs),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PulsingDot(),
                              SizedBox(width: 6),
                              Text(
                                'SURPLUS ENGINE ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Surplus Food Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Turn daily kitchen excess into immediate revenue & zero food waste.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MK.rSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                    icon: const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: MK.amber,
                    ),
                    label: const Text(
                      'Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: onQuickTemplates,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MK.brand,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MK.rSm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      '+ New Pack',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: onNewPack,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 12),

          // Bottom Metric Strip
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 620;
              final stats = [
                _HeroStatItem(
                  label: 'Live Packs',
                  value: '$live',
                  color: MK.brandTint,
                  icon: Icons.storefront_rounded,
                ),
                _HeroStatItem(
                  label: 'Low Stock',
                  value: '$low',
                  color: const Color(0xFFFFE082),
                  icon: Icons.warning_amber_rounded,
                ),
                _HeroStatItem(
                  label: 'Kitchen Stock',
                  value: '$unitsLeft',
                  color: const Color(0xFF93C5FD),
                  icon: Icons.inventory_2_outlined,
                ),
                _HeroStatItem(
                  label: 'Units Rescued',
                  value: '$rescued',
                  color: const Color(0xFFC8E6C9),
                  icon: Icons.eco_outlined,
                ),
                _HeroStatItem(
                  label: 'Value Saved',
                  value: 'GHS ${rescuedValue.toStringAsFixed(0)}',
                  color: MK.goldTint,
                  icon: Icons.savings_outlined,
                ),
              ];

              if (isNarrow) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats
                      .map(
                        (s) => SizedBox(width: (c.maxWidth - 8) / 2, child: s),
                      )
                      .toList(),
                );
              }

              return Row(
                children: stats.map((s) => Expanded(child: s)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: MPressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(MK.rSm),
          border: filled ? null : Border.all(color: Colors.white38),
        ),
        child: Icon(icon, size: 19, color: filled ? MK.brand : Colors.white),
      ),
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3 + 0.6 * _ctrl.value),
              blurRadius: 4 + 4 * _ctrl.value,
              spreadRadius: 1 * _ctrl.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeroStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Redesigned Surplus Pack Card with inline Stock Stepper (+ / -), high-def imagery, price calculations, and toolbar.
class _ListingCard extends StatelessWidget {
  final FoodDeal deal;
  final String bucket;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onRestock;
  final ValueChanged<int> onQuickAdjust;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ListingCard({
    required this.deal,
    required this.bucket,
    required this.onEdit,
    required this.onToggle,
    required this.onRestock,
    required this.onQuickAdjust,
    required this.onDuplicate,
    required this.onDelete,
  });

  static const _bucketMeta = {
    'live': (label: 'LIVE', color: MerchantTheme.brandGreen),
    'paused': (label: 'PAUSED', color: MerchantTheme.textMuted),
    'low': (label: 'LOW STOCK', color: MerchantTheme.amberWarning),
    'soldout': (label: 'SOLD OUT', color: MerchantTheme.roseDanger),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _bucketMeta[bucket]!;
    final pct = deal.originalPrice > 0
        ? (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) *
                  100)
              .round()
        : 0;
    final sold = deal.quantityTotal - deal.quantityRemaining;
    final fill = deal.quantityTotal == 0
        ? 0.0
        : (deal.quantityRemaining / deal.quantityTotal).clamp(0.0, 1.0);
    final savings = (deal.originalPrice - deal.discountedPrice).clamp(
      0.0,
      9999.0,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deal.isActive ? MerchantTheme.cardBorder : MK.line,
          width: 1.1,
        ),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Image, Title, Category Pill, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  height: 54,
                  color: MK.lineSoft,
                  child: deal.imageUrl.isNotEmpty
                      ? Image.network(
                          deal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) => const Icon(
                            Icons.restaurant_rounded,
                            size: 24,
                            color: MerchantTheme.brandGreen,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant_rounded,
                          size: 24,
                          color: MerchantTheme.brandGreen,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: MerchantTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${categoryEmoji(deal.category)} ${deal.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: MerchantTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (pct > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: MerchantTheme.goldLightBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '-$pct%',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: MerchantTheme.goldAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  meta.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: meta.color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Price Comparison & Quick Stock Stepper
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'GHS ${deal.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: MerchantTheme.brandGreen,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'GHS ${deal.originalPrice.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MerchantTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (savings > 0)
                      Text(
                        'Save GHS ${savings.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: MK.brandGlow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Quick Stepper (- / +)
              Container(
                decoration: BoxDecoration(
                  color: MK.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MerchantTheme.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onQuickAdjust(-1),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 15,
                          color: MerchantTheme.textMuted,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${deal.quantityRemaining}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: meta.color,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => onQuickAdjust(1),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: MerchantTheme.brandGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(height: 6, color: MK.lineSoft),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: c.maxWidth * fill,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [meta.color.withValues(alpha: 0.7), meta.color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Pickup window & units sold
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: MerchantTheme.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  deal.pickupWindow.isEmpty
                      ? 'Pickup window not set'
                      : deal.pickupWindow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: MerchantTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (sold > 0)
                Text(
                  '$sold rescued',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: MerchantTheme.brandGreen,
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Action Toolbar
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: MerchantTheme.goldAccent,
                ),
                tooltip: 'Edit listing',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: MerchantTheme.skyInfo,
                ),
                tooltip: 'Duplicate deal',
                onPressed: onDuplicate,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_box_outlined,
                  size: 17,
                  color: MerchantTheme.amberWarning,
                ),
                tooltip: 'Restock units',
                onPressed: onRestock,
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              // Toggle live / pause
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deal.isActive
                        ? MK.lineSoft
                        : MerchantTheme.brandGreen,
                    foregroundColor: deal.isActive
                        ? MerchantTheme.textDark
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: Icon(
                    deal.isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 14,
                  ),
                  label: Text(
                    deal.isActive ? 'Pause' : 'Go Live',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onToggle,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: MerchantTheme.roseDanger,
                ),
                tooltip: 'Delete listing',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Curated high-resolution stock photography presets for instant, frictionless listing creation.
typedef CuratedPhotoPreset = ({String title, String category, String url, String emoji});

const List<CuratedPhotoPreset> kCuratedPhotoPresets = [
  (
    title: 'Bakery & Pastries',
    category: 'Bakery',
    url:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80',
    emoji: '🥐',
  ),
  (
    title: 'Hot Kitchen Meal',
    category: 'Restaurant Meal',
    url:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80',
    emoji: '🍲',
  ),
  (
    title: 'Farm Fresh Produce',
    category: 'Produce',
    url:
        'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=800&auto=format&fit=crop&q=80',
    emoji: '🥗',
  ),
  (
    title: 'Desserts & Cakes',
    category: 'Desserts',
    url:
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=80',
    emoji: '🍰',
  ),
];

/// Redesigned Deal Form Bottom Sheet with Live Economics breakdown, Photo Presets, and robust fallback.
class _DealForm extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final FoodDeal? existing;
  final Map<String, dynamic>? presetTemplate;

  const _DealForm({required this.business, this.existing, this.presetTemplate});

  @override
  ConsumerState<_DealForm> createState() => _DealFormState();
}

class _DealFormState extends ConsumerState<_DealForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: widget.existing?.title ?? widget.presetTemplate?['title'] ?? '',
  );
  late final _desc = TextEditingController(
    text:
        widget.existing?.description ??
        widget.presetTemplate?['description'] ??
        '',
  );
  late final _orig = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.originalPrice.toStringAsFixed(0)
        : (widget.presetTemplate?['originalPrice']?.toString() ?? ''),
  );
  late final _disc = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.discountedPrice.toStringAsFixed(0)
        : (widget.presetTemplate?['discountedPrice']?.toString() ?? ''),
  );
  late final _window = TextEditingController(
    text:
        widget.existing?.pickupWindow ??
        widget.presetTemplate?['pickupWindow'] ??
        '',
  );
  late final _qty = TextEditingController(
    text: widget.existing != null
        ? '${widget.existing!.quantityTotal}'
        : (widget.presetTemplate?['quantity']?.toString() ?? ''),
  );
  late String _category =
      widget.existing != null &&
          kDealCategories.contains(widget.existing!.category)
      ? widget.existing!.category
      : (widget.presetTemplate?['category'] ?? '');

  Uint8List? _bytes;
  String _selectedPresetUrl = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existing?.imageUrl.isNotEmpty == true) {
      _selectedPresetUrl = widget.existing!.imageUrl;
    } else if (widget.presetTemplate?['imageUrl'] != null) {
      _selectedPresetUrl = widget.presetTemplate!['imageUrl'];
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _orig.dispose();
    _disc.dispose();
    _window.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _bytes = bytes;
      });
    }
  }

  Future<void> _pickPresetPhoto() async {
    final chosen = await _showUberPicker<CuratedPhotoPreset>(
      context: context,
      title: 'Select Photo Preset',
      items: kCuratedPhotoPresets,
      selectedItem: kCuratedPhotoPresets.any((p) => p.url == _selectedPresetUrl)
          ? kCuratedPhotoPresets.firstWhere((p) => p.url == _selectedPresetUrl)
          : null,
      labelOf: (p) => '${p.emoji} ${p.title}',
      subtitleOf: (p) => p.category,
      leadingOf: (p) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          p.url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 44,
            height: 44,
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: Text(p.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
      isSelected: (item, current) => current != null && item.url == current.url,
    );

    if (chosen != null) {
      setState(() {
        _bytes = null;
        _selectedPresetUrl = chosen.url;
        if (_category.isEmpty) {
          _category = chosen.category;
        }
      });
    }
  }

  Future<void> _pickCategory() async {
    final chosen = await _showUberPicker<String>(
      context: context,
      title: 'Select Category',
      items: kDealCategories,
      selectedItem: _category.isNotEmpty ? _category : null,
      labelOf: (c) => c,
      leadingOf: (c) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(categoryEmoji(c), style: const TextStyle(fontSize: 18)),
      ),
      isSelected: (item, current) => item == current,
    );

    if (chosen != null) {
      setState(() => _category = chosen);
    }
  }

  Future<void> _pickPickupWindow() async {
    const timeOptions = [
      'Today 16:00 – 18:00 (Afternoon rush)',
      'Today 17:30 – 19:30 (Dinner time)',
      'Today 18:00 – 20:00 (Evening rush)',
      'Today 19:00 – 21:00 (Late dinner)',
      'Tonight 20:00 – 21:30 (Closing rush)',
      'Tonight 21:00 – 22:30 (Night closing)',
      'Tomorrow 08:30 – 10:30 (Morning rescue)',
      'Tomorrow 11:30 – 13:30 (Lunch pickup)',
      'Tomorrow 14:00 – 16:00 (Afternoon pickup)',
      'Tomorrow 17:30 – 19:30 (Evening pickup)',
      'Custom time window…',
    ];

    final chosen = await _showUberPicker<String>(
      context: context,
      title: 'Select Pickup Window',
      items: timeOptions,
      selectedItem: timeOptions.firstWhere(
        (t) => t.startsWith(_window.text) && _window.text.isNotEmpty,
        orElse: () => _window.text.isNotEmpty ? 'Custom time window…' : '',
      ),
      labelOf: (t) => t.contains(' (') ? t.split(' (').first : t,
      subtitleOf: (t) => t.contains(' (') ? t.split(' (').last.replaceAll(')', '') : null,
      leadingOf: (t) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          t.startsWith('Custom') ? Icons.edit_calendar_outlined : Icons.schedule_rounded,
          size: 18,
          color: MerchantTheme.brandDeepGreen,
        ),
      ),
      isSelected: (item, current) =>
          item == current || (_window.text.isNotEmpty && item.startsWith(_window.text)),
    );

    if (chosen != null) {
      if (chosen.startsWith('Custom')) {
        final custom = await _showCustomInputDialog(
          title: 'Custom Pickup Window',
          hint: 'e.g. Today 15:00 – 17:00',
          current: _window.text,
        );
        if (custom != null && custom.isNotEmpty) {
          setState(() => _window.text = custom);
        }
      } else {
        final clean = chosen.contains(' (') ? chosen.split(' (').first : chosen;
        setState(() => _window.text = clean);
      }
    }
  }

  Future<void> _pickUnitsAvailable() async {
    final qtyOptions = [
      1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 75, 100, -1,
    ];

    final currentQty = int.tryParse(_qty.text.trim());

    final chosen = await _showUberPicker<int>(
      context: context,
      title: 'Select Units Available',
      items: qtyOptions,
      selectedItem: currentQty,
      labelOf: (q) => q == -1 ? 'Custom quantity…' : '$q ${q == 1 ? "pack" : "packs"}',
      subtitleOf: (q) => q == -1
          ? 'Enter specific surplus count'
          : (q <= 3 ? 'Small batch' : (q <= 10 ? 'Popular standard size' : 'Bulk surplus batch')),
      leadingOf: (q) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          q == -1 ? Icons.dialpad_rounded : Icons.inventory_2_outlined,
          size: 18,
          color: MerchantTheme.brandDeepGreen,
        ),
      ),
      isSelected: (item, current) {
        if (item == -1) return current != null && !qtyOptions.contains(current);
        return item == current;
      },
    );

    if (chosen != null) {
      if (chosen == -1) {
        final custom = await _showCustomInputDialog(
          title: 'Custom Units Available',
          hint: 'e.g. 18',
          current: _qty.text,
          keyboardType: TextInputType.number,
        );
        if (custom != null && int.tryParse(custom) != null) {
          setState(() => _qty.text = custom);
        }
      } else {
        setState(() => _qty.text = '$chosen');
      }
    }
  }

  Future<String?> _showCustomInputDialog({
    required String title,
    required String hint,
    String current = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: MerchantTheme.brandGreen, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MerchantTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantTheme.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_category.trim().isEmpty) {
      setState(() => _error = 'Please select a category for this surplus pack');
      return;
    }
    if (_window.text.trim().isEmpty) {
      setState(() => _error = 'Please select a pickup time window');
      return;
    }
    if (_qty.text.trim().isEmpty) {
      setState(() => _error = 'Please select the number of units available');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      String finalImageUrl = _selectedPresetUrl;

      // Upload if bytes picked, with graceful fallback to preset if storage fails
      if (_bytes != null) {
        try {
          final uploaded = await SupabaseService().uploadImage(
            bucket: 'uploads',
            path:
                '${widget.business.id}/deal_${DateTime.now().millisecondsSinceEpoch}.jpg',
            fileBytes: _bytes!,
          );
          if (uploaded.isNotEmpty) finalImageUrl = uploaded;
        } catch (_) {
          // Graceful fallback to category preset image
          if (finalImageUrl.isEmpty) {
            finalImageUrl = kCuratedPhotoPresets
                .firstWhere(
                  (p) => p.category == _category,
                  orElse: () => kCuratedPhotoPresets.first,
                )
                .url;
          }
        }
      }

      if (finalImageUrl.isEmpty) {
        finalImageUrl = kCuratedPhotoPresets
            .firstWhere(
              (p) => p.category == _category,
              orElse: () => kCuratedPhotoPresets.first,
            )
            .url;
      }

      final notifier = ref.read(appStateProvider.notifier);
      final original = double.parse(_orig.text.trim());
      final discounted = double.parse(_disc.text.trim());
      final totalQty = int.parse(_qty.text.trim());

      if (widget.existing == null) {
        await notifier.addDeal(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          originalPrice: original,
          discountedPrice: discounted,
          pickupWindow: _window.text.trim(),
          quantity: totalQty,
          imageUrl: finalImageUrl,
        );
      } else {
        await notifier.updateDeal(
          dealId: widget.existing!.id,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          originalPrice: original,
          discountedPrice: discounted,
          pickupWindow: _window.text.trim(),
          quantity: totalQty,
          imageUrl: finalImageUrl,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      MToast.ok(
        context,
        widget.existing == null
            ? '“${_title.text.trim()}” is now live'
            : 'Listing updated',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  InputDecoration _field(
    String label, {
    String? hint,
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 19, color: MerchantTheme.textMuted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: MerchantTheme.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: MerchantTheme.brandGreen, width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  @override
  Widget build(BuildContext context) {
    final orig = double.tryParse(_orig.text.trim()) ?? 0;
    final disc = double.tryParse(_disc.text.trim()) ?? 0;
    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final pct = orig > 0 && disc > 0 && disc < orig
        ? (((orig - disc) / orig) * 100).round()
        : 0;
    final savingsPerPack = (orig - disc).clamp(0.0, 9999.0);
    final commissionRate = ref.watch(appStateProvider).commissionRate;
    final merchantNetPerPack = (disc * (1 - commissionRate)).clamp(0.0, 9999.0);
    final totalNetRevenue = merchantNetPerPack * qty;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Photo Selection & Quick Photo Presets ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: MK.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MerchantTheme.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _bytes != null
                    ? Image.memory(_bytes!, fit: BoxFit.cover)
                    : (_selectedPresetUrl.isNotEmpty
                          ? Image.network(
                              _selectedPresetUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const _PhotoPlaceholder(),
                            )
                          : const _PhotoPlaceholder()),
              ),
            ),
          ),
          const SizedBox(height: 8),

          _UberDropdown(
            label: 'PHOTO QUICK PRESET',
            hint: 'Choose a photo preset or leave custom',
            icon: Icons.auto_awesome_rounded,
            value: _selectedPresetUrl.isNotEmpty
                ? (kCuratedPhotoPresets.any((p) => p.url == _selectedPresetUrl)
                    ? '${kCuratedPhotoPresets.firstWhere((p) => p.url == _selectedPresetUrl).emoji} ${kCuratedPhotoPresets.firstWhere((p) => p.url == _selectedPresetUrl).title}'
                    : 'Preset photo selected')
                : null,
            onTap: _pickPresetPhoto,
          ),

          const SizedBox(height: 16),
          const _FormLabel('PACK TITLE'),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field(
              'e.g. Pastry & Sourdough Surplus Box',
              icon: Icons.restaurant_rounded,
            ),
            validator: (v) => (v == null || v.trim().length < 4)
                ? 'Give the pack a descriptive title'
                : null,
          ),

          const SizedBox(height: 14),
          const _FormLabel('DESCRIPTION & PORTIONS'),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field(
              'Freshness, ingredients, portions, allergy advisories…',
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Describe the contents (10+ characters)'
                : null,
          ),

          const SizedBox(height: 14),
          _UberDropdown(
            label: 'CATEGORY',
            hint: 'Select category',
            icon: Icons.category_outlined,
            value: _category.isNotEmpty ? '${categoryEmoji(_category)} $_category' : null,
            hasError: _category.isEmpty && _error != null,
            errorText: _category.isEmpty ? 'Category is required' : null,
            onTap: _pickCategory,
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FormLabel('REGULAR VALUE'),
                    TextFormField(
                      controller: _orig,
                      keyboardType: TextInputType.number,
                      decoration: _field('GHS 0.00', icon: Icons.sell_outlined),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0)
                            ? 'Enter regular value'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FormLabel('RESCUE PRICE'),
                    TextFormField(
                      controller: _disc,
                      keyboardType: TextInputType.number,
                      decoration: _field(
                        'GHS 0.00',
                        icon: Icons.local_offer_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Enter rescue price';
                        final o = double.tryParse(_orig.text.trim()) ?? 0;
                        if (o > 0 && n >= o)
                          return 'Must be below regular value';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Real-Time Economics Breakdown Ribbon ──
          if (disc > 0 && orig > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MK.brandTint,
                borderRadius: BorderRadius.circular(MK.rSm),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 16,
                        color: MK.brandGlow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pct% DISCOUNT · Rescuer saves GHS ${savingsPerPack.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: MK.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Payout / Pack: GHS ${merchantNetPerPack.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MK.brandDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Batch Total: GHS ${totalNetRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MK.brandDeep,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          _UberDropdown(
            label: 'PICKUP WINDOW',
            hint: 'Select pickup time window',
            icon: Icons.schedule_rounded,
            value: _window.text.isNotEmpty ? _window.text : null,
            hasError: _window.text.isEmpty && _error != null,
            errorText: _window.text.isEmpty ? 'Pickup window is required' : null,
            onTap: _pickPickupWindow,
          ),

          const SizedBox(height: 14),
          _UberDropdown(
            label: 'UNITS AVAILABLE IN SURPLUS',
            hint: 'Select available packs',
            icon: Icons.inventory_2_outlined,
            value: _qty.text.isNotEmpty
                ? '${_qty.text} ${_qty.text == "1" ? "pack" : "packs"} available'
                : null,
            hasError: _qty.text.isEmpty && _error != null,
            errorText: _qty.text.isEmpty ? 'Units available is required' : null,
            onTap: _pickUnitsAvailable,
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: MerchantTheme.roseDanger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: MerchantTheme.roseDanger,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: MerchantTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantTheme.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    widget.existing == null
                        ? 'Publish Surplus Pack'
                        : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _busy ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UberDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData? icon;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorText;

  const _UberDropdown({
    required this.label,
    required this.hint,
    required this.onTap,
    this.value,
    this.icon,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasVal = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormLabel(label),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? MerchantTheme.roseDanger
                      : (hasVal
                          ? MerchantTheme.brandGreen.withValues(alpha: 0.6)
                          : MerchantTheme.cardBorder),
                  width: hasVal ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: hasVal
                          ? MerchantTheme.brandDeepGreen
                          : MerchantTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      hasVal ? value! : hint,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                        color: hasVal
                            ? MerchantTheme.textDark
                            : MerchantTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 11,
                color: MerchantTheme.roseDanger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<T?> _showUberPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required T? selectedItem,
  required String Function(T) labelOf,
  Widget Function(T)? leadingOf,
  String? Function(T)? subtitleOf,
  bool Function(T item, T? current)? isSelected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF8FAFC),
                  ),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final sel = isSelected != null
                        ? isSelected(item, selectedItem)
                        : item == selectedItem;
                    final leading = leadingOf?.call(item);
                    final sub = subtitleOf?.call(item);

                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx, item);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        color: sel
                            ? MerchantTheme.brandTint.withValues(alpha: 0.35)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            if (leading != null) ...[
                              leading,
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    labelOf(item),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          sel ? FontWeight.w800 : FontWeight.w600,
                                      color: sel
                                          ? MerchantTheme.brandDeepGreen
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (sub != null && sub.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      sub,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (sel)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: MerchantTheme.brandGreen,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Instant 1-tap quick template sheet for common surplus packs.
class _QuickTemplatesSheet extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _QuickTemplatesSheet({required this.onSelect});

  static const _templates = [
    {
      'title': 'Bakery Surprise Mystery Bag',
      'description':
          'Assorted fresh artisanal sourdough, butter croissants, baguettes & daily rolls baked this morning.',
      'category': 'Bakery',
      'originalPrice': 75.0,
      'discountedPrice': 28.0,
      'quantity': 6,
      'pickupWindow': 'Today 17:00 – 19:30',
      'imageUrl':
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80',
      'icon': '🥐',
    },
    {
      'title': "Chef's Hot Dinner Surplus Box",
      'description':
          "Generous portions of today's hot kitchen specials, gourmet sides, proteins and sauces packed fresh.",
      'category': 'Restaurant Meal',
      'originalPrice': 110.0,
      'discountedPrice': 48.0,
      'quantity': 8,
      'pickupWindow': 'Tonight 20:30 – 22:00',
      'imageUrl':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80',
      'icon': '🍲',
    },
    {
      'title': 'Farm Fresh Market Produce Basket',
      'description':
          'Crisp organic seasonal fruits, leafy greens, root vegetables and herbs directly from our pantry.',
      'category': 'Produce',
      'originalPrice': 60.0,
      'discountedPrice': 25.0,
      'quantity': 5,
      'pickupWindow': 'Today 16:00 – 18:30',
      'imageUrl':
          'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=800&auto=format&fit=crop&q=80',
      'icon': '🥗',
    },
    {
      'title': 'Gourmet Pastry & Cafe Delights',
      'description':
          'Slices of artisan cakes, sweet tarts, cookies and afternoon bakery treats from the counter.',
      'category': 'Desserts',
      'originalPrice': 55.0,
      'discountedPrice': 22.0,
      'quantity': 10,
      'pickupWindow': 'Today 18:00 – 20:00',
      'imageUrl':
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=80',
      'icon': '🍰',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MK.inkFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: MK.amber, size: 22),
              SizedBox(width: 8),
              Text(
                '1-Tap Surplus Pack Templates',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: MerchantTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a template to prefill prices, descriptions, and high-converting photos instantly.',
            style: TextStyle(fontSize: 12, color: MerchantTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ..._templates.map(
            (tpl) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: MK.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(tpl),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            tpl['imageUrl'] as String,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tpl['title'] as String,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: MerchantTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tpl['category']} · ${tpl['quantity']} units · ${tpl['pickupWindow']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: MerchantTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'GHS ${(tpl['discountedPrice'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: MerchantTheme.brandGreen,
                              ),
                            ),
                            Text(
                              'GHS ${(tpl['originalPrice'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: MerchantTheme.textMuted,
                                decoration: TextDecoration.lineThrough,
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
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.add_a_photo_outlined,
        size: 28,
        color: MerchantTheme.brandGreen,
      ),
      const SizedBox(height: 8),
      const Text(
        'Tap to upload dish photo or pick preset below',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: MerchantTheme.textMuted,
        ),
      ),
    ],
  );
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        color: MerchantTheme.textMuted,
        letterSpacing: 0.9,
      ),
    ),
  );
}

/// Small numeric prompt used by restock.
Future<String?> askNumber(
  BuildContext context, {
  required String title,
  required String hint,
  required String initial,
  String? Function(String)? validate,
}) async {
  final ctrl = TextEditingController(text: initial);
  String? error;
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDlg) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: MerchantTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: hint,
                errorText: error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setDlg(() => error = null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantTheme.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final msg = validate?.call(ctrl.text);
              if (msg != null) {
                setDlg(() => error = msg);
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text(
              'Save Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
