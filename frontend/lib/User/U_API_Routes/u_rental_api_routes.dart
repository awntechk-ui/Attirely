import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../Common_Screens/session_manager.dart';
import '../../app_config.dart';

class RentalsApiRoutes {
  static String get _baseUrl => '${AppConfig.baseUrl}/rentals';

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

    return <String, dynamic>{};
  }

  /// Creates rental requests. The backend processes each outfit separately
  /// and returns successful_items and failed_items.

  static Future<Map<String, dynamic>> createRentalBooking({required List<Map<String, dynamic>> items, required Map<String, dynamic> deliveryAddress}) async {
    final token = await _getAccessToken();

    // Validate address before sending the request.
    if (deliveryAddress.isEmpty) {
      throw Exception('Delivery address is missing.');
    }

    if (items.isEmpty) {
      throw Exception('No outfits selected for rental.');
    }

    final requestBody = {
      'items': items,
      'payment_method': 'dummy',
      'delivery_address': deliveryAddress,
    };

    // Debug: verify the exact request being sent.
    debugPrint('RENTAL CHECKOUT REQUEST:');
    debugPrint(jsonEncode(requestBody));

    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('RENTAL RESPONSE: ${response.statusCode}');
    debugPrint('RENTAL RESPONSE BODY: ${response.body}');

    final data = _decodeResponse(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final detail = data['detail'] ??
          data['message'] ??
          'Rental booking failed.';

      throw Exception(detail.toString());
    }

    return data;
  }

  /// Fetch all rentals belonging to the logged-in customer.
  static Future<List<Map<String, dynamic>>> getMyRentals() async {
    final token = await _getAccessToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/my-rentals'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('MY RENTALS RESPONSE: ${response.statusCode}');
    debugPrint('MY RENTALS BODY: ${response.body}');

    final data = _decodeResponse(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        (data['detail'] ?? data['message'] ?? 'Unable to load rentals.')
            .toString(),
      );
    }

    final rentals = data['rentals'];

    if (rentals is! List) {
      return [];
    }

    return rentals
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }


  /// Cancel a rental request before owner acceptance.
  static Future<Map<String, dynamic>> cancelRental({required String rentalId, required String reason}) async {
    final token = await _getAccessToken();

    if (reason.trim().isEmpty) {
      throw Exception('Please provide a cancellation reason.');
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/$rentalId/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason.trim(),
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        (data['detail'] ??
            data['message'] ??
            'Unable to cancel rental.')
            .toString(),
      );
    }

    return data;
  }


}
