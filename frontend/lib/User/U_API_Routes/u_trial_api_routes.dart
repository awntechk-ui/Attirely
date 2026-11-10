
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Common_Screens/session_manager.dart';
import '../../app_config.dart';

class UserTrialApiRoutes {
  static String get _baseUrl => '${AppConfig.baseUrl}/trials';

  static Future<String> _getAccessToken() async {
    String? token = SessionManager.getToken();

    if (token == null || token.isEmpty) {
      token = await SessionManager.loadToken();
    }

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    return token;
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return {};
  }

  static Future<Map<String, dynamic>> bookTrials({required List<Map<String, dynamic>> outfits,}) async {
    final token = await _getAccessToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/book'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'outfits': outfits,
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['detail'] ??
          data['message'] ??
          'Could not complete trial booking.';

      throw Exception(message.toString());
    }

    return data;
  }
}
