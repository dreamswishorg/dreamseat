import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import '../common/help_support_screen.dart';
import 'merchant_kit.dart';

/// Shop profile tab: identity, contact, location and compliance documents.
class MerchantProfileScreen extends ConsumerStatefulWidget {
  final BusinessProfile business;
  const MerchantProfileScreen({super.key, required this.business});

  @override
  ConsumerState<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> {
  bool _editing = false;
  bool _busy = false;
  bool _searching = false;
  bool _gpsing = false;

  late final _name = TextEditingController(text: widget.business.name);
  late final _desc = TextEditingController(text: widget.business.description);
  late final _location = TextEditingController(text: widget.business.location);
  late final _phone = TextEditingController(text: widget.business.phone);
  late String _category =
      kDealCategories.contains(widget.business.category) ? widget.business.category : kDealCategories.first;
  double? _lat;
  double? _lng;
  List<PredictedAddress> _predictions = [];

  Map<String, MerchantDocument> _docs = {};
  bool _loadingDocs = true;

  @override
  void initState() {
    super.initState();
    _lat = widget.business.latitude;
    _lng = widget.business.longitude;
    _loadDocs();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    try {
      final docs = await ref.read(appStateProvider.notifier).fetchMerchantDocuments(widget.business.id);
      if (mounted) setState(() => _docs = docs);
    } catch (_) {
      // Document status simply shows as "not on file" if the vault is unreachable.
    } finally {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  void _startEditing() {
    _name.text = widget.business.name;
    _desc.text = widget.business.description;
    _location.text = widget.business.location;
    _phone.text = widget.business.phone;
    _category =
        kDealCategories.contains(widget.business.category) ? widget.business.category : kDealCategories.first;
    _lat = widget.business.latitude;
    _lng = widget.business.longitude;
    _predictions = [];
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _name.text = widget.business.name;
    _desc.text = widget.business.description;
    _location.text = widget.business.location;
    _phone.text = widget.business.phone;
    _lat = widget.business.latitude;
    _lng = widget.business.longitude;
    setState(() {
      _editing = false;
      _predictions = [];
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 3) {
      MToast.err(context, 'Shop name needs at least 3 characters');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(appStateProvider.notifier).updateBusinessProfile(
            widget.business.id,
            name: _name.text.trim(),
            description: _desc.text.trim(),
            category: _category,
            location: _location.text.trim(),
            phone: _phone.text.trim(),
            lat: _lat,
            lng: _lng,
          );
      if (!mounted) return;
      setState(() => _editing = false);
      MToast.ok(context, 'Shop profile saved');
    } catch (e) {
      if (mounted) MToast.err(context, 'Save failed: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadImage({required bool cover}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 1600);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await SupabaseService().uploadImage(
        bucket: 'merchant-logos',
        path: '${widget.business.id}/${cover ? 'cover' : 'logo'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileBytes: bytes,
      );
      await SupabaseService().updateBusinessImages(widget.business.id, logoUrl: cover ? null : url, coverUrl: cover ? url : null);
      await ref.read(appStateProvider.notifier).refreshMerchantBusiness();
      if (mounted) MToast.ok(context, cover ? 'Cover photo updated' : 'Logo updated');
    } catch (e) {
      if (mounted) MToast.err(context, 'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dial(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      MToast.info(context, 'No phone dialer available on this device');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await LocationService().searchPredictiveAddresses(query);
    if (mounted) {
      setState(() {
        _predictions = results;
        _searching = false;
      });
    }
  }

  Future<void> _useGps() async {
    setState(() => _gpsing = true);
    final pos = await LocationService().getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        setState(() => _gpsing = false);
        MToast.err(context, 'Location permission denied or GPS unavailable');
      }
      return;
    }
    final addr = await LocationService().getAddressFromLatLng(pos);
    if (!mounted) return;
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      if (addr != null && addr.isNotEmpty) _location.text = addr;
      _gpsing = false;
      _predictions = [];
    });
  }

  Future<void> _openDocSheet(String docType, String label) async {
    await showMSheet<void>(
      context,
      title: label,
      child: _DocumentUpload(
        business: widget.business,
        docType: docType,
        label: label,
        existing: _docs[docType],
        onSaved: (doc) => setState(() => _docs[docType] = doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final business = state.businesses.firstWhere(
      (b) => b.id == widget.business.id,
      orElse: () => widget.business,
    );
    final deals = state.merchantDeals;
    final orders = state.orders.where((o) => o.businessId == business.id).toList();
    final collected = orders.where((o) => o.status == 'collected').length;

    final wide = useSideNav(context);
    return ResponsiveCenter(
      maxWidth: 1140,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 14, wide ? 24 : 16, wide ? 28 : 110),
        children: [
          MReveal(child: _ShopHeader(business: business, busy: _busy, onLogo: () => _uploadImage(cover: false), onCover: () => _uploadImage(cover: true))),
          const SizedBox(height: 14),
          MReveal(
            delay: 60,
            child: MCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MSectionHeader(
                    title: 'Shop information',
                    subtitle: 'What customers see on your storefront',
                    icon: Icons.storefront_rounded,
                    trailing: _editing
                        ? Row(
                            children: [
                              MButton('Cancel', kind: MKind.ghost, height: 38, onPressed: _busy ? null : _cancelEditing),
                              const SizedBox(width: 8),
                              MButton('Save', icon: Icons.check_rounded, height: 38, loading: _busy, onPressed: _busy ? null : _save),
                            ],
                          )
                        : MButton('Edit', icon: Icons.edit_outlined, kind: MKind.soft, height: 38, onPressed: _startEditing),
                  ),
                  const SizedBox(height: 18),
                  if (!_editing) ...[
                    _InfoLine(icon: Icons.category_outlined, label: 'Category', value: '${categoryEmoji(business.category)} ${business.category}'),
                    _InfoLine(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: business.phone.isEmpty ? 'Not added — customers cannot call you' : business.phone,
                      valueColor: business.phone.isEmpty ? MK.danger : MK.ink,
                      action: business.phone.isEmpty
                          ? MButton('Add', kind: MKind.soft, height: 32, onPressed: _startEditing)
                          : MIconButton(
                              icon: Icons.call_rounded,
                              color: MK.brand,
                              size: 32,
                              tooltip: 'Dial ${business.phone}',
                              onPressed: () => _dial(business.phone),
                            ),
                    ),
                    _InfoLine(icon: Icons.place_outlined, label: 'Location', value: business.location),
                    _InfoLine(
                      icon: Icons.star_outline_rounded,
                      label: 'Rating',
                      value: business.rating <= 0 ? 'Not rated yet' : '${business.rating.toStringAsFixed(1)} / 5.0',
                    ),
                    if (business.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        business.description,
                        style: const TextStyle(fontSize: 12.5, color: MK.inkSoft, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.my_location_rounded, size: 13, color: MK.inkSoft.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Coordinates ${business.latitude.toStringAsFixed(4)}, ${business.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _Field(
                      label: 'SHOP NAME',
                      controller: _name,
                      icon: Icons.storefront_rounded,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'ABOUT THE SHOP',
                      controller: _desc,
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      hint: 'What you sell, how you pack, anything customers should know',
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'CONTACT PHONE',
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: 'e.g. 024 412 3456',
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 14),
                    const _MiniLabel('PRIMARY CATEGORY'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kDealCategories
                          .map((c) => MPressable(
                                onTap: () => setState(() => _category = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _category == c ? MK.brand.withValues(alpha: 0.12) : Colors.white,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: _category == c ? MK.brand : MK.line, width: _category == c ? 1.5 : 1),
                                  ),
                                  child: Text(
                                    '$categoryEmoji $c',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _category == c ? MK.brand : MK.ink,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const _MiniLabel('SHOP LOCATION'),
                    TextField(
                      controller: _location,
                      enabled: !_busy,
                      onChanged: _searchAddress,
                      decoration: InputDecoration(
                        hintText: 'Start typing a street or area…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 19),
                        suffixIcon: _gpsing
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MK.brand)),
                              )
                            : IconButton(tooltip: 'Use my current GPS', icon: const Icon(Icons.my_location_rounded, size: 19), onPressed: _useGps),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.line)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.brand, width: 1.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      ),
                    ),
                    if (_searching) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 3, color: MK.brand, backgroundColor: MK.line),
                    ],
                    ..._predictions.take(4).map(
                          (p) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.pin_drop_outlined, size: 18, color: MK.brand),
                            title: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                            onTap: () => setState(() {
                              _location.text = p.displayName;
                              _lat = p.latitude;
                              _lng = p.longitude;
                              _predictions = [];
                            }),
                          ),
                        ),
                    if (_lat != null && _lng != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pinned at ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 10.5, color: MK.brand, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MReveal(
            delay: 100,
            child: MCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MSectionHeader(
                    title: 'Compliance documents',
                    subtitle: business.isApproved
                        ? 'Approved by the DreamEats team'
                        : 'Submitted documents are reviewed by our compliance team',
                    icon: Icons.verified_user_outlined,
                    iconColor: business.isApproved ? MK.brand : MK.amber,
                    trailing: MIconButton(icon: Icons.refresh_rounded, onPressed: _loadingDocs ? null : _loadDocs, tooltip: 'Reload'),
                  ),
                  const SizedBox(height: 12),
                  _DocRow(
                    label: 'Business registration',
                    doc: _docs[MerchantDocument.businessRegistration],
                    loading: _loadingDocs,
                    onUpload: () => _openDocSheet(MerchantDocument.businessRegistration, 'Business registration'),
                  ),
                  _DocRow(
                    label: 'Health certificate',
                    doc: _docs[MerchantDocument.healthCertificate],
                    loading: _loadingDocs,
                    onUpload: () => _openDocSheet(MerchantDocument.healthCertificate, 'Health certificate'),
                  ),
                  _DocRow(
                    label: 'Tax clearance',
                    doc: _docs[MerchantDocument.taxClearance],
                    loading: _loadingDocs,
                    onUpload: () => _openDocSheet(MerchantDocument.taxClearance, 'Tax clearance'),
                    last: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MReveal(
            delay: 140,
            child: MCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MSectionHeader(title: 'Shop at a glance', icon: Icons.insights_rounded, iconColor: MK.grape),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _MiniStat('${deals.where((d) => d.isActive).length}', 'live listings', MK.brand)),
                      Expanded(child: _MiniStat('$collected', 'completed orders', MK.sky)),
                      Expanded(
                        child: _MiniStat(
                          MK.money(orders.fold<double>(0, (s, o) => s + o.price)),
                          'lifetime sales',
                          MK.grape,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MReveal(
            delay: 180,
            child: MCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  _LinkRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & support',
                    detail: 'Ask the DreamEats team',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                  ),
                  if (business.phone.isNotEmpty)
                    _LinkRow(
                      icon: Icons.call_rounded,
                      label: 'Call your shop line',
                      detail: business.phone,
                      onTap: () => _dial(business.phone),
                    ),
                  _LinkRow(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    detail: 'End this session',
                    danger: true,
                    onTap: () => ref.read(appStateProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final BusinessProfile business;
  final bool busy;
  final VoidCallback onLogo;
  final VoidCallback onCover;

  const _ShopHeader({required this.business, required this.busy, required this.onLogo, required this.onCover});

  @override
  Widget build(BuildContext context) {
    final cover = business.coverUrl.isNotEmpty
        ? business.coverUrl
        : (business.logoUrl.isNotEmpty ? business.logoUrl : null);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MK.rLg),
        border: Border.all(color: MK.line),
        boxShadow: MK.shadow,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 128,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: cover == null ? MK.heroGradient : null,
                  image: cover == null
                      ? null
                      : DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: MIconButton(
                  icon: Icons.add_photo_alternate_outlined,
                  color: Colors.white,
                  size: 34,
                  onPressed: busy ? null : onCover,
                  tooltip: 'Change cover photo',
                ),
              ),
              Positioned(
                left: 18,
                bottom: -26,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: MK.shadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: business.logoUrl.isEmpty
                          ? Center(
                              child: Text(
                                business.name.isEmpty ? 'D' : business.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MK.brandDeep),
                              ),
                            )
                          : Image.network(business.logoUrl, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, color: MK.brand)),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: MIconButton(
                        icon: Icons.camera_alt_rounded,
                        color: MK.brand,
                        size: 30,
                        onPressed: busy ? null : onLogo,
                        tooltip: 'Change logo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MK.ink, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        business.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                MPill(
                  business.isApproved ? 'VERIFIED' : 'IN REVIEW',
                  color: business.isApproved ? MK.brand : MK.amber,
                  pulse: !business.isApproved,
                  fontSize: 8.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? action;

  const _InfoLine({required this.icon, required this.label, required this.value, this.valueColor, this.action});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: MK.inkSoft),
            const SizedBox(width: 10),
            SizedBox(
              width: 78,
              child: Text(label, style: const TextStyle(fontSize: 11.5, color: MK.inkSoft, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: valueColor ?? MK.ink),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MiniLabel(label),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: maxLines == 1 ? Icon(icon, size: 19) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MK.rSm), borderSide: const BorderSide(color: MK.brand, width: 1.6)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: maxLines == 1 ? 13 : 11),
            ),
          ),
        ],
      );
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: MK.inkSoft, letterSpacing: 0.9),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w800)),
        ],
      );
}

class _DocRow extends StatelessWidget {
  final String label;
  final MerchantDocument? doc;
  final bool loading;
  final bool last;
  final VoidCallback onUpload;

  const _DocRow({required this.label, required this.doc, required this.loading, required this.onUpload, this.last = false});

  static const _statusMeta = {
    'submitted': ('SUBMITTED', MK.sky),
    'under_review': ('UNDER REVIEW', MK.amber),
    'verified': ('VERIFIED', MK.brand),
    'rejected': ('REJECTED', MK.danger),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta[doc?.status ?? ''] ?? ('NOT ON FILE', MK.inkSoft);
    final uploaded = doc?.isUploaded == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: MK.line))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: meta.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(uploaded ? Icons.description_outlined : Icons.post_add, size: 17, color: meta.$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MK.ink)),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? 'Checking the vault…'
                      : uploaded
                          ? '${doc!.referenceNumber.isEmpty ? 'No reference number' : 'Ref ${doc!.referenceNumber}'} · uploaded ${doc!.uploadedAt == null ? '' : MK.ago(doc!.uploadedAt!)}'
                              '${doc!.reviewerNote == null ? '' : '\n${doc!.reviewerNote}'}'
                          : 'Upload the official document so our team can verify your shop',
                  style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!loading && uploaded) MPill(meta.$1, color: meta.$2, fontSize: 8),
          const SizedBox(width: 8),
          MButton(
            uploaded ? 'Replace' : 'Upload',
            kind: uploaded ? MKind.ghost : MKind.soft,
            height: 34,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool danger;

  const _LinkRow({required this.icon, required this.label, required this.detail, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => MPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: danger ? MK.danger : MK.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: danger ? MK.danger : MK.ink),
                    ),
                    Text(detail, style: const TextStyle(fontSize: 10.5, color: MK.inkSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: danger ? MK.danger.withValues(alpha: 0.6) : MK.inkSoft),
            ],
          ),
        ),
      );
}

