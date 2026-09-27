import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../../app_routes.dart';

class ProfileLogic {
  Future<void> logout(
      BuildContext context,
      ) async {
    await SessionManager.clearToken();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }
}