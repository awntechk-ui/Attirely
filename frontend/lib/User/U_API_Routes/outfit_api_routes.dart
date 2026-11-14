import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../../app_config.dart';

class OutfitApiRoutes {
  // =========================================================
  // CREATE OUTFIT
  // =========================================================

  static Future<Map<String, dynamic>> createOutfit({
    required String accessToken,
    required String name,
    required String description,
    required String gender,
    String? brand,
    required String occasion,
    required String category,

    // Additional outfit fields
    String? outfitType,
    String? fit,
    String? pattern,
    String? collar,
    String? ageGroup,

    required double rentalPrice,
    double? mrp,
    required double securityDeposit,
    required String colorName,
    required String colorHex,
    required String sizeType,
    required List<String> sizes,
    required Map<String, String> measurements,
    String? material,
    String? sleeve,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/outfits'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields.addAll({
      'name': name,
      'description': description,
      'gender': gender,
      'occasion': occasion,
      'category': category,
      'rental_price': rentalPrice.toString(),
      'security_deposit': securityDeposit.toString(),
      'color_name': colorName,
      'color_hex': colorHex,
      'size_type': sizeType,
      'sizes': jsonEncode(sizes),
      'measurements': jsonEncode(measurements),
      'outfit_type': outfitType ?? '',
      'fit': fit ?? '',
      'pattern': pattern ?? '',
      'collar': collar ?? '',
      'age_group': ageGroup ?? '',
      'material': material ?? '',
      'sleeve': sleeve ?? '',
    });

    if (brand != null && brand.trim().isNotEmpty) {
      request.fields['brand'] = brand.trim();
    }

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    for (final image in photos) {
      final mimeType = lookupMimeType(image.path);

      if (mimeType == null) {
        throw Exception(
          'Could not determine image type: ${image.path}',
        );
      }

      final parts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          image.path,
          contentType: http.MediaType(parts[0], parts[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          data['message'] ??
          'Failed to publish outfit.',
    );
  }

  // =========================================================
  // GET OUTFITS UPLOADED BY SIGNED-IN USER
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMyOutfits({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/outfits'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final raw = data['outfits'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return <Map<String, dynamic>>[];
    }

    throw Exception(
      (data['detail'] ?? data['message'] ?? 'Failed to load outfits.')
          .toString(),
    );
  }

  // =========================================================
  // GET ONE OUTFIT WITH ORDERED IMAGES
  // =========================================================

  static Future<Map<String, dynamic>> getOutfitDetails({
    required String accessToken,
    required String outfitId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/outfits/${Uri.encodeComponent(outfitId)}',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final outfit = data['outfit'];

      if (outfit is Map) {
        return Map<String, dynamic>.from(outfit);
      }

      return data;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to load outfit details.')
          .toString(),
    );
  }

  // =========================================================
  // UPDATE RENTAL AVAILABILITY
  // =========================================================

  static Future<bool> updateOutfitAvailability({
    required String accessToken,
    required String outfitId,
    required bool isAvailable,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${AppConfig.baseUrl}/outfits/${Uri.encodeComponent(outfitId)}/availability',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'is_available': isAvailable,
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to update availability.')
          .toString(),
    );
  }

  // =========================================================
  // COMMON RESPONSE DECODER
  // =========================================================

  static Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  // =========================================================
  // UPDATE OUTFIT
  // =========================================================

  static Future<void> updateOutfit({
    required String accessToken,
    required String outfitId,
    required String name,
    required String description,
    required String gender,
    String? brand,
    required String occasion,
    required String category,

    // Additional outfit fields
    String? outfitType,
    String? fit,
    String? pattern,
    String? collar,
    String? ageGroup,

    required double rentalPrice,
    double? mrp,
    required double securityDeposit,
    required String colorName,
    required String colorHex,
    required String sizeType,
    required List<String> sizes,
    required Map<String, String> measurements,
    String? material,
    String? sleeve,
    required List<String> keepImageIds,
    required List<File> newPhotos,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(
        '${AppConfig.baseUrl}/outfits/${Uri.encodeComponent(outfitId)}',
      ),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields.addAll({
      'name': name,
      'description': description,
      'gender': gender,
      'occasion': occasion,
      'category': category,
      'rental_price': rentalPrice.toString(),
      'security_deposit': securityDeposit.toString(),
      'color_name': colorName,
      'color_hex': colorHex,
      'size_type': sizeType,
      'sizes': jsonEncode(sizes),
      'measurements': jsonEncode(measurements),
      'outfit_type': outfitType ?? '',
      'fit': fit ?? '',
      'pattern': pattern ?? '',
      'collar': collar ?? '',
      'age_group': ageGroup ?? '',
      'material': material ?? '',
      'sleeve': sleeve ?? '',
      'keep_image_ids': jsonEncode(keepImageIds),
    });

    if (brand != null && brand.trim().isNotEmpty) {
      request.fields['brand'] = brand.trim();
    }

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    for (final photo in newPhotos) {
      final mimeType = lookupMimeType(photo.path);

      if (mimeType == null) {
        throw Exception('Could not determine image type.');
      }

      final parts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          photo.path,
          contentType: http.MediaType(parts[0], parts[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to update outfit.')
          .toString(),
    );
  }
  // =========================================================
// DELETE VENDOR OUTFIT
// =========================================================

  static Future<void> deleteVendorOutfit({
    required String accessToken,
    required String outfitId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${AppConfig.baseUrl}/vendor/outfits/'
            '${Uri.encodeComponent(outfitId)}',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to delete outfit.')
          .toString(),
    );
  }
}
