import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/biometric_switch_tile.dart';

/// Public-facing business profile screen for merchants to manage their storefront.
class MerchantProfileScreen extends ConsumerStatefulWidget {
  final BusinessProfile business;
  const MerchantProfileScreen({super.key, required this.business});

  @override
  ConsumerState<MerchantProfileScreen> createState() =>
      _MerchantProfileScreenState();
}

class _MerchantProfileScreenState
    extends ConsumerState<MerchantProfileScreen> {
  bool _isEditing = false;
  bool _isUploading = false;
  bool _isSearchingAddress = false;
  bool _isGettingGps = false;

  double? _selectedLat;
  double? _selectedLng;
  List<PredictedAddress> _predictions = [];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _hoursCtrl;
  String _selectedCategory = 'Restaurant Meal';
  String _bizRegStatus = "Verified GH-2024-882";
  String _healthStatus = "Valid: Oct 2025";
  String _taxStatus = "GRA Compliant";
  String? _bizRegUrl;
  String? _healthUrl;
  String? _taxUrl;

  final List<String> _categories = [
    'Restaurant Meal',
    'Bakery Pack',
    'Grocery Bundle',
    'Fruit & Vegetable Pack',
    'Hotel Buffet',
    'Snacks & Drinks',
    'Farm Produce',
    'Wholesale Bundle',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.business.name);
    _descCtrl = TextEditingController(text: widget.business.description);
    _locationCtrl = TextEditingController(text: widget.business.location);
    _hoursCtrl = TextEditingController(text: '08:00 AM – 09:00 PM');
    _selectedCategory = _categories.contains(widget.business.category)
        ? widget.business.category
        : _categories.first;
    _selectedLat = widget.business.latitude;
    _selectedLng = widget.business.longitude;

    // Load any existing KYC uploads from audit trail
    final auditLogs = ref.read(appStateProvider).auditLogs;
    for (final log in auditLogs) {
      if (log.action == 'KYC_UPLOAD' && log.entityId == widget.business.id) {
        final docTitle = log.metadata['document_title']?.toString().toLowerCase() ?? '';
        final fileUrl = log.metadata['file_url']?.toString();
        final refNum = log.metadata['reference_number']?.toString();
        if (docTitle.contains('business')) {
          _bizRegUrl ??= fileUrl;
          if (refNum != null && refNum.isNotEmpty) _bizRegStatus = "Uploaded ($refNum)";
        } else if (docTitle.contains('health')) {
          _healthUrl ??= fileUrl;
          if (refNum != null && refNum.isNotEmpty) _healthStatus = "Uploaded ($refNum)";
        } else if (docTitle.contains('tax') || docTitle.contains('vat')) {
          _taxUrl ??= fileUrl;
          if (refNum != null && refNum.isNotEmpty) _taxStatus = "Uploaded ($refNum)";
        }
      }
    }
  }

  Future<void> _onSearchAddress(String query) async {
    if (query.trim().length < 3) {
      if (mounted) setState(() => _predictions.clear());
      return;
    }
    setState(() => _isSearchingAddress = true);
    final results = await LocationService().searchPredictiveAddresses(query);
    if (mounted) {
      setState(() {
        _predictions = results;
        _isSearchingAddress = false;
      });
    }
  }

  Future<void> _useCurrentGpsLocation() async {
    setState(() => _isGettingGps = true);
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      final addr = await LocationService().getAddressFromLatLng(pos);
      if (mounted) {
        setState(() {
          _selectedLat = pos.latitude;
          _selectedLng = pos.longitude;
          if (addr != null && addr.isNotEmpty) {
            _locationCtrl.text = addr;
          }
          _isGettingGps = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📍 Pinned shop GPS to: (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isGettingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not get GPS location. Please check permissions.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final logoUrl = await SupabaseService().uploadImage(
          bucket: 'merchant-logos',
          path: '${widget.business.id}/$fileName',
          fileBytes: bytes,
        );

        await ref.read(appStateProvider.notifier).updateBusinessBranding(
          widget.business.id,
          logoUrl: logoUrl,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logo updated successfully!"), backgroundColor: AppTheme.primaryGreen),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppTheme.errorRed),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final coverUrl = await SupabaseService().uploadImage(
          bucket: 'merchant-logos',
          path: '${widget.business.id}/$fileName',
          fileBytes: bytes,
        );

        await ref.read(appStateProvider.notifier).updateBusinessBranding(
          widget.business.id,
          coverUrl: coverUrl,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cover photo updated successfully!"), backgroundColor: AppTheme.primaryGreen),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppTheme.errorRed),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Business Profile',
          style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close : Icons.edit_rounded, color: AppTheme.primaryGreen, size: 16),
              label: Text(_isEditing ? 'Cancel' : 'Edit', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.lightGreenBg,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: ResponsiveCenter(
          maxWidth: 850,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // ── Visual Branding ───────────────────────────────────
            _buildBrandingSection(),
            const SizedBox(height: 32),

            // ── Business Form ─────────────────────────────────────
            const Text("Core Identity", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal)),
            const SizedBox(height: 16),
            _buildProfileForm(),

            const SizedBox(height: 24),
            if (_isEditing)
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Update Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

            const SizedBox(height: 32),

            // ── KYC & Compliance Vault ────────────────────────────
            _buildKycVaultSection(),
            const SizedBox(height: 32),

            // ── Gallery / Photos ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Store Gallery", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal)),
                TextButton(
                  onPressed: () {},
                  child: const Text("Manage Photos", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGallerySection(),

            const SizedBox(height: 32),
            const Text("Security & Settings", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: const BiometricSwitchTile(),
            ),

            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Cover Photo Placeholder
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppTheme.charcoal, Color(0xFF475569)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (widget.business.coverUrl.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(widget.business.coverUrl, fit: BoxFit.cover),
                      ),
                    ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.store_mall_directory_rounded, size: 100, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white70, size: 18),
                      label: Text(
                        widget.business.coverUrl.isEmpty ? "Add Cover" : "Change Cover",
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logo
            Positioned(
              bottom: -30,
              child: GestureDetector(
                onTap: _isUploading ? null : _pickLogo,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ClipOval(
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : widget.business.logoUrl.isNotEmpty
                            ? Image.network(widget.business.logoUrl, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.lightGreenBg,
                                child: Icon(_categoryIcon(_selectedCategory), color: AppTheme.primaryGreen, size: 40),
                              ),
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: -30,
                right: MediaQuery.of(context).size.width / 2 - 45,
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryGreen,
                    child: const Icon(Icons.add_a_photo_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildField(
            label: "Display Name",
            controller: _nameCtrl,
            icon: Icons.store_rounded,
            enabled: _isEditing,
          ),
          const SizedBox(height: 20),
          _buildField(
            label: "About Business",
            controller: _descCtrl,
            icon: Icons.info_outline_rounded,
            maxLines: 3,
            enabled: _isEditing,
          ),
          const SizedBox(height: 20),
          _buildLocationSection(),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.mutedGrey)),
              const SizedBox(height: 8),
              _isEditing
                  ? DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: context.cardColor,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.mutedGrey),
                      decoration: _inputDecoration("Category", Icons.category_rounded),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 14, color: context.textPrimary, fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.category_rounded, size: 18, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Text(_selectedCategory, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Store Location & GPS Pin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.mutedGrey)),
        const SizedBox(height: 8),
        if (!_isEditing) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_locationCtrl.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  ],
                ),
                if (_selectedLat != null && _selectedLng != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGreenBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "📍 Verified GPS: (${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)})",
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _locationCtrl,
            onChanged: (val) => _onSearchAddress(val),
            decoration: _inputDecoration("Type street address or business name...", Icons.location_on_rounded).copyWith(
              suffixIcon: _isSearchingAddress
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                      onPressed: () => _onSearchAddress(_locationCtrl.text),
                    ),
            ),
          ),
          if (_predictions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _predictions.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final pred = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 18, color: AppTheme.primaryGreen),
                    title: Text(pred.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text("Lat: ${pred.latitude.toStringAsFixed(4)}, Lng: ${pred.longitude.toStringAsFixed(4)}", style: const TextStyle(fontSize: 10, color: AppTheme.mutedGrey)),
                    onTap: () {
                      setState(() {
                        _locationCtrl.text = pred.displayName;
                        _selectedLat = pred.latitude;
                        _selectedLng = pred.longitude;
                        _predictions.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Pinned coordinates to: ${pred.latitude.toStringAsFixed(4)}, ${pred.longitude.toStringAsFixed(4)}")),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _useCurrentGpsLocation,
              icon: _isGettingGps
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                  : const Icon(Icons.my_location_rounded, size: 16, color: AppTheme.primaryGreen),
              label: const Text("📍 Use My Current Shop Location (GPS)", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppTheme.lightGreenBg,
              ),
            ),
          ),
          if (_selectedLat != null && _selectedLng != null) ...[
            const SizedBox(height: 6),
            Text(
              "✅ Selected GPS: (${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)})",
              style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required IconData icon, int maxLines = 1, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.mutedGrey)),
        const SizedBox(height: 8),
        enabled
            ? TextFormField(
                controller: controller,
                maxLines: maxLines,
                decoration: _inputDecoration(label, icon),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.text,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _buildGallerySection() {
    return Container(
      height: 100,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Gallery management coming soon!")),
              );
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.05)),
              ),
              child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.mutedGrey),
            ),
          ),
          // In a real app, map through actual gallery URLs here
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: const Text(
              "No additional photos yet",
              style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycVaultSection() {
    final isApproved = widget.business.isApproved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text("KYC & Compliance Vault", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isApproved ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isApproved ? "VERIFIED VAULT" : "PENDING REVIEW",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isApproved ? AppTheme.primaryGreen : Colors.orange.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Upload and update your mandatory legal, tax, and food safety inspection certificates for platform verification.",
          style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Document Cards
        _buildKycDocTile(
          title: "Business Registration Certificate",
          subtitle: "Certificate of Incorporation / Registrar General",
          status: _bizRegStatus,
          fileUrl: _bizRegUrl,
          icon: Icons.business_center_rounded,
          onPreview: () => _previewKycDocument("Business Registration Certificate", _bizRegUrl),
          onUpload: () => _showUploadDialog("Business Registration Certificate", _bizRegStatus, (val) {
            setState(() => _bizRegStatus = val);
          }),
        ),
        const SizedBox(height: 14),
        _buildKycDocTile(
          title: "Health & Safety Inspection Permit",
          subtitle: "Municipal Food Hygiene & Sanitation Certificate",
          status: _healthStatus,
          fileUrl: _healthUrl,
          icon: Icons.health_and_safety_rounded,
          onPreview: () => _previewKycDocument("Health & Safety Inspection Permit", _healthUrl),
          onUpload: () => _showUploadDialog("Health & Safety Inspection Permit", _healthStatus, (val) {
            setState(() => _healthStatus = val);
          }),
        ),
        const SizedBox(height: 14),
        _buildKycDocTile(
          title: "VAT / Tax Identification Number (TIN)",
          subtitle: "Ghana Revenue Authority (GRA) Tax Compliance",
          status: _taxStatus,
          fileUrl: _taxUrl,
          icon: Icons.account_balance_wallet_rounded,
          onPreview: () => _previewKycDocument("VAT / Tax Identification Number (TIN)", _taxUrl),
          onUpload: () => _showUploadDialog("VAT / Tax Identification Number (TIN)", _taxStatus, (val) {
            setState(() => _taxStatus = val);
          }),
        ),
      ],
    );
  }

  void _previewKycDocument(String title, String? fileUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 550,
          color: const Color(0xFF0F172A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.black.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text("KYC Document Preview • Pinch to zoom", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: fileUrl != null && fileUrl.isNotEmpty
                        ? Image.network(
                            fileUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                            errorBuilder: (c, e, s) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: AppTheme.errorRed, size: 40),
                                  SizedBox(height: 8),
                                  Text("Failed to load document image", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.file_present_rounded, size: 48, color: AppTheme.mutedGrey),
                                const SizedBox(height: 12),
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                const Text("Official verified record on file", style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: Colors.black.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycDocTile({
    required String title,
    required String subtitle,
    required String status,
    required String? fileUrl,
    required IconData icon,
    required VoidCallback onPreview,
    required VoidCallback onUpload,
  }) {
    final hasImage = fileUrl != null && fileUrl.isNotEmpty;
    final isVerified = status.toLowerCase().contains('verified') || status.toLowerCase().contains('valid') || status.toLowerCase().contains('compliant') || status.toLowerCase().contains('uploaded');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail / Icon Area
              GestureDetector(
                onTap: onPreview,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasImage ? const Color(0xFF0F172A) : (isVerified ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.network(
                          fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Center(child: Icon(icon, color: AppTheme.primaryGreen, size: 28)),
                        )
                      else
                        Center(child: Icon(icon, color: isVerified ? AppTheme.primaryGreen : Colors.orange.shade800, size: 28)),
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in_rounded, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          size: 14,
                          color: isVerified ? AppTheme.primaryGreen : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isVerified ? AppTheme.primaryGreen : Colors.orange.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                  label: const Text("View Image", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.charcoal,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded, size: 14),
                  label: Text(hasImage ? "Replace" : "Upload", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(String docTitle, String currentStatus, ValueChanged<String> onSave) {
    final ctrl = TextEditingController(text: currentStatus.contains('(') ? currentStatus.split('(').last.replaceAll(')', '').trim() : currentStatus);
    String? selectedFileName;
    Uint8List? selectedFileBytes;
    String? selectedFileExt;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.upload_file_rounded, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(child: Text("Upload $docTitle", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select a clear PDF or photo scan of your certificate. Admin compliance team will verify authenticity within 24 hours.",
                    style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
                  ),
                  const SizedBox(height: 16),
                  const Text("Certificate / Registration Number", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl,
                    enabled: !isSaving,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "e.g. GH-2024-882 or FDA-2025",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Document File (PDF / JPG / PNG)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isSaving ? null : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedFileName = image.name;
                            selectedFileBytes = bytes;
                            selectedFileExt = image.name.split('.').last.toLowerCase();
                          });
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error picking file: $e"), backgroundColor: AppTheme.errorRed),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedFileName != null ? AppTheme.primaryGreen.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedFileName != null ? AppTheme.primaryGreen : const Color(0xFFCBD5E1),
                          style: selectedFileName != null ? BorderStyle.solid : BorderStyle.none,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedFileName != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                            color: selectedFileName != null ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFileName ?? "Tap to choose file from device",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                              color: selectedFileName != null ? AppTheme.primaryGreen : AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (selectedFileBytes == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text("⚠️ Please choose a document file first!"), backgroundColor: AppTheme.errorRed),
                    );
                    return;
                  }

                  setDialogState(() {
                    isSaving = true;
                  });

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  try {
                    final cleanExt = selectedFileExt ?? 'jpg';
                    final fileName = '${docTitle.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
                    
                    // Upload to 'uploads' bucket under public storage
                    final fileUrl = await SupabaseService().uploadImage(
                      bucket: 'uploads',
                      path: 'kyc/${widget.business.id}/$fileName',
                      fileBytes: selectedFileBytes!,
                    );

                    final docNum = ctrl.text.trim().isEmpty ? "Pending" : ctrl.text.trim();
                    final newVal = "Uploaded ($docNum)";

                    // Log this upload event with URL attachment in metadata
                    await SupabaseService().logAction(
                      action: "KYC_UPLOAD",
                      entityType: "business",
                      entityId: widget.business.id,
                      description: "Merchant uploaded KYC document: $docTitle",
                      metadata: {
                        'document_title': docTitle,
                        'reference_number': docNum,
                        'file_url': fileUrl,
                        'uploaded_at': DateTime.now().toIso8601String(),
                      },
                    );

                    setState(() {
                      if (docTitle.toLowerCase().contains('business')) {
                        _bizRegUrl = fileUrl;
                      } else if (docTitle.toLowerCase().contains('health')) {
                        _healthUrl = fileUrl;
                      } else {
                        _taxUrl = fileUrl;
                      }
                    });
                    onSave(newVal);
                    navigator.pop();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("✅ $docTitle uploaded and sent to KYC Vault successfully!"),
                        backgroundColor: AppTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    setDialogState(() {
                      isSaving = false;
                    });
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("❌ Upload failed: $e"),
                        backgroundColor: AppTheme.errorRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Submit to Vault", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final category = _selectedCategory;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving profile and resolving GPS coordinates...')),
    );

    double? lat = _selectedLat ?? widget.business.latitude;
    double? lng = _selectedLng ?? widget.business.longitude;

    if (location.isNotEmpty && location != widget.business.location && _selectedLat == null) {
      final pos = await LocationService().getLatLngFromAddress(location);
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    }

    try {
      await ref.read(appStateProvider.notifier).updateBusinessProfile(
        widget.business.id,
        name: name,
        description: description,
        category: category,
        location: location,
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile & exact map location saved!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }



  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Bakery Pack':
        return Icons.bakery_dining;
      case 'Restaurant Meal':
        return Icons.restaurant;
      case 'Fruit & Vegetable Pack':
        return Icons.local_florist;
      case 'Hotel Buffet':
        return Icons.hotel;
      case 'Grocery Bundle':
        return Icons.shopping_basket;
      case 'Snacks & Drinks':
        return Icons.local_cafe;
      case 'Farm Produce':
        return Icons.grass;
      default:
        return Icons.storefront;
    }
  }
}
