

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../User/U_API_Routes/outfit_api_routes.dart';
import '../API_Routes/accessory_api_routes.dart';
import '../session_manager.dart';

class EditListingLogic extends ChangeNotifier {
  EditListingLogic({
    required this.listingId,
    required this.listingType,
  });

  final String listingId;
  final String listingType;

  bool get isOutfit => listingType.toLowerCase() == 'outfit';
  bool get isAccessory => listingType.toLowerCase() == 'accessory';

  static const int maxPhotos = 5;

  final ImagePicker _picker = ImagePicker();

  // Common fields
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final rentalPriceController = TextEditingController();
  final mrpController = TextEditingController();
  final securityDepositController = TextEditingController();
  final materialController = TextEditingController();

  // Accessory field
  final quantityController = TextEditingController();

  // Outfit measurements
  final bustController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();
  final shoulderController = TextEditingController();
  final lengthController = TextEditingController();

  // Common selections
  String? colorName;
  String? colorHex;

  // Outfit selections
  String? gender;
  String? category;
  String? occasion;
  String? sleeve;
  String? sizeType = 'standard';
  String? outfitType;
  String? fit;
  String? pattern;
  String? collar;
  String? ageGroup;

  final Set<String> selectedSizes = {};

  // Accessory selections
  String? collection;
  String? accessoryType;

  // Images
  List<Map<String, dynamic>> existingImages = [];
  List<File> newPhotos = [];

  List<String> get keepImageIds => existingImages
      .map((image) => image['id'].toString())
      .toList();

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool get canAddPhotos =>
      existingImages.length + newPhotos.length < maxPhotos;

  int get totalPhotos => existingImages.length + newPhotos.length;

  // --------------------------------------------------
  // LOAD LISTING
  // --------------------------------------------------

  Future<void> loadListing() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = SessionManager.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      if (isOutfit) {
        await _loadOutfit(token);
      } else if (isAccessory) {
        await _loadAccessory(token);
      } else {
        throw Exception('Invalid listing type.');
      }
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOutfit(String token) async {
    final data = await OutfitApiRoutes.getOutfitDetails(
      accessToken: token,
      outfitId: listingId,
    );

    nameController.text = _value(data['name']);
    descriptionController.text = _value(data['description']);
    brandController.text = _value(data['brand']);
    rentalPriceController.text = _value(data['rental_price']);
    mrpController.text = _value(data['mrp']);
    securityDepositController.text = _value(data['security_deposit']);
    materialController.text = _value(data['material']);

    gender = _value(data['gender']);
    category = _value(data['category']);
    occasion = _value(data['occasion']);
    sleeve = _value(data['sleeve']);

    outfitType = _value(data['outfit_type']);
    fit = _value(data['fit']);
    pattern = _value(data['pattern']);
    collar = _value(data['collar']);
    ageGroup = _value(data['age_group']);

    sizeType = _value(data['size_type']).isEmpty
        ? 'standard'
        : _value(data['size_type']);

    colorName = _value(data['color_name']);
    colorHex = _value(data['color_hex']);

    selectedSizes.clear();

    final rawSizes = data['sizes'];
    if (rawSizes is List) {
      selectedSizes.addAll(rawSizes.map((e) => e.toString()));
    }

    final measurements = data['measurements'];
    if (measurements is Map) {
      bustController.text = _value(measurements['bust']);
      waistController.text = _value(measurements['waist']);
      hipController.text = _value(measurements['hip']);
      shoulderController.text = _value(measurements['shoulder']);
      lengthController.text = _value(measurements['length']);
    }

    _loadImages(data['images']);
  }

  Future<void> _loadAccessory(String token) async {
    final data = await AccessoryApiRoutes.getAccessoryDetails(
      accessToken: token,
      accessoryId: listingId,
    );

    nameController.text = _value(data['name']);
    descriptionController.text = _value(data['description']);
    brandController.text = _value(data['brand']);
    rentalPriceController.text = _value(data['rental_price']);
    mrpController.text = _value(data['mrp']);
    securityDepositController.text = _value(data['security_deposit']);
    quantityController.text = _value(data['quantity']);

    category = _value(data['category']);
    accessoryType = _value(data['accessory_type']);
    collection = _value(data['collection']);

    colorName = _value(data['color_name']);
    colorHex = _value(data['color_hex']);
    materialController.text = _value(data['material']);

    _loadImages(data['images']);
  }

  void _loadImages(dynamic rawImages) {
    existingImages = [];

    if (rawImages is List) {
      existingImages = rawImages
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
        ..sort((a, b) {
          final first = int.tryParse(
            _value(a['display_order']),
          ) ??
              0;
          final second = int.tryParse(
            _value(b['display_order']),
          ) ??
              0;
          return first.compareTo(second);
        });
    }

    newPhotos.clear();
  }

  // --------------------------------------------------
  // IMAGE MANAGEMENT
  // --------------------------------------------------

