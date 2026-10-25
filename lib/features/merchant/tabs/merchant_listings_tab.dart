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

  const MerchantListingsTab({super.key, required this.business, this.composeNew = false});

  @override
  ConsumerState<MerchantListingsTab> createState() => _MerchantListingsTabState();
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
  static const _statusFilters = ['all', 'live', 'low', 'paused', 'soldout'];
  static const _statusLabels = ['All Items', 'Live & Selling', 'Low Stock', 'Paused', 'Sold Out'];

  String _statusFilter = 'all';
  String _categoryFilter = 'all';
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

  Future<void> _compose([FoodDeal? existing]) async {
    if (!widget.business.isApproved) {
      await showMResult(
        context,
        title: 'Verification In Review',
        message:
            'Your shop application is currently in review by compliance. You cannot publish surplus packs until your business documents are approved.',
        ok: false,
        actionLabel: 'Got it',
      );
      return;
    }
    await showMSheet<void>(
      context,
      title: existing == null ? 'Publish a Surplus Pack' : 'Edit Listing',
      maxWidth: 640,
      child: _DealForm(business: widget.business, existing: existing),
    );
  }

  Future<void> _toggle(FoodDeal deal, bool activate) async {
    if (activate && !widget.business.isApproved) {
      if (mounted) MToast.err(context, 'Cannot activate listing: Shop is awaiting admin verification.');
      return;
    }
    try {
      await ref.read(appStateProvider.notifier).toggleDealStatus(deal.id, activate);
      if (mounted) {
        MToast.ok(context, '“${deal.title}” is now ${activate ? 'live and discoverable' : 'paused'}');
      }
    } catch (e) {
      if (mounted) MToast.err(context, 'Could not update: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _quickStockAdjust(FoodDeal deal, int delta) async {
    final newRemaining = (deal.quantityRemaining + delta).clamp(0, 999);
    final newTotal = (deal.quantityTotal + (delta > 0 ? delta : 0)).clamp(newRemaining, 999);
    if (newRemaining == deal.quantityRemaining) return;

    HapticFeedback.lightImpact();
    try {
      await ref.read(appStateProvider.notifier).updateDeal(
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
        MToast.ok(context, 'Updated ${deal.title}: $newRemaining units available');
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
        if (n < deal.quantityTotal - deal.quantityRemaining) return 'Total cannot be below units already sold';
        return null;
      },
    );
    if (qty == null) return;
    try {
      await ref.read(appStateProvider.notifier).updateDeal(
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
      if (mounted) MToast.ok(context, 'Stock updated to $qty units · visible immediately');
    } catch (e) {
      if (mounted) MToast.err(context, 'Restock failed: ${e.toString().replaceFirst('Exception: ', '')}');
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
                decoration: BoxDecoration(
                  color: MerchantTheme.roseLightBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 28, color: MerchantTheme.roseDanger),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete this listing?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MerchantTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                '“${deal.title}” will immediately be removed from consumer discovery. Existing orders for this item will remain accessible in your Orders tab.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: MerchantTheme.textMuted, height: 1.45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep Listing', style: TextStyle(color: MerchantTheme.textDark, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MerchantTheme.roseDanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
      if (mounted) MToast.err(context, 'Delete failed: ${e.toString().replaceFirst('Exception: ', '')}');
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
      final matchesStatus = _statusFilter == 'all' || _bucketOf(d) == _statusFilter;
      final matchesCategory = _categoryFilter == 'all' || d.category == _categoryFilter;
      final matchesQuery = q.isEmpty ||
          d.title.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q);
      return matchesStatus && matchesCategory && matchesQuery;
    }).toList();

    // Sort
    switch (_sort) {
      case _ListingSort.recent:
        filtered.sort((a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0));
        break;
      case _ListingSort.priceAsc:
        filtered.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case _ListingSort.priceDesc:
        filtered.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case _ListingSort.stockAsc:
        filtered.sort((a, b) => a.quantityRemaining.compareTo(b.quantityRemaining));
        break;
      case _ListingSort.stockDesc:
        filtered.sort((a, b) => b.quantityRemaining.compareTo(a.quantityRemaining));
        break;
      case _ListingSort.discountDesc:
        filtered.sort((a, b) => b.percentageSaved.compareTo(a.percentageSaved));
        break;
    }

    final isWide = useSideNav(context);

    return ResponsiveCenter(
      maxWidth: 1320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── KPI Summary Cards Ribbon ──
          if (deals.isNotEmpty)
            _ListingsKpiRibbon(deals: deals),

          // ── Header & Action Controls Bar ──
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 14, isWide ? 24 : 16, 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Input
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 380 : double.infinity),
                  child: MSearchField(
                    controller: _search,
                    hint: 'Search by title, ingredients, category…',
                    onChanged: (_) => setState(() {}),
                    onClear: _search.text.isEmpty
                        ? null
                        : () {
                            _search.clear();
                            setState(() {});
                          },
                  ),
                ),

                // Actions: Sort, Grid/Table Toggle, Export, Add Deal
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MerchantTheme.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_ListingSort>(
                          value: _sort,
                          icon: const Icon(Icons.sort_rounded, size: 18, color: MerchantTheme.textMuted),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MerchantTheme.textDark),
                          items: const [
                            DropdownMenuItem(value: _ListingSort.recent, child: Text('Sort: Default')),
                            DropdownMenuItem(value: _ListingSort.priceAsc, child: Text('Price: Low to High')),
                            DropdownMenuItem(value: _ListingSort.priceDesc, child: Text('Price: High to Low')),
                            DropdownMenuItem(value: _ListingSort.stockAsc, child: Text('Stock: Lowest First')),
                            DropdownMenuItem(value: _ListingSort.stockDesc, child: Text('Stock: Highest First')),
                            DropdownMenuItem(value: _ListingSort.discountDesc, child: Text('Discount: High to Low')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _sort = v);
                          },
                        ),
                      ),
                    ),

                    // Grid / Table View Switcher
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
                              color: !_isTableView ? MerchantTheme.emeraldPrimary : MerchantTheme.textMuted,
                            ),
                            tooltip: 'Cards View',
                            onPressed: () => setState(() => _isTableView = false),
                            visualDensity: VisualDensity.compact,
                          ),
                          Container(width: 1, height: 20, color: MerchantTheme.cardBorder),
                          IconButton(
                            icon: Icon(
                              Icons.table_rows_rounded,
                              size: 19,
                              color: _isTableView ? MerchantTheme.emeraldPrimary : MerchantTheme.textMuted,
                            ),
                            tooltip: 'Table View',
                            onPressed: () => setState(() => _isTableView = true),
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
                        side: const BorderSide(color: MerchantTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 17, color: MerchantTheme.skyInfo),
                      label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: deals.isEmpty ? null : () => _triggerExport(deals),
                    ),

                    // New Deal CTA
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MerchantTheme.emeraldPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ New Pack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _compose(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Filter Chips Strip ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 4),
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
                          Text(_statusLabels[i]),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSel ? MerchantTheme.emeraldPrimary : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : MerchantTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: isSel,
                      selectedColor: MerchantTheme.emeraldLightBg,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSel ? MerchantTheme.emeraldPrimary : MerchantTheme.cardBorder,
                        ),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? MerchantTheme.emeraldDeep : MerchantTheme.textMuted,
                      ),
                      onSelected: (_) => setState(() => _statusFilter = key),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Main Content: Grid vs Table ──
          Expanded(
            child: RefreshIndicator(
              color: MerchantTheme.emeraldPrimary,
              onRefresh: () => notifier.loadMerchantDeals(),
              child: state.isLoadingMerchantDeals && deals.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: MerchantTheme.emeraldPrimary))
                  : deals.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          children: [
                            MFeedbackBlock(
                              icon: Icons.storefront_outlined,
                              title: 'No surplus packs published yet',
                              message:
                                  'Start rescuing food and turning potential loss into revenue. Create your first rescue bag in under 2 minutes.',
                              actionLabel: 'Publish First Deal',
                              onAction: () => _compose(),
                            ),
                          ],
                        )
                      : filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                              children: [
                                MFeedbackBlock(
                                  icon: Icons.filter_alt_off_rounded,
                                  title: 'No listings match criteria',
                                  message: 'Try clearing your search query or choosing another status tab.',
                                  actionLabel: 'Reset Filters',
                                  onAction: () {
                                    _search.clear();
                                    setState(() {
                                      _statusFilter = 'all';
                                      _categoryFilter = 'all';
                                    });
                                  },
                                ),
                              ],
                            )
                          : _isTableView
                              ? _buildTableView(filtered, isWide)
                              : _buildGridView(filtered, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<FoodDeal> visible, bool isWide) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 6, isWide ? 24 : 16, 32),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isWide ? 440 : 380,
        mainAxisExtent: 265,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 6, isWide ? 24 : 16, 32),
      child: Container(
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
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Pickup Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                            color: const Color(0xFFF1F5F9),
                            child: deal.imageUrl.isNotEmpty
                                ? Image.network(
                                    deal.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, err, stack) => const Icon(Icons.restaurant_rounded, size: 20, color: MerchantTheme.emeraldPrimary),
                                  )
                                : const Icon(Icons.restaurant_rounded, size: 20, color: MerchantTheme.emeraldPrimary),
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
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: MerchantTheme.textDark),
                              ),
                              if (deal.description.isNotEmpty)
                                Text(
                                  deal.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: MerchantTheme.textMuted),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${categoryEmoji(deal.category)} ${deal.category}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MerchantTheme.textDark),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: MerchantTheme.emeraldPrimary),
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

                  // Stock with Quick Adjust
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
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
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          visualDensity: VisualDensity.compact,
                          color: MerchantTheme.emeraldPrimary,
                          onPressed: () => _quickStockAdjust(deal, 1),
                        ),
                      ],
                    ),
                  ),

                  // Status
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      style: const TextStyle(fontSize: 11.5, color: MerchantTheme.textMuted),
                    ),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17, color: MerchantTheme.violetAccent),
                          tooltip: 'Edit listing',
                          onPressed: () => _compose(deal),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: MerchantTheme.skyInfo),
                          tooltip: 'Duplicate deal',
                          onPressed: () => _duplicateDeal(deal),
                        ),
                        IconButton(
                          icon: Icon(
                            deal.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                            size: 18,
                            color: deal.isActive ? MerchantTheme.amberWarning : MerchantTheme.emeraldPrimary,
                          ),
                          tooltip: deal.isActive ? 'Pause' : 'Go Live',
                          onPressed: () => _toggle(deal, !deal.isActive),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: MerchantTheme.roseDanger),
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

