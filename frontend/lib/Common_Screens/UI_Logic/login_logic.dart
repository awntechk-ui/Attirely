import 'package:flutter/material.dart';

import '../auth_api_routes.dart';
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

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // =======================================================
    // VALIDATION
    // =======================================================

    if (selectedRole == null) {
      _showMessage(
        context,
        'Please select User or Vendor',
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        context,
        'Please enter your email and password',
      );
      return;
    }

    // =======================================================
    // API CALL
    // =======================================================

    try {
      isLoading = true;

      final response = await AuthApiRoutes.login(
        email: email,
        password: password,
        role: selectedRole!,
      );

      final accessToken = response['access_token'];

      if (accessToken == null ||
          accessToken.toString().isEmpty) {
        throw Exception(
          'Access token not received',
        );
      }

      // =====================================================
      // SAVE SESSION
      // =====================================================

      await SessionManager.setToken(
        accessToken.toString(),
      );

      if (!context.mounted) return;

      // =====================================================
      // ROUTE BASED ON VERIFIED ROLE
      // =====================================================

      final role = response['role'];

      if (role == 'user') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
        return;
      }

      if (role == 'vendor') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vendorDashboard,
        );
        return;
      }

      throw Exception(
        'Unknown account role',
      );
    } catch (e) {
      if (!context.mounted) return;

      _showMessage(
        context,
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
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