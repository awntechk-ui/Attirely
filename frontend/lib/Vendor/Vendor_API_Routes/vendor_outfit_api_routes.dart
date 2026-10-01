import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../../app_config.dart';

class VendorOutfitApiRoutes {
  // =========================================================
  // CREATE OUTFIT
  //
  // Flutter -> FastAPI only.
  // Flutter does NOT connect to Supabase directly.
  // vendor_id is NOT sent by Flutter.
  // FastAPI gets the authenticated vendor from the bearer token.
  // =========================================================

  static Future<Map<String, dynamic>> createOutfit({
    required String accessToken,
    required String name,
    required String description,
    required String gender,
    String? brand,
    required String occasion,
    required String category,
    required double rentalPrice,
    double? mrp,
    required double securityDeposit,
    required String colorName,
    required String colorHex,
    required String sizeType,
    required List<String> sizes,
    required Map<String, String> measurements,
    required String material,
    required String sleeve,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/vendor/outfits'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['gender'] = gender;
    request.fields['occasion'] = occasion;
    request.fields['category'] = category;
    request.fields['rental_price'] = rentalPrice.toString();
    request.fields['security_deposit'] = securityDeposit.toString();
    request.fields['color_name'] = colorName;
    request.fields['color_hex'] = colorHex;
    request.fields['size_type'] = sizeType;
    request.fields['sizes'] = jsonEncode(sizes);
    request.fields['measurements'] = jsonEncode(measurements);
    request.fields['material'] = material;
    request.fields['sleeve'] = sleeve;

    if (brand != null && brand.trim().isNotEmpty) {
      request.fields['brand'] = brand.trim();
    }

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    // for (final photo in photos) {
    //   request.files.add(
    //     await http.MultipartFile.fromPath(
    //       'photos',
    //       photo.path,
    //     ),
    //   );
    // }
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
          contentType: http.MediaType(
            parts[0],
            parts[1],
          ),
        ),
      );
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Backend may return an empty/non-JSON body on server errors.
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail'] ??
          data['message'] ??
          'Failed to publish outfit.',
    );
  }
}
