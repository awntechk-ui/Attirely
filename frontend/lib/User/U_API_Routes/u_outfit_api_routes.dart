
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_config.dart';

class UOutfitApiRoutes {
  static Future<List<Map<String, dynamic>>> getCatalogue() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/uoutfits/catalogue',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final decoded = _decodeResponse(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['detail']?.toString() ?? 'Failed to load outfits.',
      );
    }

    final outfits = decoded['outfits'];

    if (outfits is! List) return [];

    return outfits
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> getOutfitDetails(String outfitId) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/uoutfits/${Uri.encodeComponent(outfitId)}',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final decoded = _decodeResponse(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['detail']?.toString() ?? 'Failed to load outfit details.',
      );
    }

    final outfit = decoded['outfit'];

    if (outfit is Map) {
      return Map<String, dynamic>.from(outfit);
    }

    throw Exception('Invalid outfit details response.');
  }

  // ============================================================
// GET OUTFITS FROM A PARTICULAR VENDOR
// ============================================================

  static Future<List<Map<String, dynamic>>> getVendorOutfits({required String vendorId, String? excludeOutfitId,}) async {
    final queryParams = <String, String>{};

    if (excludeOutfitId != null &&
        excludeOutfitId.isNotEmpty) {
      queryParams['exclude_outfit_id'] = excludeOutfitId;
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/uoutfits/vendor/'
          '${Uri.encodeComponent(vendorId)}',
    ).replace(
      queryParameters:
      queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    final decoded = _decodeResponse(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded['detail']?.toString() ??
            'Failed to load vendor outfits.',
      );
    }

    final outfits = decoded['outfits'];

    if (outfits is! List) return [];

    return outfits
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Handled by the caller.
    }

    return <String, dynamic>{};
  }
}
