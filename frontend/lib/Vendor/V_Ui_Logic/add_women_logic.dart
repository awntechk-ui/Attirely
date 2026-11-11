
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_outfits_api_routes.dart';

class AddWomenLogic extends ChangeNotifier {
  // =========================================================
  // FORM CONTROLLERS
  // =========================================================

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final brandController = TextEditingController();

  final rentalPriceController = TextEditingController();
  final mrpController = TextEditingController();
  final securityDepositController = TextEditingController();

  final materialController = TextEditingController();

  final bustController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();
  final shoulderController = TextEditingController();
  final lengthController = TextEditingController();

  // =========================================================
  // SELECTIONS
  // =========================================================

  String? selectedGender = 'Women';
  String? selectedCategory;
  String? selectedOccasion;
  String? selectedSleeve;

  String selectedColorName = 'Rose Pink';
  String selectedColorHex = '#D98B9C';
  Color selectedColor = const Color(0xFFD98B9C);

  String sizeType = 'standard';

  final Set<String> selectedSizes = {};

  // =========================================================
  // PHOTOS
  // =========================================================

  final ImagePicker _picker = ImagePicker();
  final List<File> selectedPhotos = [];

  // Backend subscription limits are authoritative.
  // This is the current client-side selection ceiling.
  // Dynamic 1/3/5 plan limits still need to be fetched.
  static const int maxPhotos = 5;

  final List<Map<String, dynamic>> existingImages = [];

  bool isLoadingOutfit = false;
  String? loadingError;

  List<String> get keptImageIds => existingImages
      .map((image) => image['id'].toString())
      .toList();

  int get totalImageCount =>
      existingImages.length + selectedPhotos.length;

  bool get canAddMorePhotos => totalImageCount < maxPhotos;

  // =========================================================
  // STATE
  // =========================================================

  bool isPublishing = false;

  // =========================================================
  // OPTIONS
  // =========================================================

  final List<String> genders = const [
    'Women',
    'Girls',
  ];

  final List<String> categories = const [
    'Traditional',
    'Western',
    'Semi Western',
    'Ethnic',
    'Indo Western',
    'Fusion',
    'Formal',
    'Casual',
  ];

  final List<String> occasions = const [
    'Wedding',
    'Reception',
    'Marriage',
    'Engagement',
    'Party',
    'Birthday',
    'Festival',
    'Haldi',
    'Mehendi',
    'Sangeet',
    'Casual',
    'Formal Event',
    'Other',
  ];

  final List<String> materials = const [
    'Silk',
    'Cotton',
    'Georgette',
    'Chiffon',
    'Velvet',
    'Net',
    'Linen',
    'Rayon',
    'Polyester',
    'Satin',
    'Organza',
    'Other',
  ];

  final List<String> sleeves = const [
    'Sleeveless',
    'Half Sleeve',
    '3/4 Sleeve',
    'Full Sleeve',
    'Puff Sleeve',
    'Off Shoulder',
    'One Shoulder',
    'Cape Sleeve',
    'Other',
  ];

  final List<String> sizes = const [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  final List<Map<String, dynamic>> colorOptions = const [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Maroon', 'color': Color(0xFF800000)},
    {'name': 'Pink', 'color': Colors.pink},
    {'name': 'Rose Pink', 'color': Color(0xFFD98B9C)},
    {'name': 'Peach', 'color': Color(0xFFFFB07C)},
    {'name': 'Orange', 'color': Colors.orange},
    {'name': 'Yellow', 'color': Colors.yellow},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Olive', 'color': Color(0xFF808000)},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Navy Blue', 'color': Color(0xFF000080)},
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Lavender', 'color': Color(0xFFE6E6FA)},
    {'name': 'Brown', 'color': Colors.brown},
    {'name': 'Beige', 'color': Color(0xFFF5F5DC)},
    {'name': 'Grey', 'color': Colors.grey},
    {'name': 'Gold', 'color': Color(0xFFD4AF37)},
  ];

  // =========================================================
  // EDIT OUTFIT
  // =========================================================

