import 'package:flutter/material.dart';

import '../../Vendor/Vendor_API_Routes/vendor_auth_api_routes.dart';
import '../../Vendor/Vendor_API_Routes/vendor_subscription_api_routes.dart';
import '../API_Routes/auth_api_routes.dart';
import '../session_manager.dart';
import '../../app_routes.dart';

class LoginLogic {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  // =========================================================
  // ACCOUNT TYPE
  // =========================================================

  String? selectedRole;

  bool isLoading = false;

  // =========================================================
  // LOGIN
  // =========================================================

  // Future<void> login(BuildContext context) async {
  //   final email = emailController.text.trim();
  //   final password = passwordController.text;
  //
  //   // =======================================================
  //   // VALIDATION
  //   // =======================================================
  //
  //   if (selectedRole == null) {
  //     _showMessage(
  //       context,
  //       'Please select User or Vendor',
  //     );
  //     return;
  //   }
  //
  //   if (email.isEmpty || password.isEmpty) {
  //     _showMessage(
  //       context,
  //       'Please enter your email and password',
  //     );
  //     return;
  //   }
  //   if (password.length < 6) {
  //     _showMessage(
  //       context,
  //       'Password must be at least 6 characters',
  //     );
  //     return;
  //   }
  //
  //   // =======================================================
  //   // API CALL
  //   // =======================================================
  //
  //   try {
  //     isLoading = true;
  //
  //     final response = await AuthApiRoutes.login(
  //       email: email,
  //       password: password,
  //       role: selectedRole!,
  //     );
  //
  //     final accessToken = response['access_token'];
  //
  //     if (accessToken == null ||
  //         accessToken.toString().isEmpty) {
  //       throw Exception(
  //         'Access token not received',
  //       );
  //     }
  //
  //     // =====================================================
  //     // SAVE SESSION
  //     // =====================================================
  //
  //     await SessionManager.setToken(
  //       accessToken.toString(),
  //     );
  //
  //     if (!context.mounted) return;
  //
  //     // =====================================================
  //     // ROUTE BASED ON VERIFIED ROLE
  //     // =====================================================
  //
  //     final role = response['role'];
  //
  //     if (role == 'user') {
  //       Navigator.pushReplacementNamed(
  //         context,
  //         AppRoutes.userMain,
  //       );
  //       return;
  //     }
  //
  //     if (role == 'vendor') {
  //       Navigator.pushReplacementNamed(
  //         context,
  //         AppRoutes.vendorMain,
  //       );
  //       return;
  //     }
  //
  //     throw Exception(
  //       'Unknown account role',
  //     );
  //   } catch (e) {
  //     if (!context.mounted) return;
  //
  //     _showMessage(
  //       context,
  //       e.toString().replaceFirst(
  //         'Exception: ',
  //         '',
  //       ),
  //     );
  //   } finally {
  //     isLoading = false;
  //   }
  // }
  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // =======================================================
    // VALIDATION
    // =======================================================

    if (selectedRole == null) {
      _showMessage(context, 'Please select User or Vendor');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter your email and password');
      return;
    }

    if (password.length < 6) {
      _showMessage(context, 'Password must be at least 6 characters');
      return;
    }

    try {
      isLoading = true;

      // =====================================================
      // 1. LOGIN
      // =====================================================

      final response = await AuthApiRoutes.login(
        email: email,
        password: password,
        role: selectedRole!,
      );

      final accessToken = response['access_token'];

      if (accessToken == null ||
          accessToken.toString().isEmpty) {
        throw Exception('Access token not received');
      }

      // =====================================================
      // 2. SAVE SESSION
      // =====================================================

      await SessionManager.setToken(accessToken.toString());

      if (!context.mounted) return;

      // Use the role returned by the backend.
      final role = response['role']
          ?.toString()
          .toLowerCase();

      // =====================================================
      // 3. CUSTOMER LOGIN — EXISTING FLOW
      // =====================================================

      if (role == 'user') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.userMain,
        );
        return;
      }

      // =====================================================
      // 4. VENDOR LOGIN — CHECK VENDOR PROFILE
      // =====================================================

      if (role == 'vendor') {
        final vendorResponse =
        await VendorAuthApiRoutes.getMyVendor(
          accessToken: accessToken.toString(),
        );

        if (!context.mounted) return;

        final vendorExists = vendorResponse['exists'] == true;

        // ---------------------------------------------------
        // CASE 1: VENDOR PROFILE DOES NOT EXIST
        // ---------------------------------------------------

        if (!vendorExists) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.vendorRegister,
          );
          return;
        }

        // ---------------------------------------------------
        // CASE 2: VENDOR PROFILE EXISTS — CHECK SUBSCRIPTION
        // ---------------------------------------------------

        final subscriptionResponse =
        await VendorSubscriptionApiRoutes.getCurrentSubscription(
          accessToken: accessToken.toString(),
        );

        if (!context.mounted) return;

        final hasActiveSubscription =
            subscriptionResponse['has_active_subscription'] == true;

        // ---------------------------------------------------
        // CASE 3: NO ACTIVE SUBSCRIPTION
        // ---------------------------------------------------

        if (!hasActiveSubscription) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.vendorUpgrade,
          );
          return;
        }

        // ---------------------------------------------------
        // CASE 4: ACTIVE SUBSCRIPTION EXISTS
        // ---------------------------------------------------

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vendorMain,
        );
        return;
      }

      throw Exception('Unknown account role');

    } catch (e) {
      if (!context.mounted) return;

      _showMessage(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );

    } finally {
      isLoading = false;
    }
  }
  // =========================================================
  // MESSAGE
  // =========================================================

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
  }
}