/// Persists a compliance document to the merchant documents vault.
class _DocumentUpload extends ConsumerStatefulWidget {
  final BusinessProfile business;
  final String docType;
  final String label;
  final MerchantDocument? existing;
  final ValueChanged<MerchantDocument> onSaved;

  const _DocumentUpload({
    required this.business,
    required this.docType,
    required this.label,
    required this.onSaved,
    this.existing,
  });

  @override
  ConsumerState<_DocumentUpload> createState() => _DocumentUploadState();
}

class _DocumentUploadState extends ConsumerState<_DocumentUpload> {
  final _ref = TextEditingController(text: '');
  Uint8List? _bytes;
  String? _fileName;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_bytes == null) {
      setState(() => _error = 'Choose a photo of the document first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final url = await SupabaseService().uploadImage(
        bucket: 'uploads',
        path: 'kyc/${widget.business.id}/${widget.docType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileBytes: _bytes!,
      );
      final reference = _ref.text.trim();
      await ref.read(appStateProvider.notifier).saveMerchantDocument(
            widget.business.id,
            docType: widget.docType,
            fileUrl: url,
            referenceNumber: reference,
          );
      if (!mounted) return;
      widget.onSaved(MerchantDocument(
        docType: widget.docType,
        referenceNumber: reference,
        fileUrl: url,
        status: 'under_review',
        uploadedAt: DateTime.now(),
      ));
      Navigator.pop(context);
      MToast.ok(context, '${widget.label} sent for review');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Upload a clear photo of your ${widget.label.toLowerCase()}. Our compliance team reviews new submissions daily.',
            style: const TextStyle(fontSize: 12.5, color: MK.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          _Field(label: 'DOCUMENT NUMBER (OPTIONAL)', controller: _ref, icon: Icons.confirmation_number_outlined, hint: 'e.g. GRA-2026-114', enabled: !_busy),
          const SizedBox(height: 16),
          MPressable(
            onTap: _busy ? null : _pick,
            child: Container(
              height: 116,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F1),
                borderRadius: BorderRadius.circular(MK.rMd),
                border: Border.all(color: _bytes == null ? MK.line : MK.brand.withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _bytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_rounded, size: 28, color: MK.brand),
                        const SizedBox(height: 8),
                        Text(
                          widget.existing?.isUploaded == true ? 'Replace current document' : 'Choose document photo',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MK.inkSoft),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_bytes!, fit: BoxFit.cover),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: MK.ink.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
                            child: Text(_fileName ?? '', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: MK.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(fontSize: 11.5, color: MK.danger, fontWeight: FontWeight.w800, height: 1.4))),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: MButton('Cancel', kind: MKind.ghost, onPressed: _busy ? null : () => Navigator.pop(context))),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: MButton('Send for review', icon: Icons.send_rounded, loading: _busy, onPressed: _busy ? null : _submit)),
            ],
          ),
        ],
      );
}
