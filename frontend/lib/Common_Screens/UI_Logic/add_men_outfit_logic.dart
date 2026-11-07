import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../API_Routes/outfit_api_routes.dart';
import '../session_manager.dart';

/// UI-only state for the men's outfit form.
/// Backend/API integration can be added later without changing the page layout.
class AddMenOutfitLogic extends ChangeNotifier {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final rentalPriceController = TextEditingController();
  final mrpController = TextEditingController();
  final securityDepositController = TextEditingController();

  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final shoulderController = TextEditingController();
  final sleeveLengthController = TextEditingController();
  final garmentLengthController = TextEditingController();
  final hipController = TextEditingController();
  final inseamController = TextEditingController();

  final _picker = ImagePicker();
  final List<File> photos = [];
  static const int maxPhotos = 5;
  bool isPublishing = false;

  String? category;
  String? outfitType;
  String? occasion;
  String? fit;
  String? pattern;
  String? collar;
  String? sleeve;
  String? material;
  String? sizeMode = 'Standard sizes';
  String? selectedColorName = 'Navy Blue';
  Color selectedColor = const Color(0xFF172B4D);

  final Set<String> selectedSizes = {};

  final categories = const [
    'Traditional', 'Ethnic', 'Indo-Western', 'Formal',
    'Western', 'Casual', 'Party Wear', 'Wedding Wear',
  ];

  final Map<String, List<String>> outfitTypes = const {
    'Traditional': ['Sherwani', 'Kurta Set', 'Nehru Jacket', 'Dhoti Set', 'Pathani Suit'],
    'Ethnic': ['Kurta', 'Kurta Pyjama', 'Angavastram Set', 'Veshti Set'],
    'Indo-Western': ['Indo-Western Sherwani', 'Jacket Kurta Set', 'Asymmetric Kurta'],
    'Formal': ['Two-Piece Suit', 'Three-Piece Suit', 'Blazer', 'Tuxedo', 'Formal Shirt & Trouser'],
    'Western': ['Shirt', 'T-Shirt', 'Jeans', 'Trousers', 'Jacket'],
    'Casual': ['Casual Shirt', 'Polo T-Shirt', 'Casual Trousers', 'Shorts', 'Co-ord Set'],
    'Party Wear': ['Party Shirt', 'Cocktail Suit', 'Statement Blazer', 'Designer Kurta'],
    'Wedding Wear': ['Groom Sherwani', 'Reception Suit', 'Wedding Achkan', 'Wedding Kurta Set'],
  };

  final occasions = const [
    'Wedding', 'Reception', 'Marriage', 'Engagement', 'Groom Wear',
    'Sangeet', 'Haldi', 'Mehendi', 'Party', 'Birthday', 'Festival',
    'Formal Event', 'Office', 'Casual', 'Date Night', 'Other',
  ];

  final fits = const ['Slim Fit', 'Regular Fit', 'Relaxed Fit', 'Tailored Fit', 'Oversized'];
  final patterns = const ['Solid', 'Printed', 'Striped', 'Checked', 'Embroidered', 'Textured', 'Self-Design'];
  final collars = const ['Mandarin / Chinese', 'Bandhgala', 'Spread', 'Button-Down', 'Notched Lapel', 'Peak Lapel', 'Shawl Lapel', 'Round Neck', 'V-Neck', 'Hooded', 'No Collar'];
  final sleeves = const ['Sleeveless', 'Half Sleeve', '3/4 Sleeve', 'Full Sleeve', 'Roll-Up Sleeve'];
  final materials = const [
    'Cotton', 'Linen', 'Silk', 'Raw Silk', 'Velvet', 'Wool', 'Wool Blend',
    'Rayon', 'Viscose', 'Polyester', 'Denim', 'Satin', 'Chanderi', 'Brocade',
    'Jacquard', 'Georgette', 'Khadi', 'Other',
  ];
  final sizes = const ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final colors = const <Map<String, dynamic>>[
    {'name': 'Black', 'color': Color(0xFF171717)},
    {'name': 'White', 'color': Color(0xFFF8F7F2)},
    {'name': 'Navy Blue', 'color': Color(0xFF172B4D)},
    {'name': 'Royal Blue', 'color': Color(0xFF3155A6)},
    {'name': 'Maroon', 'color': Color(0xFF800020)},
    {'name': 'Wine', 'color': Color(0xFF722F37)},
    {'name': 'Beige', 'color': Color(0xFFE7D8C5)},
    {'name': 'Ivory', 'color': Color(0xFFFFF8E7)},
    {'name': 'Olive', 'color': Color(0xFF66734A)},
    {'name': 'Emerald', 'color': Color(0xFF176B50)},
    {'name': 'Grey', 'color': Color(0xFF858585)},
    {'name': 'Brown', 'color': Color(0xFF795548)},
    {'name': 'Gold', 'color': Color(0xFFD4AF37)},
    {'name': 'Pastel Pink', 'color': Color(0xFFE8BFC5)},
  ];

