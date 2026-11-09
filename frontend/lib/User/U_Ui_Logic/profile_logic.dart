
import 'dart:io';

import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../../app_routes.dart';
import '../U_API_Routes/user_profile_api_routes.dart';

class ProfileLogic extends ChangeNotifier {
  Map<String, dynamic>? profile;

  bool isLoading = false;
  bool isUploadingImage = false;
  String? errorMessage;

  // =========================================================
  // FETCH PROFILE
  // =========================================================

  Future<void> fetchProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await UserProfileApiRoutes.getMyProfile();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // UPLOAD PROFILE IMAGE
  // =========================================================

  Future<bool> uploadProfileImage(File imageFile) async {
    isUploadingImage = true;
    errorMessage = null;
    notifyListeners();

    try {
      final imageUrl =
      await UserProfileApiRoutes.uploadProfileImage(imageFile);

      profile ??= {};

      profile!['profile_image_url'] = imageUrl;

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      profile = await UserProfileApiRoutes.updateMyProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout(BuildContext context) async {
    await SessionManager.clearToken();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }
}
