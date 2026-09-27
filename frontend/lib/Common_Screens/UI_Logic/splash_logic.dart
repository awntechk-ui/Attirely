import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../auth_api_routes.dart';
import '../session_manager.dart';

class SplashLogic {
  // =========================================================
  // CHECK SESSION
  // =========================================================

  Future<void> checkSession(
      BuildContext context,
      ) async {
    try {
      // -------------------------------------------------------
      // LOAD TOKEN SAVED ON THE DEVICE
      // -------------------------------------------------------

      final accessToken =
      await SessionManager.loadToken();

      // -------------------------------------------------------
      // NO SAVED TOKEN
      // -------------------------------------------------------

      if (accessToken == null ||
          accessToken.isEmpty) {
        _goToLogin(context);
        return;
      }

      // -------------------------------------------------------
      // VALIDATE TOKEN WITH BACKEND
      // -------------------------------------------------------

      await AuthApiRoutes.validateSession(
        accessToken: accessToken,
      );

      // -------------------------------------------------------
      // TOKEN IS VALID
      // -------------------------------------------------------

      if (!context.mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } catch (e) {
      // -------------------------------------------------------
      // TOKEN IS INVALID / EXPIRED
      // -------------------------------------------------------

      await SessionManager.clearToken();

      if (!context.mounted) return;

      _goToLogin(context);
    }
  }

  // =========================================================
  // GO TO LOGIN
  // =========================================================

  void _goToLogin(
      BuildContext context,
      ) {
    if (!context.mounted) return;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );
  }
}