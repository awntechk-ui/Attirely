
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'accessory_logic.dart';

/// UI state and publishing coordination for the accessories wizard.
class AddAccessoriesLogic extends ChangeNotifier {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final rentalPriceController = TextEditingController();
  final mrpController = TextEditingController();
  final securityDepositController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final variantNotesController = TextEditingController();

  final _picker = ImagePicker();
  final List<File> photos = [];

  static const maxPhotos = 5;

  final AccessoryLogic _accessoryLogic = AccessoryLogic();

  int step = 0;

  String? gender;
  String? category;
  String? subcategory;
  String? material;
  String? colour;
  String? sizeOption;

  bool isPublishing = false;
  String? errorMessage;

  final genders = const ['Men', 'Women', 'Unisex'];

  final categories = const [
    'Bags',
    'Jewellery',
    'Watches',
    'Footwear',
    'Eyewear',
    'Hair Accessories',
    'Belts & Wallets',
    'Scarves & Wraps',
    'Other',
  ];

  final Map<String, List<String>> subcategories = const {
    'Bags': [
      'Handbag',
      'Clutch',
      'Potli Bag',
      'Sling Bag',
      'Tote Bag',
      'Backpack',
      'Wallet',
    ],
    'Jewellery': [
      'Earrings',
      'Necklace',
      'Pendant',
      'Bracelet',
      'Bangle',
      'Ring',
      'Anklet',
      'Jewellery Set',
    ],
    'Watches': [
      'Analog Watch',
      'Digital Watch',
      'Luxury Watch',
      'Smart Watch',
    ],
    'Footwear': [
      'Heels',
      'Flats',
      'Sandals',
      'Sneakers',
      'Formal Shoes',
      'Ethnic Footwear',
      'Boots',
    ],
    'Eyewear': [
      'Sunglasses',
      'Optical Frames',
    ],
    'Hair Accessories': [
      'Hair Clip',
      'Tiara',
      'Headband',
      'Hair Chain',
      'Decorative Pin',
    ],
    'Belts & Wallets': [
      'Belt',
      'Wallet',
      'Card Holder',
    ],
    'Scarves & Wraps': [
      'Scarf',
      'Stole',
      'Shawl',
      'Dupatta',
    ],
    'Other': [
      'Accessory',
    ],
  };

  final materials = const [
    'Leather',
    'Faux Leather',
    'Metal',
    'Gold-Plated',
    'Silver',
    'Fabric',
    'Silk',
    'Cotton',
    'Beads',
    'Pearl',
    'Stone',
    'Wood',
    'Acrylic',
    'Mixed Material',
    'Other',
  ];

  final colours = const [
    'Black',
    'White',
    'Gold',
    'Silver',
    'Rose Gold',
    'Beige',
    'Brown',
    'Maroon',
    'Red',
    'Pink',
    'Blue',
    'Green',
    'Multicolour',
    'Other',
  ];

  List<String> get availableSubcategories =>
      category == null ? [] : (subcategories[category] ?? []);

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  Future<void> pickPhotos() async {
    final remaining = maxPhotos - photos.length;

    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    for (final image in picked.take(remaining)) {
      photos.add(File(image.path));
    }

    notifyListeners();
  }

  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      photos.removeAt(index);
      notifyListeners();
    }
  }

  // =========================================================
  // WIZARD NAVIGATION
  // =========================================================

  void nextStep() {
    if (step < 4) {
      step++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  String? validateStep() {
    switch (step) {
      case 0:
        if (photos.isEmpty) {
          return 'Please add at least one accessory photo.';
        }
        return null;

      case 1:
        if (nameController.text.trim().isEmpty) {
          return 'Please enter the product name.';
        }

        if (gender == null) {
          return 'Please select who this accessory is for.';
        }

        if (category == null || subcategory == null) {
          return 'Please select a category and type.';
        }

        if (descriptionController.text.trim().isEmpty) {
          return 'Please add a short description.';
        }

        return null;

      case 2:
        final price = double.tryParse(
          rentalPriceController.text.trim(),
        );

        if (price == null || price <= 0) {
          return 'Enter a valid rental price.';
        }

        final deposit = double.tryParse(
          securityDepositController.text.trim(),
        );

        if (deposit == null || deposit < 0) {
          return 'Enter a valid security deposit.';
        }

        final mrpText = mrpController.text.trim();

        if (mrpText.isNotEmpty) {
          final mrp = double.tryParse(mrpText);

          if (mrp == null || mrp < price) {
            return 'MRP must be equal to or higher than rental price.';
          }
        }

        return null;

      case 3:
        final quantity = int.tryParse(
          quantityController.text.trim(),
        );

        if (quantity == null || quantity < 1) {
          return 'Enter an available quantity of at least 1.';
        }

        return null;

      default:
        return null;
    }
  }

  // =========================================================
  // VALIDATE ALL FIELDS BEFORE PUBLISHING
  // =========================================================

  String? validateAllFields() {
    if (photos.isEmpty) {
      return 'Please add at least one accessory photo.';
    }

    if (nameController.text.trim().isEmpty) {
      return 'Please enter the product name.';
    }

    if (gender == null) {
      return 'Please select who this accessory is for.';
    }

    if (category == null || subcategory == null) {
      return 'Please select a category and type.';
    }

    if (descriptionController.text.trim().isEmpty) {
      return 'Please add a short description.';
    }

    final price = double.tryParse(
      rentalPriceController.text.trim(),
    );

    if (price == null || price <= 0) {
      return 'Enter a valid rental price.';
    }

    final deposit = double.tryParse(
      securityDepositController.text.trim(),
    );

    if (deposit == null || deposit < 0) {
      return 'Enter a valid security deposit.';
    }

    final mrpText = mrpController.text.trim();

    if (mrpText.isNotEmpty) {
      final mrp = double.tryParse(mrpText);

      if (mrp == null || mrp < price) {
        return 'MRP must be equal to or higher than rental price.';
      }
    }

    final quantity = int.tryParse(
      quantityController.text.trim(),
    );

    if (quantity == null || quantity < 1) {
      return 'Enter an available quantity of at least 1.';
    }

    return null;
  }

  // =========================================================
  // PUBLISH ACCESSORY
  // =========================================================

  Future<bool> publishAccessory({
    required String accessToken,
  }) async {
    if (isPublishing) return false;

    final validationError = validateAllFields();

    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    isPublishing = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Convert UI gender values to backend collection values.
      final collectionValue = switch (gender) {
        'Men' => 'men',
        'Women' => 'women',
        'Unisex' => 'all',
        _ => throw Exception('Invalid accessory collection.'),
      };

      final success = await _accessoryLogic.publishAccessory(
        accessToken: accessToken,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: category!,
        accessoryType: subcategory!,
        collection: collectionValue,
        rentalPrice: double.parse(
          rentalPriceController.text.trim(),
        ),
        mrp: mrpController.text.trim().isEmpty
            ? null
            : double.parse(mrpController.text.trim()),
        securityDeposit: double.parse(
          securityDepositController.text.trim(),
        ),
        brand: brandController.text.trim().isEmpty
            ? null
            : brandController.text.trim(),
        colorName: colour,
        material: material,
        quantity: int.parse(
          quantityController.text.trim(),
        ),
        photos: photos,
      );

      if (!success) {
        errorMessage = _accessoryLogic.errorMessage ??
            'Failed to publish accessory.';
      }

      return success;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    for (final controller in [
      nameController,
      descriptionController,
      brandController,
      rentalPriceController,
      mrpController,
      securityDepositController,
      quantityController,
      variantNotesController,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }
}
