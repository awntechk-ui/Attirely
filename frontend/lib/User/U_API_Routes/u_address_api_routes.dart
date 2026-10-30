
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Common_Screens/session_manager.dart';
import '../../app_config.dart';

class UserAddressApiRoutes {
  static String get _baseUrl =>
      '${AppConfig.baseUrl}/addresses';

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
        'Address request failed.';

    throw Exception(message.toString());
  }

  // =========================================================
  // GET ALL USER ADDRESSES
  // =========================================================

  static Future<Map<String, dynamic>> getAddresses() async {
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
  // ADD NEW ADDRESS
  // =========================================================

  static Future<Map<String, dynamic>> addAddress({
    required Map<String, dynamic> address,
  }) async {
    final token = await _getAccessToken();

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(address),
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // UPDATE ADDRESS
  // =========================================================

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required Map<String, dynamic> address,
  }) async {
    final token = await _getAccessToken();

    final encodedId = Uri.encodeComponent(addressId);

    final response = await http.put(
      Uri.parse('$_baseUrl/$encodedId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(address),
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // SET DEFAULT ADDRESS
  // =========================================================

  static Future<Map<String, dynamic>> setDefaultAddress({
    required String addressId,
  }) async {
    final token = await _getAccessToken();

    final encodedId = Uri.encodeComponent(addressId);

    final response = await http.patch(
      Uri.parse('$_baseUrl/$encodedId/default'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  static Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async {
    final token = await _getAccessToken();

    final encodedId = Uri.encodeComponent(addressId);

    final response = await http.delete(
      Uri.parse('$_baseUrl/$encodedId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _checkResponse(response);

    return _decodeResponse(response.body);
  }
}
