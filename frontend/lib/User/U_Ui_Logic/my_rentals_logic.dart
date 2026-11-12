
import 'package:flutter/foundation.dart';

import '../U_API_Routes/u_rental_api_routes.dart';

class MyRentalsLogic extends ChangeNotifier {
  List<Map<String, dynamic>> _rentals = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedFilter = 'All';
  String searchQuery = '';
  final Set<String> cancellingRentalIds = {};

  final List<String> filters = [
    'All',
    'Pending',
    'Accepted',
    'Active',
    'Rejected',
    'Completed',
    'Cancelled',
  ];

  List<Map<String, dynamic>> get rentals =>
      List.unmodifiable(_rentals);

  Future<void> loadRentals() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _rentals = await RentalsApiRoutes.getMyRentals();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> cancelRental({required String rentalId, required String reason}) async {
    if (rentalId.trim().isEmpty) {
      throw Exception('Invalid rental ID.');
    }

    final rental = _rentals.firstWhere(
          (item) => item['id']?.toString() == rentalId,
      orElse: () => {},
    );

    if (rental.isEmpty) {
      throw Exception('Rental not found.');
    }

    // Only pending rentals can be cancelled.
    if (statusOf(rental) != 'pending') {
      throw Exception(
        'Only pending rentals can be cancelled.',
      );
    }

    if (reason.trim().isEmpty) {
      throw Exception('Cancellation reason is required.');
    }

    if (cancellingRentalIds.contains(rentalId)) return;

    cancellingRentalIds.add(rentalId);
    notifyListeners();

    try {
      await RentalsApiRoutes.cancelRental(
        rentalId: rentalId,
        reason: reason.trim(),
      );

      // Fetch the latest status from the backend.
      await loadRentals();
    } finally {
      cancellingRentalIds.remove(rentalId);
      notifyListeners();
    }
  }


  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  String statusOf(Map<String, dynamic> rental) {
    return (rental['status'] ?? 'pending').toString().toLowerCase();
  }

  int countFor(String filter) {
    if (filter == 'All') return _rentals.length;

    return _rentals.where((rental) {
      return statusOf(rental) == filter.toLowerCase();
    }).length;
  }

