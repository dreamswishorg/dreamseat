import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../customer/customer_navigation.dart';
import '../merchant/merchant_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'forgot_password_screen.dart';
import '../common/legal_screens.dart';
import '../../services/biometric_service.dart';

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
  final _suPasswordController = TextEditingController();
  final _suConfirmPasswordController = TextEditingController();
  final _suBizNameController = TextEditingController();
  final _suBizDescController = TextEditingController();
  final _suBizAddressController = TextEditingController();

  String _suRole = 'customer';
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
    _suPasswordController.dispose();
    _suConfirmPasswordController.dispose();
    _suBizNameController.dispose();
    _suBizDescController.dispose();
    _suBizAddressController.dispose();
    super.dispose();
  }

  Future<void> _initBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricsAvailable = available;
        _isBiometricsEnabled = enabled;
      });
    }

    if (enabled && available) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performBiometricLogin();
      });
    }
  }

  Future<void> _performBiometricLogin() async {
    final hasBiometrics = await BiometricService.isBiometricAvailable();
    if (!hasBiometrics) {
      _showSnackBar("Biometric authentication is not supported or set up on this device.", isError: true);
      return;
    }

    final isEnabled = await BiometricService.isBiometricEnabled();
    if (!isEnabled) {
      _showSnackBar("Biometric login is not enabled. Please sign in with password first.", isError: true);
      return;
    }

    final authenticated = await BiometricService.authenticate();
    if (!authenticated) return;

    final creds = await BiometricService.getSavedCredentials();
    if (creds == null) {
      _showSnackBar("No saved account found. Please sign in with your password first.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final error = await ref.read(appStateProvider.notifier).signIn(
          identifier: creds['email']!,
          password: creds['password']!,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnackBar("Auto-login failed: ${error.replaceAll('AuthException: ', '').trim()}", isError: true);
      return;
    }

    final user = ref.read(appStateProvider).currentUser;
    if (!mounted || user == null) return;

    final Widget destination;
    if (user.role == 'merchant') {
      destination = const MerchantDashboardScreen();
    } else if (user.role == 'admin' || user.role == 'super_admin') {
      destination = const AdminDashboardScreen();
    } else {
      destination = const CustomerNavigation();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }



  // ─── Sign-in ───────────────────────────────────────────────────────────────

  void _signIn() async {
    if (!_signInKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref.read(appStateProvider.notifier).signIn(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnackBar(error.replaceAll('AuthException: ', '').trim(),
          isError: true);
      return;
    }

    final user = ref.read(appStateProvider).currentUser;
    if (!mounted || user == null) return;

    final Widget destination;
    if (user.role == 'merchant') {
      destination = const MerchantDashboardScreen();
    } else if (user.role == 'admin' || user.role == 'super_admin') {
      destination = const AdminDashboardScreen();
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
          businessName:
              _suRole == 'merchant' ? _suBizNameController.text.trim() : null,
          businessDescription:
              _suRole == 'merchant' ? _suBizDescController.text.trim() : null,
          businessCategory: _suRole == 'merchant' ? _suBizCategory : null,
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

    final Widget destination;
    if (_suRole == 'merchant') {
      destination = const MerchantDashboardScreen();
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
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // ── Gradient background accents ──
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.12),
                    AppTheme.primaryGreen.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF66BB6A).withValues(alpha: 0.1),
                    const Color(0xFF66BB6A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA5D6A7).withValues(alpha: 0.08),
                    const Color(0xFFA5D6A7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo & branding ──
                        _buildBrandHeader(),
                        const SizedBox(height: 16),

                        // ── Tab selector ──
                        _SlidingTabSelector(
                          activeIndex: _activeTab,
                          tabs: const ['Sign In', 'Create Account'],
                          onChanged: (index) =>
                              setState(() {
                                _activeTab = index;
                                _suStep = 0;
                              }),
                        ),
                        const SizedBox(height: 16),

                        // ── Form card ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<int>(_activeTab),
                                child: _activeTab == 0
                                    ? _buildSignInForm()
                                    : _buildRegisterForm(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Footer text ──
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms of Service\n& Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppTheme.mutedGrey.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBrandHeader() {
    return Center(
      child: Column(
        children: [
          // Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'DreamEats',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.charcoal,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
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
          // Welcome back text
          const Text(
            'Welcome back 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue rescuing meals',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.mutedGrey.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),

          // Email or Phone Number
          _buildInputField(
            controller: _emailController,
            label: 'Email or Phone Number',
            hint: 'you@example.com or 024xxxxxxx',
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
          const SizedBox(height: 16),

          // Password
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureSignIn,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignIn
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.mutedGrey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureSignIn = !_obscureSignIn),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
            autofillHints: const [],
          ),
          const SizedBox(height: 8),

          // Forgot password
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign In Button
          Row(
            children: [
              Expanded(
                child: _buildPrimaryButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _signIn,
                ),
              ),
              if (_isBiometricsAvailable && _isBiometricsEnabled) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: _isLoading ? null : _performBiometricLogin,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          _orDivider(),
          const SizedBox(height: 16),
          _socialButtons(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REGISTRATION FORM
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

  Widget _buildRegisterForm() {
    const totalSteps = 2;

    return Form(
      key: _signUpKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Professional Role Selection Banner
          Text(
            'Select Account Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedGrey.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildRoleTile(
            role: 'customer',
            title: 'Customer Account 🍔',
            subtitle: 'Order surplus food up to 70% off',
            icon: Icons.fastfood_rounded,
            isSelected: _suRole == 'customer',
            onTap: () => setState(() {
              _suRole = 'customer';
              _suStep = 0;
            }),
          ),
          const SizedBox(height: 12),
          _buildRoleTile(
            role: 'merchant',
            title: 'Merchant Partner 🏪',
            subtitle: 'Sell surplus food & earn new revenue',
            icon: Icons.storefront_rounded,
            isSelected: _suRole == 'merchant',
            onTap: () => setState(() {
              _suRole = 'merchant';
              _suStep = 0;
            }),
          ),
          const SizedBox(height: 22),

          // Step Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _suRole == 'customer'
                    ? (_suStep == 0 ? 'Step 1 of 2: Personal Info' : 'Step 2 of 2: Security & Terms')
                    : (_suStep == 0 ? 'Step 1 of 2: Account Security' : 'Step 2 of 2: Store Setup'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Text(
                '${((_suStep + 1) / totalSteps * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_suStep + 1) / totalSteps,
              backgroundColor: const Color(0xFFE5E8EC),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 18),

          // Step Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey<String>('$_suRole-$_suStep'),
              child: _buildRegisterStepContent(),
            ),
          ),
          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              if (_suStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _prevStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1.5),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 3,
                child: _buildPrimaryButton(
                  label: _suStep == 0
                      ? 'Next Step ➔'
                      : (_suRole == 'customer' ? 'Create Account' : 'Launch Store 🚀'),
                  onPressed: _isLoading ? null : _nextStep,
                ),
              ),
            ],
          ),

          // Only show social buttons on Step 0
          if (_suStep == 0) ...[
            const SizedBox(height: 16),
            _orDivider(),
            const SizedBox(height: 12),
            _socialButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleTile({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightGreenBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.charcoal.withValues(alpha: 0.85) : AppTheme.mutedGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterStepContent() {
    if (_suRole == 'customer') {
      if (_suStep == 0) {
        // Customer Step 0: Personal Contact
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Personal Contact Information',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _suNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suEmailController,
              label: 'Email Address',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suPhoneController,
              label: 'Phone Number (Optional)',
              hint: '0550 402 859',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        );
      } else {
        // Customer Step 1: Security & Terms
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Password & Security',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _suPasswordController,
              label: 'Create Password',
              hint: 'Min. 6 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureSignUp,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUp
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.mutedGrey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureSignUp = !_obscureSignUp),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
              autofillHints: const [],
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suConfirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.mutedGrey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _suPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              autofillHints: const [],
            ),
            const SizedBox(height: 20),
            _buildTermsCheckbox(),
          ],
        );
      }
    } else {
      // Merchant Flow
      if (_suStep == 0) {
        // Merchant Step 0: Contact & Security
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Merchant Account & Security',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            _buildInputField(
              controller: _suNameController,
              label: 'Manager Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suEmailController,
              label: 'Business Email Address',
              hint: 'store@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suPhoneController,
              label: 'Store Phone Number',
              hint: '0550 402 859',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone number required' : null,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _suPasswordController,
              label: 'Create Password',
              hint: 'Min. 6 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureSignUp,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUp
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.mutedGrey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureSignUp = !_obscureSignUp),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
              autofillHints: const [],
            ),
          ],
        );
      } else {
        // Merchant Step 1: Store Setup & Terms
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Store Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    controller: _suBizNameController,
                    label: 'Business Name',
                    hint: 'Your restaurant or bakery name',
                    icon: Icons.business_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Business name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _suBizDescController,
                    label: 'Short Description',
                    hint: 'What kind of delicious food do you offer?',
                    icon: Icons.description_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please describe your business'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _suBizAddressController,
                    label: 'Physical Address / Landmark',
                    hint: 'e.g., Osu Oxford Street, Accra',
                    icon: Icons.location_on_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Primary Food Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _suBizCategory,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.mutedGrey),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined,
                          color: AppTheme.primaryGreen, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color:
                                AppTheme.charcoal.withValues(alpha: 0.08)),
                      ),
                    ),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _suBizCategory = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTermsCheckbox(),
          ],
        );
      }
    }
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _agreeToTerms ? AppTheme.lightGreenBg : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _agreeToTerms ? AppTheme.primaryGreen : Colors.transparent),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
            activeColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("I agree to the ", style: TextStyle(fontSize: 12.5, color: AppTheme.charcoal)),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                  child: const Text("Terms of Service", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, decoration: TextDecoration.underline)),
                ),
                const Text(" and ", style: TextStyle(fontSize: 12.5, color: AppTheme.charcoal)),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  child: const Text("Privacy Policy", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedGrey.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
          autofillHints: autofillHints,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.mutedGrey.withValues(alpha: 0.45),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: AppTheme.charcoal,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppTheme.charcoal.withValues(alpha: 0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.errorRed, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: _HoverScale(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppTheme.primaryGreen.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }



  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.charcoal.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: AppTheme.mutedGrey.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.charcoal.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _socialButtons() {
    return Column(
      children: [
        _HoverScale(
          child: SizedBox(
            height: 46,
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.charcoal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                    color: AppTheme.charcoal.withValues(alpha: 0.1),
                    width: 1.5),
                elevation: 0,
              ),
              onPressed: () => _signInOAuth(OAuthProvider.google),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogoIcon(size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _HoverScale(
          child: SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => _signInOAuth(OAuthProvider.apple),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Apple',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIDING TAB SELECTOR
// ═══════════════════════════════════════════════════════════════════════════════

class _SlidingTabSelector extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final List<String> tabs;

  const _SlidingTabSelector({
    required this.activeIndex,
    required this.onChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: activeIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = activeIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppTheme.mutedGrey,
                        letterSpacing: -0.2,
                      ),
                      child: Text(tabs[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOVER SCALE EFFECT
// ═══════════════════════════════════════════════════════════════════════════════

class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});

  final double hoverScale = 1.02;

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
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
