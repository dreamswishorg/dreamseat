import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import 'customer_home.dart';
import '../admin/admin_dashboard.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() =>
      _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState
    extends ConsumerState<CustomerSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingAddress = false;
  bool _isSearchingAddress = false;
  bool _isGettingGps = false;
  List<PredictedAddress> _predictions = [];

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
            );
        _showSnackBar('Updated location to current GPS');
      }
    } else {
      if (mounted) {
        setState(() => _isGettingGps = false);
        _showSnackBar('Could not retrieve GPS location', isError: true);
      }
    }
  }

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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);
    final error = await ref.read(appStateProvider.notifier).updateUserProfile(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
        );
    setState(() => _isSavingProfile = false);

    if (!mounted) return;
    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar('Profile updated successfully');
    }
  }

  void _saveDeliveryAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showSnackBar('Please enter a delivery address', isError: true);
      return;
    }
    setState(() => _isSavingAddress = true);
    ref.read(userLocationProvider.notifier).setAddress(address);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isSavingAddress = false);
        _showSnackBar('Delivery address updated');
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final user = state.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppTheme.charcoal;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.mutedGrey;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.charcoal.withValues(alpha: 0.06);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.role == 'admin' || user?.role == 'super_admin') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Executive Administration",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Access live metrics, orders & governance",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("HQ Console", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x06000000),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),



              // Section: Personal Information
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x06000000),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter your full name',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      inputBg: inputBg,
                      borderColor: borderColor,
                    ),
                    Divider(height: 28, color: borderColor),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'MoMo Number',
                      icon: Icons.phone_android_rounded,
                      hint: 'e.g. 0241234567',
                      keyboardType: TextInputType.phone,
                      prefix: '+233  ',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      inputBg: inputBg,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isSavingProfile
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          _isSavingProfile ? 'SAVING...' : 'SAVE PROFILE',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section: Delivery Address
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Default Delivery Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isGettingGps ? null : _useCurrentGpsLocation,
                    icon: _isGettingGps
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                        : const Icon(Icons.my_location_rounded, size: 15, color: AppTheme.primaryGreen),
                    label: Text(
                      _isGettingGps ? 'Locating...' : 'Use GPS',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x06000000),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Street Address or Landmark',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          onChanged: _onSearchAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type landmark or street (e.g. Osu, Oxford St, East Legon)...',
                            hintStyle: TextStyle(fontSize: 13, color: secondaryTextColor),
                            filled: true,
                            fillColor: inputBg,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryGreen),
                            ),
                            suffixIcon: _isSearchingAddress
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen)),
                                  )
                                : (_addressController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 16),
                                        onPressed: () => setState(() {
                                          _addressController.clear();
                                          _predictions.clear();
                                        }),
                                      )
                                    : null),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),

                    // Typeahead Predictive Suggestions Dropdown
                    if (_predictions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _predictions.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                          itemBuilder: (context, i) {
                            final pred = _predictions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_rounded, color: AppTheme.primaryGreen, size: 18),
                              title: Text(
                                pred.displayName,
                                style: TextStyle(
                                   fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.north_west_rounded, size: 14, color: AppTheme.mutedGrey),
                              onTap: () {
                                setState(() {
                                  _addressController.text = pred.displayName;
                                  _predictions.clear();
                                });
                                ref.read(userLocationProvider.notifier).setAddress(
                                      pred.displayName,
                                    );
                                _showSnackBar("Address selected: ${pred.displayName}");
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      'This address is saved as your primary location for food rescue deliveries. Predictive search helps pinpoint exact Ghana landmarks.',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingAddress ? null : _saveDeliveryAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isSavingAddress
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          _isSavingAddress ? 'SAVING...' : 'SAVE DELIVERY ADDRESS',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section: Account Actions
              Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x06000000),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      showModernLogoutConfirmDialog(
                        context,
                        () => ref.read(appStateProvider.notifier).signOut(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign Out',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.errorRed),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign out of your account on this device',
                                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.errorRed, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color inputBg,
    required Color borderColor,
    String? hint,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: primaryTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13.5, color: secondaryTextColor, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
            prefixText: prefix,
            prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: primaryTextColor, fontSize: 14.5),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
