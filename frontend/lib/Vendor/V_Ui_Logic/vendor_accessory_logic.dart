
import 'dart:io';

import '../Vendor_API_Routes/vendor_accessories_api_routes.dart';

class VendorAccessoryLogic {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> publishAccessory({
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
    isLoading = true;
    errorMessage = null;

    try {
      await VendorAccessoryApiRoutes.createAccessory(
        accessToken: accessToken,
        name: name,
        description: description,
        category: category,
        accessoryType: accessoryType,
        collection: collection,
        rentalPrice: rentalPrice,
        mrp: mrp,
        securityDeposit: securityDeposit,
        brand: brand,
        colorName: colorName,
        material: material,
        quantity: quantity,
        photos: photos,
      );

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }
}
