
import 'package:flutter/foundation.dart';

class UserCartLogic extends ChangeNotifier {
  UserCartLogic._();

  static final UserCartLogic instance = UserCartLogic._();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items =>
      List.unmodifiable(_items);

  int get itemCount => _items.length;

  bool contains(String outfitId) {
    return _items.any(
          (item) => item['id']?.toString() == outfitId,
    );
  }

  void addOutfit(Map<String, dynamic> outfit) {
    final id = outfit['id']?.toString();

    if (id == null || id.isEmpty || contains(id)) return;

    _items.add(Map<String, dynamic>.from(outfit));
    notifyListeners();
  }

  void removeOutfit(String outfitId) {
    _items.removeWhere(
          (item) => item['id']?.toString() == outfitId,
    );

    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get rentalSubtotal {
    return _items.fold<double>(
      0,
          (total, item) => total + _number(item['rental_price']),
    );
  }

  double get securityDepositTotal {
    return _items.fold<double>(
      0,
          (total, item) => total + _number(item['security_deposit']),
    );
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
