import 'package:flutter/foundation.dart';
import '../API_Routes/outfit_api_routes.dart';
import '../session_manager.dart';

class OutfitDetailsLogic extends ChangeNotifier {
  OutfitDetailsLogic(this.outfitId);
  final String outfitId;
  Map<String, dynamic>? outfit;
  bool isLoading = true;
  bool isUpdatingAvailability = false;
  String? error;
  int selectedImageIndex = 0;

  List<Map<String, dynamic>> get images {
    final raw = outfit?['images'];
    if (raw is! List) return <Map<String, dynamic>>[];
    final result = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    result.sort((a, b) => ((a['display_order'] ?? 0) as num).compareTo((b['display_order'] ?? 0) as num));
    return result;
  }
  bool get isAvailable => outfit?['is_available'] == true;

  Future<void> load() async {
    isLoading = true; error = null; notifyListeners();
    try {
      final token = SessionManager.getToken();
      if (token == null || token.isEmpty) throw Exception('Your session has expired. Please log in again.');
      outfit = await OutfitApiRoutes.getOutfitDetails(accessToken: token, outfitId: outfitId);
      selectedImageIndex = 0;
    } catch (e) { error = e.toString().replaceFirst('Exception: ', ''); }
    finally { isLoading = false; notifyListeners(); }
  }

  void selectImage(int index) {
    if (index < 0 || index >= images.length) return;
    selectedImageIndex = index; notifyListeners();
  }

  Future<void> setAvailability(bool value) async {
    if (outfit == null || isUpdatingAvailability || value == isAvailable) return;
    final token = SessionManager.getToken();
    if (token == null || token.isEmpty) throw Exception('Your session has expired. Please log in again.');
    final old = outfit!['is_available'];
    outfit!['is_available'] = value; isUpdatingAvailability = true; notifyListeners();
    try {
      await OutfitApiRoutes.updateOutfitAvailability(accessToken: token, outfitId: outfitId, isAvailable: value);
    } catch (_) { outfit!['is_available'] = old; rethrow; }
    finally { isUpdatingAvailability = false; notifyListeners(); }
  }
}
