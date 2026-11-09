
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_config.dart';

class UAccessoryApiRoutes {
  static Future<List<Map<String, dynamic>>> getCatalogue() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/accessories/catalogue'),
      headers: {
        'Accept': 'application/json',
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final raw = data['accessories'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    }

    throw Exception(
      (data['detail'] ??
              data['message'] ??
              'Failed to load accessories.')
          .toString(),
    );
  }
}
