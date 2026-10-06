import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/config.dart';
import 'core/cache_manager.dart';
import 'features/auth/admin_login_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive offline cache
  await CacheManager().init();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  runApp(
    const ProviderScope(
      child: DreamEatsAdminApp(),
    ),
  );
}

class DreamEatsAdminApp extends ConsumerWidget {
  const DreamEatsAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DREAMEATS ADMIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      // On the admin port, the home is ALWAYS the admin login
      home: const AdminLoginScreen(),
    );
  }
}
