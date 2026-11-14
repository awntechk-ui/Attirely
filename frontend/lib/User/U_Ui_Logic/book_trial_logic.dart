
import 'package:flutter/foundation.dart';

import '../U_API_Routes/u_trial_api_routes.dart';
import 'trial_address_logic.dart';

class BookTrialLogic extends ChangeNotifier {
  BookTrialLogic({
    required List<Map<String, dynamic>> outfits,
  }) {
    _selectedOutfits = List<Map<String, dynamic>>.from(outfits);
  }

  // =========================================================
  // CONSTANTS
  // =========================================================

  static const double trialChargePerOutfit = 150;
  static const double platformFeePerOutfit = 50;

  static const List<String> trialTimeSlots = [
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  // =========================================================
  // STATE
  // =========================================================

  List<Map<String, dynamic>> _selectedOutfits = [];

  Map<String, dynamic>? selectedAddress;

  final Map<String, DateTime> _trialDates = {};
  final Map<String, String> _trialTimeSlots = {};

  bool isSubmitting = false;

  // =========================================================
  // GETTERS
  // =========================================================

  List<Map<String, dynamic>> get selectedOutfits =>
      List.unmodifiable(_selectedOutfits);

  int get outfitCount => _selectedOutfits.length;

  double get totalTrialCharge =>
      outfitCount * trialChargePerOutfit;

  double get totalPlatformFee =>
      outfitCount * platformFeePerOutfit;

  double get totalPayable =>
      totalTrialCharge + totalPlatformFee;

  double get refundableAmount =>
      totalPayable - totalPlatformFee;

  bool get canContinue =>
      _selectedOutfits.isNotEmpty &&
          selectedAddress != null &&
          hasCompleteSchedule &&
          !isSubmitting;

  bool get hasCompleteSchedule =>
      _selectedOutfits.every((outfit) {
        final id = outfit['id']?.toString() ?? '';

        return id.isNotEmpty &&
            _trialDates.containsKey(id) &&
            (_trialTimeSlots[id]?.isNotEmpty ?? false);
      });

  // =========================================================
  // ADDRESS MANAGEMENT
  // =========================================================

  Future<void> loadSavedAddresses() async {
    final addressLogic = TrialAddressLogic.instance;

    await addressLogic.loadAddresses(refresh: true);

    final address = addressLogic.selectedAddress;

    if (address != null) {
      setAddress(address);
    }
  }

  void setAddress(Map<String, dynamic> address) {
    selectedAddress = Map<String, dynamic>.from(address);
    notifyListeners();
  }

  void clearAddress() {
    selectedAddress = null;
    notifyListeners();
  }

  Map<String, dynamic> formatTrialAddress() {
    final address = selectedAddress;

    if (address == null) {
      throw Exception('Please select a trial address.');
    }

    return {
      'name': address['full_name'] ?? '',
      'phone': address['mobile'] ?? '',
      'house': address['house'] ?? '',
      'street': address['street'] ?? '',
      'landmark': address['landmark'],
      'city': address['city'] ?? '',
      'state': address['state'] ?? '',
      'pincode': address['pincode'] ?? '',
    };
  }

  String addressText(Map<String, dynamic> address) {
    final parts = [
      address['house'],
      address['street'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ];

    return parts
        .where((part) =>
    part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  // =========================================================
  // OUTFIT MANAGEMENT
  // =========================================================

  void removeOutfit(String outfitId) {
    _selectedOutfits.removeWhere(
          (outfit) => outfit['id']?.toString() == outfitId,
    );

    _trialDates.remove(outfitId);
    _trialTimeSlots.remove(outfitId);

    notifyListeners();
  }

  String imageUrl(Map<String, dynamic> outfit) {
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

  // =========================================================
  // DATE AND TIME MANAGEMENT
  // =========================================================

  DateTime? trialDateFor(String outfitId) =>
      _trialDates[outfitId];

  String? timeSlotFor(String outfitId) =>
      _trialTimeSlots[outfitId];

  void setTrialDate(String outfitId, DateTime date) {
    _trialDates[outfitId] = date;
    notifyListeners();
  }

  void setTrialTimeSlot(String outfitId, String timeSlot) {
    _trialTimeSlots[outfitId] = timeSlot;
    notifyListeners();
  }

  String apiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  void validateBooking() {
    if (_selectedOutfits.isEmpty) {
      throw Exception('Please select at least one outfit.');
    }

    if (selectedAddress == null) {
      throw Exception('Please add or select a trial address.');
    }

    if (!hasCompleteSchedule) {
      throw Exception(
        'Please select a date and time for every outfit.',
      );
    }

    for (final outfit in _selectedOutfits) {
      final outfitId = outfit['id']?.toString() ?? '';
      final selectedSize =
          outfit['selected_size']?.toString().trim() ?? '';

      if (outfitId.isEmpty || selectedSize.isEmpty) {
        throw Exception(
          'An outfit is missing its ID or selected size.',
        );
      }
    }
  }

  // =========================================================
  // BUILD BOOKING REQUEST
  // =========================================================

  List<Map<String, dynamic>> buildBookingRequest() {
    validateBooking();

    final address = formatTrialAddress();

    return _selectedOutfits.map((outfit) {
      final outfitId = outfit['id'].toString();

      final trialDate = _trialDates[outfitId]!;
      final timeSlot = _trialTimeSlots[outfitId]!;

      return {
        'outfit_id': outfitId,
        'selected_size': outfit['selected_size'].toString().trim(),
        'preferred_trial_date': apiDate(trialDate),
        'preferred_time_slot': timeSlot,
        'trial_address': Map<String, dynamic>.from(address),
      };
    }).toList();
  }

  // =========================================================
  // API SUBMISSION
  // =========================================================

  Future<Map<String, dynamic>> submitBooking() async {
    if (isSubmitting) {
      throw Exception('Booking is already being submitted.');
    }

    validateBooking();

    isSubmitting = true;
    notifyListeners();

    try {
      final requestOutfits = buildBookingRequest();

      final response = await UserTrialApiRoutes.bookTrials(
        outfits: requestOutfits,
      );

      return response;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // =========================================================
  // FORMATTING
  // =========================================================

  String money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return '₹${number.toStringAsFixed(0)}';
  }
}


//
// import 'package:flutter/foundation.dart';
//
// class BookTrialLogic extends ChangeNotifier {
//   BookTrialLogic({
//     required List<Map<String, dynamic>> outfits,
//   }) {
//     _selectedOutfits = List<Map<String, dynamic>>.from(outfits);
//   }
//
//   static const int trialChargePerOutfit = 200;
//   static const int refundablePerOutfit = 150;
//   static const int platformPaymentFeePerOutfit = 50;
//
//   List<Map<String, dynamic>> _selectedOutfits = [];
//
//   Map<String, dynamic>? selectedAddress;
//
//   // Each outfit has its own preferred date and time.
//   final Map<String, DateTime> _trialDates = {};
//   final Map<String, String> _trialTimeSlots = {};
//
//   List<Map<String, dynamic>> get selectedOutfits =>
//       List.unmodifiable(_selectedOutfits);
//
//   int get outfitCount => _selectedOutfits.length;
//
//   int get trialCharge => outfitCount * trialChargePerOutfit;
//
//   int get refundableAmount => outfitCount * refundablePerOutfit;
//
//   int get platformPaymentFee =>
//       outfitCount * platformPaymentFeePerOutfit;
//
//   int get totalPayable => trialCharge;
//
//   bool get canContinue =>
//       _selectedOutfits.isNotEmpty && selectedAddress != null;
//
//   String _key(String outfitId) => outfitId;
//
//   DateTime? trialDateFor(String outfitId) =>
//       _trialDates[_key(outfitId)];
//
//   String? timeSlotFor(String outfitId) =>
//       _trialTimeSlots[_key(outfitId)];
//
//   bool get hasCompleteSchedule => _selectedOutfits.every((outfit) {
//     final id = outfit['id']?.toString() ?? '';
//     return id.isNotEmpty &&
//         _trialDates.containsKey(id) &&
//         (_trialTimeSlots[id]?.isNotEmpty ?? false);
//   });
//
//   void setTrialDate(String outfitId, DateTime date) {
//     _trialDates[_key(outfitId)] = date;
//     notifyListeners();
//   }
//
//   void setTrialTimeSlot(String outfitId, String timeSlot) {
//     _trialTimeSlots[_key(outfitId)] = timeSlot;
//     notifyListeners();
//   }
//
//   void removeOutfit(String outfitId) {
//     _selectedOutfits.removeWhere(
//           (outfit) => outfit['id']?.toString() == outfitId,
//     );
//
//     _trialDates.remove(outfitId);
//     _trialTimeSlots.remove(outfitId);
//
//     notifyListeners();
//   }
//
//   void setAddress(Map<String, dynamic> address) {
//     selectedAddress = Map<String, dynamic>.from(address);
//     notifyListeners();
//   }
//
//   void clearAddress() {
//     selectedAddress = null;
//     notifyListeners();
//   }
//
//   void disposeLogic() {
//     dispose();
//   }
//
//
// }
