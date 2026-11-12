
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../session_manager.dart';

class LocationApiRoutes {
  static Future<Map<String, dynamic>> getMyLocation() async {
    final token = SessionManager.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login again.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/location/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['detail'] ?? 'Could not retrieve saved location.');
  }

  static Future<Map<String, dynamic>> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = SessionManager.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login again.');
    }

    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/location/setup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['detail'] ?? 'Could not save location.');
  }
}
