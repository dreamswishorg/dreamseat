/// Application configuration constants.
/// Supabase and Paystack keys are embedded here for the DreamEats app.
class AppConfig {
  // ─── Supabase ─────────────────────────────────────────────────────────────
  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://trhefcuuhwavbdqhgamr.supabase.co',
  );

  /// Supabase anon/publishable key (safe for client — RLS protects data)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyaGVmY3V1aHdhdmJkcWhnYW1yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxOTc3NjgsImV4cCI6MjA5Nzc3Mzc2OH0.hoEq_NPK-wbcyYAfFYAXOUEeTGjvmk77ukX_YSKUwN4',
  );

  /// Supabase service role key — NEVER embed in Flutter client.
  /// Only used in server-side Edge Functions (set as a Supabase secret).
  // SUPABASE_SERVICE_ROLE_KEY = set via: supabase secrets set SERVICE_ROLE_KEY=eyJ...

  // ─── Paystack ─────────────────────────────────────────────────────────────
  /// Paystack live public key
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_live_e6500f08c004c1a3bd280e13937920e745f095ea',
  );

  /// Paystack live secret key — NEVER embedded in client.
  /// Server-side payment operations are executed via Supabase Edge Functions.
  static String get paystackSecretKey {
    return const String.fromEnvironment('PAYSTACK_SECRET_KEY', defaultValue: '');
  }

  static const bool isLive = bool.fromEnvironment(
    'PAYSTACK_LIVE',
    defaultValue: true,
  );

  // ─── Firebase ─────────────────────────────────────────────────────────────
  /// Firebase project ID (used for FCM via Edge Function)
  static const String firebaseProjectId = 'dreamseat-75ed1';

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'DreamEats';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@winningedgeinvestment.com';
  static const String websiteUrl = 'https://dreameats.fly.dev';
  static const String privacyPolicyUrl = 'https://dreameats.fly.dev/privacy.html';
  static const String termsOfServiceUrl = 'https://dreameats.fly.dev/terms.html';
  static const String currency = 'GHS';
  static const String currencyCode = 'GHS';

  // ─── SMTP (used only in Edge Functions) ───────────────────────────────────
  // Configured purely via Supabase secrets:
  // supabase secrets set SMTP_HOST=... SMTP_PORT=587 SMTP_USER=... SMTP_PASS=... SMTP_FROM_NAME=DreamEats

  // ─── Feature Flags ────────────────────────────────────────────────────────
  static const bool enableRealtime = true;
  static const bool enableOfflineCache = true;
  static const bool enablePushNotifications = true;
}
