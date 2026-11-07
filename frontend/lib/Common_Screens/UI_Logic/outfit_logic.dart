import 'package:flutter/foundation.dart';

import '../API_Routes/outfit_api_routes.dart';
import '../API_Routes/accessory_api_routes.dart';
import '../session_manager.dart';

class OutfitsLogic extends ChangeNotifier {
  OutfitsLogic();

  // =========================================================
  // COLLECTION DATA
  // =========================================================

  List<Map<String, dynamic>> _outfits = [];
  List<Map<String, dynamic>> _accessories = [];

  List<Map<String, dynamic>> get outfits =>
      List.unmodifiable(_outfits);

  List<Map<String, dynamic>> get accessories =>
      List.unmodifiable(_accessories);

  // =========================================================
  // LOADING AND ERRORS
  // =========================================================

  bool _isLoading = false;
  bool _isLoadingAccessories = false;

  String? _error;
  String? _accessoriesError;

  bool get isLoading => _isLoading;
  bool get isLoadingAccessories => _isLoadingAccessories;

  String? get error => _error;
  String? get accessoriesError => _accessoriesError;

  // =========================================================
  // COLLECTION SELECTION
  // =========================================================

  bool _showAccessories = false;

  bool get showAccessories => _showAccessories;

  void selectCollection(bool accessoriesSelected) {
    _showAccessories = accessoriesSelected;
    notifyListeners();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredOutfits {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _outfits;

    return _outfits.where((item) {
      return [
        item['name'],
        item['category'],
        item['brand'],
        item['occasion'],
      ].where((value) => value != null).any(
            (value) => value.toString().toLowerCase().contains(query),
      );
    }).toList();
  }

  List<Map<String, dynamic>> get filteredAccessories {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _accessories;

    return _accessories.where((item) {
      return [
        item['name'],
        item['category'],
        item['accessory_type'],
        item['brand'],
        item['collection'],
        item['material'],
      ].where((value) => value != null).any(
            (value) => value.toString().toLowerCase().contains(query),
      );
    }).toList();
  }

  // =========================================================
  // OUTFIT STATISTICS
  // =========================================================

  int get allCount => _outfits.length;

  int get availableCount =>
      _outfits.where(_isAvailable).length;

  int get unavailableCount =>
      _outfits.length - availableCount;

  bool _isAvailable(Map<String, dynamic> item) =>
      item['is_available'] == true;

  // =========================================================
  // ACCESSORY STATISTICS
  // =========================================================

  int get accessoryCount => _accessories.length;

  int get availableAccessoryCount =>
      _accessories.where(_isAvailable).length;

  int get unavailableAccessoryCount =>
      _accessories.length - availableAccessoryCount;

  // =========================================================
  // LOAD OUTFITS
  // =========================================================

  Future<void> loadOutfits() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getAccessToken();

      _outfits = await OutfitApiRoutes.getMyOutfits(
        accessToken: token,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOAD ACCESSORIES
  // =========================================================

  Future<void> loadAccessories() async {
    if (_isLoadingAccessories) return;

    _isLoadingAccessories = true;
    _accessoriesError = null;
    notifyListeners();

    try {
      final token = await _getAccessToken();

      _accessories = await AccessoryApiRoutes.getMyAccessories(
        accessToken: token,
      );
    } catch (e) {
      _accessoriesError =
          e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingAccessories = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOAD BOTH COLLECTIONS
  // =========================================================

  Future<void> loadCollections() async {
    await Future.wait([
      loadOutfits(),
      loadAccessories(),
    ]);
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
  // REFRESH
  // =========================================================

  Future<void> refreshOutfits() async {
    await loadCollections();
  }
}