class _ListingsKpiRibbon extends StatelessWidget {
  final List<FoodDeal> deals;
  const _ListingsKpiRibbon({required this.deals});

  @override
  Widget build(BuildContext context) {
    int live = 0;
    int paused = 0;
    int low = 0;
    int soldOut = 0;
    int totalUnits = 0;
    int rescuedUnits = 0;

    for (final d in deals) {
      if (!d.isActive) {
        paused++;
      } else if (d.quantityRemaining == 0) {
        soldOut++;
      } else if (d.quantityRemaining <= 2) {
        low++;
        live++;
      } else {
        live++;
      }
      totalUnits += d.quantityRemaining;
      rescuedUnits += (d.quantityTotal - d.quantityRemaining);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final items = [
          _RibbonItem(label: 'Live Deals', value: '$live', color: MerchantTheme.emeraldPrimary, icon: Icons.fiber_manual_record_rounded),
          _RibbonItem(label: 'Low Stock', value: '$low', color: MerchantTheme.amberWarning, icon: Icons.warning_amber_rounded),
          _RibbonItem(label: 'Paused', value: '$paused', color: MerchantTheme.textMuted, icon: Icons.pause_circle_outline_rounded),
          _RibbonItem(label: 'Sold Out', value: '$soldOut', color: MerchantTheme.roseDanger, icon: Icons.remove_circle_outline_rounded),
          _RibbonItem(label: 'Stock Left', value: '$totalUnits', color: MerchantTheme.skyInfo, icon: Icons.inventory_2_outlined),
          _RibbonItem(label: 'Units Rescued', value: '$rescuedUnits', color: MerchantTheme.violetAccent, icon: Icons.eco_outlined),
        ];

        if (isCompact) {
          const gap = 8.0;
          final itemW = (constraints.maxWidth - 32 - gap) / 2;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items.map((item) => SizedBox(width: itemW, child: item)).toList(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: item,
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _RibbonItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RibbonItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MerchantTheme.cardBorder),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: MerchantTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: MerchantTheme.textMuted,
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
    'live': (label: 'LIVE', color: MerchantTheme.emeraldPrimary),
    'paused': (label: 'PAUSED', color: MerchantTheme.textMuted),
    'low': (label: 'LOW STOCK', color: MerchantTheme.amberWarning),
    'soldout': (label: 'SOLD OUT', color: MerchantTheme.roseDanger),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _bucketMeta[bucket]!;
    final pct = deal.originalPrice > 0
        ? (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) * 100).round()
        : 0;
    final sold = deal.quantityTotal - deal.quantityRemaining;
    final fill = deal.quantityTotal == 0 ? 0.0 : (deal.quantityRemaining / deal.quantityTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.cardBorder),
        boxShadow: MerchantTheme.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFF1F5F9),
                  child: deal.imageUrl.isNotEmpty
                      ? Image.network(
                          deal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) => const Icon(Icons.restaurant_rounded, size: 22, color: MerchantTheme.emeraldPrimary),
                        )
                      : const Icon(Icons.restaurant_rounded, size: 22, color: MerchantTheme.emeraldPrimary),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: MerchantTheme.textDark),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${categoryEmoji(deal.category)} ${deal.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: MerchantTheme.textMuted, fontWeight: FontWeight.w700),
                        ),
                        if (pct > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: MerchantTheme.violetLightBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$pct%',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: MerchantTheme.violetAccent,
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
                  color: meta.color.withValues(alpha: 0.1),
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

          // Price & Stock counts
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GHS ${deal.discountedPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MerchantTheme.emeraldPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'GHS ${deal.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MerchantTheme.textMuted,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${deal.quantityRemaining}/${deal.quantityTotal} left',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: meta.color),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(height: 6, color: const Color(0xFFE2E8F0)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: c.maxWidth * fill,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [meta.color.withValues(alpha: 0.7), meta.color]),
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
              const Icon(Icons.schedule_rounded, size: 13, color: MerchantTheme.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  deal.pickupWindow.isEmpty ? 'Window not set' : deal.pickupWindow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: MerchantTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              if (sold > 0)
                Text(
                  '$sold rescued',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: MerchantTheme.emeraldPrimary),
                ),
            ],
          ),
          const Spacer(),

          // Action Toolbar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17, color: MerchantTheme.violetAccent),
                tooltip: 'Edit listing',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: MerchantTheme.skyInfo),
                tooltip: 'Duplicate deal',
                onPressed: onDuplicate,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined, size: 17, color: MerchantTheme.amberWarning),
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
                    backgroundColor: deal.isActive ? const Color(0xFFF1F5F9) : MerchantTheme.emeraldPrimary,
                    foregroundColor: deal.isActive ? MerchantTheme.textDark : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: Icon(
                    deal.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 14,
                  ),
                  label: Text(
                    deal.isActive ? 'Pause' : 'Go Live',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onToggle,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: MerchantTheme.roseDanger),
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

