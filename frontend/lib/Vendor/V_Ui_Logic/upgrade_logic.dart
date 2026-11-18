
import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_subscription_api_routes.dart';



class UpgradeLogic extends ChangeNotifier {
  // =========================================
  // STATE
  // =========================================

  bool isLoading = false;

  String? errorMessage;

  List<Map<String, dynamic>> plans = [];

  Map<String, dynamic>? currentSubscription;

  bool hasSubscription = false;
  bool hasActiveSubscription = false;

  Map<String, dynamic>? selectedPlan;

  bool selectionConfirmed = false;

  // =========================================
  // GET CURRENT PLAN DETAILS
  // =========================================

  String? get currentPlanCode =>
      currentSubscription?['plan_code']?.toString();

  String? get currentPlanName =>
      currentSubscription?['plan_name']?.toString();

  String? get currentPlanStatus =>
      currentSubscription?['status']?.toString();

  // =========================================
  // GET ACCESS TOKEN
  // =========================================

  Future<String> _getAccessToken() async {
    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    return accessToken;
  }

  // =========================================
  // LOAD PLANS AND CURRENT SUBSCRIPTION
  // =========================================

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final accessToken = await _getAccessToken();

      // Fetch both APIs together.
      final results = await Future.wait([
        VendorSubscriptionApiRoutes.getActivePlans(
          accessToken: accessToken,
        ),
        VendorSubscriptionApiRoutes.getCurrentSubscription(
          accessToken: accessToken,
        ),
      ]);

      // Active plans
      plans = results[0] as List<Map<String, dynamic>>;

      // Current subscription
      final subscriptionResponse =
      results[1] as Map<String, dynamic>;

      hasSubscription =
          subscriptionResponse['has_subscription'] == true;

      hasActiveSubscription =
          subscriptionResponse['has_active_subscription'] == true;

      final subscriptionData =
      subscriptionResponse['subscription'];

      if (subscriptionData is Map) {
        currentSubscription =
        Map<String, dynamic>.from(subscriptionData);
      } else {
        currentSubscription = null;
      }

      // Clear previous selection when reloading.
      selectedPlan = null;
      selectionConfirmed = false;

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================
  // CHECK WHETHER PLAN IS COMING SOON
  // =========================================

  bool isComingSoon(Map<String, dynamic> plan) {
    final note = plan['price_note']?.toString().toLowerCase() ?? '';

    return note.contains('coming soon');
  }

  // =========================================
  // SELECT PLAN (LOCAL ONLY)
  // =========================================

  void setSelectedPlan(Map<String, dynamic> plan) {
    if (isComingSoon(plan)) return;

    selectedPlan = plan;
    selectionConfirmed = false;

    notifyListeners();
  }

  // =========================================
  // CONFIRM SELECTION (NO DATABASE UPDATE)
  // =========================================

  void confirmPlanSelection() {
    if (selectedPlan == null) return;

    selectionConfirmed = true;

    notifyListeners();
  }

  // =========================================
  // CLEAR SELECTION
  // =========================================

  void clearSelection() {
    selectedPlan = null;
    selectionConfirmed = false;

    notifyListeners();
  }
}
