
import 'package:flutter/foundation.dart';

import '../U_API_Routes/u_outfit_api_routes.dart';

class UserRentalsLogic extends ChangeNotifier {
  List<Map<String, dynamic>> _outfits = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedCategory = 'All';
  String selectedGender = 'All';

  List<Map<String, dynamic>> get outfits => List.unmodifiable(_outfits);

  List<String> get categories {
    final values = _outfits
        .map((item) => item['category']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...values];
  }

  List<String> get genders {
    final values = _outfits
        .map((item) => item['gender']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...values];
  }

  List<Map<String, dynamic>> get filteredOutfits {
    return _outfits.where((outfit) {
      final category = outfit['category']?.toString() ?? '';
      final gender = outfit['gender']?.toString() ?? '';

      final categoryMatches = selectedCategory == 'All' ||
          category == selectedCategory;

      final genderMatches = selectedGender == 'All' ||
          gender.toLowerCase() == selectedGender.toLowerCase();

      return categoryMatches && genderMatches;
    }).toList();
  }

  Future<void> loadOutfits({bool refresh = false}) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;

    if (refresh) notifyListeners();
    notifyListeners();

    try {
      _outfits = await UOutfitApiRoutes.getCatalogue();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }

  void setGender(String value) {
    selectedGender = value;
    notifyListeners();
  }
}
