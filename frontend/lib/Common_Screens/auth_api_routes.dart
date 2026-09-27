import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_config.dart';

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
  }) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.baseUrl}/auth/register',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'has_store': hasStore,
      }),
    );

    final data = jsonDecode(
      response.body,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          'Registration failed',
    );
  }

  // =========================
  // LOGIN
  // =========================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.baseUrl}/auth/login',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(
      response.body,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          'Login failed',
    );
  }
  // =========================
// VALIDATE SESSION
// =========================

  static Future<Map<String, dynamic>> validateSession({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/auth/session',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

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