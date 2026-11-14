import 'package:flutter/foundation.dart';

/// Business calculations and data formatting for the Rent Out flow.
/// Context-dependent work (dialogs, navigation and address sheets) stays in the UI.
class RentOutLogic extends ChangeNotifier {
  RentOutLogic({
    required List<Map<String, dynamic>> outfits,
    DateTime? defaultStart,
  }) : selectedOutfits = outfits.map((source) {
    final outfit = Map<String, dynamic>.from(source);
    outfit['rental_start_date'] ??= isoDate(
      (defaultStart ?? DateTime.now()).add(const Duration(days: 1)),
    );
    outfit['rental_days'] ??= 4;
    return outfit;
  }).toList();

  final List<Map<String, dynamic>> selectedOutfits;
  Map<String, dynamic>? selectedAddress;
  bool backupSize = true;
  bool coutureCare = true;

  static const double careFee = 299;
  static const double platformFeePerOutfit = 50;
  double get platformFee => selectedOutfits.length * platformFeePerOutfit;
  static const double defaultSecurityDeposit = 1000;

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

  static DateTime startFor(Map<String, dynamic> outfit) =>
      DateTime.tryParse(outfit['rental_start_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1));

  static int daysFor(Map<String, dynamic> outfit) {
    final value = outfit['rental_days'];
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return (parsed == null || parsed < 1) ? 4 : parsed;
  }

  static DateTime returnFor(Map<String, dynamic> outfit) =>
      startFor(outfit).add(Duration(days: daysFor(outfit) - 1));

  static double number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String money(dynamic value) =>
      '₹${number(value).toStringAsFixed(0)}';

  static String image(Map<String, dynamic> outfit) {
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

  static double depositFor(Map<String, dynamic> outfit) {
    final deposit = number(
      outfit['security_deposit'] ??
          outfit['security_price'] ??
          outfit['deposit_amount'] ??
          outfit['security'],
    );
    return deposit > 0 ? deposit : defaultSecurityDeposit;
  }

  double get rentalTotal => selectedOutfits.fold<double>(
    0,
        (sum, outfit) =>
    sum + number(outfit['rental_price']) * daysFor(outfit),
  );

  double get securityDeposit => selectedOutfits.fold<double>(
    0,
        (sum, outfit) => sum + depositFor(outfit),
  );

  double get careTotal => coutureCare ? careFee : 0;


  double get totalPayable => rentalTotal + securityDeposit + careTotal + platformFee;

  void setStartDate(int index, DateTime date) {
    if (index < 0 || index >= selectedOutfits.length) return;
    selectedOutfits[index]['rental_start_date'] = isoDate(date);
    notifyListeners();
  }

  void setDuration(int index, int days) {
    if (index < 0 || index >= selectedOutfits.length || days < 1) return;
    selectedOutfits[index]['rental_days'] = days;
    notifyListeners();
  }

  String removeOutfit(int index) {
    if (index < 0 || index >= selectedOutfits.length) return '';
    final name = selectedOutfits[index]['name']?.toString() ?? 'Outfit';
    selectedOutfits.removeAt(index);
    notifyListeners();
    return name;
  }

  void setAddress(Map<String, dynamic>? address) {
    selectedAddress = address;
    notifyListeners();
  }

  void setBackupSize(bool value) {
    backupSize = value;
    notifyListeners();
  }

  void setCoutureCare(bool value) {
    coutureCare = value;
    notifyListeners();
  }

  static String date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  static String fullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String addressText(Map<String, dynamic> address) {
    final parts = [
      address['house'], address['street'], address['landmark'],
      address['city'], address['state'], address['pincode'],
    ];
    return parts
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }
}
