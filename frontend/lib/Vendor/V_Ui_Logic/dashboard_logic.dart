
import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_accessories_api_routes.dart';
import '../Vendor_API_Routes/vendor_auth_api_routes.dart';

import '../Vendor_API_Routes/vendor_outfits_api_routes.dart';
import '../Vendor_API_Routes/vendor_subscription_api_routes.dart';

class DashboardLogic extends ChangeNotifier {
  bool isLoading = true;
  bool isVendorFound = false;

  String brandName = '';

  // Listing statistics
  int activeOutfits = 0;
  int totalOutfits = 0;
  int activeAccessories = 0;
  int totalAccessories = 0;
  int get totalListings => totalOutfits + totalAccessories;

  // Rental statistics
  int trialRequests = 0;
  int completedRentals = 0;

  // Subscription
  bool hasActiveSubscription = false;
  Map<String, dynamic>? subscription;

  String get planName =>
      subscription?['plan_label']?.toString() ??
          subscription?['plan_name']?.toString() ??
          'No active plan';

  String get planCode =>
      subscription?['plan_code']?.toString() ?? '';

  String get billingInterval =>
      subscription?['billing_interval']?.toString() ?? '';

  String get subscriptionStatus =>
      subscription?['status']?.toString() ?? '';

  String get subscriptionPrice =>
      subscription?['price']?.toString() ?? '0';

  int get outfitLimit => _toInt(subscription?['outfits_limit']) ?? 0;

  int get accessoryLimit =>
      _toInt(subscription?['accessories_limit']) ?? 0;

  bool get outfitsUnlimited =>
      subscription?['outfits_unlimited'] == true;

  bool get accessoriesUnlimited =>
      subscription?['accessories_unlimited'] == true;

  int get remainingOutfitSlots =>
      outfitsUnlimited ? 0 : (outfitLimit - totalOutfits).clamp(0, outfitLimit);

  int get remainingAccessorySlots =>
      accessoriesUnlimited
          ? 0
          : (accessoryLimit - totalAccessories).clamp(0, accessoryLimit);

  double get outfitUsage =>
      outfitsUnlimited || outfitLimit <= 0
          ? 0
          : (totalOutfits / outfitLimit).clamp(0.0, 1.0);

  double get accessoryUsage =>
      accessoriesUnlimited || accessoryLimit <= 0
          ? 0
          : (totalAccessories / accessoryLimit).clamp(0.0, 1.0);

  String get subscriptionEndDate =>
      subscription?['ends_at']?.toString() ?? '';

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      final accessToken = SessionManager.getToken();

      if (accessToken == null || accessToken.isEmpty) {
        isVendorFound = false;
        return;
      }

      // 1. Vendor profile
      try {
        final response = await VendorAuthApiRoutes.getMyVendor(
          accessToken: accessToken,
        );

        if (response['exists'] == true) {
          isVendorFound = true;

          final storeName = response['store_name'];

          if (storeName is String && storeName.trim().isNotEmpty) {
            brandName = storeName.trim();
          }

          trialRequests =
              _toInt(response['trial_requests']) ?? trialRequests;

          completedRentals =
              _toInt(response['completed_rentals']) ?? completedRentals;
        }
      } catch (e) {
        debugPrint('VENDOR PROFILE LOAD ERROR: $e');
      }

      // 2. Outfit listings
      try {
        final outfits = await VendorOutfitApiRoutes.getMyOutfits(
          accessToken: accessToken,
        );

        totalOutfits = outfits.length;

        activeOutfits = outfits.where((outfit) {
          return outfit['is_available'] == true;
        }).length;
      } catch (e) {
        debugPrint('DASHBOARD OUTFITS LOAD ERROR: $e');
      }

      // 3. Accessory listings
      try {
        final accessories = await VendorAccessoryApiRoutes.getMyAccessories(
          accessToken: accessToken,
        );

        totalAccessories = accessories.length;

        activeAccessories = accessories.where((item) {
          if (item is! Map) return false;
          return item['is_available'] == true;
        }).length;
      } catch (e) {
        debugPrint('DASHBOARD ACCESSORIES LOAD ERROR: $e');
      }

      // 4. Current subscription
      try {
        final response =
        await VendorSubscriptionApiRoutes.getCurrentSubscription(
          accessToken: accessToken,
        );

        hasActiveSubscription =
            response['has_active_subscription'] == true;

        final currentPlan = response['subscription'];

        subscription = currentPlan is Map
            ? Map<String, dynamic>.from(currentPlan)
            : null;
      } catch (e) {
        debugPrint('DASHBOARD SUBSCRIPTION LOAD ERROR: $e');
      }
    } catch (e) {
      debugPrint('DASHBOARD LOAD ERROR: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
