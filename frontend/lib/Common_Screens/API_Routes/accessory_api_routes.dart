
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../../app_config.dart';

class AccessoryApiRoutes {
  // =========================================================
  // CREATE ACCESSORY
  // =========================================================

  static Future<Map<String, dynamic>> createAccessory({
    required String accessToken,
    required String name,
    required String description,
    required String category,
    required String accessoryType,
    required String collection,
    required double rentalPrice,
    double? mrp,
    required double securityDeposit,
    String? brand,
    String? colorName,
    String? material,
    required int quantity,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/accessories'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields.addAll({
      'name': name,
      'description': description,
      'category': category,
      'accessory_type': accessoryType,
      'collection': collection,
      'rental_price': rentalPrice.toString(),
      'security_deposit': securityDeposit.toString(),
      'quantity': quantity.toString(),
    });

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    if (brand != null && brand.trim().isNotEmpty) {
      request.fields['brand'] = brand.trim();
    }

    if (colorName != null && colorName.trim().isNotEmpty) {
      request.fields['color_name'] = colorName.trim();
    }

    if (material != null && material.trim().isNotEmpty) {
      request.fields['material'] = material.trim();
    }

    for (final photo in photos) {
      final mimeType = lookupMimeType(photo.path);

      if (mimeType == null) {
        throw Exception(
          'Could not determine image type: ${photo.path}',
        );
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
      return data;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to publish accessory.')
          .toString(),
    );
  }

  // =========================================================
  // GET ACCESSORIES UPLOADED BY SIGNED-IN USER
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMyAccessories({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/accessories'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final raw = data['accessories'];

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return <Map<String, dynamic>>[];
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to load accessories.')
          .toString(),
    );
  }

  // =========================================================
  // GET ONE ACCESSORY WITH IMAGES
  // =========================================================

  static Future<Map<String, dynamic>> getAccessoryDetails({
    required String accessToken,
    required String accessoryId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/accessories/${Uri.encodeComponent(accessoryId)}',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final accessory = data['accessory'];

      if (accessory is Map) {
        return Map<String, dynamic>.from(accessory);
      }

      return data;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to load accessory details.')
          .toString(),
    );
  }

  // =========================================================
  // UPDATE ACCESSORY AVAILABILITY
  // =========================================================

  static Future<bool> updateAccessoryAvailability({
    required String accessToken,
    required String accessoryId,
    required bool isAvailable,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${AppConfig.baseUrl}/accessories/${Uri.encodeComponent(accessoryId)}/availability',
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
          'Failed to update accessory availability.')
          .toString(),
    );
  }
  // =========================================================
// UPDATE ACCESSORY
// =========================================================

  static Future<void> updateAccessory({
    required String accessToken,
    required String accessoryId,
    required String name,
    required String description,
    required String category,
    required String accessoryType,
    required String collection,
    required double rentalPrice,
    double? mrp,
    required double securityDeposit,
    String? brand,
    String? colorName,
    String? colorHex,
    String? material,
    required int quantity,
    required List<String> keepImageIds,
    required List<File> newPhotos,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(
        '${AppConfig.baseUrl}/accessories/'
            '${Uri.encodeComponent(accessoryId)}',
      ),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields.addAll({
      'name': name,
      'description': description,
      'category': category,
      'accessory_type': accessoryType,
      'collection': collection,
      'rental_price': rentalPrice.toString(),
      'security_deposit': securityDeposit.toString(),
      'quantity': quantity.toString(),
      'keep_image_ids': jsonEncode(keepImageIds),
      'color_name': colorName ?? '',
      'color_hex': colorHex ?? '',
      'material': material ?? '',
      'brand': brand ?? '',
    });

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    for (final photo in newPhotos) {
      final mimeType = lookupMimeType(photo.path);

      if (mimeType == null) {
        throw Exception(
          'Could not determine image type: ${photo.path}',
        );
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

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    throw Exception(
      (data['detail'] ??
          data['message'] ??
          'Failed to update accessory.')
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
}
