import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static String? accessToken;

  // =========================================================
  // SET TOKEN
  // =========================================================

  static Future<void> setToken(String token) async {
    accessToken = token;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'access_token',
      token,
    );
  }

  // =========================================================
  // GET TOKEN
  // =========================================================

  static String? getToken() {
    return accessToken;
  }

  // =========================================================
  // LOAD SAVED TOKEN
  // =========================================================

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(
      'access_token',
    );

    accessToken = token;

    return token;
  }

  // =========================================================
  // CLEAR TOKEN
  // =========================================================

  static Future<void> clearToken() async {
    accessToken = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      'access_token',
    );
  }

  // =========================================================
  // GET USER ID
  // =========================================================

  static Future<String?> getUserId() async {
    try {
      final token = getToken() ?? await loadToken();

      if (token == null || token.isEmpty) {
        return null;
      }

      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      String payload = parts[1];

      // Handle Base64 URL padding
      payload += '=' * ((4 - payload.length % 4) % 4);

      final decodedPayload =
      utf8.decode(base64Url.decode(payload));

      final Map<String, dynamic> data =
      jsonDecode(decodedPayload);

      // Extract the user ID from the JWT payload
      return (data['sub'] ??
          data['user_id'] ??
          data['id'])
          ?.toString();
    } catch (e) {
      print('GET USER ID ERROR: $e');
      return null;
    }
  }
}