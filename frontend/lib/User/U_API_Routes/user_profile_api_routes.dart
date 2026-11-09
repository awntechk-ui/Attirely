
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../../Common_Screens/session_manager.dart';

class UserProfileApiRoutes {
  // =========================================================
  // GET USER PROFILE
  // GET /users/me
  // =========================================================

  static Future<Map<String, dynamic>> getMyProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data['profile']);
    }

    throw Exception(
      data['detail'] ?? 'Failed to fetch profile',
    );
  }

  // =========================================================
  // UPDATE USER PROFILE
  // PUT /users/me
  // =========================================================

  static Future<Map<String, dynamic>> updateMyProfile({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
  }) async {
    final token = await _getToken();

    final Map<String, dynamic> body = {};

    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
    if (gender != null) body['gender'] = gender;

    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data['profile']);
    }

    throw Exception(
      data['detail'] ?? 'Failed to update profile',
    );
  }

  // =========================================================
  // UPLOAD PROFILE IMAGE
  // POST /users/me/profile-image
  // =========================================================

  static Future<String> uploadProfileImage(
      File imageFile,
      ) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${AppConfig.baseUrl}/users/me/profile-image',
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data['profile_image_url'];
    }

    throw Exception(
      data['detail'] ?? 'Failed to upload profile image',
    );
  }

  // =========================================================
  // GET ACCESS TOKEN
  // =========================================================

  static Future<String> _getToken() async {
    String? token = SessionManager.getToken();

    token ??= await SessionManager.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    return token;
  }
}
