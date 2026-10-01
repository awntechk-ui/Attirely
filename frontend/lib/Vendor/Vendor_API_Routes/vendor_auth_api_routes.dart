import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_config.dart';

class VendorAuthApiRoutes {
  // =========================================================
  // CHECK CURRENT USER'S VENDOR PROFILE
  // =========================================================

  static Future<Map<String, dynamic>> getMyVendor({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/vendor/me',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    // print("Vendor Data : $data");

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          'Failed to check vendor profile',
    );
  }

  // =========================================================
  // CREATE VENDOR PROFILE
  // =========================================================

  static Future<Map<String, dynamic>> createVendor({
    required String accessToken,
    required String fullName,
    String? aadhaar,
    String? pan,
    required String role,
    required String storeName,
    required String businessDescription,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? instagram,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.baseUrl}/vendor/create',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'aadhaar': aadhaar,
        'pan': pan,
        'role': role,
        'store_name': storeName,
        'business_description': businessDescription,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'instagram': instagram,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          'Failed to create vendor profile',
    );
  }

}