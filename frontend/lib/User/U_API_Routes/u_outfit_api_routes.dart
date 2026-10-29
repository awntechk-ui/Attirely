import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app_config.dart';

class UOutfitApiRoutes {

  static Future<List<Map<String, dynamic>>> getCatalogue() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/uoutfits/catalogue',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load outfits: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid catalogue response.');
    }

    final outfits = decoded['outfits'];

    if (outfits is! List) {
      return [];
    }

    return outfits
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}