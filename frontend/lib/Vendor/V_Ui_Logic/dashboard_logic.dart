import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_auth_api_routes.dart';

class DashboardLogic extends ChangeNotifier {
  bool isLoading = true;
  bool isVendorFound = false;

  String brandName = '';

  int activeOutfits = 0;
  int trialRequests = 0;
  int upcomingTrials = 0;
  int completedRentals = 0;

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      final accessToken = SessionManager.getToken();

      if (accessToken == null || accessToken.isEmpty) {
        isVendorFound = false;
        return;
      }

      final response = await VendorAuthApiRoutes.getMyVendor(
        accessToken: accessToken,
      );

      // final vendor = response['exists'];

      if (response['exists'] == true) {
        isVendorFound = true;

        final storeName = response['store_name'];

        if (storeName is String && storeName.trim().isNotEmpty) {
          brandName = storeName.trim();
        }
      }

      // These dashboard counters will be replaced by the
      // vendor dashboard FastAPI endpoint later.

      activeOutfits =
          _toInt(response['active_outfits']) ?? activeOutfits;
      trialRequests =
          _toInt(response['trial_requests']) ?? trialRequests;
      upcomingTrials =
          _toInt(response['upcoming_trials']) ?? upcomingTrials;
      completedRentals =
          _toInt(response['completed_rentals']) ??
              completedRentals;
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