  List<String> get availableOutfitTypes =>
      category == null ? [] : (outfitTypes[category] ?? []);

  Future<void> pickPhotos() async {
    final remaining = maxPhotos - photos.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
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

  void toggleSize(String value) {
    selectedSizes.contains(value) ? selectedSizes.remove(value) : selectedSizes.add(value);
    notifyListeners();
  }

  void setCategory(String? value) {
    category = value;
    outfitType = null;
    notifyListeners();
  }

  void setColor(String name, Color color) {
    selectedColorName = name;
    selectedColor = color;
    notifyListeners();
  }

  Future<Map<String, dynamic>> publishOutfit() async {
    final error = validate();

    if (error != null) {
      throw Exception(error);
    }

    if (isPublishing) {
      throw Exception('Publishing is already in progress.');
    }

    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    isPublishing = true;
    notifyListeners();

    try {
      final measurements = <String, String>{};

      if (sizeMode == 'Measurements') {
        final fields = {
          'chest': chestController,
          'waist': waistController,
          'shoulder': shoulderController,
          'sleeve_length': sleeveLengthController,
          'garment_length': garmentLengthController,
          'hip': hipController,
          'inseam': inseamController,
        };

        for (final entry in fields.entries) {
          final value = entry.value.text.trim();
          if (value.isNotEmpty) {
            measurements[entry.key] = value;
          }
        }
      }

      final colorHex = selectedColor.value
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase();

      final result = await OutfitApiRoutes.createOutfit(
        accessToken: accessToken,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        gender: 'men',
        brand: brandController.text.trim().isEmpty
            ? null
            : brandController.text.trim(),
        occasion: occasion!,
        category: category!,
        outfitType: outfitType,
        fit: fit,
        pattern: pattern,
        collar: collar,
        rentalPrice: double.parse(rentalPriceController.text.trim()),
        mrp: mrpController.text.trim().isEmpty
            ? null
            : double.parse(mrpController.text.trim()),
        securityDeposit:
        double.parse(securityDepositController.text.trim()),
        colorName: selectedColorName ?? '',
        colorHex: '#$colorHex',
        sizeType: sizeMode == 'Standard sizes'
            ? 'standard'
            : 'measurements',
        sizes: selectedSizes.toList(),
        measurements: measurements,
        material: material,
        sleeve: sleeve,
        photos: photos,
      );

      return result;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  String? validate() {
    if (photos.isEmpty) return 'Please add at least one product photo.';
    if (nameController.text.trim().isEmpty) return 'Please enter the outfit name.';
    if (descriptionController.text.trim().isEmpty) return 'Please enter a description.';
    if (category == null || outfitType == null) return 'Please select a category and outfit type.';
    if (occasion == null) return 'Please select an occasion.';
    if (material == null) return 'Please select a fabric.';
    if (sizeMode == 'Standard sizes' && selectedSizes.isEmpty) return 'Please select at least one size.';
    if (sizeMode == 'Measurements' &&
        [chestController, waistController, garmentLengthController].any((c) => c.text.trim().isEmpty)) {
      return 'Please enter chest, waist and garment length.';
    }
    final price = double.tryParse(rentalPriceController.text.trim());
    if (price == null || price <= 0) return 'Enter a valid rental price.';
    final deposit = double.tryParse(securityDepositController.text.trim());
    if (deposit == null || deposit < 0) return 'Enter a valid security deposit.';
    final mrpText = mrpController.text.trim();
    if (mrpText.isNotEmpty) {
      final mrp = double.tryParse(mrpText);
      if (mrp == null || mrp <= 0 || mrp < price) return 'Enter a valid MRP equal to or above rental price.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      nameController, descriptionController, brandController,
      rentalPriceController, mrpController, securityDepositController,
      chestController, waistController, shoulderController,
      sleeveLengthController, garmentLengthController, hipController, inseamController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
