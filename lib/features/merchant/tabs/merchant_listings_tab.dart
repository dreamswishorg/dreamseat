import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/models.dart';
import '../../../providers/app_state.dart';
import '../../../services/supabase_service.dart';
import '../merchant_kit.dart';

class MerchantListingsTab extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final bool composeNew;

  const MerchantListingsTab({super.key, required this.business, this.composeNew = false});

  @override
  ConsumerState<MerchantListingsTab> createState() => _MerchantListingsTabState();
}

class _MerchantListingsTabState extends ConsumerState<MerchantListingsTab> {
  static const _filters = ['all', 'live', 'paused', 'low', 'soldout'];
  static const _labels = ['All', 'Live', 'Paused', 'Low stock', 'Sold out'];

  String _filter = 'all';
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
    await showMSheet<void>(
      context,
      title: existing == null ? 'Publish a surplus pack' : 'Edit listing',
      maxWidth: 620,
      child: _DealForm(business: widget.business, existing: existing),
    );
  }

  Future<void> _toggle(FoodDeal deal, bool activate) async {
    try {
      await ref.read(appStateProvider.notifier).toggleDealStatus(deal.id, activate);
      if (mounted) MToast.ok(context, '${deal.title} is now ${activate ? 'live' : 'paused'}');
    } catch (e) {
      if (mounted) MToast.err(context, 'Could not update: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _restock(FoodDeal deal) async {
    final qty = await askNumber(
      context,
      title: 'Restock ${deal.title}',
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
          );
      if (mounted) MToast.ok(context, 'Stock updated · customers see it immediately');
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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: MK.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, size: 26, color: MK.danger),
              ),
              const SizedBox(height: 14),
              const Text('Delete this listing?', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: MK.ink)),
              const SizedBox(height: 6),
              Text(
                '“${deal.title}” disappears from discovery. Orders already placed stay in your Orders tab.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: MK.inkSoft, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: MButton('Keep it', kind: MKind.ghost, onPressed: () => Navigator.pop(ctx, false))),
                  const SizedBox(width: 10),
                  Expanded(child: MButton('Delete', kind: MKind.danger, icon: Icons.delete_outline_rounded, onPressed: () => Navigator.pop(ctx, true))),
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
      if (mounted) MToast.ok(context, 'Listing deleted');
    } catch (e) {
      if (mounted) MToast.err(context, 'Delete failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final deals = state.merchantDeals.toList()
      ..sort((a, b) => (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0));

    int countOf(String f) => f == 'all' ? deals.length : deals.where((d) => _bucketOf(d) == f).length;

    final q = _search.text.trim().toLowerCase();
    final visible = deals
        .where((d) => _filter == 'all' || _bucketOf(d) == _filter)
        .where((d) => q.isEmpty || d.title.toLowerCase().contains(q) || d.category.toLowerCase().contains(q))
        .toList();

    final wide = useSideNav(context);
    return ResponsiveCenter(
      maxWidth: 1240,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 16 : 12, wide ? 24 : 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: MSearchField(
                        controller: _search,
                        hint: 'Search your listings…',
                        onChanged: (_) => setState(() {}),
                        onClear: _search.text.isEmpty
                            ? null
                            : () {
                                _search.clear();
                                setState(() {});
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 46,
                      child: MIconButton(
                        icon: Icons.upload_file_rounded,
                        tooltip: 'Export listings',
                        color: MK.sky,
                        size: 46,
                        onPressed: deals.isEmpty
                            ? null
                            : () => exportCsv(
                                context,
                                csv: buildCsv(
                                  ['Title', 'Category', 'Original', 'Discounted', 'Off', 'Total', 'Remaining', 'Status'],
                                  deals
                                      .map((d) => [
                                            d.title,
                                            d.category,
                                            d.originalPrice.toStringAsFixed(2),
                                            d.discountedPrice.toStringAsFixed(2),
                                            '${d.percentageSaved}%',
                                            '${d.quantityTotal}',
                                            '${d.quantityRemaining}',
                                            _bucketOf(d),
                                          ])
                                      .toList(),
                                ),
                                fileName: '${widget.business.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').toLowerCase()}_listings.csv',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              MChipRow(
                items: _labels,
                values: _filters,
                value: _filter,
                countOf: countOf,
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => notifier.loadMerchantDeals(),
                  child: state.isLoadingMerchantDeals && deals.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: MK.brand))
                      : state.merchantDealsError != null && deals.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                MFeedbackBlock(
                                  icon: Icons.cloud_off_rounded,
                                  title: 'Could not load listings',
                                  message: state.merchantDealsError!,
                                  actionLabel: 'Try again',
                                  onAction: notifier.loadMerchantDeals,
                                  problem: true,
                                ),
                              ],
                            )
                          : deals.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 20),
                                  children: [
                                    MFeedbackBlock(
                                      icon: Icons.storefront_outlined,
                                      title: 'No listings yet',
                                      message:
                                          'Publish surplus food and it goes live for nearby rescuers within seconds.',
                                      actionLabel: 'Create first pack',
                                      onAction: () => _compose(),
                                    ),
                                  ],
                                )
                              : visible.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        MFeedbackBlock(
                                          icon: Icons.filter_alt_off_rounded,
                                          title: 'Nothing in this filter',
                                          message: 'Try another tab above or clear your search.',
                                          actionLabel: 'Show all',
                                          onAction: () {
                                            _search.clear();
                                            setState(() => _filter = 'all');
                                          },
                                        ),
                                      ],
                                    )
                                  : GridView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 8, wide ? 24 : 16, wide ? 28 : 120),
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 380,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: visible.length,
                                      itemBuilder: (_, i) => MReveal(
                                        delay: (i * 45).clamp(0, 320),
                                        child: _ListingCard(
                                          deal: visible[i],
                                          bucket: _bucketOf(visible[i]),
                                          onEdit: () => _compose(visible[i]),
                                          onToggle: () => _toggle(visible[i], !visible[i].isActive),
                                          onRestock: () => _restock(visible[i]),
                                          onDelete: () => _delete(visible[i]),
                                        ),
                                      ),
                                    ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              backgroundColor: MK.brand,
              foregroundColor: Colors.white,
              elevation: 5,
              onPressed: () => _compose(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New pack', style: TextStyle(fontWeight: FontWeight.w900)),
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
  final VoidCallback onDelete;

  const _ListingCard({
    required this.deal,
    required this.bucket,
    required this.onEdit,
    required this.onToggle,
    required this.onRestock,
    required this.onDelete,
  });

  static const _bucketMeta = {
    'live': (label: 'LIVE', color: MK.brand),
    'paused': (label: 'PAUSED', color: MK.inkSoft),
    'low': (label: 'LOW STOCK', color: MK.amber),
    'soldout': (label: 'SOLD OUT', color: MK.coral),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _bucketMeta[bucket]!;
    final pct = deal.originalPrice > 0
        ? (((deal.originalPrice - deal.discountedPrice) / deal.originalPrice) * 100).round()
        : 0;
    final sold = deal.quantityTotal - deal.quantityRemaining;
    final fill = deal.quantityTotal == 0 ? 0.0 : (deal.quantityRemaining / deal.quantityTotal).clamp(0.0, 1.0);

    return MCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MThumb(url: deal.imageUrl, size: 52, badge: MPill('$pct% OFF', color: MK.grape, fontSize: 7.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: MK.ink, height: 1.15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${categoryEmoji(deal.category)} ${deal.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MPill(meta.label, color: meta.color, pulse: bucket == 'live', fontSize: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MK.money(deal.discountedPrice),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: MK.brand, letterSpacing: -0.6),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  MK.money(deal.originalPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    color: MK.inkSoft,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w700,
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
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(height: 7, color: const Color(0xFFEDF2ED)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    height: 7,
                    width: c.maxWidth * fill,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [meta.color.withValues(alpha: 0.6), meta.color]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 13, color: MK.inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deal.pickupWindow.isEmpty ? 'Pickup window not set' : deal.pickupWindow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
                ),
              ),
              if (sold > 0)
                Text(
                  '$sold sold',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: MK.brand),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              MIconButton(icon: Icons.edit_outlined, onPressed: onEdit, color: MK.grape, tooltip: 'Edit'),
              const SizedBox(width: 7),
              MIconButton(icon: Icons.add_box_outlined, onPressed: onRestock, color: MK.amber, tooltip: 'Restock'),
              const SizedBox(width: 7),
              MIconButton(
                icon: deal.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: onToggle,
                color: deal.isActive ? MK.inkSoft : MK.brand,
                tooltip: deal.isActive ? 'Pause listing' : 'Publish listing',
              ),
              const Spacer(),
              MButton(
                deal.isActive ? 'Pause' : 'Go live',
                kind: deal.isActive ? MKind.ghost : MKind.primary,
                height: 36,
                onPressed: onToggle,
              ),
              const SizedBox(width: 7),
              MIconButton(icon: Icons.delete_outline_rounded, onPressed: onDelete, color: MK.danger, tooltip: 'Delete'),
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
        prefixIcon: icon == null ? null : Icon(icon, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MK.rSm),
          borderSide: const BorderSide(color: MK.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MK.rSm),
          borderSide: const BorderSide(color: MK.brand, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
          MPressable(
            onTap: _pick,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F1),
                borderRadius: BorderRadius.circular(MK.rMd),
                border: Border.all(color: MK.line),
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
          const SizedBox(height: 16),
          const _FormLabel('PACK NAME'),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field('e.g. Jollof + chicken family pack', icon: Icons.restaurant_rounded),
            validator: (v) => (v == null || v.trim().length < 4) ? 'Give the pack a clear name' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('WHAT IS INSIDE'),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field('Portions, freshness, packaging'),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Describe the pack (10+ characters)' : null,
          ),
          const SizedBox(height: 14),
          const _FormLabel('CATEGORY'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kDealCategories
                .map(
                  (c) => MPressable(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _category == c ? MK.brand.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _category == c ? MK.brand : MK.line, width: _category == c ? 1.6 : 1),
                      ),
                      child: Text(
                        '${categoryEmoji(c)} $c',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _category == c ? MK.brand : MK.ink,
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
                        return (n == null || n <= 0) ? 'Enter the regular price' : null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
                        if (n == null || n <= 0) return 'Enter the rescue price';
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
            Align(
              alignment: Alignment.centerLeft,
              child: MPill('$pct% OFF · customers save ${MK.money(orig - disc)}', color: MK.grape, solid: true, fontSize: 10),
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
                const Icon(Icons.error_outline_rounded, size: 16, color: MK.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: const TextStyle(fontSize: 11.5, color: MK.danger, fontWeight: FontWeight.w800, height: 1.4)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MButton('Cancel', kind: MKind.ghost, onPressed: _busy ? null : () => Navigator.pop(context)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: MButton(
                  widget.existing == null ? 'Publish listing' : 'Save changes',
                  icon: Icons.bolt_rounded,
                  loading: _busy,
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
          const Icon(Icons.add_a_photo_outlined, size: 26, color: MK.brand),
          const SizedBox(height: 8),
          const Text('Add a photo (recommended)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: MK.inkSoft)),
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
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: MK.inkSoft, letterSpacing: 0.9),
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
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MK.ink)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm)),
              ),
              onChanged: (_) => setDlg(() => error = null),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          MButton(
            'Save',
            height: 40,
            onPressed: () {
              final msg = validate?.call(ctrl.text);
              if (msg != null) {
                setDlg(() => error = msg);
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            },
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
