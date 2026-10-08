import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme.dart';
import 'core/config.dart';
import 'core/cache_manager.dart';
import 'core/responsive.dart';
import 'core/web_utils.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/customer/customer_navigation.dart';
import 'features/merchant/merchant_dashboard.dart';
import 'features/admin/admin_dashboard.dart';

import 'providers/app_state.dart';

/// Background message handler — must be a top-level function (not a closure).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message: ${message.messageId}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait non-blocking
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  if (kIsWeb && hasSessionInLocalStorage()) {
    clearUrlParams();
  }

  // 1 & 2 & 3. Initialize Hive cache, Supabase, and Firebase in parallel
  await Future.wait([
    CacheManager().init(),
    Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 2,
      ),
    ),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ]);

  clearUrlParams();

  // 4. Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5. Initialize push notifications (non-blocking)
  NotificationService().initialize(navigatorKey).catchError((e) {
    debugPrint('Notification initialization failed: $e');
  });

  runApp(
    const ProviderScope(
      child: DreamEatsApp(),
    ),
  );
}

class DreamEatsApp extends ConsumerStatefulWidget {
  const DreamEatsApp({super.key});

  @override
  ConsumerState<DreamEatsApp> createState() => _DreamEatsAppState();
}

class _DreamEatsAppState extends ConsumerState<DreamEatsApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
            (route) => false,
          );
        } else if (data.event == AuthChangeEvent.signedIn) {
          clearUrlParams();
          // If currentUser is already set in appState, in-app sign-in / registration
          // has already navigated directly. Skip redundant navigation to prevent screen flash.
          if (ref.read(appStateProvider).currentUser != null) {
            return;
          }

          // Hydrate profile and navigate if user is signed in via external OAuth / deep link
          final profile = await ref.read(appStateProvider.notifier).handleOAuthSignedIn();
          if (!mounted || profile == null || navigatorKey.currentState == null) return;

          final Widget destination;
          if (profile.role == 'merchant') {
            destination = const MerchantDashboardScreen();
          } else if (profile.role == 'admin' || profile.role == 'super_admin') {
            destination = const AdminDashboardScreen();
          } else {
            destination = const CustomerNavigation();
          }
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => destination),
            (route) => false,
          );
        } else if (data.event == AuthChangeEvent.signedOut) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        }
      });
    } catch (_) {
      _authSub = null;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appStateProvider.select((s) => s.platformSettings));

    if (settings.maintenanceMode) {
      return MaterialApp(
        title: 'DREAMEATS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) => ResponsiveAppWrapper(child: child),
        home: const MaintenanceScreen(),
      );
    }

    return MaterialApp(
      title: 'DREAMEATS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      navigatorKey: navigatorKey,
      builder: (context, child) => ResponsiveAppWrapper(child: child),
      home: const SplashScreen(),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
                child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryGreen, size: 64),
              ),
              const SizedBox(height: 32),
              const Text("System Optimization", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.charcoal, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              const Text(
                "DREAMEATS is currently undergoing scheduled maintenance to improve our rescue engine. We'll be back online in Accra shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mutedGrey, height: 1.5, fontSize: 14),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }
}
