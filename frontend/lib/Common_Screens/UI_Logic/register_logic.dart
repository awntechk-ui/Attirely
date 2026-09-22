import 'package:flutter/material.dart';

import '../../User/User_API_routes/auth_api_routes.dart';
import '../../app_routes.dart';

class RegisterLogic {
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

  bool isLoading = false;

  Future<void> register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final fullName = fullNameController.text.trim();
    final phoneNumber = phoneNumberController.text.trim();

    // Check required fields
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        fullName.isEmpty ||
        phoneNumber.isEmpty ||
        dateOfBirth == null ||
        gender == null ||
        hasStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    // Check password length
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
        ),
      );
      return;
    }

    // Check password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }

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
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful'),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    phoneNumberController.dispose();
  }
}