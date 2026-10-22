import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';

class AuthApiRoutes {
  // =========================
  // REGISTER
  // =========================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String gender,
    required bool hasStore,

    // Vendor details
    String? storeName,
    String? businessDescription,
    String? ownerType,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? instagram,
    String? aadhaar,
    String? pan,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // Common account details
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'has_store': hasStore,

        // Vendor details
        'store_name': storeName,
        'business_description': businessDescription,
        'owner_type': ownerType,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'instagram': instagram,
        'aadhaar': aadhaar,
        'pan': pan,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ?? 'Registration failed',
    );
  }

  // =========================
  // LOGIN
  // =========================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ?? 'Login failed',
    );
  }
  // =========================
// VALIDATE SESSION
// =========================

  // static Future<Map<String, dynamic>> validateSession({
  //   required String accessToken,
  // }) async {
  //   final response = await http.get(
  //     Uri.parse(
  //       '${AppConfig.baseUrl}/auth/session',
  //     ),
  //     headers: {
  //       'Authorization': 'Bearer $accessToken',
  //       'Content-Type': 'application/json',
  //     },
  //   );
  //
  //   final data = jsonDecode(
  //     response.body,
  //   );
  //
  //   if (response.statusCode >= 200 &&
  //       response.statusCode < 300) {
  //     return data;
  //   }
  //
  //   throw Exception(
  //     data['detail'] ??
  //         'Session validation failed',
  //   );
  // }

  static Future<Map<String, dynamic>> validateSession({
    required String accessToken,
  }) async {

    print('CALLING SESSION API');

    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/auth/session',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print('SESSION STATUS: ${response.statusCode}');
    print('SESSION BODY: ${response.body}');

    final data = jsonDecode(
      response.body,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          'Session validation failed',
    );
  }
}