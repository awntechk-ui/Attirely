
import 'package:flutter/foundation.dart';

class UserWishlistLogic extends ChangeNotifier {
  UserWishlistLogic._();

  static final UserWishlistLogic instance = UserWishlistLogic._();

  // Store saved outfits using their unique outfit IDs.
  final Map<String, Map<String, dynamic>> _wishlist = {};

  List<Map<String, dynamic>> get outfits =>
      _wishlist.values.toList(growable: false);

  int get itemCount => _wishlist.length;

  bool contains(String outfitId) {
    return _wishlist.containsKey(outfitId);
  }

  void toggleOutfit(Map<String, dynamic> outfit) {
    final id = outfit['id']?.toString();

    if (id == null || id.isEmpty) return;

    if (_wishlist.containsKey(id)) {
      _wishlist.remove(id);
    } else {
      _wishlist[id] = Map<String, dynamic>.from(outfit);
    }

    notifyListeners();
  }

  void removeOutfit(String outfitId) {
    if (_wishlist.remove(outfitId) != null) {
      notifyListeners();
    }
  }
}
