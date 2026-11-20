import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../../providers/biometric_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/biometric_switch_tile.dart';
import '../admin/admin_dashboard.dart';
import 'avatar_picker.dart';
import 'customer_home.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingAddress = false;
  bool _isSearchingAddress = false;
  bool _isGettingGps = false;
  bool _isUploadingAvatar = false;
  Uint8List? _localAvatarBytes;
  List<PredictedAddress> _predictions = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(appStateProvider);
    _nameController.text = state.currentUser?.name ?? '';
    _phoneController.text = state.currentUser?.phone ?? '';
    _addressController.text = ref.read(userLocationProvider).address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
          if (addr != null && addr.isNotEmpty) {
            _addressController.text = addr;
          }
          _predictions.clear();
          _isGettingGps = false;
        });
        ref.read(userLocationProvider.notifier).setAddress(
              addr ?? _addressController.text,
              pos,
            );
        AppToast.success(context, 'Updated location to current GPS');
      }
    } else {
      if (mounted) {
        setState(() => _isGettingGps = false);
        AppToast.error(context, 'Could not retrieve GPS location');
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppToast.error(context, 'Name cannot be empty');
      return;
    }

    setState(() => _isSavingProfile = true);
    final error = await ref.read(appStateProvider.notifier).updateUserProfile(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
        );
    if (mounted) setState(() => _isSavingProfile = false);

    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
    } else {
      AppToast.success(context, 'Profile updated successfully');
    }
  }

  void _saveDeliveryAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      AppToast.error(context, 'Please enter a delivery address');
      return;
    }
    setState(() => _isSavingAddress = true);
    ref.read(userLocationProvider.notifier).setAddress(address);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isSavingAddress = false);
        AppToast.success(context, 'Delivery address updated');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider.select((s) => s.currentUser));
    final isAdmin = user?.role == 'admin' || user?.role == 'super_admin';
    final showBiometrics = ref.watch(biometricStateProvider.select((b) => b.isSupported || !b.isInitialized));

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: dsScreenBar(context, title: 'Account Settings'),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdmin) ...[
                _AdminBanner(
                  onOpen: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    (route) => false,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
              ],

              // ── Identity ────────────────────────────────────────────────
              DsCard(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    DsAvatar(
                      name: user?.name ?? '',
                      url: user?.avatarUrl,
                      bytes: _localAvatarBytes,
                      size: 68,
                      busy: _isUploadingAvatar,
                      onEdit: () => changeProfilePhoto(
                        context,
                        ref,
                        onBusy: (v) {
                          if (mounted) setState(() => _isUploadingAvatar = v);
                        },
                        onPreview: (b) {
                          if (mounted) setState(() => _localAvatarBytes = b);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Customer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.4),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Personal information ────────────────────────────────────
              const DsSectionHeader(
                title: 'Personal Information',
                padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md),
              ),
              DsCard(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    DsTextField(
                      controller: _phoneController,
                      label: 'MoMo Number',
                      hint: 'e.g. 0245678901',
                      icon: Icons.phone_android_rounded,
                      prefixText: '+233  ',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DsButton(
                      label: 'Save profile',
                      icon: Icons.check_circle_outline_rounded,
                      loading: _isSavingProfile,
                      onPressed: _isSavingProfile ? null : _saveProfile,
                    ),
                  ],
                ),
              ),

              // ── Delivery address ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, 0, AppSpace.md),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Default Delivery Address',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.5, height: 1.2),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isGettingGps ? null : _useCurrentGpsLocation,
                      icon: _isGettingGps
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_isGettingGps ? 'Locating...' : 'Use GPS'),
                    ),
                  ],
                ),
              ),
              DsCard(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsTextField(
                      controller: _addressController,
                      label: 'Street Address or Landmark',
                      hint: 'e.g. Osu, Oxford St, East Legon',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      onChanged: _onSearchAddress,
                      suffix: _isSearchingAddress
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpace.md + 2),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (_addressController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear address',
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => setState(() {
                                    _addressController.clear();
                                    _predictions.clear();
                                  }),
                                )
                              : null),
                    ),

                    // Typeahead suggestions
                    if (_predictions.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(color: AppTheme.hairline),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _predictions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final pred = _predictions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_rounded, color: AppTheme.primaryGreen, size: 20),
                              title: Text(
                                pred.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                              ),
                              trailing: const Icon(Icons.north_west_rounded, size: 16, color: AppTheme.mutedGrey),
                              onTap: () {
                                setState(() {
                                  _addressController.text = pred.displayName;
                                  _predictions.clear();
                                });
                                ref.read(userLocationProvider.notifier).setAddress(
                                      pred.displayName,
                                      pred.toPosition(),
                                    );
                                AppToast.success(context, 'Address selected: ${pred.displayName}');
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpace.md),
                    const Text(
                      'This address is saved as your primary location for food rescue deliveries. Predictive search helps pinpoint exact Ghana landmarks.',
                      style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey, height: 1.45),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DsButton(
                      label: 'Save delivery address',
                      icon: Icons.check_circle_outline_rounded,
                      variant: DsButtonVariant.dark,
                      loading: _isSavingAddress,
                      onPressed: _isSavingAddress ? null : _saveDeliveryAddress,
                    ),
                  ],
                ),
              ),

              // ── Security & biometrics ───────────────────────────────────
              if (showBiometrics) ...[
                const DsSectionHeader(
                  title: 'Security & Biometrics',
                  padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md),
                ),
                const DsMenuGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
                      child: BiometricSwitchTile(),
                    ),
                  ],
                ),
              ],

              // ── Account actions ─────────────────────────────────────────
              const DsSectionHeader(
                title: 'Account Actions',
                padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md),
              ),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  DsMenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    subtitle: 'Sign out of your account on this device',
                    tone: DsTone.danger,
                    onTap: () => showModernLogoutConfirmDialog(
                      context,
                      () => ref.read(appStateProvider.notifier).signOut(),
                    ),
                  ),
                  DsMenuTile(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    subtitle: 'Permanently remove your profile and personal data',
                    tone: DsTone.danger,
                    onTap: () => showModernDeleteAccountConfirmDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown to admin / super-admin accounts only: the way back to the HQ console.
class _AdminBanner extends StatelessWidget {
  final VoidCallback onOpen;
  const _AdminBanner({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return DsHeroCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite.withValues(alpha: 0.12),
                  borderRadius: AppRadius.rSm,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.limeAccent, size: 24),
              ),
              const SizedBox(width: AppSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Administration',
                      style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2),
                    ),
                    SizedBox(height: AppSpace.xxs),
                    Text(
                      'Access live metrics, orders & governance',
                      style: TextStyle(color: AppTheme.mintGreen, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          DsButton(label: 'HQ Console', icon: Icons.arrow_forward_rounded, variant: DsButtonVariant.outline, onPressed: onOpen),
        ],
      ),
    );
  }
}