  Future<void> pickPhotos() async {
    if (!canAddPhotos) {
      errorMessage = 'You can upload a maximum of 5 photos.';
      notifyListeners();
      return;
    }

    try {
      final remaining = maxPhotos - totalPhotos;

      final selected = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );

      if (selected.isEmpty) return;

      final available = maxPhotos - totalPhotos;

      newPhotos.addAll(
        selected.take(available).map((image) => File(image.path)),
      );

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Unable to select images: ${_cleanError(e)}';
      notifyListeners();
    }
  }

  void removeExistingImage(int index) {
    if (index < 0 || index >= existingImages.length) return;

    existingImages.removeAt(index);
    notifyListeners();
  }

  void removeNewPhoto(int index) {
    if (index < 0 || index >= newPhotos.length) return;

    newPhotos.removeAt(index);
    notifyListeners();
  }

  void reorderExistingImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= existingImages.length) return;

    if (newIndex > oldIndex) newIndex--;

    if (newIndex < 0 || newIndex >= existingImages.length) return;

    final item = existingImages.removeAt(oldIndex);
    existingImages.insert(newIndex, item);

    notifyListeners();
  }

  // --------------------------------------------------
  // SAVE
  // --------------------------------------------------

  Future<bool> saveChanges() async {
    if (isSaving) return false;

    errorMessage = _validate();

    if (errorMessage != null) {
      notifyListeners();
      return false;
    }

    isSaving = true;
    notifyListeners();

    try {
      final token = SessionManager.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final rental = double.parse(rentalPriceController.text.trim());

      final mrpText = mrpController.text.trim();
      final mrp = mrpText.isEmpty
          ? null
          : double.parse(mrpText);

      final deposit = double.parse(
        securityDepositController.text.trim(),
      );

      if (isOutfit) {
        await _saveOutfit(
          token: token,
          rental: rental,
          mrp: mrp,
          deposit: deposit,
        );
      } else {
        await _saveAccessory(
          token: token,
          rental: rental,
          mrp: mrp,
          deposit: deposit,
        );
      }

      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _saveOutfit({
    required String token,
    required double rental,
    required double? mrp,
    required double deposit,
  }) async {
    if (gender == null || category == null || occasion == null) {
      throw Exception('Complete the required outfit selections.');
    }

    final measurements = <String, String>{
      'bust': bustController.text.trim(),
      'waist': waistController.text.trim(),
      'hip': hipController.text.trim(),
      'shoulder': shoulderController.text.trim(),
      'length': lengthController.text.trim(),
    }..removeWhere((key, value) => value.isEmpty);

    await OutfitApiRoutes.updateOutfit(
      accessToken: token,
      outfitId: listingId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      gender: gender!,
      brand: _optional(brandController.text),
      occasion: occasion!,
      category: category!,
      outfitType: _optional(outfitType),
      fit: _optional(fit),
      pattern: _optional(pattern),
      collar: _optional(collar),
      ageGroup: _optional(ageGroup),
      rentalPrice: rental,
      mrp: mrp,
      securityDeposit: deposit,
      colorName: colorName ?? '',
      colorHex: colorHex ?? '',
      sizeType: sizeType ?? 'standard',
      sizes: sizeType == 'standard'
          ? selectedSizes.toList()
          : <String>[],
      measurements: measurements,
      material: _optional(materialController.text),
      sleeve: sleeve ?? '',
      keepImageIds: keepImageIds,
      newPhotos: newPhotos,
    );
  }

  Future<void> _saveAccessory({
    required String token,
    required double rental,
    required double? mrp,
    required double deposit,
  }) async {
    if (category == null || accessoryType == null) {
      throw Exception('Select an accessory category and type.');
    }

    final quantity = int.tryParse(quantityController.text.trim());

    if (quantity == null || quantity < 0) {
      throw Exception('Enter a valid quantity.');
    }

    final mappedCollection = switch (collection?.toLowerCase()) {
      'men' => 'men',
      'women' => 'women',
      'unisex' || 'all' => 'all',
      _ => throw Exception('Select a valid collection.'),
    };

    await AccessoryApiRoutes.updateAccessory(
      accessToken: token,
      accessoryId: listingId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      category: category!,
      accessoryType: accessoryType!,
      collection: mappedCollection,
      rentalPrice: rental,
      mrp: mrp,
      securityDeposit: deposit,
      quantity: quantity,
      brand: _optional(brandController.text),
      colorName: _optional(colorName),
      colorHex: _optional(colorHex),
      material: _optional(materialController.text),
      keepImageIds: keepImageIds,
      newPhotos: newPhotos,
    );
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  String? _validate() {
    if (nameController.text.trim().length < 2) {
      return 'Enter a valid listing name.';
    }

    if (descriptionController.text.trim().isEmpty) {
      return 'Enter a description.';
    }

    final rental = double.tryParse(rentalPriceController.text.trim());

    if (rental == null || rental <= 0) {
      return 'Enter a valid rental price.';
    }

    final mrpText = mrpController.text.trim();

    if (mrpText.isNotEmpty) {
      final mrp = double.tryParse(mrpText);

      if (mrp == null || mrp < rental) {
        return 'MRP must be equal to or higher than rental price.';
      }
    }

    final deposit = double.tryParse(
      securityDepositController.text.trim(),
    );

    if (deposit == null || deposit < 0) {
      return 'Enter a valid security deposit.';
    }

    if (totalPhotos < 1) {
      return 'Keep at least one listing photo.';
    }

    if (totalPhotos > maxPhotos) {
      return 'A maximum of 5 photos is allowed.';
    }

    if (isOutfit) {
      if (gender == null || category == null || occasion == null) {
        return 'Complete the required outfit selections.';
      }
    } else {
      if (category == null || accessoryType == null || collection == null) {
        return 'Complete the accessory selections.';
      }

      final quantity = int.tryParse(quantityController.text.trim());

      if (quantity == null || quantity < 0) {
        return 'Enter a valid quantity.';
      }
    }

    return null;
  }

  String _value(dynamic value) => value?.toString() ?? '';

  String? _optional(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    for (final controller in [
      nameController,
      descriptionController,
      brandController,
      rentalPriceController,
      mrpController,
      securityDepositController,
      materialController,
      quantityController,
      bustController,
      waistController,
      hipController,
      shoulderController,
      lengthController,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }
}
