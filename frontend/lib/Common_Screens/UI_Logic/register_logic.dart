import 'package:flutter/material.dart';

import '../API_Routes/auth_api_routes.dart';
import '../../app_routes.dart';

class RegisterLogic {
  // =========================================================
  // COMMON ACCOUNT DETAILS
  // =========================================================

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController phoneNumberController =
  TextEditingController();

  DateTime? dateOfBirth;
  String? gender;
  bool? hasStore;

  // =========================================================
  // VENDOR DETAILS
  // =========================================================

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

  final TextEditingController aadhaarController =
  TextEditingController();

  final TextEditingController panController =
  TextEditingController();

  String? ownerType;

  bool isLoading = false;

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final fullName = fullNameController.text.trim();
    final phoneNumber = phoneNumberController.text.trim();

    // =======================================================
    // COMMON VALIDATION
    // =======================================================

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        fullName.isEmpty ||
        phoneNumber.isEmpty ||
        dateOfBirth == null ||
        gender == null ||
        hasStore == null) {
      _showMessage(
        context,
        'Please fill all required fields',
      );
      return;
    }

    if (password.length < 8) {
      _showMessage(
        context,
        'Password must be at least 8 characters',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        context,
        'Passwords do not match',
      );
      return;
    }

    // =======================================================
    // VENDOR VALIDATION
    // =======================================================

    if (hasStore == true) {
      if (storeNameController.text.trim().isEmpty ||
          businessDescriptionController.text.trim().isEmpty ||
          ownerType == null ||
          addressController.text.trim().isEmpty ||
          cityController.text.trim().isEmpty ||
          stateController.text.trim().isEmpty ||
          pincodeController.text.trim().isEmpty) {
        _showMessage(
          context,
          'Please fill all required store details',
        );
        return;
      }
    }

    // =======================================================
    // API CALL
    // =======================================================

    try {
      await AuthApiRoutes.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth:
        dateOfBirth!.toIso8601String().split('T')[0],
        gender: gender!,
        hasStore: hasStore!,

        // Vendor details
        storeName: hasStore == true
            ? storeNameController.text.trim()
            : null,

        businessDescription: hasStore == true
            ? businessDescriptionController.text.trim()
            : null,

        ownerType: hasStore == true
            ? ownerType
            : null,

        address: hasStore == true
            ? addressController.text.trim()
            : null,

        city: hasStore == true
            ? cityController.text.trim()
            : null,

        state: hasStore == true
            ? stateController.text.trim()
            : null,

        pincode: hasStore == true
            ? pincodeController.text.trim()
            : null,

        instagram: hasStore == true
            ? _optionalValue(instagramController)
            : null,

        aadhaar: hasStore == true
            ? _optionalValue(aadhaarController)
            : null,

        pan: hasStore == true
            ? _optionalValue(panController)
            : null,
      );

      if (!context.mounted) return;

      _showMessage(
        context,
        hasStore == true
            ? 'Vendor registration successful'
            : 'Registration successful',
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      );
    } catch (e) {
      if (!context.mounted) return;

      _showMessage(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String? _optionalValue(
      TextEditingController controller,
      ) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    phoneNumberController.dispose();

    storeNameController.dispose();
    businessDescriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    instagramController.dispose();
    aadhaarController.dispose();
    panController.dispose();
  }
}