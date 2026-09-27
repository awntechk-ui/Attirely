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
}