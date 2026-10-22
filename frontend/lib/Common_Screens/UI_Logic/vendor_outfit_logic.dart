import 'package:flutter/foundation.dart';

import '../API_Routes/outfit_api_routes.dart';
import '../session_manager.dart';

class OutfitsLogic extends ChangeNotifier {
  OutfitsLogic();

  // final accessToken = SessionManager.getToken();
  List<Map<String, dynamic>> _outfits = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = all, 1 = available, 2 = unavailable

  List<Map<String, dynamic>> get outfits => List.unmodifiable(_outfits);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  int get allCount => _outfits.length;
  int get availableCount => _outfits.where(_isAvailable).length;
  int get unavailableCount => _outfits.length - availableCount;

  List<Map<String, dynamic>> get filteredOutfits {
    Iterable<Map<String, dynamic>> result = _outfits;
    if (_selectedFilter == 1) result = result.where(_isAvailable);
    if (_selectedFilter == 2) result = result.where((item) => !_isAvailable(item));
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) {
        return [item['name'], item['category'], item['brand'], item['occasion']]
            .where((value) => value != null)
            .any((value) => value.toString().toLowerCase().contains(query));
      });
    }
    return result.toList();
  }

  bool _isAvailable(Map<String, dynamic> outfit) =>
      outfit['is_available'] == true;

  Future<void> loadOutfits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final accessToken = SessionManager.getToken();

      if (accessToken == null || accessToken.isEmpty) {
        return;
      }
      _outfits = await OutfitApiRoutes.getMyOutfits(
        accessToken: accessToken,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(int value) {
    _selectedFilter = value;
    notifyListeners();
  }
}
