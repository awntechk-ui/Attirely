
import 'package:flutter/foundation.dart';

import '../U_API_Routes/Cart_Api_routes.dart';
import '../U_API_Routes/u_outfit_api_routes.dart';

class UserCartLogic extends ChangeNotifier {
  UserCartLogic._();
  // Similar outfit recommendations

  List<Map<String, dynamic>> _similarOutfits = [];

  bool isLoadingSimilar = false;

  List<Map<String, dynamic>> get similarOutfits =>
      List.unmodifiable(_similarOutfits);

  static final UserCartLogic instance = UserCartLogic._();

  // Each item contains:
  // cart_item_id, added_at, outfit, can_rent

  final List<Map<String, dynamic>> _items = [];

  bool isLoading = false;
  bool isUpdating = false;
  String? errorMessage;

  List<Map<String, dynamic>> get items =>
      List.unmodifiable(_items);

  int get itemCount => _items.length;


  // =========================================================
// LOAD SIMILAR OUTFITS
// =========================================================

  Future<void> loadSimilarOutfits() async {
    if (isLoadingSimilar) return;

    if (_items.isEmpty) {
      _similarOutfits.clear();
      notifyListeners();
      return;
    }

    isLoadingSimilar = true;
    notifyListeners();

    try {
      final catalogue = await UOutfitApiRoutes.getCatalogue();

      final cartOutfitIds = _items
          .map((item) => _getOutfit(item)?['id']?.toString())
          .whereType<String>()
          .toSet();

      final cartOutfits = _items
          .map(_getOutfit)
          .whereType<Map<String, dynamic>>()
          .toList();

      final candidates = catalogue.where((outfit) {
        final id = outfit['id']?.toString() ?? '';

        return !cartOutfitIds.contains(id) &&
            outfit['is_available'] == true &&
            outfit['status'] == 'published';
      }).toList();

      final exactMatches = candidates.where((candidate) {
        return cartOutfits.any((cartOutfit) {
          return _same(candidate['gender'], cartOutfit['gender']) &&
              _same(candidate['category'], cartOutfit['category']) &&
              _same(candidate['occasion'], cartOutfit['occasion']);
        });
      }).toList();

      final categoryMatches = candidates.where((candidate) {
        return cartOutfits.any((cartOutfit) {
          return _same(candidate['gender'], cartOutfit['gender']) &&
              _same(candidate['category'], cartOutfit['category']);
        });
      }).toList();

      final fallbackMatches = candidates.where((candidate) {
        return cartOutfits.any((cartOutfit) {
          return _same(candidate['gender'], cartOutfit['gender']) ||
              _same(candidate['category'], cartOutfit['category']);
        });
      }).toList();

      final combined = <Map<String, dynamic>>[];

      void addUnique(List<Map<String, dynamic>> source) {
        for (final outfit in source) {
          final id = outfit['id']?.toString();

          if (id != null &&
              !combined.any((item) => item['id']?.toString() == id)) {
            combined.add(outfit);
          }
        }
      }

      addUnique(exactMatches);

      if (combined.length < 6) {
        addUnique(categoryMatches);
      }

      if (combined.length < 6) {
        addUnique(fallbackMatches);
      }

      _similarOutfits = combined.take(6).toList();
    } catch (error) {
      debugPrint('SIMILAR OUTFITS ERROR: $error');
      _similarOutfits = [];
    } finally {
      isLoadingSimilar = false;
      notifyListeners();
    }
  }

