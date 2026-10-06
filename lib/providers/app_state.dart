import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../core/cache_manager.dart';
import '../core/email_templates.dart';
import '../core/config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppState
// ─────────────────────────────────────────────────────────────────────────────

class AppState {
  final AppUser? currentUser;
  final List<AppUser> users;
  final List<BusinessProfile> businesses;
  final List<FoodDeal> deals;
  final List<Order> orders;
  final List<AppNotification> notifications;
  final List<DisputeTicket> disputes;
  final List<BasketItem> basket;
  final Set<String> favoriteBusinessIds;
  final int customerDreamPoints;
  final double customerReferralCredit;
  final List<String> referredEmails;
  final SustainabilityStats globalStats;
  final SustainabilityStats customerStats;
  final double commissionRate;
  final PlatformSettings platformSettings;
  final List<AuditLog> auditLogs;
  final List<Voucher> vouchers;
  final List<BroadcastMessage> broadcasts;
  final List<SupportTicket> supportTickets;
  final ThemeMode themeMode;
  final bool isLoading;
  final String? errorMessage;

  const AppState({
    required this.currentUser,
    required this.users,
    required this.businesses,
    required this.deals,
    required this.orders,
    required this.notifications,
    required this.disputes,
    required this.basket,
    required this.favoriteBusinessIds,
    required this.customerDreamPoints,
    required this.customerReferralCredit,
    required this.referredEmails,
    required this.globalStats,
    required this.customerStats,
    required this.platformSettings,
    this.auditLogs = const [],
    this.vouchers = const [],
    this.broadcasts = const [],
    this.supportTickets = const [],
    this.themeMode = ThemeMode.light,
    this.commissionRate = 0.15,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Factory for a fully empty/logged-out state.
  static AppState empty() => AppState(
        currentUser: null,
        users: const [],
        businesses: const [],
        deals: const [],
        orders: const [],
        notifications: const [],
        disputes: const [],
        basket: const [],
        favoriteBusinessIds: const {},
        customerDreamPoints: 0,
        customerReferralCredit: 0.0,
        referredEmails: const [],
        globalStats: SustainabilityStats.zero(),
        customerStats: SustainabilityStats.zero(),
        platformSettings: PlatformSettings.defaultSettings(),
        auditLogs: const [],
        vouchers: const [],
        broadcasts: const [],
        supportTickets: const [],
        themeMode: ThemeMode.light,
        commissionRate: 0.15,
        isLoading: false,
        errorMessage: null,
      );

  AppState copyWith({
    AppUser? currentUser,
    bool nullCurrentUser = false,
    List<AppUser>? users,
    List<BusinessProfile>? businesses,
    List<FoodDeal>? deals,
    List<Order>? orders,
    List<AppNotification>? notifications,
    List<DisputeTicket>? disputes,
    List<BasketItem>? basket,
    Set<String>? favoriteBusinessIds,
    int? customerDreamPoints,
    double? customerReferralCredit,
    List<String>? referredEmails,
    SustainabilityStats? globalStats,
    SustainabilityStats? customerStats,
    double? commissionRate,
    PlatformSettings? platformSettings,
    List<AuditLog>? auditLogs,
    List<Voucher>? vouchers,
    List<BroadcastMessage>? broadcasts,
    List<SupportTicket>? supportTickets,
    ThemeMode? themeMode,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AppState(
      currentUser: nullCurrentUser ? null : (currentUser ?? this.currentUser),
      users: users ?? this.users,
      businesses: businesses ?? this.businesses,
      deals: deals ?? this.deals,
      orders: orders ?? this.orders,
      notifications: notifications ?? this.notifications,
      disputes: disputes ?? this.disputes,
      basket: basket ?? this.basket,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      customerDreamPoints: customerDreamPoints ?? this.customerDreamPoints,
      customerReferralCredit:
          customerReferralCredit ?? this.customerReferralCredit,
      referredEmails: referredEmails ?? this.referredEmails,
      globalStats: globalStats ?? this.globalStats,
      customerStats: customerStats ?? this.customerStats,
      commissionRate: commissionRate ?? this.commissionRate,
      platformSettings: platformSettings ?? this.platformSettings,
      auditLogs: auditLogs ?? this.auditLogs,
      vouchers: vouchers ?? this.vouchers,
      broadcasts: broadcasts ?? this.broadcasts,
      supportTickets: supportTickets ?? this.supportTickets,
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }


  double get basketTotal =>
      basket.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get basketItemCount =>
      basket.fold(0, (sum, item) => sum + item.quantity);

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppStateManager
// ─────────────────────────────────────────────────────────────────────────────

class AppStateManager extends Notifier<AppState> {
  final _supa = SupabaseService();

  List<BasketItem> _basket = [];
  double _commissionRate = 0.15;
  BusinessProfile? _merchantBusiness;

  RealtimeChannel? _dealsSub;
  RealtimeChannel? _ordersSub;
  RealtimeChannel? _notificationsSub;
  Timer? _refreshTimer;

  // ─── build ────────────────────────────────────────────────────

  @override
  AppState build() {
    final cache = CacheManager();
    final cachedUser = cache.getCurrentUser();
    final cachedDeals = cache.getDeals();
    final cachedBusinesses = cache.getBusinesses();
    final cachedOrders = cache.getOrders();
    final cachedFavorites = cache.getFavorites();
    final cachedCustomerStats = cache.getCustomerStats();
    final cachedGlobalStats = cache.getGlobalStats();
    final cachedDreamPoints = cache.getDreamPoints();
    final cachedReferralCredit = cache.getReferralCredit();
    final cachedDisputes = cache.getDisputes();
    final cachedNotifications = cache.getNotifications();
    _basket = cache.getBasket();
    _commissionRate = 0.15;

    // Fire-and-forget async hydration from Supabase.
    Future.microtask(() => _hydrate());

    return AppState(
      currentUser: cachedUser,
      users: const [],
      businesses: cachedBusinesses,
      deals: cachedDeals,
      orders: cachedOrders,
      notifications: cachedNotifications,
      disputes: cachedDisputes,
      basket: List.from(_basket),
      favoriteBusinessIds: cachedFavorites,
      customerDreamPoints: cachedDreamPoints,
      customerReferralCredit: cachedReferralCredit,
      referredEmails: const [],
      globalStats: cachedGlobalStats,
      customerStats: cachedCustomerStats,
      commissionRate: _commissionRate,
      platformSettings: PlatformSettings.defaultSettings(),
      isLoading: false,
      errorMessage: null,
    );
  }

  // ─── Hydration ────────────────────────────────────────────────

  Future<void> _hydrate() async {
    if (!_supa.isAuthenticated) {
      // Even if not logged in, fetch platform settings for version check/maintenance
      try {
        final settings = await _supa.fetchPlatformSettings();
        state = state.copyWith(platformSettings: settings);
      } catch (_) {}
      return;
    }
    try {
      // Phase 1: Load critical landing data (Profile, Businesses, Deals, Settings) in parallel.
      final results = await Future.wait([
        _supa.getCurrentUserProfile(),
        _supa.fetchBusinesses(),
        _supa.fetchDeals(),
        _supa.fetchPlatformSettings(),
      ]);

      final profile = results[0] as AppUser?;
      final businesses = List<BusinessProfile>.from(results[1] as List<BusinessProfile>);
      final deals = results[2] as List<FoodDeal>;
      final platformSettings = results[3] as PlatformSettings;

      _commissionRate = platformSettings.commissionRate;

      // Instantly update the state with core data so navigation / UI can load immediately!
      state = state.copyWith(
        currentUser: profile,
        businesses: businesses,
        deals: deals,
        platformSettings: platformSettings,
        commissionRate: _commissionRate,
        clearErrorMessage: true,
      );

      // Save initial cache to prevent empty screen flashes
      _updateCache();

      // Phase 2: Load secondary data in the background (non-blocking)
      _hydrateBackground(profile);
      startBackgroundRefresh();
    } catch (_) {
      // Silently fail — cached data remains visible.
    }
  }

  Future<void> _hydrateBackground(AppUser? profile) async {
    if (profile == null) return;

    try {
      // 1. Setup Realtime Subscriptions (Parallel & Non-blocking)
      if (_notificationsSub != null) Supabase.instance.client.removeChannel(_notificationsSub!);
      if (_dealsSub != null) Supabase.instance.client.removeChannel(_dealsSub!);
      if (_ordersSub != null) Supabase.instance.client.removeChannel(_ordersSub!);

      _notificationsSub = _supa.subscribeToNotifications(_supa.currentUserId!, (updatedNotifs) {
        state = state.copyWith(notifications: updatedNotifs);
        CacheManager().saveNotifications(updatedNotifs);
      });

      _dealsSub = _supa.subscribeToDeals((updatedDeals) {
        state = state.copyWith(deals: updatedDeals);
        CacheManager().saveDeals(updatedDeals);
      });

      _ordersSub = _supa.subscribeToOrders(_supa.currentUserId!, profile.role, (updatedOrders) {
        state = state.copyWith(orders: updatedOrders);
        CacheManager().saveOrders(updatedOrders);
      });

      // 2. Parallel Data Fetching
      final List<Order> orders;
      final List<AppNotification> notifications;
      final Set<String> favorites;

      final backgroundResults = await Future.wait([
        _supa.fetchNotifications(_supa.currentUserId!),
        _supa.fetchFavorites(_supa.currentUserId!),
        if (profile.role == 'customer')
          _supa.fetchCustomerOrders(_supa.currentUserId!)
        else if (profile.role == 'merchant')
           (getMerchantBusiness()?.id.isNotEmpty == true)
               ? _supa.fetchMerchantOrders(getMerchantBusiness()!.id)
               : Future.value(<Order>[])
        else
          _supa.fetchAllOrders(),
      ]);

      notifications = backgroundResults[0] as List<AppNotification>;
      favorites = backgroundResults[1] as Set<String>;
      orders = backgroundResults[2] as List<Order>;

      List<DisputeTicket> disputes = [];
      List<AppUser> users = [];
      List<AuditLog> auditLogs = [];
      List<Voucher> vouchers = [];
      List<BroadcastMessage> broadcasts = [];
      List<SupportTicket> supportTickets = [];

      if (profile.role == 'admin' || profile.role == 'super_admin') {
        final adminResults = await Future.wait([
          _supa.fetchDisputes(),
          _supa.fetchAllUsers(),
          _supa.fetchAuditLogs(),
          _supa.fetchVouchers(),
          _supa.fetchBroadcasts(),
          _supa.fetchSupportTickets(),
        ]);
        disputes = adminResults[0] as List<DisputeTicket>;
        users = adminResults[1] as List<AppUser>;
        auditLogs = adminResults[2] as List<AuditLog>;
        vouchers = adminResults[3] as List<Voucher>;
        broadcasts = adminResults[4] as List<BroadcastMessage>;
        supportTickets = adminResults[5] as List<SupportTicket>;
      }

      // 3. Merchant Specific (Conditional)
      if (profile.role == 'merchant' && _merchantBusiness == null) {
        final merchantBusiness = await _supa.fetchMerchantBusiness(_supa.currentUserId!);
        if (merchantBusiness != null) {
          _merchantBusiness = merchantBusiness;
          final merchantOrders = await _supa.fetchMerchantOrders(merchantBusiness.id);

          final currentBusinesses = List<BusinessProfile>.from(state.businesses);
          if (!currentBusinesses.any((b) => b.id == merchantBusiness.id)) {
            currentBusinesses.add(merchantBusiness);
          }
          state = state.copyWith(businesses: currentBusinesses, orders: merchantOrders);
        }
      }

      // Calculate Stats
      SustainabilityStats globalStats = state.globalStats;
      if (profile.role == 'admin' || profile.role == 'super_admin') {
        globalStats = SustainabilityStats.zero();
        for (final o in orders) {
          if (o.status == 'collected' || o.status == 'reserved') {
            final savings = o.originalPrice - o.price;
            globalStats = globalStats.addMeal(savings > 0 ? savings : 0, o.price);
          }
        }
      }

      SustainabilityStats customerStats = SustainabilityStats.zero();
      if (profile.role == 'customer') {
        for (final o in orders) {
          if (o.status == 'collected' || o.status == 'reserved') {
            final savings = o.originalPrice - o.price;
            customerStats = customerStats.addMeal(savings > 0 ? savings : 0, o.price);
          }
        }
      }

      state = state.copyWith(
        orders: orders,
        notifications: notifications,
        favoriteBusinessIds: favorites,
        disputes: disputes,
        users: users,
        auditLogs: auditLogs,
        vouchers: vouchers,
        broadcasts: broadcasts,
        supportTickets: supportTickets,
        customerDreamPoints: profile.dreamPoints,
        customerReferralCredit: profile.referralCredit,
        customerStats: profile.role == 'customer' ? customerStats : state.customerStats,
        globalStats: (profile.role == 'admin' || profile.role == 'super_admin') ? globalStats : state.globalStats,
      );

      _updateCache();
    } catch (e) {
      debugPrint('Background hydration error: $e');
    }
  }


  // ─── Cache helpers ────────────────────────────────────────────

  void _updateCache() {
    final cache = CacheManager();
    cache.saveCurrentUser(state.currentUser);
    cache.saveDeals(state.deals);
    cache.saveBusinesses(state.businesses);
    cache.saveOrders(state.orders);
    cache.saveDisputes(state.disputes);
    cache.saveFavorites(state.favoriteBusinessIds);
    cache.saveCustomerStats(state.customerStats);
    cache.saveGlobalStats(state.globalStats);
    cache.saveDreamPoints(state.customerDreamPoints);
    cache.saveReferralCredit(state.customerReferralCredit);
    cache.saveBasket(_basket);
  }

  void _syncBasket() {
    state = state.copyWith(basket: List.from(_basket));
    CacheManager().saveBasket(_basket);
  }

  // ─── Getters ─────────────────────────────────────────────────

  AppUser? get currentUser => state.currentUser;
  List<AppUser> get users => state.users;
  List<BusinessProfile> get businesses => state.businesses;
  List<FoodDeal> get deals => state.deals;
  List<Order> get orders => state.orders;
  List<DisputeTicket> get disputes => state.disputes;
  List<BasketItem> get basket => _basket;
  Set<String> get favoriteBusinessIds => state.favoriteBusinessIds;
  int get customerDreamPoints => state.customerDreamPoints;
  double get customerReferralCredit => state.customerReferralCredit;
  List<String> get referredEmails => state.referredEmails;
  SustainabilityStats get globalStats => state.globalStats;
  SustainabilityStats get customerStats => state.customerStats;
  double get commissionRate => _commissionRate;

  BusinessProfile? getMerchantBusiness() {
    if (_merchantBusiness != null) return _merchantBusiness;
    final uid = state.currentUser?.id ?? _supa.currentUserId;
    if (uid != null && uid.isNotEmpty) {
      for (final b in state.businesses) {
        if (b.ownerId == uid) {
          _merchantBusiness = b;
          return b;
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────────

  /// Returns null on success, error message string on failure.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? businessName,
    String? businessDescription,
    String? businessCategory,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final error = await _supa.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        businessName: businessName,
        businessDescription: businessDescription,
        businessCategory: businessCategory,
      );
      if (error == 'needs_confirmation') {
        state = state.copyWith(isLoading: false);
        return 'needs_confirmation';
      }
      if (error != null) {
        state = state.copyWith(isLoading: false, errorMessage: error);
        return error;
      }

      // Send Polished Welcome Email (if email provided)
      if (email.isNotEmpty) {
        try {
          await NotificationService().sendWelcomeEmail(email: email, name: name);
        } catch (_) {}
      }

      await _hydrate();
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  /// Returns null on success, error message string on failure.
  Future<String?> signIn({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final isEmail = identifier.contains('@');
      final String? email = isEmail ? identifier.trim() : null;
      final String? phone = isEmail ? null : identifier.trim();

      final error = await _supa.signIn(
        email: email,
        phone: phone,
        password: password,
      );
      if (error != null) {
        state = state.copyWith(isLoading: false, errorMessage: error);
        return error;
      }

      await _hydrate();
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  Future<String?> validateCurrentPassword({
    required String email,
    required String password,
  }) async {
    try {
      final client = SupabaseClient(AppConfig.supabaseUrl, AppConfig.supabaseAnonKey);
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return 'Validation failed.';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _supa.signInWithOAuth(provider);
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  Future<AppUser?> handleOAuthSignedIn() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    await _hydrate();
    state = state.copyWith(isLoading: false);
    return state.currentUser;
  }

  Future<void> signOut() async {
    stopBackgroundRefresh();
    await _supa.signOut();
    _basket = [];
    _merchantBusiness = null;
    if (_dealsSub != null) Supabase.instance.client.removeChannel(_dealsSub!);
    if (_ordersSub != null) Supabase.instance.client.removeChannel(_ordersSub!);
    if (_notificationsSub != null) Supabase.instance.client.removeChannel(_notificationsSub!);
    await CacheManager().clearAll();
    state = AppState.empty();
  }

  Future<String?> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final error = await _supa.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      if (error != null) {
        state = state.copyWith(errorMessage: error);
        return error;
      }
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final error = await _supa.updatePassword(newPassword);
      if (error != null) {
        state = state.copyWith(isLoading: false, errorMessage: error);
        return error;
      }

      await _hydrate();
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  Future<String?> updateUserProfile({String? name, String? phone}) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final error = await _supa.updateProfile(name: name, phone: phone);
      if (error != null) {
        state = state.copyWith(isLoading: false, errorMessage: error);
        return error;
      }

      await _hydrate();
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return msg;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BASKET
  // ─────────────────────────────────────────────────────────────

  void addToBasket(FoodDeal deal, {int qty = 1}) {
    final idx = _basket.indexWhere((i) => i.deal.id == deal.id);
    if (idx != -1) {
      _basket[idx] =
          _basket[idx].copyWith(quantity: _basket[idx].quantity + qty);
    } else {
      _basket.add(BasketItem(deal: deal, quantity: qty));
    }
    _syncBasket();
  }

  void updateBasketQuantity(String dealId, int qty) {
    if (qty <= 0) {
      removeFromBasket(dealId);
      return;
    }
    final idx = _basket.indexWhere((i) => i.deal.id == dealId);
    if (idx != -1) {
      _basket[idx] = _basket[idx].copyWith(quantity: qty);
      _syncBasket();
    }
  }

  void removeFromBasket(String dealId) {
    _basket.removeWhere((i) => i.deal.id == dealId);
    _syncBasket();
  }

  void clearBasket() {
    _basket = [];
    _syncBasket();
  }

  // ─────────────────────────────────────────────────────────────
  // PURCHASE
  // ─────────────────────────────────────────────────────────────

  /// Creates a single order. Returns the new [Order] or null on failure.
  Future<Order?> purchase(
    FoodDeal deal,
    String paymentMethod,
    String paymentReference,
  ) async {
    try {
      // 1. Check if order already exists (e.g. created by webhook)
      final existing = state.orders.where((o) => o.paymentReference == paymentReference);
      if (existing.isNotEmpty) return existing.first;

      final user = state.currentUser!;
      final order = await _supa.createOrder(
        dealId: deal.id,
        dealTitle: deal.title,
        businessId: deal.businessId,
        businessName: deal.businessName,
        customerId: user.id,
        customerName: user.name,
        price: deal.discountedPrice,
        originalPrice: deal.originalPrice,
        category: deal.category,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );


      final savings = deal.originalPrice - deal.discountedPrice;
      final newCustomerStats = state.customerStats.addMeal(savings > 0 ? savings : 0, deal.discountedPrice);
      final newGlobalStats = state.globalStats.addMeal(savings > 0 ? savings : 0, deal.discountedPrice);
      final pointsToAdd = (deal.discountedPrice * 10).round();
      final newPoints = state.customerDreamPoints + pointsToAdd;

      // Persist the points in the database
      if (pointsToAdd > 0) {
        await _supa.incrementDreamPoints(pointsToAdd);
      }

      final updatedDeals = state.deals.map((d) {
        if (d.id == deal.id && d.quantityRemaining > 0) {
          return d.copyWith(quantityRemaining: d.quantityRemaining - 1);
        }
        return d;
      }).toList();

      final updatedUser = state.currentUser?.copyWith(dreamPoints: newPoints);

      state = state.copyWith(
        currentUser: updatedUser,
        orders: [order, ...state.orders],
        deals: updatedDeals,
        customerStats: newCustomerStats,
        globalStats: newGlobalStats,
        customerDreamPoints: newPoints,
      );

      removeFromBasket(deal.id);
      _updateCache();

      // Send Notifications (Background)
      _sendPurchaseNotifications(order, deal);

      return order;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return null;
    }
  }

  Future<void> _sendPurchaseNotifications(Order order, FoodDeal deal) async {
    final notif = NotificationService();

    // 1. Notify Customer
    await notif.notifyCustomerOrderConfirmed(
      customerEmail: state.currentUser?.email ?? '',
      customerName: state.currentUser?.name ?? 'Hero',
      dealTitle: deal.title,
      businessName: deal.businessName,
      collectionCode: order.collectionCode,
      price: "GHS ${order.price.toStringAsFixed(2)}",
      paymentMethod: order.paymentMethod,
      orderId: order.id,
      pickupWindow: deal.pickupWindow,
    );

    // 2. Notify Merchant
    try {
      final merchantBusiness = state.businesses.firstWhere((b) => b.id == deal.businessId);

      // Try to find the merchant's email from the users list
      String merchantEmail = '';
      try {
        final merchantUser = state.users.firstWhere((u) => u.id == merchantBusiness.ownerId);
        merchantEmail = merchantUser.email;
      } catch (_) {
        // If not found in local state, maybe we should fetch it?
        // For now, use a fallback or placeholder.
      }

      await notif.notifyMerchantNewOrder(
        merchantFcmToken: '', // Backend should ideally handle this via business_id
        merchantEmail: merchantEmail,
        merchantName: merchantBusiness.name,
        customerName: state.currentUser?.name ?? 'A Customer',
        dealTitle: deal.title,
        collectionCode: order.collectionCode,
        price: "GHS ${order.price.toStringAsFixed(2)}",
        paymentMethod: order.paymentMethod,
        orderId: order.id,
      );
    } catch (_) {}
  }

  /// Purchases every item in the current basket.
  Future<List<Order>> purchaseBasket(
      String paymentMethod, String paymentReference) async {
    final created = <Order>[];
    for (final item in List<BasketItem>.from(_basket)) {
      for (var i = 0; i < item.quantity; i++) {
        final order =
            await purchase(item.deal, paymentMethod, paymentReference);
        if (order != null) created.add(order);
      }
    }
    return created;
  }

  // ─────────────────────────────────────────────────────────────
  // CUSTOMER ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String businessId) async {
    final before = Set<String>.from(state.favoriteBusinessIds);
    final updated = Set<String>.from(before);
    if (updated.contains(businessId)) {
      updated.remove(businessId);
    } else {
      updated.add(businessId);
    }
    // Optimistic update.
    state = state.copyWith(favoriteBusinessIds: updated);
    try {
      await _supa.toggleFavorite(_supa.currentUserId!, businessId);
      CacheManager().saveFavorites(state.favoriteBusinessIds);
    } catch (_) {
      // Rollback.
      state = state.copyWith(favoriteBusinessIds: before);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await _supa.updateOrderStatus(orderId, 'cancelled');
    final updated = state.orders.map((o) {
      if (o.id == orderId) return o.copyWith(status: 'cancelled');
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
    CacheManager().saveOrders(state.orders);
  }

  Future<void> submitReview({
    required String orderId,
    required String businessId,
    required int rating,
    String? comment,
  }) async {
    await _supa.submitReview(
      orderId: orderId,
      businessId: businessId,
      rating: rating,
      comment: comment,
    );

    // Award DreamPoints for Review
    await _supa.awardReviewPoints();

    // Update local orders list to show it's now rated
    final updatedOrders = state.orders.map((o) {
      if (o.id == orderId) return o.copyWith(isRated: true);
      return o;
    }).toList();

    final newPoints = state.customerDreamPoints + 20;
    final updatedUser = state.currentUser?.copyWith(dreamPoints: newPoints);

    state = state.copyWith(
      orders: updatedOrders,
      customerDreamPoints: newPoints,
      currentUser: updatedUser,
    );
    CacheManager().saveOrders(state.orders);

    // We might want to re-fetch businesses to get the new average rating
    final businesses = await _supa.fetchBusinesses();
    state = state.copyWith(businesses: businesses);
    CacheManager().saveBusinesses(state.businesses);
  }

  Future<void> updatePayoutStatus(String orderId, String status) async {
    try {
      await _supa.updateOrderPayoutStatus(orderId, status);
    } catch (e) {
      debugPrint('Supabase payout update failed or offline, updating local ledger state: $e');
    }
    final updatedOrders = state.orders.map((o) {
      if (o.id == orderId) return o.copyWith(payoutStatus: status);
      return o;
    }).toList();
    state = state.copyWith(orders: updatedOrders);
    CacheManager().saveOrders(state.orders);
  }

  Future<void> createDispute({
    required String orderId,
    required String merchantId,
    required String issueDescription,
  }) async {
    await _supa.createDispute(
      orderId: orderId,
      merchantId: merchantId,
      issueDescription: issueDescription,
    );
    // Optionally re-fetch disputes if customer can see them (though currently mostly admin sees them)
  }

  // ─────────────────────────────────────────────────────────────
  // MERCHANT ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> addDeal({
    required String title,
    required String description,
    required String category,
    required double originalPrice,
    required double discountedPrice,
    required String pickupWindow,
    required int quantity,
    String imageUrl = '',
  }) async {
    final biz = getMerchantBusiness();
    if (biz == null) return;
    await _supa.createDeal(
      businessId: biz.id,
      businessName: biz.name,
      title: title,
      description: description,
      category: category,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      pickupWindow: pickupWindow,
      quantity: quantity,
      imageUrl: imageUrl,
    );
    final deals = await _supa.fetchDeals();
    state = state.copyWith(deals: deals);
    CacheManager().saveDeals(state.deals);

    // Notify customers nearby (Topic-based broadcast)
    try {
      await NotificationService().sendNotification({
        'topic': 'all_customers',
        'title': 'New Surplus Meal Nearby! 🌿',
        'body': '${biz.name} just listed $title for GHS ${discountedPrice.toStringAsFixed(0)}. Rescue it now!',
        'screen': 'deal_detail',
        'dealId': deals.firstWhere((d) => d.title == title).id, // Get the new ID
      });
    } catch (_) {}
  }

  Future<void> updateDeal({
    required String dealId,
    required String title,
    required String description,
    required String category,
    required double originalPrice,
    required double discountedPrice,
    required String pickupWindow,
    required int quantity,
    String? imageUrl,
  }) async {
    await _supa.updateDeal(
      dealId: dealId,
      title: title,
      description: description,
      category: category,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      pickupWindow: pickupWindow,
      quantity: quantity,
      imageUrl: imageUrl,
    );
    final deals = await _supa.fetchDeals();
    state = state.copyWith(deals: deals);
    CacheManager().saveDeals(state.deals);
  }

  Future<void> deleteDeal(String dealId) async {
    await _supa.deleteDeal(dealId);
    final deals = await _supa.fetchDeals();
    state = state.copyWith(deals: deals);
    CacheManager().saveDeals(state.deals);
  }

  Future<void> confirmCollection(String orderId) async {
    await _supa.updateOrderStatus(orderId, 'collected');
    final updated = state.orders.map((o) {
      if (o.id == orderId) return o.copyWith(status: 'collected');
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
    CacheManager().saveOrders(state.orders);
  }

  Future<void> broadcastAnnouncement({
    required String title,
    required String message,
    required String audience, // 'all', 'customers', 'merchants'
    bool sendPush = true,
    bool sendEmail = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final notif = NotificationService();

      String topic = 'all_users';
      if (audience == 'customers') topic = 'all_customers';
      if (audience == 'merchants') topic = 'all_merchants';

      if (sendPush) {
        await notif.sendNotification({
          'topic': topic,
          'title': title,
          'body': message,
          'screen': 'home',
        }, type: 'broadcast');
      }

      if (sendEmail) {
        // Use Polished HTML for Broadcast
        final polishedHtml = EmailTemplates.base('''
          <h1>$title</h1>
          <p>$message</p>
          <p>Target Audience: ${audience.toUpperCase()}</p>
          <a href="https://dreameats.app" class="button">Open DreamEats</a>
        ''');

        await _supa.sendGlobalEmail(
          subject: title,
          content: message, // Still send text version
          html: polishedHtml, // Pass HTML version
          audience: audience,
        );
      }

      // Save to History
      await _supa.createBroadcast(title: title, message: message, audience: audience);
      final updatedBroadcasts = await _supa.fetchBroadcasts();

      state = state.copyWith(isLoading: false, broadcasts: updatedBroadcasts);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // ─── Notification Actions ──────────────────

  Future<void> markNotificationAsRead(String id) async {
    await _supa.markNotificationAsRead(id);
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
    CacheManager().saveNotifications(updated);
  }

  Future<void> markAllNotificationsAsRead() async {
    final uid = _supa.currentUserId;
    if (uid == null) return;
    await _supa.markAllNotificationsAsRead(uid);
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    CacheManager().saveNotifications(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // ADMIN ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> setMerchantApproval(String businessId, bool approved) async {
    final biz = state.businesses.firstWhere((b) => b.id == businessId);
    await _supa.updateBusinessApproval(businessId, approved);

    // Audit Log
    await _supa.logAction(
      action: approved ? 'approve_merchant' : 'suspend_merchant',
      entityType: 'merchant',
      entityId: businessId,
      description: '${approved ? "Approved" : "Suspended"} merchant: ${biz.name}',
      metadata: {'name': biz.name},
    );

    if (approved) {
      // Send Polished Approval Email
      try {
        final biz = state.businesses.firstWhere((b) => b.id == businessId);
        final user = state.users.firstWhere((u) => u.id == biz.ownerId);
        await NotificationService().sendMerchantApprovalEmail(
          email: user.email,
          merchantName: biz.name,
        );
      } catch (_) {}
    }

    final updated = state.businesses.map((b) {
      if (b.id == businessId) return b.copyWith(isApproved: approved);
      return b;
    }).toList();
    state = state.copyWith(businesses: updated);
    CacheManager().saveBusinesses(state.businesses);
  }

  Future<void> updateBusinessBranding(String businessId, {String? logoUrl, String? coverUrl}) async {
    await _supa.updateBusinessBranding(businessId, logoUrl: logoUrl, coverUrl: coverUrl);
    final businesses = await _supa.fetchBusinesses();
    state = state.copyWith(businesses: businesses);

    if (_merchantBusiness?.id == businessId) {
       _merchantBusiness = businesses.firstWhere((b) => b.id == businessId);
    }

    CacheManager().saveBusinesses(state.businesses);
  }

  Future<void> updateBusinessProfile(
    String businessId, {
    String? name,
    String? description,
    String? category,
    String? location,
    double? lat,
    double? lng,
  }) async {
    await _supa.updateBusinessProfile(
      businessId,
      name: name,
      description: description,
      category: category,
      location: location,
      lat: lat,
      lng: lng,
    );
    final businesses = await _supa.fetchBusinesses();
    state = state.copyWith(businesses: businesses);

    if (_merchantBusiness?.id == businessId) {
       _merchantBusiness = businesses.firstWhere((b) => b.id == businessId);
    }

    CacheManager().saveBusinesses(state.businesses);
  }

  Future<void> toggleUserSuspension(String userId) async {
    final user = state.users.firstWhere((u) => u.id == userId);
    final newSuspended = !user.isSuspended;
    await _supa.toggleUserSuspension(userId, newSuspended);

    // Audit Log
    await _supa.logAction(
      action: newSuspended ? 'suspend_user' : 'activate_user',
      entityType: 'user',
      entityId: userId,
      description: '${newSuspended ? "Suspended" : "Activated"} ${user.role}: ${user.name}',
      metadata: {'name': user.name, 'role': user.role},
    );
    final updated = state.users.map((u) {
      if (u.id == userId) return u.copyWith(isSuspended: newSuspended);
      return u;
    }).toList();
    state = state.copyWith(users: updated);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final user = state.users.firstWhere((u) => u.id == userId);
    final oldRole = user.role;
    await _supa.updateUserRole(userId, newRole);

    // Audit Log
    await _supa.logAction(
      action: 'update_role',
      entityType: 'user',
      entityId: userId,
      description: 'Changed role of ${user.name} from $oldRole to $newRole',
      metadata: {'name': user.name, 'old': oldRole, 'new': newRole},
    );

    final updated = state.users.map((u) {
      if (u.id == userId) return u.copyWith(role: newRole);
      return u;
    }).toList();
    state = state.copyWith(users: updated);
  }

  Future<void> resolveDispute(String disputeId) async {
    final ticket = state.disputes.firstWhere((d) => d.id == disputeId);
    await _supa.resolveDisputeById(disputeId);

    // Audit Log
    await _supa.logAction(
      action: 'resolve_dispute',
      entityType: 'dispute',
      entityId: disputeId,
      description: 'Resolved dispute for order: ${ticket.orderId}',
      metadata: {'customer': ticket.customerName, 'merchant': ticket.merchantName},
    );

    // Send Polished Resolution Email
    try {
      final ticket = state.disputes.firstWhere((d) => d.id == disputeId);
      final order = state.orders.firstWhere((o) => o.id == ticket.orderId);
      final customer = state.users.firstWhere((u) => u.id == order.customerId);

      await NotificationService().sendDisputeResolvedEmail(
        email: customer.email,
        ticketId: disputeId.substring(0, 8),
        resolution: "Your issue has been resolved. If a refund was requested, it is being processed.",
      );
    } catch (_) {}

    final updated = state.disputes.map((d) {
      if (d.id == disputeId) return d.copyWith(status: 'resolved');
      return d;
    }).toList();
    state = state.copyWith(disputes: updated);
    CacheManager().saveDisputes(state.disputes);
  }

  Future<void> setCommissionRate(double rate) async {
    final oldRate = _commissionRate;
    _commissionRate = rate.clamp(0.0, 1.0);
    await _supa.updateCommissionRate(_commissionRate);
    state = state.copyWith(
      commissionRate: _commissionRate,
      platformSettings: state.platformSettings.copyWith(commissionRate: _commissionRate),
    );

    // Audit Log
    await _supa.logAction(
      action: 'update_commission',
      entityType: 'setting',
      entityId: 'commission_rate',
      description: 'Updated system commission from ${(oldRate * 100).toInt()}% to ${(rate * 100).toInt()}%',
      metadata: {'old': oldRate, 'new': rate},
    );
  }

  Future<void> toggleMaintenanceMode(bool active) async {
    await _supa.updatePlatformSettings(maintenanceMode: active);
    state = state.copyWith(platformSettings: state.platformSettings.copyWith(maintenanceMode: active));

    await _supa.logAction(
      action: 'toggle_maintenance',
      entityType: 'setting',
      entityId: 'maintenance_mode',
      description: '${active ? "Enabled" : "Disabled"} global maintenance mode.',
    );
  }

  Future<void> updateMinAppVersion(String version) async {
    await _supa.updatePlatformSettings(minVersion: version);
    state = state.copyWith(platformSettings: state.platformSettings.copyWith(minAppVersion: version));

    await _supa.logAction(
      action: 'update_min_version',
      entityType: 'setting',
      entityId: 'min_app_version',
      description: 'Updated minimum required app version to $version.',
    );
  }

  Future<void> createVoucher({
    required String code,
    required double amount,
    required String type,
    required int limit,
    required String fundedBy,
    DateTime? expiry,
  }) async {
    await _supa.createVoucher(code: code, amount: amount, type: type, limit: limit, fundedBy: fundedBy, expiry: expiry);
    final vouchers = await _supa.fetchVouchers();
    state = state.copyWith(vouchers: vouchers);

    await _supa.logAction(
      action: 'create_voucher',
      entityType: 'voucher',
      entityId: code,
      description: 'Created new $type voucher: $code (GHS $amount)',
    );
  }

  Future<void> toggleVoucher(String id, bool active) async {
    await _supa.toggleVoucherStatus(id, active);
    final vouchers = state.vouchers.map((v) => v.id == id ? Voucher(id: v.id, code: v.code, discountAmount: v.discountAmount, discountType: v.discountType, expiresAt: v.expiresAt, usageLimit: v.usageLimit, usageCount: v.usageCount, isActive: active, fundedBy: v.fundedBy) : v).toList();
    state = state.copyWith(vouchers: vouchers);
  }

  // ---------------------------------------------------------------------------
  // SUPPORT TICKETS
  // ---------------------------------------------------------------------------

  Future<void> replyToTicket(String ticketId, String message, {bool isStaff = true}) async {
    await _supa.sendTicketReply(ticketId: ticketId, message: message, isStaff: isStaff);
    final updatedTickets = await _supa.fetchSupportTickets();
    state = state.copyWith(supportTickets: updatedTickets);
  }

  Future<void> resolveTicket(String ticketId) async {
    await _supa.updateTicketStatus(ticketId, 'resolved');
    final updatedTickets = await _supa.fetchSupportTickets();
    state = state.copyWith(supportTickets: updatedTickets);
  }

  Future<void> createSupportTicket({
    required String subject,
    required String message,
  }) async {
    await _supa.createSupportTicket(subject: subject, message: message);
    final updatedTickets = await _supa.fetchSupportTickets();
    state = state.copyWith(supportTickets: updatedTickets);
  }

  Future<String?> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required List<String> privileges,
  }) async {
    try {
      final url = '${AppConfig.supabaseUrl}/auth/v1/signup';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {
            'name': name,
            'role': 'admin',
            'phone': 'PRIVS:${privileges.join(',')}',
          }
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final err = jsonDecode(response.body);
        return err['msg'] ?? err['error_description'] ?? 'Registration failed.';
      }

      final users = await _supa.fetchAllUsers();
      state = state.copyWith(users: users);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void setThemeMode(ThemeMode mode) {
    // Dark mode permanently disabled
    state = state.copyWith(themeMode: ThemeMode.light);
  }

  Future<void> toggleDealStatus(String dealId, bool active) async {
    await _supa.updateDealStatus(dealId, active);
    final deals = state.deals.map((d) => d.id == dealId ? d.copyWith(isActive: active) : d).toList();
    state = state.copyWith(deals: deals);
  }

  /// Re-fetches the current user profile from Supabase and updates state.
  /// Useful after mutations like avatar upload.
  Future<void> refreshCurrentUser() async {
    if (!_supa.isAuthenticated) return;
    try {
      final profile = await _supa.getCurrentUserProfile();
      if (profile != null) {
        state = state.copyWith(currentUser: profile);
      }
    } catch (_) {}
  }

  Future<void> refreshOrders() async {
    if (!_supa.isAuthenticated) return;
    try {
      final user = state.currentUser;
      if (user == null) return;

      List<Order> orders = [];
      if (user.role == 'customer') {
        orders = await _supa.fetchCustomerOrders(_supa.currentUserId!);
      } else if (user.role == 'merchant') {
        final biz = getMerchantBusiness();
        if (biz != null) orders = await _supa.fetchMerchantOrders(biz.id);
      } else {
        orders = await _supa.fetchAllOrders();
      }

      state = state.copyWith(orders: orders);
      CacheManager().saveOrders(orders);
    } catch (_) {}
  }

  Future<void> adminRefresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _supa.fetchAllUsers(),
        _supa.fetchBusinesses(),
        _supa.fetchAllOrders(),
        _supa.fetchDisputes(),
        _supa.fetchPlatformSettings(),
        _supa.fetchAuditLogs(),
        _supa.fetchVouchers(),
        _supa.fetchBroadcasts(),
        _supa.fetchSupportTickets(),
      ]);
      final settings = results[4] as PlatformSettings;
      _commissionRate = settings.commissionRate;
      state = state.copyWith(
        isLoading: false,
        users: results[0] as List<AppUser>,
        businesses: results[1] as List<BusinessProfile>,
        orders: results[2] as List<Order>,
        disputes: results[3] as List<DisputeTicket>,
        platformSettings: settings,
        commissionRate: _commissionRate,
        auditLogs: results[5] as List<AuditLog>,
        vouchers: results[6] as List<Voucher>,
        broadcasts: results[7] as List<BroadcastMessage>,
        supportTickets: results[8] as List<SupportTicket>,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }


  // ─── Referral / Rewards ───────────────────────

  /// Applies a referral code. Returns true on success.
  Future<bool> applyReferral(String code) async {
    final success = await _supa.applyReferralCode(code);
    if (success) {
      await _hydrate(); // Refresh profile to get new points/credit
      return true;
    }
    return false;
  }

  /// Redeems DreamPoints for a reward. Returns true if enough points.
  Future<bool> redeemReward(int pointsCost, String rewardName) async {
    final success = await _supa.redeemPoints(pointsCost);
    if (success) {
      await _hydrate(); // Refresh profile
      return true;
    }
    return false;
  }

  void startBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await performBackgroundRefresh();
    });
  }

  void stopBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> performBackgroundRefresh() async {
    if (!_supa.isAuthenticated) {
      stopBackgroundRefresh();
      return;
    }

    final user = state.currentUser;
    if (user == null) return;

    try {
      final updatedBusinesses = await _supa.fetchBusinesses();
      if (updatedBusinesses.isNotEmpty) {
        state = state.copyWith(businesses: updatedBusinesses);
        CacheManager().saveBusinesses(updatedBusinesses);
      }

      if (user.role == 'customer') {
        final profile = await _supa.getCurrentUserProfile();
        if (profile != null) {
          state = state.copyWith(
            currentUser: profile,
            customerDreamPoints: profile.dreamPoints,
            customerReferralCredit: profile.referralCredit,
          );
        }
      } else if (user.role == 'merchant') {
        final updatedBiz = await _supa.fetchMerchantBusiness(_supa.currentUserId!);
        if (updatedBiz != null) {
          _merchantBusiness = updatedBiz;
        }
      } else if (user.role == 'admin' || user.role == 'super_admin') {
        final results = await Future.wait([
          _supa.fetchAllUsers(),
          _supa.fetchAllOrders(),
          _supa.fetchDisputes(),
          _supa.fetchPlatformSettings(),
          _supa.fetchAuditLogs(),
          _supa.fetchVouchers(),
          _supa.fetchBroadcasts(),
          _supa.fetchSupportTickets(),
        ]);
        
        final settings = results[3] as PlatformSettings;
        _commissionRate = settings.commissionRate;
        
        state = state.copyWith(
          users: results[0] as List<AppUser>,
          orders: results[1] as List<Order>,
          disputes: results[2] as List<DisputeTicket>,
          platformSettings: settings,
          commissionRate: _commissionRate,
          auditLogs: results[4] as List<AuditLog>,
          vouchers: results[5] as List<Voucher>,
          broadcasts: results[6] as List<BroadcastMessage>,
          supportTickets: results[7] as List<SupportTicket>,
        );
      }
    } catch (_) {
      // Suppress background errors
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    final success = await _supa.deleteUserAccount();
    state = state.copyWith(isLoading: false);
    return success;
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final appStateProvider = NotifierProvider<AppStateManager, AppState>(() {
  return AppStateManager();
});

class CustomerTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final customerTabProvider = NotifierProvider<CustomerTabNotifier, int>(() {
  return CustomerTabNotifier();
});
