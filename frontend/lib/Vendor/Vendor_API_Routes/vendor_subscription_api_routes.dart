
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../app_config.dart';

class VendorSubscriptionApiRoutes {
  // =========================================
  // SELECT / ACTIVATE VENDOR SUBSCRIPTION
  // =========================================

  static Future<Map<String, dynamic>> selectPlan({
    required String accessToken,
    required String planCode,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.baseUrl}/vendor/subscription/select',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'plan_code': planCode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ?? 'Failed to activate subscription',
    );
  }
  // =========================================
// GET CURRENT VENDOR SUBSCRIPTION
// =========================================

  static Future<Map<String, dynamic>> getCurrentSubscription({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/vendor/subscription/current',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ?? 'Failed to fetch subscription',
    );
  }
}
