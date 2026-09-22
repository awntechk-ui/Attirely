import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiRoutes {
  static const String baseUrl =
      'http://192.168.1.9:8000';

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
        '$baseUrl/auth/register',
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
        '$baseUrl/auth/login',
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
}