import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/ds_kit.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../providers/biometric_provider.dart';
import '../customer/customer_navigation.dart';
import '../merchant/merchant_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../rider/rider_dashboard.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';
import '../common/legal_screens.dart';
import '../../services/biometric_service.dart';
import '../../widgets/face_id_icon.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AuthScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _signInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();

  // Sign-in fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sign-up fields
  final _suNameController = TextEditingController();
  final _suEmailController = TextEditingController();
  final _suPhoneController = TextEditingController();
  final _suReferralController = TextEditingController();
  final _suPasswordController = TextEditingController();
  final _suConfirmPasswordController = TextEditingController();
  final _suBizNameController = TextEditingController();
  final _suBizDescController = TextEditingController();
  final _suBizAddressController = TextEditingController();
  final _suLicenseController = TextEditingController();

  String _suRole = 'customer';
  String _suVehicleType = 'Motorbike';
  String _suBizCategory = 'Restaurant Meal';
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  int _activeTab = 0;
  int _suStep = 0;

  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  String _biometricLabel = "Biometrics";
  bool _isPasswordLoginInProgress = false;
  bool _isBiometricLoginInProgress = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Restaurant Meal',
    'Bakery Pack',
    'Grocery Bundle',
    'Fruit & Vegetable Pack',
    'Hotel Buffet',
    'Snacks & Drinks',
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    _initBiometrics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _suNameController.dispose();
    _suEmailController.dispose();
    _suPhoneController.dispose();
    _suReferralController.dispose();
    _suPasswordController.dispose();
    _suConfirmPasswordController.dispose();
    _suBizNameController.dispose();
    _suBizDescController.dispose();
    _suBizAddressController.dispose();
    _suLicenseController.dispose();
    super.dispose();
  }

  Future<void> _initBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final label = await BiometricService.getBiometricLabel();
    if (mounted) {
      setState(() {
        _isBiometricsAvailable = available;
        _isBiometricsEnabled = enabled;
        _biometricLabel = label;
      });
    }

    // Deliberate user action: Do not silently auto-fire biometric on screen load.
    // The user can explicitly tap the Face ID / Fingerprint button to sign in.
  }

  Future<void> _performBiometricLogin() async {
    if (_isPasswordLoginInProgress || _isBiometricLoginInProgress || _isLoading) return;
    _isBiometricLoginInProgress = true;

    try {
      final hasBiometrics = await BiometricService.isBiometricAvailable();
      if (!hasBiometrics) {
        _showSnackBar("Biometric authentication is not supported or set up on this device.", isError: true);
        return;
      }

      final isEnabled = await BiometricService.isBiometricEnabled();
      if (!isEnabled) {
        _showSnackBar("$_biometricLabel is not enabled. Please sign in with your password to set it up.", isError: false);
        return;
      }

      final unlock = await BiometricService.getSavedUnlock();
      if (unlock == null) {
        _showSnackBar("$_biometricLabel isn't linked yet. Sign in with your password once, then enable it in Settings.", isError: false);
        return;
      }

      final result = await BiometricService.authenticateWithDetails(
        reason: 'Scan your $_biometricLabel to sign in to DreamEats',
      );

      // Handle outcomes distinctly
      if (result.isCancelled) {
        // User cancelled Face ID prompt - silently return to form, NO error message
        if (_emailController.text.isEmpty) {
          _emailController.text = unlock['email']!;
        }
        return;
      }

      if (!result.isSuccess) {
        if (result.isLockedOut) {
          _showSnackBar("Biometrics locked out due to multiple failed attempts. Please enter your password.", isError: true);
        } else if (result.isNotAvailable) {
          _showSnackBar("Biometrics unavailable. Please enter your password.", isError: true);
        } else {
          _showSnackBar("$_biometricLabel not recognized. Please try again or use your password.", isError: true);
        }
        return;
      }

      setState(() => _isLoading = true);
      var error = await ref.read(appStateProvider.notifier).restoreSessionFromRefreshToken(
            unlock['refreshToken']!,
          );

      final errorLower = error?.toLowerCase() ?? '';
      final tokenIsDead = errorLower.contains('expired') ||
          errorLower.contains('invalid refresh token') ||
          errorLower.contains('already used') ||
          errorLower.contains('refresh_token_already_used') ||
          errorLower.contains('invalid_token');

      // Expired/rotated/revoked refresh token: the stored unlock data is dead,
      // so drop it and require one password sign-in to re-link Face ID.
      if (error != null && tokenIsDead) {
        await ref.read(biometricStateProvider.notifier).setEnabled(false);
        if (mounted) {
          _showSnackBar(
            "$_biometricLabel sign-in needs relinking. Please sign in with your password once — it'll work again automatically.",
            isError: false,
          );
        }
        error = null;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        if (error.toLowerCase().contains('suspended')) {
          _showSuspendedDialog(error.replaceAll('AuthException: ', '').trim());
        } else {
          _showSnackBar("Sign-in failed: ${error.replaceAll('AuthException: ', '').trim()}", isError: true);
        }
        return;
      }

      final user = ref.read(appStateProvider).currentUser;
      if (!mounted || user == null) return;

      _proceedToApp(user);
    } finally {
      _isBiometricLoginInProgress = false;
    }
  }

  void _showSuspendedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 48),
        title: const Text(
          "Account Suspended",
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.charcoal),
        ),
        content: Text(
          message.isNotEmpty
              ? message
              : "Your account has been suspended by administration. Please contact customer support for assistance.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppTheme.charcoal),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Understood", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sign-in ───────────────────────────────────────────────────────────────

  void _signIn() async {
    if (_isPasswordLoginInProgress || _isBiometricLoginInProgress || _isLoading) return;
    if (!_signInKey.currentState!.validate()) return;
    _isPasswordLoginInProgress = true;
    setState(() => _isLoading = true);

    final error = await ref.read(appStateProvider.notifier).signIn(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _isPasswordLoginInProgress = false;
      if (error.toLowerCase().contains('suspended')) {
        _showSuspendedDialog(error.replaceAll('AuthException: ', '').trim());
      } else {
        _showSnackBar(error.replaceAll('AuthException: ', '').trim(), isError: true);
      }
      return;
    }

    // Clear any lingering snackbars/messages from prior actions
    ScaffoldMessenger.of(context).clearSnackBars();

    final user = ref.read(appStateProvider).currentUser;
    if (!mounted || user == null) {
      _isPasswordLoginInProgress = false;
      return;
    }

    final email = _emailController.text.trim();

    // Check if biometric is available and whether it is already enrolled
    final isBioAvailable = await BiometricService.isBiometricAvailable();
    final isBioEnabled = await BiometricService.isBiometricEnabled();

    if (isBioAvailable && isBioEnabled) {
      // User has already enrolled: keep the saved unlock session synchronized
      final refreshToken = Supabase.instance.client.auth.currentSession?.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await BiometricService.saveUnlockAccount(
          email: email,
          refreshToken: refreshToken,
        );
      }
      _proceedToApp(user);
    } else if (isBioAvailable && !isBioEnabled) {
      // Prompt user to enable Face ID / Biometrics
      await _offerBiometricEnrollment(user: user);
    } else {
      _proceedToApp(user);
    }
  }

  Future<void> _offerBiometricEnrollment({
    required AppUser user,
  }) async {
    final label = await BiometricService.getBiometricLabel();
    if (mounted) {
      setState(() => _biometricLabel = label);
    }

    if (!mounted) return;

    final shouldEnroll = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppTheme.charcoal : Colors.white;
        final textPrimary = isDark ? Colors.white : AppTheme.charcoal;

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: DynamicBiometricIcon(
                  size: 40,
                  color: AppTheme.primaryGreen,
                  biometricLabel: _biometricLabel,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Enable $_biometricLabel?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Would you like to use $_biometricLabel for faster, secure sign-in next time?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.mutedGrey, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Not Now",
                  style: TextStyle(
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Mark that the user has responded to the first-login prompt
    await BiometricService.setPromptedEnrollment(true);

    if (shouldEnroll == true) {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await Future.delayed(const Duration(milliseconds: 350));

      final authResult = await BiometricService.authenticateWithDetails(
        reason: 'Scan your $_biometricLabel to enable instant sign-in',
      );

      if (authResult.isSuccess) {
        final refreshToken = Supabase.instance.client.auth.currentSession?.refreshToken;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await BiometricService.saveUnlockAccount(
            email: user.email,
            refreshToken: refreshToken,
          );
          await BiometricService.setBiometricEnabled(true);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricLabel enabled successfully!'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Did not succeed - keep biometric disabled
        if (mounted && !authResult.isCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult.message ?? '$_biometricLabel verification was not completed.'),
              backgroundColor: AppTheme.warningOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    _proceedToApp(user);
  }

  void _proceedToApp(AppUser user) {
    if (!mounted) return;
    _isPasswordLoginInProgress = false;
    _isBiometricLoginInProgress = false;

    if (user.isSuspended) {
      ref.read(appStateProvider.notifier).signOut(
            errorMessage: 'Your account has been suspended by administration. Please contact support.',
          );
      _showSuspendedDialog('Your account has been suspended by administration. Please contact support.');
      return;
    }

    final Widget destination;
    if (user.role == 'merchant') {
      destination = const MerchantDashboardScreen();
    } else if (user.role == 'admin' || user.role == 'super_admin') {
      destination = const AdminDashboardScreen();
    } else if (user.role == 'rider') {
      destination = const RiderDashboardScreen();
    } else {
      destination = const CustomerNavigation();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  void _register() async {
    if (!_signUpKey.currentState!.validate()) return;
    if (_suPasswordController.text != _suConfirmPasswordController.text) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }
    if (!_agreeToTerms) {
      _showSnackBar('Please check the box to agree to our Terms of Service & Privacy Policy.', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    final error = await ref.read(appStateProvider.notifier).signUp(
          name: _suNameController.text.trim(),
          email: _suEmailController.text.trim(),
          password: _suPasswordController.text,
          role: _suRole,
          phone: () {
            final raw = _suPhoneController.text.trim();
            if (raw.isEmpty) return null;
            // Normalize to local 0XXXXXXXXX format for consistent DB storage
            final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length == 9) return '0$digits';   // user skipped leading 0
            if (digits.length == 10 && digits.startsWith('0')) return digits;
            if (digits.startsWith('233') && digits.length == 12) {
              return '0${digits.substring(3)}';
            }
            return raw; // fallback: store as typed
          }(),
          referralCode: _suReferralController.text.trim().isNotEmpty
              ? _suReferralController.text.trim().toUpperCase()
              : null,
          businessName:
              _suRole == 'merchant' ? _suBizNameController.text.trim() : null,
          businessDescription:
              _suRole == 'merchant' ? _suBizDescController.text.trim() : null,
          businessCategory: _suRole == 'merchant' ? _suBizCategory : null,
          vehicleType: _suRole == 'rider' ? _suVehicleType : null,
          licenseNumber: _suRole == 'rider' ? _suLicenseController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == 'needs_confirmation') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: AppTheme.primaryGreen,
            size: 48,
          ),
          title: const Text(
            "Verify Your Email",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppTheme.charcoal,
            ),
          ),
          content: Text(
            "We have sent a verification email to ${_suEmailController.text.trim()}.\n\nPlease click the link in the email to activate your account, then return here to sign in.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.mutedGrey,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Switch to Sign In tab!
                setState(() => _activeTab = 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Got it, Sign In",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (error != null) {
      _showSnackBar(error.replaceAll('AuthException: ', '').trim(),
          isError: true);
      return;
    }

    if (!mounted) return;

    final user = ref.read(appStateProvider).currentUser;
    if (user != null) {
      final isBioAvailable = await BiometricService.isBiometricAvailable();
      final isBioEnabled = await BiometricService.isBiometricEnabled();
      if (isBioAvailable && !isBioEnabled) {
        await _offerBiometricEnrollment(user: user);
        return;
      }
    }

    if (!mounted) return;

    final Widget destination;
    if (_suRole == 'merchant') {
      destination = const MerchantDashboardScreen();
    } else if (_suRole == 'rider') {
      destination = const RiderDashboardScreen();
    } else {
      destination = const CustomerNavigation();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _signInOAuth(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    final error =
        await ref.read(appStateProvider.notifier).signInWithOAuth(provider);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      _showSnackBar(error, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: AppTheme.pureWhite,
              size: 20,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.md),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AuthShell.wideBreakpoint;
    return AuthShell(
      fade: _fadeAnimation,
      eyebrow: 'Surplus food rescue platform',
      headline: 'Rescue quality meals.',
      subhead: 'Save up to 70% every day.',
      description:
          'Connect directly with top restaurants, bakeries, and grocers to buy fresh surplus food at a fraction of the original price.',
      benefits: const [
        AuthBenefit(Icons.sell_outlined, 'Up to 70% off', 'Surplus meals at a fraction of the price'),
        AuthBenefit(Icons.verified_outlined, 'Verified fresh food', 'Safe, instant QR-code pickups'),
        AuthBenefit(Icons.storefront_outlined, 'Local partners', 'Restaurants, bakeries and grocers near you'),
      ],
      footer: _footerNote(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabSwitch(),
          const SizedBox(height: AppSpace.xl),
          _buildFormSwitcher(register: wide ? _buildWideRegisterForm : _buildRegisterForm),
        ],
      ),
    );
  }

  Widget _buildTabSwitch() {
    return DsSegmented(
      labels: const ['Sign In', 'Create Account'],
      selected: _activeTab,
      onChanged: (i) => setState(() {
        _activeTab = i;
        _suStep = 0;
      }),
    );
  }

  Widget _buildFormSwitcher({required Widget Function() register}) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : AppMotion.base,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
        ),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(_activeTab),
          child: _activeTab == 0 ? _buildSignInForm() : register(),
        ),
      ),
    );
  }

  Widget _footerNote() {
    return const Text(
      'By continuing, you agree to our Terms of Service & Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.5, color: AppTheme.mutedGrey, height: 1.5),
    );
  }

  Widget _formHeading(String title, String subtitle) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: text.headlineLarge)),
        const SizedBox(height: AppSpace.xs),
        Text(subtitle, style: text.bodyMedium),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDE SCREEN REGISTRATION FORM (FITS SCREEN WITHOUT EXCESS SCROLLING)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWideRegisterForm() {
    final merchant = _suRole == 'merchant';
    return Form(
      key: _signUpKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formHeading('Create your account', 'Join DreamEats to rescue meals and enjoy up to 70% off.'),
          const SizedBox(height: AppSpace.xl),
          Row(
            children: [
              Expanded(
                child: _roleChoice('customer', 'Customer Account', 'Order surplus food at up to 70% off',
                    Icons.person_outline_rounded, compact: true),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _roleChoice('merchant', 'Merchant Partner', 'Sell surplus food & earn new revenue',
                    Icons.storefront_outlined, compact: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          ..._spaced(merchant
              ? [
                  _pair(
                    _buildInputField(
                      controller: _suNameController,
                      label: 'Manager Full Name',
                      hint: 'Your full name',
                      icon: Icons.person_outline_rounded,
                      validator: _required('Name required'),
                    ),
                    _buildInputField(
                      controller: _suEmailController,
                      label: 'Business Email',
                      hint: 'store@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                  ),
                  _pair(
                    _buildInputField(
                      controller: _suBizNameController,
                      label: 'Business Name',
                      hint: 'Restaurant / Bakery name',
                      icon: Icons.storefront_outlined,
                      validator: _required('Store name required'),
                    ),
                    _buildInputField(
                      controller: _suPhoneController,
                      label: 'Store Phone',
                      hint: '0245678901',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _required('Phone required'),
                    ),
                  ),
                  _pair(
                    _categoryField(),
                    _buildInputField(
                      controller: _suBizDescController,
                      label: 'Store Description',
                      hint: 'e.g. Artisanal pastries & daily surplus packs',
                      icon: Icons.description_outlined,
                      validator: _required('Description required'),
                    ),
                  ),
                  _pair(
                    _passwordField(label: 'Password'),
                    _confirmField(hint: 'Re-enter password'),
                  ),
                ]
              : [
                  _pair(
                    _buildInputField(
                      controller: _suNameController,
                      label: 'Full Name',
                      hint: 'Your full name',
                      icon: Icons.person_outline_rounded,
                      validator: _required('Name is required'),
                    ),
                    _buildInputField(
                      controller: _suPhoneController,
                      label: 'Phone Number',
                      hint: '0245678901',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _phoneValidator,
                    ),
                  ),
                  _pair(
                    _buildInputField(
                      controller: _suEmailController,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    _referralField(),
                    flexA: 3,
                    flexB: 2,
                  ),
                  _pair(
                    _passwordField(label: 'Password'),
                    _confirmField(hint: 'Re-enter password'),
                  ),
                ]),
          const SizedBox(height: AppSpace.lg),
          _buildTermsCheckbox(),
          const SizedBox(height: AppSpace.xl),
          _buildPrimaryButton(
            label: merchant ? 'Register Merchant Account' : 'Create Customer Account',
            onPressed: _isLoading ? null : _register,
          ),
          const SizedBox(height: AppSpace.xl),
          _orDivider(),
          const SizedBox(height: AppSpace.lg),
          _socialButtons(),
        ],
      ),
    );
  }

  // ── Shared form pieces ─────────────────────────────────────────────────────

  /// Inserts the standard gap between stacked fields.
  List<Widget> _spaced(List<Widget> items, {double gap = AppSpace.lg}) => [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          items[i],
        ],
      ];

  /// Two fields side by side on wide screens.
  Widget _pair(Widget a, Widget b, {int flexA = 1, int flexB = 1}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: flexA, child: a),
          const SizedBox(width: AppSpace.md),
          Expanded(flex: flexB, child: b),
        ],
      );

  Widget _roleChoice(String role, String title, String subtitle, IconData icon, {bool compact = false}) {
    return DsChoiceTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      compact: compact,
      selected: _suRole == role,
      onTap: () => setState(() {
        _suRole = role;
        _suStep = 0;
      }),
    );
  }

  String? Function(String?) _required(String message) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 12) return 'Enter a valid phone number';
    return null;
  }

  Widget _passwordField({String label = 'Create Password', String hint = 'Min. 6 characters'}) {
    return _buildInputField(
      controller: _suPasswordController,
      label: label,
      hint: hint,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscureSignUp,
      suffixIcon: DsObscureToggle(
        obscured: _obscureSignUp,
        onToggle: () => setState(() => _obscureSignUp = !_obscureSignUp),
      ),
      validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
      autofillHints: const [],
    );
  }

  Widget _confirmField({String hint = 'Re-enter your password'}) {
    return _buildInputField(
      controller: _suConfirmPasswordController,
      label: 'Confirm Password',
      hint: hint,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirm,
      suffixIcon: DsObscureToggle(
        obscured: _obscureConfirm,
        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';
        if (v != _suPasswordController.text) return 'Passwords do not match';
        return null;
      },
      autofillHints: const [],
    );
  }

  Widget _referralField() {
    return _buildInputField(
      controller: _suReferralController,
      label: 'Referral Code (Optional)',
      hint: 'e.g. REF-1234ABCD',
      icon: Icons.card_giftcard_rounded,
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _categoryField() {
    return DsDropdownField<String>(
      label: 'Primary Food Category',
      value: _suBizCategory,
      items: _categories,
      itemLabel: (c) => c,
      icon: Icons.category_outlined,
      onChanged: (v) => setState(() => _suBizCategory = v),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN-IN FORM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSignInForm() {
    return Form(
      key: _signInKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formHeading('Welcome back', 'Sign in to continue rescuing meals'),
          const SizedBox(height: AppSpace.xl),

          // Email or phone number
          _buildInputField(
            controller: _emailController,
            label: 'Email or Phone Number',
            hint: 'you@example.com or 0245678901',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email or phone number is required';
              }
              final isEmail = v.contains('@');
              if (isEmail) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
              } else {
                final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly.length < 9) {
                  return 'Enter a valid phone number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpace.lg),

          // Password
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureSignIn,
            suffixIcon: DsObscureToggle(
              obscured: _obscureSignIn,
              onToggle: () => setState(() => _obscureSignIn = !_obscureSignIn),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            autofillHints: const [],
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // Sign in + biometrics
          Row(
            children: [
              Expanded(
                child: _buildPrimaryButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _signIn,
                ),
              ),
              if (_isBiometricsAvailable) ...[
                const SizedBox(width: AppSpace.md),
                _biometricButton(),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.xl),

          _orDivider(),
          const SizedBox(height: AppSpace.lg),
          _socialButtons(),
        ],
      ),
    );
  }

  Widget _biometricButton() {
    return Tooltip(
      message: 'Sign in with $_biometricLabel',
      child: DsPressable(
        onTap: _isLoading ? null : _performBiometricLogin,
        semanticLabel: 'Sign in with $_biometricLabel',
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.lightGreenBg,
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: _isBiometricsEnabled ? AppTheme.primaryGreen : AppTheme.mintGreen,
              width: 1.5,
            ),
          ),
          child: Center(
            child: DynamicBiometricIcon(
              size: 26,
              color: AppTheme.primaryGreen,
              biometricLabel: _biometricLabel,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE REGISTRATION FORM
  // ═══════════════════════════════════════════════════════════════════════════

  void _nextStep() {
    if (_signUpKey.currentState!.validate()) {
      const totalSteps = 2;
      if (_suStep < totalSteps - 1) {
        setState(() {
          _suStep++;
        });
      } else {
        _register();
      }
    }
  }

  void _prevStep() {
    if (_suStep > 0) {
      setState(() {
        _suStep--;
      });
    }
  }

  String _registerStepLabel() {
    switch (_suRole) {
      case 'merchant':
        return _suStep == 0 ? 'Account security' : 'Store setup';
      case 'rider':
        return _suStep == 0 ? 'Rider info' : 'Vehicle & security';
      default:
        return _suStep == 0 ? 'Personal info' : 'Security & terms';
    }
  }

  Widget _buildRegisterForm() {
    const totalSteps = 2;

    return Form(
      key: _signUpKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formHeading('Create your account', 'Join DreamEats to rescue meals and enjoy up to 70% off.'),
          const SizedBox(height: AppSpace.xl),
          DsStepProgress(step: _suStep, total: totalSteps, label: _registerStepLabel()),
          const SizedBox(height: AppSpace.xl),

          // Account type — chosen on the first step only
          if (_suStep == 0) ...[
            const Text(
              'Select Account Type',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
            ),
            const SizedBox(height: AppSpace.sm),
            _roleChoice('customer', 'Customer Account', 'Order surplus food up to 70% off', Icons.person_outline_rounded),
            const SizedBox(height: AppSpace.md),
            _roleChoice('merchant', 'Merchant Partner', 'Sell surplus food & earn new revenue', Icons.storefront_outlined),
            const SizedBox(height: AppSpace.md),
            _roleChoice('rider', 'Courier / Rider Partner', 'Deliver orders across Accra & earn GHS', Icons.two_wheeler_rounded),
            const SizedBox(height: AppSpace.xl),
          ],

          // Step content
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base,
            child: KeyedSubtree(
              key: ValueKey<String>('$_suRole-$_suStep'),
              child: _buildRegisterStepContent(),
            ),
          ),
          const SizedBox(height: AppSpace.xxl),

          // Navigation
          Row(
            children: [
              if (_suStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: DsButton(
                    label: 'Back',
                    variant: DsButtonVariant.secondary,
                    onPressed: _isLoading ? null : _prevStep,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                flex: 3,
                child: _buildPrimaryButton(
                  label: _suStep == 0
                      ? 'Next Step'
                      : (_suRole == 'customer'
                          ? 'Create Account'
                          : (_suRole == 'merchant' ? 'Launch Store' : 'Register Rider')),
                  onPressed: _isLoading ? null : _nextStep,
                ),
              ),
            ],
          ),

          // Social sign-up only on the first step
          if (_suStep == 0) ...[
            const SizedBox(height: AppSpace.xl),
            _orDivider(),
            const SizedBox(height: AppSpace.lg),
            _socialButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterStepContent() {
    final List<Widget> fields;
    if (_suRole == 'customer') {
      fields = _suStep == 0
          ? [
              _buildInputField(
                controller: _suNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: _required('Name is required'),
              ),
              _buildInputField(
                controller: _suEmailController,
                label: 'Email Address',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              _buildInputField(
                controller: _suPhoneController,
                label: 'Phone Number',
                hint: '0245678901',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _phoneValidator,
              ),
              _referralField(),
            ]
          : [_passwordField(), _confirmField(), _buildTermsCheckbox()];
    } else if (_suRole == 'merchant') {
      fields = _suStep == 0
          ? [
              _buildInputField(
                controller: _suNameController,
                label: 'Manager Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: _required('Name is required'),
              ),
              _buildInputField(
                controller: _suEmailController,
                label: 'Business Email Address',
                hint: 'store@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              _buildInputField(
                controller: _suPhoneController,
                label: 'Store Phone Number',
                hint: '0245678901',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _required('Phone number required'),
              ),
              _passwordField(),
              _confirmField(),
            ]
          : [
              _buildInputField(
                controller: _suBizNameController,
                label: 'Business Name',
                hint: 'Your restaurant or bakery name',
                icon: Icons.business_outlined,
                validator: _required('Business name is required'),
              ),
              _buildInputField(
                controller: _suBizDescController,
                label: 'Short Description',
                hint: 'What kind of delicious food do you offer?',
                icon: Icons.description_outlined,
                maxLines: 2,
                validator: _required('Please describe your business'),
              ),
              _buildInputField(
                controller: _suBizAddressController,
                label: 'Physical Address / Landmark',
                hint: 'e.g., 12 Main Street',
                icon: Icons.location_on_outlined,
                validator: _required('Address is required'),
              ),
              _categoryField(),
              _buildTermsCheckbox(),
            ];
    } else {
      fields = _suStep == 0
          ? [
              _buildInputField(
                controller: _suNameController,
                label: 'Full Legal Name',
                hint: 'As on your Ghana Card / ID',
                icon: Icons.person_outline_rounded,
                validator: _required('Name is required'),
              ),
              _buildInputField(
                controller: _suEmailController,
                label: 'Email Address',
                hint: 'rider@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              _buildInputField(
                controller: _suPhoneController,
                label: 'MoMo / Phone Number',
                hint: '0245678901',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _required('Phone number required for delivery alerts'),
              ),
            ]
          : [
              DsDropdownField<String>(
                label: 'Vehicle Type',
                value: _suVehicleType,
                items: const ['Motorbike', 'Bicycle', 'Scooter', 'Car'],
                itemLabel: (v) => v,
                icon: Icons.two_wheeler_rounded,
                onChanged: (v) => setState(() => _suVehicleType = v),
              ),
              _buildInputField(
                controller: _suLicenseController,
                label: 'Driver License / Ghana Card PIN',
                hint: 'e.g. GHA-123456789-0',
                icon: Icons.badge_outlined,
                validator: _required('ID or license is required'),
              ),
              _passwordField(),
              _confirmField(),
              _buildTermsCheckbox(),
            ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced(fields),
    );
  }

  Widget _buildTermsCheckbox() {
    const body = TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4);
    const link = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppTheme.primaryGreen,
      decoration: TextDecoration.underline,
    );
    Widget linkText(String text, Widget screen) => InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text(text, style: link),
          ),
        );

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: _agreeToTerms ? AppTheme.lightGreenBg : AppTheme.lightGrey,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: _agreeToTerms ? AppTheme.primaryGreen : AppTheme.hairline, width: 1.5),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agreeToTerms,
            semanticLabel: 'I agree to the Terms of Service and Privacy Policy',
            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('I agree to the ', style: body),
                linkText('Terms of Service', const TermsOfServiceScreen()),
                const Text(' and ', style: body),
                linkText('Privacy Policy', const PrivacyPolicyScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS — thin wrappers over the DreamEats kit (core/ds_kit.dart)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return DsTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType,
      obscureText: obscureText,
      suffix: suffixIcon,
      prefixText: prefixText,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return DsButton(label: label, onPressed: onPressed, loading: _isLoading);
  }

  Widget _orDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Text(
            'or continue with',
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _socialButtons() {
    const pad = EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md);
    final google = DsButton(
      label: 'Google',
      leading: const GoogleLogoIcon(size: 20),
      variant: DsButtonVariant.outline,
      padding: pad,
      onPressed: () => _signInOAuth(OAuthProvider.google),
    );
    final apple = DsButton(
      label: 'Apple',
      icon: Icons.apple,
      variant: DsButtonVariant.outline,
      padding: pad,
      onPressed: () => _signInOAuth(OAuthProvider.apple),
    );
    return Row(
      children: [
        Expanded(child: google),
        const SizedBox(width: AppSpace.md),
        Expanded(child: apple),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GOOGLE LOGO ICON
// ═══════════════════════════════════════════════════════════════════════════════

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;

    // Path 1: Red
    final Paint paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Path pathRed = Path()
      ..moveTo(12.0 * s, 5.0 * s)
      ..relativeCubicTo(2.61 * s, 0.0, 4.96 * s, 0.9 * s, 6.8 * s, 2.62 * s)
      ..relativeLineTo(3.64 * s, -3.64 * s)
      ..cubicTo(20.12 * s, 1.84 * s, 16.37 * s, 1.0 * s, 12.0 * s, 1.0 * s)
      ..cubicTo(7.58 * s, 1.0 * s, 3.73 * s, 3.53 * s, 1.83 * s, 7.23 * s)
      ..relativeLineTo(4.03 * s, 3.13 * s)
      ..cubicTo(6.79 * s, 7.56 * s, 9.17 * s, 5.0 * s, 12.0 * s, 5.0 * s)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // Path 2: Blue
    final Paint paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path pathBlue = Path()
      ..moveTo(23.49 * s, 12.27 * s)
      ..relativeCubicTo(0.0, -0.82 * s, -0.07 * s, -1.6 * s, -0.2 * s, -2.36 * s)
      ..lineTo(12.0 * s, 9.91 * s)
      ..lineTo(12.0 * s, 14.42 * s)
      ..lineTo(18.49 * s, 14.42 * s)
      ..relativeCubicTo(-0.29 * s, 1.48 * s, -1.14 * s, 2.73 * s, -2.4 * s, 3.58 * s)
      ..relativeLineTo(4.43 * s, 3.43 * s)
      ..relativeCubicTo(2.6 * s, -2.4 * s, 4.97 * s, -5.96 * s, 4.97 * s, -9.16 * s)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Path 3: Green
    final Paint paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Path pathGreen = Path()
      ..moveTo(12.0 * s, 23.0 * s)
      ..relativeCubicTo(2.97 * s, 0.0, 5.46 * s, -0.97 * s, 7.28 * s, -2.66 * s)
      ..relativeLineTo(-3.57 * s, -2.77 * s)
      ..relativeCubicTo(-0.98 * s, 0.66 * s, -2.23 * s, 1.06 * s, -3.71 * s, 1.06 * s)
      ..relativeCubicTo(-2.86 * s, 0.0, -5.29 * s, -1.93 * s, -6.16 * s, -4.53 * s)
      ..lineTo(1.8 * s, 17.22 * s)
      ..cubicTo(3.61 * s, 20.77 * s, 7.51 * s, 23.0 * s, 12.0 * s, 23.0 * s)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Path 4: Yellow
    final Paint paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Path pathYellow = Path()
      ..moveTo(5.84 * s, 14.09 * s)
      ..relativeCubicTo(-0.22 * s, -0.66 * s, -0.35 * s, -1.36 * s, -0.35 * s, -2.09 * s)
      ..relativeCubicTo(0.0, -0.73 * s, 0.13 * s, -1.43 * s, 0.35 * s, -2.09 * s)
      ..lineTo(5.84 * s, 6.77 * s)
      ..lineTo(1.81 * s, 6.77 * s)
      ..cubicTo(1.16 * s, 8.07 * s, 0.8 * s, 9.53 * s, 0.8 * s, 11.08 * s)
      ..cubicTo(0.8 * s, 12.63 * s, 1.16 * s, 14.09 * s, 1.81 * s, 15.39 * s)
      ..lineTo(5.84 * s, 12.09 * s)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
