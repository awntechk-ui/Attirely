import 'package:flutter/material.dart';

import 'package:attirely/Vendor/Vendor_API_Routes/vendor_auth_api_routes.dart';

import '../../app_routes.dart';
import '../../Common_Screens/session_manager.dart';
import '../U_API_Routes/u_outfit_api_routes.dart';

class HomeLogic extends ChangeNotifier {
  bool isCheckingVendor = false;
  bool isLoadingCatalogue = false;
  String? catalogueError;

  List<Map<String, dynamic>> featuredOutfits = [];

  Future<void> loadCatalogue() async {
    isLoadingCatalogue = true;
    catalogueError = null;
    notifyListeners();

    try {
      featuredOutfits = await UOutfitApiRoutes.getCatalogue();
    } catch (e) {
      catalogueError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingCatalogue = false;
      notifyListeners();
    }
  }

  Future<void> openVendorSection(BuildContext context) async {
    if (isCheckingVendor) return;

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
    notifyListeners();

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
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      isCheckingVendor = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}