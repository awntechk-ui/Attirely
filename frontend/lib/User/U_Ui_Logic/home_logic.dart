import 'package:flutter/material.dart';

import 'package:attirely/Vendor/Vendor_API_Routes/vendor_auth_api_routes.dart';

import '../../app_routes.dart';
import '../../Common_Screens/session_manager.dart';
import '../U_API_Routes/u_accessory_api_routes.dart';
import '../U_API_Routes/u_outfit_api_routes.dart';

class HomeLogic extends ChangeNotifier {
  bool isCheckingVendor = false;
  bool isLoadingCatalogue = false;
  String? catalogueError;

  List<Map<String, dynamic>> featuredOutfits = [];
  bool isLoadingAccessories = false;
  String? accessoriesError;

  List<Map<String, dynamic>> featuredAccessories = [];
  String searchQuery = '';

  List<Map<String, dynamic>> get filteredOutfits {
    if (searchQuery.trim().isEmpty) {
      return featuredOutfits;
    }

    final query = searchQuery.toLowerCase().trim();

    return featuredOutfits.where((outfit) {
      final searchableFields = [
        outfit['name'],
        outfit['title'],
        outfit['outfit_name'],
        outfit['category'],
        outfit['subcategory'],
        outfit['occasion'],
        outfit['description'],
        outfit['brand_name'],
      ];

      return searchableFields.any((value) {
        return value != null &&
            value.toString().toLowerCase().contains(query);
      });
    }).toList();
  }

  void updateSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCatalogue() async {
    isLoadingCatalogue = true;
    isLoadingAccessories = true;

    catalogueError = null;
    accessoriesError = null;

    notifyListeners();

    // Load outfits
    try {
      featuredOutfits = await UOutfitApiRoutes.getCatalogue();
    } catch (e) {
      catalogueError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingCatalogue = false;
      notifyListeners();
    }

    // Load accessories
    try {
      featuredAccessories = await UAccessoryApiRoutes.getCatalogue();
    } catch (e) {
      accessoriesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingAccessories = false;
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
