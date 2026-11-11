import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../../app_config.dart';

class VendorAccessoryApiRoutes {
  static const String _basePath = '/vendor/accessories';

  // --------------------------------------------------
  // CREATE ACCESSORY
  // --------------------------------------------------

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
    String? colorHex,
    String? material,
    required int quantity,
    required List<File> photos,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$_basePath');

    final request = http.MultipartRequest('POST', uri);

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

    if (brand != null) {
      request.fields['brand'] = brand;
    }

    if (colorName != null) {
      request.fields['color_name'] = colorName;
    }

    if (colorHex != null) {
      request.fields['color_hex'] = colorHex;
    }

    if (material != null) {
      request.fields['material'] = material;
    }

    for (final photo in photos) {
      final mimeType = lookupMimeType(photo.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          photo.path,
          contentType: mimeType != null
              ? _parseMimeType(mimeType)
              : null,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  // --------------------------------------------------
  // GET MY ACCESSORIES
  // --------------------------------------------------

  static Future<List<dynamic>> getMyAccessories({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$_basePath');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    return data['accessories'] ?? [];
  }

  // --------------------------------------------------
  // GET ACCESSORY DETAILS
  // --------------------------------------------------

  static Future<Map<String, dynamic>> getAccessoryDetails({
    required String accessToken,
    required String accessoryId,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}$_basePath/$accessoryId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    return data['accessory'] ?? data;
  }

  // --------------------------------------------------
  // UPDATE ACCESSORY AVAILABILITY
  // --------------------------------------------------

  static Future<Map<String, dynamic>> updateAccessoryAvailability({
    required String accessToken,
    required String accessoryId,
    required bool isAvailable,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}$_basePath/$accessoryId/availability',
    );

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'is_available': isAvailable,
      }),
    );

    return _decodeResponse(response);
  }

  // --------------------------------------------------
  // UPDATE ACCESSORY
  // --------------------------------------------------

  static Future<Map<String, dynamic>> updateAccessory({
    required String accessToken,
    required String accessoryId,
    required String name,
    required String description,
    required String category,
    required String accessoryType,
    required String collection,
    required double rentalPrice,
    required String mrp,
    required double securityDeposit,
    required String brand,
    required String colorName,
    required String colorHex,
    required String material,
    required int quantity,
    required List<String> keepImageIds,
    required List<File> newPhotos,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}$_basePath/$accessoryId',
    );

    final request = http.MultipartRequest('PATCH', uri);

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields.addAll({
      'name': name,
      'description': description,
      'category': category,
      'accessory_type': accessoryType,
      'collection': collection,
      'rental_price': rentalPrice.toString(),
      'mrp': mrp,
      'security_deposit': securityDeposit.toString(),
      'brand': brand,
      'color_name': colorName,
      'color_hex': colorHex,
      'material': material,
      'quantity': quantity.toString(),
      'keep_image_ids': jsonEncode(keepImageIds),
    });

    for (final photo in newPhotos) {
      final mimeType = lookupMimeType(photo.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          photo.path,
          contentType: mimeType != null
              ? _parseMimeType(mimeType)
              : null,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  // --------------------------------------------------
  // MIME TYPE
  // --------------------------------------------------

  static http.MediaType _parseMimeType(String mimeType) {
    final parts = mimeType.split('/');

    return http.MediaType(parts[0], parts[1]);
  }

  // --------------------------------------------------
  // RESPONSE DECODER
  // --------------------------------------------------

  static Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Server returned an invalid response (${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    String message = 'Request failed (${response.statusCode}).';

    if (decoded is Map<String, dynamic>) {
      message = decoded['detail']?.toString() ??
          decoded['message']?.toString() ??
          message;
    }

    throw Exception(message);
  }
}