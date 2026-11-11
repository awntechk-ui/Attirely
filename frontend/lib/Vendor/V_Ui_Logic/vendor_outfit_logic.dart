
import 'package:flutter/foundation.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/vendor_accessories_api_routes.dart';
import '../Vendor_API_Routes/vendor_outfits_api_routes.dart';
import '../Vendor_API_Routes/vendor_subscription_api_routes.dart';


class VendorOutfitLogic extends ChangeNotifier {
  VendorOutfitLogic();

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
// SUBSCRIPTION LIMITS
// =========================================================

  bool _isLoadingPlanLimits = false;
  bool _hasActiveSubscription = false;
  bool _planLimitsLoaded = false;

  int? _outfitsLimit;
  int? _accessoriesLimit;

  bool _outfitsUnlimited = false;
  bool _accessoriesUnlimited = false;

  bool get isLoadingPlanLimits => _isLoadingPlanLimits;
  bool get hasActiveSubscription => _hasActiveSubscription;
  bool get planLimitsLoaded => _planLimitsLoaded;

  int? get outfitsLimit => _outfitsLimit;
  int? get accessoriesLimit => _accessoriesLimit;

  bool get outfitsUnlimited => _outfitsUnlimited;
  bool get accessoriesUnlimited => _accessoriesUnlimited;

  bool get canAddOutfit {
    if (!_planLimitsLoaded || !_hasActiveSubscription) return false;

    return _outfitsUnlimited ||
        (_outfitsLimit != null && allCount < _outfitsLimit!);
  }

  bool get canAddAccessory {
    if (!_planLimitsLoaded || !_hasActiveSubscription) return false;

    return _accessoriesUnlimited ||
        (_accessoriesLimit != null &&
            accessoryCount < _accessoriesLimit!);
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
// LOAD CURRENT SUBSCRIPTION LIMITS
// =========================================================

  Future<void> loadSubscriptionLimits() async {
    if (_isLoadingPlanLimits) return;

    _isLoadingPlanLimits = true;
    _planLimitsLoaded = false;
    notifyListeners();

    try {
      final token = await _getAccessToken();

      final response =
      await VendorSubscriptionApiRoutes.getCurrentSubscription(
        accessToken: token,
      );

      _hasActiveSubscription =
          response['has_active_subscription'] == true;

      final subscription = response['subscription'];

      if (_hasActiveSubscription && subscription is Map) {
        _outfitsLimit = int.tryParse(
          subscription['outfits_limit']?.toString() ?? '',
        );

        _accessoriesLimit = int.tryParse(
          subscription['accessories_limit']?.toString() ?? '',
        );

        _outfitsUnlimited =
            subscription['outfits_unlimited'] == true;

        _accessoriesUnlimited =
            subscription['accessories_unlimited'] == true;
      } else {
        _outfitsLimit = null;
        _accessoriesLimit = null;
        _outfitsUnlimited = false;
        _accessoriesUnlimited = false;
      }

      _planLimitsLoaded = true;
    } catch (e) {
      _hasActiveSubscription = false;
      _planLimitsLoaded = false;
      debugPrint('SUBSCRIPTION LIMIT ERROR: $e');
    } finally {
      _isLoadingPlanLimits = false;
      notifyListeners();
    }
  }

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

      final response = await VendorOutfitApiRoutes.getMyOutfits(
        accessToken: token,
      );

      _outfits = response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
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

      final response = await VendorAccessoryApiRoutes.getMyAccessories(
        accessToken: token,
      );

      _accessories = response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
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
    // First load the actual listing counts.
    await Future.wait([
      loadOutfits(),
      loadAccessories(),
    ]);

    // Only after counts are loaded, fetch subscription limits.
    await loadSubscriptionLimits();
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