  List<Map<String, dynamic>> get filteredRentals {
    return _rentals.where((rental) {
      final status = statusOf(rental);

      final matchesFilter = selectedFilter == 'All' ||
          status == selectedFilter.toLowerCase();

      final searchable = [
        rental['booking_reference'],
        rental['outfit_name'],
        rental['selected_size'],
        rental['outfit_id'],
      ].join(' ').toLowerCase();

      final matchesSearch =
          searchQuery.isEmpty || searchable.contains(searchQuery);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get groupedRentals {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final rental in filteredRentals) {
      final reference =
          rental['booking_reference']?.toString() ?? 'Unknown';

      groups.putIfAbsent(reference, () => []).add(rental);
    }

    final result = groups.entries.map((entry) {
      final rows = entry.value;

      rows.sort((a, b) {
        final aDate = DateTime.tryParse(
          a['created_at']?.toString() ?? '',
        );
        final bDate = DateTime.tryParse(
          b['created_at']?.toString() ?? '',
        );

        return (bDate ?? DateTime(2000))
            .compareTo(aDate ?? DateTime(2000));
      });

      return <String, dynamic>{
        'booking_reference': entry.key,
        'booked_on': rows.first['created_at'],
        'total_outfits': rows.length,
        'outfits': rows,
      };
    }).toList();

    result.sort((a, b) {
      final aDate = DateTime.tryParse(
        a['booked_on']?.toString() ?? '',
      );
      final bDate = DateTime.tryParse(
        b['booked_on']?.toString() ?? '',
      );

      return (bDate ?? DateTime(2000))
          .compareTo(aDate ?? DateTime(2000));
    });

    return result;
  }

  String imageOf(Map<String, dynamic> rental) {
    return rental['outfit_image_url']?.toString() ?? '';
  }

  String outfitName(Map<String, dynamic> rental) {
    return rental['outfit_name']?.toString() ?? 'Outfit';
  }

  String bookingLabel(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) return 'RENT-UNKNOWN';

    final compact = text.replaceAll('-', '').toUpperCase();

    return 'RENT-${compact.length > 8 ? compact.substring(0, 8) : compact}';
  }

  String dateLabel(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String money(dynamic value) {
    final amount = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;

    return '₹${amount.toStringAsFixed(0)}';
  }

  String titleCase(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  Map<String, dynamic> addressOf(Map<String, dynamic> rental) {
    final address = rental['delivery_address'];

    if (address is Map) {
      return Map<String, dynamic>.from(address);
    }

    return {};
  }

  String addressLabel(Map<String, dynamic> rental) {
    final address = addressOf(rental);

    return [
      address['house'],
      address['street'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ].where((part) {
      return part != null && part.toString().trim().isNotEmpty;
    }).join(', ');
  }
}


//
// import 'package:flutter/foundation.dart';
//
// import '../U_API_Routes/u_rental_api_routes.dart';
//
// class MyRentalsLogic extends ChangeNotifier {
//   List<Map<String, dynamic>> _rentals = [];
//
//   bool isLoading = false;
//   String? errorMessage;
//
//   String selectedFilter = 'All';
//   String searchQuery = '';
//
//   final List<String> filters = [
//     'All',
//     'Pending',
//     'Accepted',
//     'Active',
//     'Rejected',
//     'Completed',
//     'Cancelled',
//   ];
//
//   List<Map<String, dynamic>> get rentals =>
//       List.unmodifiable(_rentals);
//
//   Future<void> loadRentals() async {
//     if (isLoading) return;
//
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();
//
//     try {
//       _rentals = await RentalsApiRoutes.getMyRentals();
//     } catch (e) {
//       errorMessage = e.toString().replaceFirst('Exception: ', '');
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void setFilter(String filter) {
//     selectedFilter = filter;
//     notifyListeners();
//   }
//
//   void setSearch(String value) {
//     searchQuery = value.trim().toLowerCase();
//     notifyListeners();
//   }
//
//   String statusOf(Map<String, dynamic> rental) {
//     return (rental['status'] ?? 'pending').toString().toLowerCase();
//   }
//
//   int countFor(String filter) {
//     if (filter == 'All') return _rentals.length;
//
//     return _rentals.where((rental) {
//       return statusOf(rental) == filter.toLowerCase();
//     }).length;
//   }
//
//   List<Map<String, dynamic>> get filteredRentals {
//     return _rentals.where((rental) {
//       final status = statusOf(rental);
//
//       final matchesFilter = selectedFilter == 'All' ||
//           status == selectedFilter.toLowerCase();
//
//       final searchable = [
//         rental['booking_reference'],
//         rental['outfit_name'],
//         rental['selected_size'],
//         rental['outfit_id'],
//       ].join(' ').toLowerCase();
//
//       final matchesSearch =
//           searchQuery.isEmpty || searchable.contains(searchQuery);
//
//       return matchesFilter && matchesSearch;
//     }).toList();
//   }
//
//   List<Map<String, dynamic>> get groupedRentals {
//     final groups = <String, List<Map<String, dynamic>>>{};
//
//     for (final rental in filteredRentals) {
//       final reference =
//           rental['booking_reference']?.toString() ?? 'Unknown';
//
//       groups.putIfAbsent(reference, () => []).add(rental);
//     }
//
//     final result = groups.entries.map((entry) {
//       final rows = entry.value;
//
//       rows.sort((a, b) {
//         final aDate = DateTime.tryParse(
//           a['created_at']?.toString() ?? '',
//         );
//         final bDate = DateTime.tryParse(
//           b['created_at']?.toString() ?? '',
//         );
//
//         return (bDate ?? DateTime(2000))
//             .compareTo(aDate ?? DateTime(2000));
//       });
//
//       return <String, dynamic>{
//         'booking_reference': entry.key,
//         'booked_on': rows.first['created_at'],
//         'total_outfits': rows.length,
//         'outfits': rows,
//       };
//     }).toList();
//
//     result.sort((a, b) {
//       final aDate = DateTime.tryParse(
//         a['booked_on']?.toString() ?? '',
//       );
//       final bDate = DateTime.tryParse(
//         b['booked_on']?.toString() ?? '',
//       );
//
//       return (bDate ?? DateTime(2000))
//           .compareTo(aDate ?? DateTime(2000));
//     });
//
//     return result;
//   }
//
//   String imageOf(Map<String, dynamic> rental) {
//     return rental['outfit_image_url']?.toString() ?? '';
//   }
//
//   String outfitName(Map<String, dynamic> rental) {
//     return rental['outfit_name']?.toString() ?? 'Outfit';
//   }
//
//   String bookingLabel(dynamic value) {
//     final text = value?.toString() ?? '';
//
//     if (text.isEmpty) return 'RENT-UNKNOWN';
//
//     final compact = text.replaceAll('-', '').toUpperCase();
//
//     return 'RENT-${compact.length > 8 ? compact.substring(0, 8) : compact}';
//   }
//
//   String dateLabel(dynamic value) {
//     if (value == null) return 'Date unavailable';
//
//     final date = DateTime.tryParse(value.toString());
//     if (date == null) return value.toString();
//
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
//     ];
//
//     return '${date.day} ${months[date.month - 1]} ${date.year}';
//   }
//
//   String money(dynamic value) {
//     final amount = value is num
//         ? value
//         : num.tryParse(value?.toString() ?? '') ?? 0;
//
//     return '₹${amount.toStringAsFixed(0)}';
//   }
//
//   String titleCase(String value) {
//     if (value.isEmpty) return value;
//
//     return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
//   }
//
//   Map<String, dynamic> addressOf(Map<String, dynamic> rental) {
//     final address = rental['delivery_address'];
//
//     if (address is Map) {
//       return Map<String, dynamic>.from(address);
//     }
//
//     return {};
//   }
//
//   String addressLabel(Map<String, dynamic> rental) {
//     final address = addressOf(rental);
//
//     return [
//       address['house'],
//       address['street'],
//       address['landmark'],
//       address['city'],
//       address['state'],
//       address['pincode'],
//     ].where((part) {
//       return part != null && part.toString().trim().isNotEmpty;
//     }).join(', ');
//   }
// }
