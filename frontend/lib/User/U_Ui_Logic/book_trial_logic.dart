
import 'package:flutter/foundation.dart';

class BookTrialLogic extends ChangeNotifier {
  BookTrialLogic({
    required List<Map<String, dynamic>> outfits,
  }) {
    _selectedOutfits = List<Map<String, dynamic>>.from(outfits);
  }

  static const int trialChargePerOutfit = 200;
  static const int refundablePerOutfit = 150;
  static const int platformPaymentFeePerOutfit = 50;

  List<Map<String, dynamic>> _selectedOutfits = [];

  Map<String, dynamic>? selectedAddress;

  List<Map<String, dynamic>> get selectedOutfits =>
      List.unmodifiable(_selectedOutfits);

  int get outfitCount => _selectedOutfits.length;

  int get trialCharge => outfitCount * trialChargePerOutfit;

  int get refundableAmount => outfitCount * refundablePerOutfit;

  int get platformPaymentFee =>
      outfitCount * platformPaymentFeePerOutfit;

  // The ₹50 fee is deducted from the ₹200 trial charge.
  // The remaining ₹150 is refundable.
  int get totalPayable => trialCharge;

  bool get canContinue =>
      _selectedOutfits.isNotEmpty && selectedAddress != null;

  void removeOutfit(String outfitId) {
    _selectedOutfits.removeWhere(
          (outfit) => outfit['id']?.toString() == outfitId,
    );
    notifyListeners();
  }

  void setAddress(Map<String, dynamic> address) {
    selectedAddress = Map<String, dynamic>.from(address);
    notifyListeners();
  }

  void clearAddress() {
    selectedAddress = null;
    notifyListeners();
  }

  void disposeLogic() {
    dispose();
  }
}
