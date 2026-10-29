
import 'package:flutter/foundation.dart';

class UserOutfitsLogic extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> outfits = [];

  Future<void> loadMyOutfits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Call UserOutfitsApiRoutes.getMyOutfits().
      // Assign the returned list to outfits.

      outfits = [];
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