  Future<void> loadOutfitForEditing(String outfitId) async {
    isLoadingOutfit = true;
    loadingError = null;
    notifyListeners();

    try {
      final token = await _getAccessToken();

      final data = await VendorOutfitApiRoutes.getOutfitDetails(
        accessToken: token,
        outfitId: outfitId,
      );

      nameController.text = data['name']?.toString() ?? '';
      descriptionController.text =
          data['description']?.toString() ?? '';
      brandController.text = data['brand']?.toString() ?? '';

      rentalPriceController.text =
          data['rental_price']?.toString() ?? '';
      mrpController.text = data['mrp']?.toString() ?? '';
      securityDepositController.text =
          data['security_deposit']?.toString() ?? '';

      materialController.text = data['material']?.toString() ?? '';

      selectedGender = data['gender']?.toString();
      selectedCategory = data['category']?.toString();
      selectedOccasion = data['occasion']?.toString();
      selectedSleeve = data['sleeve']?.toString();

      selectedColorName =
          data['color_name']?.toString() ?? 'Rose Pink';
      selectedColorHex =
          data['color_hex']?.toString() ?? '#D98B9C';

      final hex = selectedColorHex.replaceFirst('#', '');

      if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
        selectedColor = Color(
          int.parse('FF$hex', radix: 16),
        );
      }

      sizeType = data['size_type']?.toString() ?? 'standard';

      selectedSizes.clear();
      final rawSizes = data['sizes'];

      if (rawSizes is List) {
        selectedSizes.addAll(rawSizes.map((e) => e.toString()));
      }

      final measurements = data['measurements'];

      if (measurements is Map) {
        bustController.text =
            measurements['bust']?.toString() ?? '';
        waistController.text =
            measurements['waist']?.toString() ?? '';
        hipController.text =
            measurements['hip']?.toString() ?? '';
        shoulderController.text =
            measurements['shoulder']?.toString() ?? '';
        lengthController.text =
            measurements['length']?.toString() ?? '';
      }

      existingImages.clear();
      final rawImages = data['images'];

      if (rawImages is List) {
        existingImages.addAll(
          rawImages
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)),
        );
      }

      existingImages.sort(
            (a, b) => ((a['display_order'] ?? 0) as num)
            .compareTo((b['display_order'] ?? 0) as num),
      );
    } catch (e) {
      loadingError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('VENDOR LOAD OUTFIT ERROR: $e');
      rethrow;
    } finally {
      isLoadingOutfit = false;
      notifyListeners();
    }
  }

  // =========================================================
  // PHOTO PICKER
  // =========================================================

  Future<void> pickPhotos() async {
    if (!canAddMorePhotos) return;

    final remaining = maxPhotos - totalImageCount;

    final images = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    for (final image in images.take(remaining)) {
      selectedPhotos.add(File(image.path));
    }

    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < 0 || index >= selectedPhotos.length) return;

    selectedPhotos.removeAt(index);
    notifyListeners();
  }

  void removeExistingImage(int index) {
    if (index < 0 || index >= existingImages.length) return;

    existingImages.removeAt(index);
    notifyListeners();
  }

  // =========================================================
  // COLOR
  // =========================================================

  void setColor({
    required Color color,
    required String name,
  }) {
    selectedColor = color;
    selectedColorName = name;

    final rgb = color.value & 0xFFFFFF;
    selectedColorHex =
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

    notifyListeners();
  }

  // =========================================================
  // SIZE
  // =========================================================

  void toggleSize(String size) {
    if (selectedSizes.contains(size)) {
      selectedSizes.remove(size);
    } else {
      selectedSizes.add(size);
    }

    notifyListeners();
  }

  void setSizeType(String value) {
    if (value != 'standard' && value != 'measurements') return;

    sizeType = value;
    notifyListeners();
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  String? validateForm() {
    if (totalImageCount == 0) {
      return 'Please add at least one outfit photo.';
    }

    if (totalImageCount > maxPhotos) {
      return 'You can upload a maximum of $maxPhotos photos.';
    }

    if (nameController.text.trim().isEmpty) {
      return 'Please enter the outfit name.';
    }

    if (descriptionController.text.trim().isEmpty) {
      return 'Please enter the outfit description.';
    }

    if (selectedGender == null) {
      return 'Please select outfit gender.';
    }

    if (selectedCategory == null) {
      return 'Please select a category.';
    }

    if (selectedOccasion == null) {
      return 'Please select an occasion.';
    }

    if (materialController.text.trim().isEmpty) {
      return 'Please select or enter the material.';
    }

    if (selectedSleeve == null) {
      return 'Please select sleeve type.';
    }

    if (sizeType == 'standard' && selectedSizes.isEmpty) {
      return 'Please select at least one size.';
    }

    if (sizeType == 'measurements') {
      if (bustController.text.trim().isEmpty ||
          waistController.text.trim().isEmpty ||
          hipController.text.trim().isEmpty ||
          lengthController.text.trim().isEmpty) {
        return 'Please enter bust, waist, hip and length measurements.';
      }
    }

    final rentalPrice = double.tryParse(
      rentalPriceController.text.trim(),
    );

    if (rentalPrice == null || rentalPrice <= 0) {
      return 'Please enter a valid rental price.';
    }

    final mrpText = mrpController.text.trim();

    if (mrpText.isNotEmpty) {
      final mrp = double.tryParse(mrpText);

      if (mrp == null || mrp <= 0) {
        return 'Please enter a valid MRP.';
      }

      if (mrp < rentalPrice) {
        return 'MRP cannot be lower than rental price.';
      }
    }

    final security = double.tryParse(
      securityDepositController.text.trim(),
    );

    if (security == null || security < 0) {
      return 'Please enter a valid security deposit.';
    }

    return null;
  }

  // =========================================================
  // PUBLISH / UPDATE THROUGH VENDOR API
  // =========================================================

  Future<bool> publishOutfit({String? outfitId}) async {
    final error = validateForm();

    if (error != null) {
      throw Exception(error);
    }

    if (isPublishing) return false;

    final accessToken = await _getAccessToken();

    isPublishing = true;
    notifyListeners();

    try {
      final measurements = sizeType == 'measurements'
          ? {
        'bust': bustController.text.trim(),
        'waist': waistController.text.trim(),
        'hip': hipController.text.trim(),
        'shoulder': shoulderController.text.trim(),
        'length': lengthController.text.trim(),
      }
          : <String, String>{};

      if (outfitId == null) {
        await VendorOutfitApiRoutes.createOutfit(
          accessToken: accessToken,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          gender: selectedGender!,
          brand: brandController.text.trim().isEmpty
              ? null
              : brandController.text.trim(),
          occasion: selectedOccasion!,
          category: selectedCategory!,
          rentalPrice: double.parse(
            rentalPriceController.text.trim(),
          ),
          mrp: mrpController.text.trim().isEmpty
              ? null
              : double.parse(mrpController.text.trim()),
          securityDeposit: double.parse(
            securityDepositController.text.trim(),
          ),
          colorName: selectedColorName,
          colorHex: selectedColorHex,
          sizeType: sizeType,
          sizes: sizeType == 'standard'
              ? selectedSizes.toList()
              : <String>[],
          measurements: measurements,
          material: materialController.text.trim(),
          sleeve: selectedSleeve!,
          photos: selectedPhotos,
        );
      } else {
        await VendorOutfitApiRoutes.updateOutfit(
          accessToken: accessToken,
          outfitId: outfitId,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          gender: selectedGender!,
          brand: brandController.text.trim().isEmpty
              ? null
              : brandController.text.trim(),
          occasion: selectedOccasion!,
          category: selectedCategory!,
          rentalPrice: double.parse(
            rentalPriceController.text.trim(),
          ),
          mrp: mrpController.text.trim().isEmpty
              ? null
              : double.parse(mrpController.text.trim()),
          securityDeposit: double.parse(
            securityDepositController.text.trim(),
          ),
          colorName: selectedColorName,
          colorHex: selectedColorHex,
          sizeType: sizeType,
          sizes: sizeType == 'standard'
              ? selectedSizes.toList()
              : <String>[],
          measurements: measurements,
          material: materialController.text.trim(),
          sleeve: selectedSleeve!,
          keepImageIds: keptImageIds,
          newPhotos: selectedPhotos,
        );
      }

      return true;
    } catch (e) {
      debugPrint('VENDOR PUBLISH OUTFIT ERROR: $e');
      rethrow;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  // =========================================================
  // SESSION
  // =========================================================

  Future<String> _getAccessToken() async {
    String? token = SessionManager.getToken();
    token ??= await SessionManager.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    return token;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    brandController.dispose();

    rentalPriceController.dispose();
    mrpController.dispose();
    securityDepositController.dispose();

    materialController.dispose();

    bustController.dispose();
    waistController.dispose();
    hipController.dispose();
    shoulderController.dispose();
    lengthController.dispose();

    super.dispose();
  }
}
