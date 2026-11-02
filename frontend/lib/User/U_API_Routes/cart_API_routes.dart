
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Common_Screens/session_manager.dart';
import '../../app_config.dart';

class CartApiRoutes {
  static String get _baseUrl => '${AppConfig.baseUrl}/cart';

  // =========================================================
  // GET AUTHENTICATION TOKEN
  // =========================================================

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

  // =========================================================
  // COMMON RESPONSE DECODER
  // =========================================================

  static Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  // =========================================================
  // COMMON ERROR HANDLER
  // =========================================================

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    final data = _decodeResponse(response.body);

    final message = data['detail'] ??
        data['message'] ??
        'Cart request failed.';

    throw Exception(message.toString());
  }

  // =========================================================
  // GET USER CART
  // =========================================================

  static Future<Map<String, dynamic>> getCart() async {
    final token = await _getAccessToken();

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // ADD OUTFIT TO CART
  // =========================================================

  static Future<Map<String, dynamic>> addToCart({
    required String outfitId,
  }) async {
    final token = await _getAccessToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'outfit_id': outfitId,
      }),
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // REMOVE OUTFIT FROM CART
  // =========================================================

  static Future<Map<String, dynamic>> removeFromCart({
    required String outfitId,
  }) async {
    final token = await _getAccessToken();

    final encodedId = Uri.encodeComponent(outfitId);

    final response = await http.delete(
      Uri.parse('$_baseUrl/items/$encodedId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // CLEAR ENTIRE CART
  // =========================================================

  static Future<Map<String, dynamic>> clearCart() async {
    final token = await _getAccessToken();

    final response = await http.delete(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }
}
