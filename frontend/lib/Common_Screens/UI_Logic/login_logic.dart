import 'package:flutter/material.dart';
import '../auth_api_routes.dart';
import '../../app_routes.dart';
import '../session_manager.dart';

class LoginLogic {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    isLoading = true;

    try {
      final response = await AuthApiRoutes.login(
        email: email,
        password: password,
      );

      final accessToken = response['access_token'];
      if (accessToken == null) {
        throw Exception('Access token not received');
      }

      await SessionManager.setToken(accessToken);
      if (!context.mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      isLoading = false;
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}