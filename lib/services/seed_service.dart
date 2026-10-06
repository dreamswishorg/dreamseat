import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SeedService {
  final _supa = SupabaseService();
  final _db = Supabase.instance.client;

  Future<void> seedMerchantWithDeals({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required String businessDescription,
    required String businessCategory,
  }) async {
    try {
      // 1. Sign up the merchant
      final error = await _supa.signUp(
        name: name,
        email: email,
        password: password,
        role: 'merchant',
        businessName: businessName,
        businessDescription: businessDescription,
        businessCategory: businessCategory,
      );

      if (error != null && error != 'needs_confirmation') {
        throw Exception('Sign up failed: $error');
      }

      // 2. Fetch the newly created business profile
      // Note: We might need to wait for the profile to be created by the trigger/getCurrentUserProfile
      // or find the user ID first. Since we are using the singleton SupabaseService,
      // it might not have the session if it requires email confirmation.
      // For seeding, we assume either confirmation is off or we use a pre-existing merchant.

      // Let's find the user ID by email (Admin required or pre-existing logic)
      final userResponse = await _db.from('profiles').select('id').eq('email', email).maybeSingle();
      if (userResponse == null) {
        throw Exception('User profile not found after sign up. Ensure email confirmation is handled or disabled.');
      }
      final userId = userResponse['id'] as String;

      // 3. Find the business
      final bizResponse = await _db.from('businesses').select().eq('owner_id', userId).maybeSingle();
      if (bizResponse == null) {
        throw Exception('Business profile not found for user.');
      }
      final bizId = bizResponse['id'] as String;

      // 4. Add Sample Deals
      final sampleDeals = _getSampleDeals(businessCategory);
      for (final deal in sampleDeals) {
        await _supa.createDeal(
          businessId: bizId,
          businessName: businessName,
          title: deal['title'],
          description: deal['description'],
          category: businessCategory,
          originalPrice: deal['originalPrice'],
          discountedPrice: deal['discountedPrice'],
          pickupWindow: "5:30 PM - 8:30 PM",
          quantity: Random().nextInt(10) + 5,
        );
      }

      // 5. Automatically Approve the Business (Admin Action)
      await _supa.updateBusinessApproval(bizId, true);

      debugPrint('Seeding completed for $businessName');
    } catch (e) {
      debugPrint('Seeding error: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getSampleDeals(String category) {
    switch (category) {
      case 'Bakery Pack':
        return [
          {'title': 'Assorted Pastry Box', 'description': '6 random fresh pastries from today.', 'originalPrice': 80.0, 'discountedPrice': 35.0},
          {'title': 'Baguette Bundle', 'description': '3 artisanal baguettes.', 'originalPrice': 45.0, 'discountedPrice': 20.0},
          {'title': 'Cake Slice Surprise', 'description': '3 gourmet cake slices.', 'originalPrice': 120.0, 'discountedPrice': 50.0},
        ];
      case 'Restaurant Meal':
      default:
        return [
          {'title': 'Surplus Jollof Pack', 'description': 'Large portion of Jollof rice with chicken/fish.', 'originalPrice': 65.0, 'discountedPrice': 30.0},
          {'title': 'Evening Special Box', 'description': 'Daily special main course and side.', 'originalPrice': 90.0, 'discountedPrice': 40.0},
          {'title': 'Sides & Salad Mix', 'description': 'Fresh salads and assorted appetizers.', 'originalPrice': 50.0, 'discountedPrice': 20.0},
        ];
    }
  }
}
