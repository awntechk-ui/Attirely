import 'package:attirely/Vendor/Vendor_API_Routes/vendor_auth_api_routes.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../Common_Screens/session_manager.dart';

class HomeLogic {
  bool isCheckingVendor = false;

  Future<void> openVendorSection(BuildContext context) async {
    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again'),
        ),
      );

      return;
    }

    isCheckingVendor = true;

    try {
      final response = await VendorAuthApiRoutes.getMyVendor(
        accessToken: accessToken,
      );

      if (!context.mounted) return;

      final exists = response['exists'] == true;

      if (exists) {
        Navigator.pushNamed(
          context,
          AppRoutes.vendorDashboard,
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.vendorRegister,
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      isCheckingVendor = false;
    }
  }

  void dispose() {}
}