/// Shared add/edit sheet. Writes straight to Supabase and refreshes state.
class _DealForm extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final FoodDeal? existing;

  const _DealForm({required this.business, this.existing});

  @override
  ConsumerState<_DealForm> createState() => _DealFormState();
}

class _DealFormState extends ConsumerState<_DealForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _desc = TextEditingController(text: widget.existing?.description ?? '');
  late final _orig = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.originalPrice.toStringAsFixed(0));
  late final _disc = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.discountedPrice.toStringAsFixed(0));
  late final _window = TextEditingController(text: widget.existing?.pickupWindow ?? '');
  late final _qty = TextEditingController(text: '${widget.existing?.quantityTotal ?? 5}');
  late String _category = widget.existing != null && kDealCategories.contains(widget.existing!.category)
      ? widget.existing!.category
      : kDealCategories.first;
  Uint8List? _bytes;
  bool _busy = false;
  String? _error;

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
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 1200);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String imageUrl = widget.existing?.imageUrl ?? '';
      if (_bytes != null) {
        imageUrl = await SupabaseService().uploadImage(
          bucket: 'uploads',
          path: '${widget.business.id}/deal_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: _bytes!,
        );
      }
      final notifier = ref.read(appStateProvider.notifier);
      final original = double.parse(_orig.text.trim());
      final discounted = double.parse(_disc.text.trim());
      if (widget.existing == null) {
        await notifier.addDeal(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          originalPrice: original,
          discountedPrice: discounted,
          pickupWindow: _window.text.trim(),
          quantity: int.parse(_qty.text.trim()),
          imageUrl: imageUrl,
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
          quantity: int.parse(_qty.text.trim()),
          imageUrl: imageUrl,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      MToast.ok(context, widget.existing == null ? '“${_title.text.trim()}” is live' : 'Listing updated');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  InputDecoration _field(String label, {String? hint, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 19, color: MerchantTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantTheme.emeraldPrimary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );

  @override
  Widget build(BuildContext context) {
    final orig = double.tryParse(_orig.text.trim()) ?? 0;
    final disc = double.tryParse(_disc.text.trim()) ?? 0;
    final pct = orig > 0 && disc > 0 && disc < orig ? (((orig - disc) / orig) * 100).round() : 0;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MerchantTheme.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _bytes != null
                    ? Image.memory(_bytes!, fit: BoxFit.cover)
                    : (widget.existing?.imageUrl.isNotEmpty == true
                        ? Image.network(widget.existing!.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const _PhotoPlaceholder())
                        : const _PhotoPlaceholder()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _FormLabel('PACK NAME'),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field('e.g. Jollof + chicken surplus rescue pack', icon: Icons.restaurant_rounded),
            validator: (v) => (v == null || v.trim().length < 4) ? 'Give the pack a clear name' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('WHAT IS INSIDE'),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field('Portions, freshness, packaging notes'),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Describe the pack (10+ characters)' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('CATEGORY'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kDealCategories
                .map(
                  (c) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _category = c),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _category == c ? MerchantTheme.emeraldLightBg : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _category == c ? MerchantTheme.emeraldPrimary : MerchantTheme.cardBorder,
                            width: _category == c ? 1.6 : 1,
                          ),
                        ),
                        child: Text(
                          '${categoryEmoji(c)} $c',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _category == c ? MerchantTheme.emeraldDeep : MerchantTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FormLabel('REGULAR PRICE'),
                    TextFormField(
                      controller: _orig,
                      keyboardType: TextInputType.number,
                      decoration: _field('GHS', icon: Icons.sell_outlined),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? 'Enter regular price' : null;
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
                      decoration: _field('GHS', icon: Icons.local_offer_outlined),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Enter rescue price';
                        final o = double.tryParse(_orig.text.trim()) ?? 0;
                        if (o > 0 && n >= o) return 'Must be below regular';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pct > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: MerchantTheme.violetLightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pct% OFF · customers save GHS ${(orig - disc).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: MerchantTheme.violetAccent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const _FormLabel('PICKUP WINDOW'),
          TextFormField(
            controller: _window,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field('e.g. Today 6:00 PM – 8:30 PM', icon: Icons.schedule_rounded),
            validator: (v) => (v == null || v.trim().length < 4) ? 'Tell customers when to collect' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('UNITS AVAILABLE'),
          TextFormField(
            controller: _qty,
            keyboardType: TextInputType.number,
            decoration: _field('e.g. 8', icon: Icons.inventory_2_outlined),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'At least one unit';
              final sold = (widget.existing?.quantityTotal ?? 0) - (widget.existing?.quantityRemaining ?? 0);
              if (n < sold) return 'Total cannot be below $sold units already sold';
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: MerchantTheme.roseDanger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: const TextStyle(fontSize: 11.5, color: MerchantTheme.roseDanger, fontWeight: FontWeight.w800, height: 1.4)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: MerchantTheme.textMuted, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantTheme.emeraldPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    widget.existing == null ? 'Publish Listing' : 'Save Changes',
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, size: 28, color: MerchantTheme.emeraldPrimary),
          const SizedBox(height: 8),
          const Text('Tap to upload dish photo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MerchantTheme.textMuted)),
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
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: MerchantTheme.textMuted, letterSpacing: 0.9),
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
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MerchantTheme.textDark)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setDlg(() => error = null),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantTheme.emeraldPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final msg = validate?.call(ctrl.text);
              if (msg != null) {
                setDlg(() => error = msg);
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Save Stock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
