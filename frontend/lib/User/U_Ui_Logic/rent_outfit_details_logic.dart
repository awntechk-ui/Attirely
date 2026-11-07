import 'package:flutter/foundation.dart';
import '../U_API_Routes/u_outfit_api_routes.dart';

class RentOutfitDetailsLogic extends ChangeNotifier {
  Map<String, dynamic>? outfit;

  bool isLoading = true;
  String? errorMessage;

  String? selectedSize;

  List<Map<String, dynamic>> vendorOutfits = [];
  bool isLoadingVendorOutfits = false;

  Future<void> loadDetails(String outfitId, {Map<String, dynamic>? initialOutfit}) async {
    if (initialOutfit != null) {
      outfit = initialOutfit;
    }

    isLoading = outfit == null;
    errorMessage = null;
    notifyListeners();

    try {
      final result =
      await UOutfitApiRoutes.getOutfitDetails(outfitId);

      outfit = result;
      isLoading = false;
      errorMessage = null;

      final availableSizes = sizes();

      if (selectedSize != null &&
          !availableSizes.contains(selectedSize)) {
        selectedSize = null;
      }

      await loadVendorOutfits();

    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<void> loadVendorOutfits() async {
    final currentOutfit = outfit;

    if (currentOutfit == null) return;

    final vendorId = currentOutfit['uploaded_by']?.toString();

    if (vendorId == null || vendorId.isEmpty) return;

    isLoadingVendorOutfits = true;
    notifyListeners();

    try {
      vendorOutfits = await UOutfitApiRoutes.getVendorOutfits(
        vendorId: vendorId,
        excludeOutfitId: currentOutfit['id']?.toString(),
      );
    } catch (e) {
      debugPrint('LOAD VENDOR OUTFITS ERROR: $e');
      vendorOutfits = [];
    } finally {
      isLoadingVendorOutfits = false;
      notifyListeners();
    }
  }


  void selectSize(String size) {
    selectedSize = size;
    notifyListeners();
  }

  double number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String text(dynamic value, [String fallback = '']) {
    final result = value?.toString().trim() ?? '';

    return result.isEmpty || result.toLowerCase() == 'null'
        ? fallback
        : result;
  }

  String money(dynamic value) {
    final amount = number(value);

    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> images() {
    final result = <Map<String, dynamic>>[];
    final rawImages = outfit?['images'];

    if (rawImages is List) {
      for (final image in rawImages) {
        if (image is Map) {
          final map = Map<String, dynamic>.from(image);

          if (text(map['image_url']).isNotEmpty) {
            result.add(map);
          }
        }
      }
    }

    if (result.isEmpty) {
      final cover = text(outfit?['cover_image_url']);

      if (cover.isNotEmpty) {
        result.add({'image_url': cover});
      }
    }

    return result;
  }

  List<String> sizes() {
    final raw = outfit?['sizes'];

    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    return [];
  }

  Map<String, dynamic> measurements() {
    final raw = outfit?['measurements'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  int discountPercentage(dynamic mrp, dynamic rentalPrice) {
    final mrpValue = number(mrp);
    final price = number(rentalPrice);

    if (mrpValue <= price || mrpValue == 0) return 0;

    return ((mrpValue - price) / mrpValue * 100).round();
  }

  String prettyLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty
        ? ''
        : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}