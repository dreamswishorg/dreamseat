import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import 'welcome_screen.dart';
import '../customer/customer_navigation.dart';
import '../merchant/merchant_dashboard.dart';
import '../admin/admin_dashboard.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  
  PlatformSettings? _fetchedSettings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _initSplash();
  }

  Future<void> _initSplash() async {
    if (mounted) _controller.forward();

    bool hasSession = false;
    try {
      hasSession = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {}

    // Concurrently fetch settings
    SupabaseService().fetchPlatformSettings().then((s) {
      _fetchedSettings = s;
    }).catchError((_) {
      // ignore
    }).whenComplete(() {
      _isLoadingSettings = false;
    });

    final isCallback = kIsWeb &&
        (Uri.base.queryParameters.containsKey('code') || Uri.base.fragment.contains('access_token'));

    // Drastically reduced delay for lightning fast entry:
    final minDelayMs = isCallback ? 150 : (hasSession ? 400 : 800);
    
    await Future.delayed(Duration(milliseconds: minDelayMs));

    // Wait for settings to complete loading (up to 1.5 seconds maximum timeout)
    int waitCount = 0;
    while (_isLoadingSettings && waitCount < 15) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }

    if (mounted) {
      _navigate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isUpdateRequired(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minimum.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minParts[i]) return true;
        if (currentParts[i] > minParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _navigate() {
    if (!mounted) return;

    final settings = _fetchedSettings ?? ref.read(appStateProvider).platformSettings;

    if (settings.maintenanceMode) {
      _showBlockingScreen(
        title: 'Maintenance in Progress',
        message: 'DreamEats is currently undergoing scheduled maintenance to improve our service. Please check back soon!',
        icon: Icons.construction_rounded,
      );
      return;
    }

    if (_isUpdateRequired(AppConfig.appVersion, settings.minAppVersion)) {
      _showBlockingScreen(
        title: 'Update Required',
        message: 'A new version of DreamEats is available with critical improvements. Please update to continue.',
        icon: Icons.system_update_rounded,
        buttonText: 'Update Now',
        onButtonPressed: () {},
      );
      return;
    }

    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {}

    if (session == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const WelcomeScreen(),
              transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 450),
            ),
          );
        });
      }
      return;
    }

    final state = ref.read(appStateProvider);
    final user = state.currentUser;

    if (user == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const WelcomeScreen(),
              transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 450),
            ),
          );
        });
      }
      return;
    }

    Widget targetScreen;
    if (user.role == 'admin' || user.role == 'super_admin') {
      targetScreen = const AdminDashboardScreen();
    } else if (user.role == 'merchant') {
      targetScreen = const MerchantDashboardScreen();
    } else {
      targetScreen = const CustomerNavigation();
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => targetScreen,
            transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
      });
    }
  }

  void _showBlockingScreen({
    required String title,
    required String message,
    required IconData icon,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedGrey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (buttonText != null && onButtonPressed != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: onButtonPressed,
                      child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle professional top-right & bottom-left emerald glow gradients
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C853).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Splash Content
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Beautiful balanced White & Green Logo Container
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: AppTheme.primaryGreen, width: 3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.restaurant_rounded,
                                      size: 54,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Clean Modern Typography
                            Text(
                              'DREAMEATS',
                              style: TextStyle(
                                fontSize: (screenW * 0.09).clamp(28.0, 40.0),
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0D3B22),
                                letterSpacing: 3.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Green Accent Divider
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Professional Pill Tagline
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F4),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'RESCUE SURPLUS • SAVOR QUALITY',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D3B22),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}
