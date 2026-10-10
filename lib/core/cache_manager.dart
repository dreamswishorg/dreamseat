import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class CacheManager {
  static const String boxName = 'dreameats_cache';
  static const String encryptionKeyName = 'hive_encryption_key';

  // Cache Keys
  static const String keyCurrentUser = 'current_user';
  static const String keyDeals = 'cached_deals';
  static const String keyBusinesses = 'cached_businesses';
  static const String keyOrders = 'cached_orders';
  static const String keyCustomerStats = 'customer_stats';
  static const String keyGlobalStats = 'global_stats';
  static const String keyDreamPoints = 'dream_points';
  static const String keyReferralCredit = 'referral_credit';
  static const String keyFavorites = 'favorite_business_ids';
  static const String keyOnboardingStage = 'onboarding_stage';
  static const String keyBasket = 'cached_basket';
  static const String keyDisputes = 'cached_disputes';
  static const String keyNotifications = 'cached_notifications';
  static const String keyCategories = 'cached_categories';

  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();

      const secureStorage = FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      String? encryptionKey;
      try {
        encryptionKey = await secureStorage.read(key: encryptionKeyName);
      } catch (e) {
        debugPrint('SecureStorage read failed: $e');
      }

      if (encryptionKey == null || encryptionKey.isEmpty) {
        final key = Hive.generateSecureKey();
        encryptionKey = base64UrlEncode(key);
        try {
          await secureStorage.write(
            key: encryptionKeyName,
            value: encryptionKey,
          );
        } catch (e) {
          debugPrint('SecureStorage write failed: $e');
        }
      }

      try {
        final decodedKey = base64Url.decode(encryptionKey);
        await Hive.openBox(boxName, encryptionCipher: HiveAesCipher(decodedKey));
      } catch (boxErr) {
        debugPrint('Failed to open encrypted Hive box: $boxErr. Resetting box...');
        try {
          await Hive.deleteBoxFromDisk(boxName);
          final key = Hive.generateSecureKey();
          encryptionKey = base64UrlEncode(key);
          await secureStorage.write(key: encryptionKeyName, value: encryptionKey);
          await Hive.openBox(boxName, encryptionCipher: HiveAesCipher(key));
        } catch (_) {
          await Hive.openBox(boxName);
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('CacheManager init error: $e');
    }
  }


  Box? get _box {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
    } catch (_) {}
    return null;
  }

  // --- Current User Cache ---
  AppUser? getCurrentUser() {
    final raw = _box?.get(keyCurrentUser);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw as String));
  }

  Future<void> saveCurrentUser(AppUser? user) async {
    if (user == null) {
      await _box?.delete(keyCurrentUser);
    } else {
      await _box?.put(keyCurrentUser, jsonEncode(user.toJson()));
    }
  }

  // --- Food Deals Cache ---
  List<FoodDeal> getDeals() {
    final raw = _box?.get(keyDeals);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => FoodDeal.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDeals(List<FoodDeal> deals) async {
    final list = deals.map((d) => d.toJson()).toList();
    await _box?.put(keyDeals, jsonEncode(list));
  }

  // --- Businesses Cache ---
  List<BusinessProfile> getBusinesses() {
    final raw = _box?.get(keyBusinesses);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => BusinessProfile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBusinesses(List<BusinessProfile> businesses) async {
    final list = businesses.map((b) => b.toJson()).toList();
    await _box?.put(keyBusinesses, jsonEncode(list));
  }

  // --- Orders Cache ---
  List<Order> getOrders() {
    final raw = _box?.get(keyOrders);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<Order> orders) async {
    final list = orders.map((o) => o.toJson()).toList();
    await _box?.put(keyOrders, jsonEncode(list));
  }

  // --- Sustainability Stats Cache ---
  SustainabilityStats getCustomerStats() {
    final raw = _box?.get(keyCustomerStats);
    if (raw == null) return SustainabilityStats.zero();
    return SustainabilityStats.fromJson(jsonDecode(raw as String));
  }

  Future<void> saveCustomerStats(SustainabilityStats stats) async {
    await _box?.put(keyCustomerStats, jsonEncode(stats.toJson()));
  }

  SustainabilityStats getGlobalStats() {
    final raw = _box?.get(keyGlobalStats);
    if (raw == null) return SustainabilityStats.zero();
    return SustainabilityStats.fromJson(jsonDecode(raw as String));
  }

  Future<void> saveGlobalStats(SustainabilityStats stats) async {
    await _box?.put(keyGlobalStats, jsonEncode(stats.toJson()));
  }

  // --- DreamPoints Cache ---
  int getDreamPoints() {
    return (_box?.get(keyDreamPoints, defaultValue: 0) as int?) ?? 0;
  }

  Future<void> saveDreamPoints(int points) async {
    await _box?.put(keyDreamPoints, points);
  }

  // --- Referral Credit Cache ---
  double getReferralCredit() {
    return (_box?.get(keyReferralCredit, defaultValue: 0.0) as double?) ?? 0.0;
  }

  Future<void> saveReferralCredit(double credit) async {
    await _box?.put(keyReferralCredit, credit);
  }

  // --- Favorites Cache ---
  Set<String> getFavorites() {
    final raw = _box?.get(keyFavorites);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw as String) as List;
      return Set.from(list.cast<String>());
    } catch (_) {
      return {};
    }
  }

  Future<void> saveFavorites(Set<String> favorites) async {
    await _box?.put(keyFavorites, jsonEncode(favorites.toList()));
  }

  // --- Onboarding Stage Cache ---
  String getOnboardingStage() {
    return (_box?.get(keyOnboardingStage, defaultValue: 'splash') as String?) ?? 'splash';
  }

  Future<void> saveOnboardingStage(String stage) async {
    await _box?.put(keyOnboardingStage, stage);
  }

  // --- Basket Cache ---
  List<BasketItem> getBasket() {
    final raw = _box?.get(keyBasket);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => BasketItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBasket(List<BasketItem> basket) async {
    final list = basket.map((item) => item.toJson()).toList();
    await _box?.put(keyBasket, jsonEncode(list));
  }

  // --- Disputes Cache ---
  List<DisputeTicket> getDisputes() {
    final raw = _box?.get(keyDisputes);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => DisputeTicket.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDisputes(List<DisputeTicket> disputes) async {
    final list = disputes.map((item) => item.toJson()).toList();
    await _box?.put(keyDisputes, jsonEncode(list));
  }

  // --- Notifications Cache ---
  List<AppNotification> getNotifications() {
    final raw = _box?.get(keyNotifications);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final list = notifications.map((n) => n.toJson()).toList();
    await _box?.put(keyNotifications, jsonEncode(list));
  }

  // --- Categories Cache ---
  List<CategoryItem> getCategories() {
    final raw = _box?.get(keyCategories);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw as String) as List;
      return list.map((item) => CategoryItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCategories(List<CategoryItem> categories) async {
    final list = categories.map((c) => c.toJson()).toList();
    await _box?.put(keyCategories, jsonEncode(list));
  }

  // --- Global Clear Cache ---
  Future<void> clearAll() async {
    await _box?.clear();
  }
}
