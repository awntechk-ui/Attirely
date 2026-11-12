import 'package:flutter/foundation.dart';

/// Pure calculations and display helpers for the Payment & Security flow.
/// Payment screens, navigation, dialogs and API orchestration remain in the UI.
class PaymentSecurityLogic extends ChangeNotifier {
  PaymentSecurityLogic({
    required this.rentalFee,
    required this.securityDeposit,
    required this.coutureCareFee,
    required this.deliveryAddress,
  });

  final double rentalFee;
  final double securityDeposit;
  final double coutureCareFee;
  final Map<String, dynamic> deliveryAddress;

  String selectedMethod = 'card';
  String couponInput = 'HAUTE10';
  bool couponApplied = true;
  bool wardrobeExpanded = true;
  bool isSubmitting = false;
  String selectedSavedCard = 'HDFC Bank Infinia Metal';

  double get discount => couponApplied ? rentalFee * 0.10 : 0;
  double get totalDue => rentalFee - discount + coutureCareFee + securityDeposit;

  void selectMethod(String value) {
    selectedMethod = value;
    notifyListeners();
  }

  void setCoupon(String value) {
    couponInput = value;
    notifyListeners();
  }

  void setCouponApplied(bool value) {
    couponApplied = value;
    notifyListeners();
  }

  void toggleWardrobe() {
    wardrobeExpanded = !wardrobeExpanded;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    isSubmitting = value;
    notifyListeners();
  }

  void selectSavedCard(String value) {
    selectedSavedCard = value;
    notifyListeners();
  }

  static String money(num amount) => '₹${amount.round()}';

  static String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static DateTime startFor(Map<String, dynamic> outfit) =>
      DateTime.tryParse(outfit['rental_start_date']?.toString() ?? '') ??
          DateTime.now();

  static int daysFor(Map<String, dynamic> outfit) {
    final value = outfit['rental_days'];
    final days = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return (days == null || days < 1) ? 4 : days;
  }

  static DateTime returnFor(Map<String, dynamic> outfit) =>
      startFor(outfit).add(Duration(days: daysFor(outfit) - 1));

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

  String addressText() {
    final parts = [
      deliveryAddress['house'], deliveryAddress['street'],
      deliveryAddress['landmark'], deliveryAddress['city'],
      deliveryAddress['state'], deliveryAddress['pincode'],
    ];
    return parts
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  static String outfitImage(Map<String, dynamic> outfit) {
    final cover = outfit['cover_image_url']?.toString() ?? '';
    if (cover.isNotEmpty) return cover;
    final images = outfit['images'];
    if (images is List) {
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          final url = image['image_url']?.toString() ?? '';
          if (url.isNotEmpty) return url;
        }
      }
      if (images.isNotEmpty && images.first is Map) {
        return images.first['image_url']?.toString() ?? '';
      }
    }
    return '';
  }
}
