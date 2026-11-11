import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_outfits_api_routes.dart';

class VAddKidsOutfitLogic extends ChangeNotifier {
  // Text controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();
  final rentalController = TextEditingController();
  final mrpController = TextEditingController();
  final depositController = TextEditingController();

  // Images
  final ImagePicker _picker = ImagePicker();
  final List<File> photos = [];

  // Local picker ceiling. Backend enforces the active vendor plan limit.
  static const int maxPhotos = 5;

  // Publishing state
  bool isPublishing = false;

  // Selected values
  String? selectedGender;
  String? selectedAge;
  String? selectedCategory;
  String? selectedOccasion;
  String? selectedSize;
  String? selectedMaterial;

  // Dropdown options
  final List<String> genders = [
    'Girls',
    'Boys',
    'Unisex',
  ];

  final List<String> ages = [
    '0–1 Years',
    '1–3 Years',
    '3–5 Years',
    '5–8 Years',
    '8–12 Years',
    '12–16 Years',
  ];

  final List<String> categories = [
    'Traditional',
    'Western',
    'Ethnic',
    'Indo Western',
    'Party Wear',
    'Casual',
    'Festive Wear',
    'Formal',
  ];

  final List<String> occasions = [
    'Birthday',
    'Wedding',
    'Reception',
    'Festival',
    'Family Function',
    'Photoshoot',
    'Casual',
    'Other',
  ];

  final List<String> sizes = [
    '1–2Y',
    '2–3Y',
    '3–4Y',
    '4–5Y',
    '5–6Y',
    '6–7Y',
    '7–8Y',
    '8–10Y',
    '10–12Y',
    '12–14Y',
    '14–16Y',
  ];

  final List<String> materials = [
    'Cotton',
    'Silk',
    'Net',
    'Georgette',
    'Velvet',
    'Satin',
    'Organza',
    'Linen',
    'Other',
  ];

  // Pick photos
  Future<void> pickPhotos() async {
    final remaining = maxPhotos - photos.length;

    if (remaining <= 0) return;

    final selected = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (selected.isEmpty) return;

    photos.addAll(
      selected.take(remaining).map((image) => File(image.path)),
    );

    notifyListeners();
  }

  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      photos.removeAt(index);
      notifyListeners();
    }
  }

  // Selection methods
  void setGender(String? value) {
    selectedGender = value;
    notifyListeners();
  }

  void setAge(String? value) {
    selectedAge = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setOccasion(String? value) {
    selectedOccasion = value;
    notifyListeners();
  }

  void setSize(String? value) {
    selectedSize = value;
    notifyListeners();
  }

  void setMaterial(String? value) {
    selectedMaterial = value;
    notifyListeners();
  }

  // Form validation
  String? validate() {
    if (photos.isEmpty) {
      return 'Please add at least one outfit photo.';
    }

    if (nameController.text.trim().isEmpty) {
      return 'Please enter the outfit name.';
    }

    if (descriptionController.text.trim().isEmpty) {
      return 'Please enter the outfit description.';
    }

    if (selectedGender == null) {
      return 'Please select Girls, Boys or Unisex.';
    }

    if (selectedAge == null) {
      return 'Please select an age group.';
    }

    if (selectedCategory == null) {
      return 'Please select a category.';
    }

    if (selectedOccasion == null) {
      return 'Please select an occasion.';
    }

    if (selectedSize == null) {
      return 'Please select an available size.';
    }

    final rentalPrice = double.tryParse(
      rentalController.text.trim(),
    );

    if (rentalPrice == null || rentalPrice <= 0) {
      return 'Please enter a valid rental price.';
    }

    final deposit = double.tryParse(
      depositController.text.trim(),
    );

    if (deposit == null || deposit < 0) {
      return 'Please enter a valid security deposit.';
    }

    final mrpText = mrpController.text.trim();

    if (mrpText.isNotEmpty) {
      final mrp = double.tryParse(mrpText);

      if (mrp == null || mrp <= 0 || mrp < rentalPrice) {
        return 'MRP must be valid and equal to or above the rental price.';
      }
    }

    return null;
  }

  // Publish vendor kids outfit
  Future<Map<String, dynamic>> publishOutfit() async {
    final error = validate();

    if (error != null) {
      throw Exception(error);
    }

    if (isPublishing) {
      throw Exception('Publishing is already in progress.');
    }

    final token = SessionManager.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final genderMap = {
      'Girls': 'girl_kid',
      'Boys': 'boy_kid',
      'Unisex': 'unisex_kid',
    };

    isPublishing = true;
    notifyListeners();

    try {
      final result = await VendorOutfitApiRoutes.createOutfit(
        accessToken: token,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        gender: genderMap[selectedGender]!,
        brand: brandController.text.trim().isEmpty
            ? null
            : brandController.text.trim(),
        occasion: selectedOccasion!,
        category: selectedCategory!,
        outfitType: null,
        fit: null,
        pattern: null,
        collar: null,
        ageGroup: selectedAge!,
        rentalPrice: double.parse(rentalController.text.trim()),
        mrp: mrpController.text.trim().isEmpty
            ? null
            : double.parse(mrpController.text.trim()),
        securityDeposit: double.parse(depositController.text.trim()),
        colorName: 'Not specified',
        colorHex: '#FFFFFF',
        sizeType: 'standard',
        sizes: [selectedSize!],
        measurements: {},
        material: selectedMaterial,
        sleeve: null,
        photos: photos,
      );

      return result;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    brandController.dispose();
    rentalController.dispose();
    mrpController.dispose();
    depositController.dispose();

    super.dispose();
  }
}