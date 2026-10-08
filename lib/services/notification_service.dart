import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/email_templates.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Firebase Cloud Messaging registration, token management,
/// and all incoming push notification routing for DreamEats.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId = 'dreameats_default';
  static const String _defaultChannelName = 'DreamEats Alerts';
  static const String _defaultChannelDesc =
      'Order confirmations, deal alerts, and platform updates.';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Call this in main() after Supabase.initialize() and Firebase.initializeApp().
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Local notifications setup
    await _setupLocalNotifications();

    // 2. Request permission (iOS/Android 13+)
    await _requestPermission();

    // 3. Get FCM token and store it
    await _refreshToken();

    // 4. Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToSupabase(newToken);
    });

    // 5. Foreground message handler → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 6. Tap on notification when app is in background (opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data, navigatorKey);
    });

    // 7. Check if app was opened via a notification (terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Small delay to let the app fully load first
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage.data, navigatorKey);
      });
    }

    // 8. Subscribe to global topics
    if (!kIsWeb) {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    }
  }

  /// Subscribe to role-specific notification topic after login.
  Future<void> subscribeToRoleTopic(String role) async {
    if (kIsWeb) return;
    if (role == 'customer') {
      await FirebaseMessaging.instance.subscribeToTopic('all_customers');
    } else if (role == 'merchant') {
      await FirebaseMessaging.instance.subscribeToTopic('all_merchants');
    } else if (role == 'admin' || role == 'super_admin') {
      await FirebaseMessaging.instance.subscribeToTopic('all_admins');
    }
  }

  /// Unsubscribe from all role topics on logout.
  Future<void> unsubscribeFromRoleTopics() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic('all_customers');
    await FirebaseMessaging.instance.unsubscribeFromTopic('all_merchants');
    await FirebaseMessaging.instance.unsubscribeFromTopic('all_admins');
  }

  // ─── Local Notification Setup ────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        // Handle tap on local notification (foreground)
        if (details.payload != null) {
          // Payload is a JSON string with routing data
        }
      },
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('NotificationService: Notifications not permitted in browser/device settings.');
        return;
      }

      // Required for iOS foreground notifications
      if (!kIsWeb) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: requestPermission ignored: $e');
    }
  }

  Future<void> _refreshToken() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Suppress token request if user/browser has blocked notifications
        return;
      }
      _fcmToken = await FirebaseMessaging.instance.getToken();
      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
        debugPrint('NotificationService: FCM token obtained');
      }
    } catch (e) {
      debugPrint('NotificationService: Push notifications skipped ($e)');
    }
  }

  /// Persists the FCM token to the user's profile in Supabase so
  /// Edge Functions can send targeted notifications.
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Update the profiles table with the device's FCM token
      await Supabase.instance.client
          .from('device_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'platform': _getPlatform(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('NotificationService: Failed to save token: $e');
    }
  }

  // ─── Message Handling ────────────────────────────────────────────────────

  /// Shows a local notification for foreground FCM messages.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannelId,
          _defaultChannelName,
          channelDescription: _defaultChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D32),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Displays an instant heads-up device notification banner with sound and badge.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            _defaultChannelName,
            channelDescription: _defaultChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF2E7D32),
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      debugPrint('NotificationService: local notification error: $e');
    }
  }

  /// Routes the user to the correct screen based on notification data.
  void _handleNotificationTap(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final screen = data['screen'] as String?;
    final dealId = data['dealId'] as String?;
    final orderId = data['orderId'] as String?;

    debugPrint('NotificationService: tap → screen=$screen dealId=$dealId orderId=$orderId');

    if (screen == null) return;

    // Direct navigation if navigatorKey is ready
    if (navigatorKey.currentState != null) {
      _navigateToScreen(screen, dealId, orderId, navigatorKey);
    } else {
      // Store for later consumption if app is still starting
      _pendingNavigationData = {
        'screen': screen,
        'dealId': dealId,
        'orderId': orderId,
      };
    }
  }

  void _navigateToScreen(
    String screen,
    String? dealId,
    String? orderId,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (screen) {
      case 'deal_detail':
        if (dealId != null) {
          // In a real app, we might need to fetch the deal first if not in state
          // but for now we assume it's available or we show a loading state
          // Navigation logic here...
        }
        break;
      case 'order_history':
        // Navigate to Order History
        break;
      case 'merchant_dashboard':
        // Navigate to Merchant Dashboard
        break;
    }
  }

  // ─── Pending Navigation State ────────────────────────────────────────────
  // Used to route user after app fully loads from terminated state

  Map<String, dynamic>? _pendingNavigationData;

  /// Returns and clears any pending navigation data from a tapped notification.
  Map<String, dynamic>? consumePendingData() {
    final data = _pendingNavigationData;
    _pendingNavigationData = null;
    return data;
  }

  // ─── Sending Notifications (Client → Edge Function) ─────────────────────

  /// Sends a push notification via the Supabase Edge Function.
  /// Use this for targeted notifications (e.g., merchant notified of new order).
  /// The optional `type` parameter allows the edge function to identify the notification purpose.
  Future<bool> sendNotification(Map<String, dynamic> payload, {String? type}) async {
    if (payload['token'] == null || (payload['token'] as String).trim().isEmpty) {
      debugPrint('NotificationService: Skipped push notification because token is empty.');
      return false;
    }
    try {
      // Include the notification type if provided.
      final requestBody = {
        'type': ?type,
        ...payload,
      };
      final response = await Supabase.instance.client.functions.invoke(
        'send-push-notification',
        body: requestBody,
      );
      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('NotificationService: Failed to send notification: $e');
      return false;
    }
  }

  /// Sends a transactional email via the Supabase Edge Function.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    String? template,
    Map<String, String>? data,
    String? html,
  }) async {
    if (to.trim().isEmpty || subject.trim().isEmpty) {
      debugPrint('NotificationService: Skipped email because "to" or "subject" is empty.');
      return false;
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-email',
        body: {
          'to': to.trim(),
          'subject': subject.trim(),
          'template': ?template,
          'data': ?data,
          'html': ?html,
        },
      );
      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('NotificationService: Failed to send email: $e');
      return false;
    }
  }

  // ─── Convenience Notification Methods ───────────────────────────────────

  /// Notifies a merchant of a new order.
  Future<void> notifyMerchantNewOrder({
    required String merchantFcmToken,
    required String merchantEmail,
    required String merchantName,
    required String customerName,
    required String dealTitle,
    required String collectionCode,
    required String price,
    required String paymentMethod,
    required String orderId,
  }) async {
    // 1. Push notification
    if (merchantFcmToken.isNotEmpty) {
      await sendNotification({
        'type': 'new_order_merchant',
        'token': merchantFcmToken,
        'customerName': customerName,
        'dealTitle': dealTitle,
        'collectionCode': 'AWAITING PICKUP',
        'price': price,
        'orderId': orderId,
      });
    }

    // 2. Polished Email notification
    if (merchantEmail.trim().isNotEmpty) {
      await sendEmail(
        to: merchantEmail,
        subject: '🛍️ New Order — $dealTitle',
        html: EmailTemplates.merchantNewOrder(
          merchantName: merchantName,
          customerName: customerName,
          dealTitle: dealTitle,
          price: price,
          collectionCode: 'AWAITING PICKUP',
        ),
      );
    } else {
      debugPrint('NotificationService: Skipped merchant email because merchantEmail is empty.');
    }
  }

  /// Sends order confirmation to customer.
  Future<void> notifyCustomerOrderConfirmed({
    required String customerEmail,
    required String customerName,
    required String dealTitle,
    required String businessName,
    required String collectionCode,
    required String price,
    required String paymentMethod,
    required String orderId,
    String? pickupWindow,
  }) async {
    // Polished Email with beautiful HTML template
    if (customerEmail.trim().isNotEmpty) {
      await sendEmail(
        to: customerEmail,
        subject: '✅ Order Confirmed — $dealTitle',
        html: EmailTemplates.orderConfirmed(
          customerName: customerName,
          dealTitle: dealTitle,
          businessName: businessName,
          collectionCode: collectionCode,
          price: price,
          pickupWindow: pickupWindow ?? 'During the pickup window',
        ),
      );
    } else {
      debugPrint('NotificationService: Skipped customer email because customerEmail is empty.');
    }
  }

  /// Sends welcome email after signup.
  Future<void> sendWelcomeEmail({
    required String email,
    required String name,
  }) async {
    await sendEmail(
      to: email,
      subject: '🌿 Welcome to DreamEats, $name!',
      html: EmailTemplates.welcome(name),
    );
  }

  /// Sends merchant approval email.
  Future<void> sendMerchantApprovalEmail({
    required String email,
    required String merchantName,
  }) async {
    await sendEmail(
      to: email,
      subject: '🎉 Your Merchant Profile is Approved!',
      html: EmailTemplates.merchantApproved(merchantName),
    );
  }

  /// Sends dispute resolution email.
  Future<void> sendDisputeResolvedEmail({
    required String email,
    required String ticketId,
    required String resolution,
  }) async {
    await sendEmail(
      to: email,
      subject: '✅ Dispute Resolved — Ticket #$ticketId',
      html: EmailTemplates.disputeResolved(ticketId, resolution),
    );
  }

  // ─── Utility ────────────────────────────────────────────────────────────

  String _getPlatform() {
    // dart:io Platform detection works for mobile; web uses a fallback
    try {
      // ignore: do_not_use_environment
      const bool isWeb = identical(0, 0.0);
      if (isWeb) return 'web';
    } catch (_) {}
    return 'mobile';
  }
}
