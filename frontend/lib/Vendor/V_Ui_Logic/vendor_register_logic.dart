import 'package:attirely/Vendor/Vendor_API_Routes/vendor_auth_api_routes.dart';
import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';

class VendorRegisterLogic {
  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController aadhaarController =
  TextEditingController();

  final TextEditingController panController =
  TextEditingController();

  final TextEditingController storeNameController =
  TextEditingController();

  final TextEditingController businessDescriptionController =
  TextEditingController();

  final TextEditingController addressController =
  TextEditingController();

  final TextEditingController cityController =
  TextEditingController();

  final TextEditingController stateController =
  TextEditingController();

  final TextEditingController pincodeController =
  TextEditingController();

  final TextEditingController instagramController =
  TextEditingController();

  String? role;

  bool isLoading = false;

  Future<bool> createVendorProfile(
      BuildContext context,
      ) async {
    // Check required fields
    if (fullNameController.text.trim().isEmpty ||
        storeNameController.text.trim().isEmpty ||
        businessDescriptionController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        stateController.text.trim().isEmpty ||
        pincodeController.text.trim().isEmpty ||
        role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields.',
          ),
        ),
      );

      return false;
    }

    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again.',
          ),
        ),
      );

      return false;
    }

    isLoading = true;

    try {
      await VendorAuthApiRoutes.createVendor(
        accessToken: accessToken,

        fullName: fullNameController.text.trim(),

        aadhaar: aadhaarController.text.trim().isEmpty
            ? null
            : aadhaarController.text.trim(),

        pan: panController.text.trim().isEmpty
            ? null
            : panController.text.trim(),

        role: role!,

        storeName: storeNameController.text.trim(),

        businessDescription:
        businessDescriptionController.text.trim(),

        address: addressController.text.trim(),

        city: cityController.text.trim(),

        state: stateController.text.trim(),

        pincode: pincodeController.text.trim(),

        instagram:
        instagramController.text.trim().isEmpty
            ? null
            : instagramController.text.trim(),
      );

      if (!context.mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner profile created successfully!',
          ),
        ),
      );

      return true;
    } catch (e) {
      if (!context.mounted) return false;

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

      return false;
    } finally {
      isLoading = false;
    }
  }

  void dispose() {
    fullNameController.dispose();
    aadhaarController.dispose();
    panController.dispose();
    storeNameController.dispose();
    businessDescriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    instagramController.dispose();
  }
}