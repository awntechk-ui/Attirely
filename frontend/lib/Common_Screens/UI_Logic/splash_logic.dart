import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../API_Routes/auth_api_routes.dart';
import '../session_manager.dart';


class SplashLogic {

  // =========================================================
  // CHECK SESSION
  // =========================================================

  Future<void> checkSession(
      BuildContext context,
      ) async {
    print('SPLASH CHECK SESSION STARTED');

    try {

      // -------------------------------------------------------
      // LOAD TOKEN SAVED ON DEVICE
      // -------------------------------------------------------

      final accessToken =
      await SessionManager.loadToken();
      print('SAVED TOKEN EXISTS: ${accessToken != null && accessToken.isNotEmpty}');


      // -------------------------------------------------------
      // NO SAVED TOKEN
      // -------------------------------------------------------

      if (accessToken == null ||
          accessToken.isEmpty) {

        _goToLogin(context);
        return;
      }


      // -------------------------------------------------------
      // VALIDATE TOKEN + GET ACCOUNT ROLE
      // -------------------------------------------------------

      final response =
      await AuthApiRoutes.validateSession(
        accessToken: accessToken,
      );


      // -------------------------------------------------------
      // READ ROLE
      // -------------------------------------------------------

      final role = response['role'];


      if (role == null) {

        throw Exception(
          'Account role not found',
        );
      }


      // -------------------------------------------------------
      // USER
      // -------------------------------------------------------

      if (role == 'user') {

        if (!context.mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );

        return;
      }


      // -------------------------------------------------------
      // VENDOR
      // -------------------------------------------------------

      if (role == 'vendor') {

        if (!context.mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vendorDashboard,
        );

        return;
      }


      // -------------------------------------------------------
      // UNKNOWN ROLE
      // -------------------------------------------------------

      throw Exception(
        'Unknown account role',
      );

    } catch (e) {

      // -------------------------------------------------------
      // INVALID SESSION / PROFILE PROBLEM
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