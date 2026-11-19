import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../../User/U_Ui_Logic/booking_checkout.dart';
import '../Vendor_API_Routes/vendor_subscription_api_routes.dart';

class UpgradeLogic extends ChangeNotifier {
  final _checkout = BookingCheckout(
    verificationPath: '/vendor/subscription/checkout/verify',
    confirmationPendingStatus: 'activation_pending',
    confirmationPendingMessage:
        'Payment received. Your plan is still being activated.',
    statusButtonLabel: 'Check payment status',
    priceChangedMessage:
        'The plan price changed. Refresh your plans and try again.',
  );

  bool isLoading = false;
  bool isCheckingOut = false;
  bool _disposed = false;
  String? errorMessage;
  List<Map<String, dynamic>> plans = [];
  Map<String, dynamic>? currentSubscription;
  Map<String, dynamic>? selectedPlan;
  bool hasActiveSubscription = false;

  bool get hasPendingPayment => _checkout.hasPendingPayment;
  String? get currentPlanCode => currentSubscription?['plan_code']?.toString();
  String? get currentPlanStatus => currentSubscription?['status']?.toString();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<String> _getAccessToken() async {
    final token = SessionManager.getToken() ?? await SessionManager.loadToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  Future<void> loadData() async {
    if (isLoading || isCheckingOut || hasPendingPayment) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await _getAccessToken();
      final results = await Future.wait([
        VendorSubscriptionApiRoutes.getActivePlans(accessToken: accessToken),
        VendorSubscriptionApiRoutes.getCurrentSubscription(
          accessToken: accessToken,
        ),
      ]);

      plans = results[0] as List<Map<String, dynamic>>;
      final subscriptionResponse = results[1] as Map<String, dynamic>;
      hasActiveSubscription =
          subscriptionResponse['has_active_subscription'] == true;
      final subscriptionData = subscriptionResponse['subscription'];
      currentSubscription = subscriptionData is Map
          ? Map<String, dynamic>.from(subscriptionData)
          : null;
      selectedPlan = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  bool isComingSoon(Map<String, dynamic> plan) {
    final note = plan['price_note']?.toString().toLowerCase() ?? '';
    return note.contains('coming soon');
  }

  bool isPaidPlan(Map<String, dynamic> plan) =>
      (double.tryParse(plan['price'].toString()) ?? 0) > 0;

  void setSelectedPlan(Map<String, dynamic> plan) {
    if (isComingSoon(plan) || isLoading || isCheckingOut || hasPendingPayment) {
      return;
    }

    selectedPlan = plan;
    notifyListeners();
  }

  Future<bool> activateSelectedPlan() async {
    final plan = selectedPlan;
    if (plan == null || isCheckingOut || isLoading) return false;
    final planCode = plan['plan_code'].toString();

    isCheckingOut = true;
    notifyListeners();
    try {
      if (isPaidPlan(plan)) {
        final amount = double.parse(plan['price'].toString());
        await _checkout.pay(
          path: '/vendor/subscription/checkout',
          description: plan['plan_name'].toString(),
          request: {'plan_code': planCode},
          expectedAmount: (amount * 100).round(),
        );
      } else {
        await VendorSubscriptionApiRoutes.selectPlan(
          accessToken: await _getAccessToken(),
          planCode: planCode,
        );
      }
    } finally {
      isCheckingOut = false;
      if (!_disposed) notifyListeners();
    }

    if (!_disposed) {
      selectedPlan = null;
      await loadData();
    }
    return true;
  }
}
