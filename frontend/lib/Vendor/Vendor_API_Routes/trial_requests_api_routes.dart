
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_config.dart';

class TrialRequestsApiRoutes {
  static const String _endpoint = '/vendor/trial-requests';

  static Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) return {};

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static String _errorMessage(Map<String, dynamic> data) {
    final detail = data['detail'] ?? data['message'];

    if (detail is String) return detail;

    return 'Something went wrong. Please try again.';
  }

  // GET ALL TRIAL REQUESTS

  static Future<List<Map<String, dynamic>>> getRequests({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}$_endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final rawRequests = data['requests'];

      if (rawRequests is List) {
        return rawRequests
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    }

    throw Exception(_errorMessage(data));
  }

  // ACCEPT OR REJECT TRIAL REQUEST

  static Future<Map<String, dynamic>> updateRequestStatus({
    required String accessToken,
    required String requestId,
    required String status,
    required String? trialMethod,
    String? rejectionReason,
  }) async {
    if (status == 'accepted' &&
        trialMethod != 'doorstep_delivery' &&
        trialMethod != 'store_visit') {
      throw Exception('Please select a valid trial method.');
    }

    if (status == 'rejected' &&
        (rejectionReason == null ||
            rejectionReason.trim().isEmpty)) {
      throw Exception('Please provide a rejection reason.');
    }

    final response = await http.patch(
      Uri.parse(
        '${AppConfig.baseUrl}$_endpoint/$requestId/status',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'status': status,
        if (status == 'accepted')
          'trial_method': trialMethod,
        if (status == 'rejected')
          'rejection_reason': rejectionReason!.trim(),
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(_errorMessage(data));
  }
}