  bool _same(dynamic first, dynamic second) {
    final a = first?.toString().trim().toLowerCase() ?? '';
    final b = second?.toString().trim().toLowerCase() ?? '';

    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  // =========================================================
  // GET OUTFIT FROM CART ITEM
  // =========================================================

  Map<String, dynamic>? _getOutfit(
      Map<String, dynamic> cartItem,
      ) {
    final value = cartItem['outfit'];

    if (value is! Map) return null;

    final outfit = Map<String, dynamic>.from(value);

    // Normalize image URL.
    String imageUrl =
        outfit['cover_image_url']?.toString() ?? '';

    final images = outfit['images'];

    if (imageUrl.isEmpty && images is List) {
      for (final image in images) {
        if (image is Map) {
          final imageMap = Map<String, dynamic>.from(image);

          if (imageMap['is_cover'] == true) {
            imageUrl =
                imageMap['image_url']?.toString() ?? '';
            break;
          }
        }
      }

      // Fallback to first image.
      if (imageUrl.isEmpty && images.isNotEmpty) {
        final first = images.first;

        if (first is Map) {
          imageUrl =
              first['image_url']?.toString() ?? '';
        }
      }
    }

    outfit['cover_image_url'] = imageUrl;

    return outfit;
  }

  // =========================================================
  // CHECK WHETHER OUTFIT IS ALREADY IN CART
  // =========================================================

  bool contains(String outfitId) {
    return _items.any((item) {
      final outfit = _getOutfit(item);

      return outfit?['id']?.toString() == outfitId;
    });
  }

  // =========================================================
  // CHECK AVAILABILITY
  // =========================================================

  bool isAvailable(String outfitId) {
    final item = _items.firstWhere(
          (item) =>
      _getOutfit(item)?['id']?.toString() == outfitId,
      orElse: () => {},
    );

    if (item.isEmpty) return false;

    return item['can_rent'] == true;
  }

  // =========================================================
  // LOAD CART FROM BACKEND
  // =========================================================

  Future<void> loadCart({bool refresh = false}) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await CartApiRoutes.getCart();

      debugPrint('========== CART API RESPONSE ==========');
      debugPrint(response.toString());

      final rawItems = response['items'];

      _items.clear();

      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is Map) {
            final item = Map<String, dynamic>.from(rawItem);

            final outfit = _getOutfit(item);

            if (outfit != null) {
              item['outfit'] = outfit;
            }

            _items.add(item);
          }
        }
      }

      debugPrint('CART ITEMS LOADED: ${_items.length}');

      for (final item in _items) {
        final outfit = _getOutfit(item);

        debugPrint(
          'ITEM: ${outfit?['name']} | '
              'RENT: ${outfit?['rental_price']} | '
              'MRP: ${outfit?['mrp']} | '
              'IMAGE: ${outfit?['cover_image_url']}',
        );
      }
    } catch (error) {
      errorMessage = _cleanError(error);
      debugPrint('CART LOAD ERROR: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // ADD OUTFIT TO CART
  // =========================================================

  Future<bool> addOutfit(
      Map<String, dynamic> outfit,
      ) async {
    final outfitId = outfit['id']?.toString();

    if (outfitId == null || outfitId.isEmpty) {
      errorMessage = 'Invalid outfit.';
      notifyListeners();
      return false;
    }

    if (contains(outfitId)) {
      errorMessage = 'Already in cart.';
      notifyListeners();
      return false;
    }

    if (isUpdating) return false;

    isUpdating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await CartApiRoutes.addToCart(
        outfitId: outfitId,
      );

      final cartItem = response['cart_item'];

      if (cartItem is Map) {
        _items.insert(
          0,
          Map<String, dynamic>.from(cartItem),
        );
      } else {
        await loadCart();
      }

      return true;
    } catch (error) {
      errorMessage = _cleanError(error);

      // Refresh in case the backend already contains the item.
      if (errorMessage == 'Already in cart.') {
        await loadCart();
      }

      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  // =========================================================
  // REMOVE ONE OUTFIT
  // =========================================================

  Future<bool> removeOutfit(String outfitId) async {
    if (isUpdating) return false;

    isUpdating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await CartApiRoutes.removeFromCart(
        outfitId: outfitId,
      );

      _items.removeWhere((item) {
        return _getOutfit(item)?['id']?.toString() ==
            outfitId;
      });

      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  Future<bool> clearCart() async {
    if (isUpdating) return false;

    isUpdating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await CartApiRoutes.clearCart();

      _items.clear();

      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  // =========================================================
  // PRICING
  // =========================================================

  double _number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  double get rentalSubtotal {
    return _items.fold<double>(
      0,
          (total, item) {
        final outfit = _getOutfit(item);

        return total +
            _number(outfit?['rental_price']);
      },
    );
  }

  double get securityDepositTotal {
    return _items.fold<double>(
      0,
          (total, item) {
        final outfit = _getOutfit(item);

        return total +
            _number(outfit?['security_deposit']);
      },
    );
  }

  double get totalRentalPayable {
    return rentalSubtotal + securityDepositTotal;
  }

  // =========================================================
  // CART ITEM HELPERS
  // =========================================================

  Map<String, dynamic>? getOutfitById(String outfitId) {
    for (final item in _items) {
      final outfit = _getOutfit(item);

      if (outfit?['id']?.toString() == outfitId) {
        return outfit;
      }
    }

    return null;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(
      'Exception: ',
      '',
    );
  }
}
