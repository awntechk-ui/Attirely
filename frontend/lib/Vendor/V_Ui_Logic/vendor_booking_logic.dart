import 'package:flutter/material.dart';

import '../../User/U_API_Routes/u_rental_api_routes.dart';

class VendorBookingLogic extends ChangeNotifier {
  bool isLoading = false;
  bool isActionLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> bookings = [];

  Future<void> loadBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
      await RentalsApiRoutes.getOwnerRentalRequests();

      bookings = response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // FILTER BOOKINGS BY CATEGORY
  // --------------------------------------------------

  List<Map<String, dynamic>> bookingsFor(String category) {
    switch (category) {
      case 'pending':
      case 'accepted':
      case 'handed_over':
      case 'rejected':
        return bookings
            .where((b) => b['status'] == category)
            .toList();

      case 'customer_cancelled':
        return bookings.where((b) {
          return b['status'] == 'cancelled' &&
              b['cancelled_by_role'] == 'customer';
        }).toList();

      case 'cancelled_by_you':
        return bookings.where((b) {
          return b['status'] == 'cancelled' &&
              ['owner', 'vendor'].contains(b['cancelled_by_role']);
        }).toList();

      default:
        return [];
    }
  }

  // --------------------------------------------------
  // ACCEPT BOOKING
  // --------------------------------------------------

  Future<bool> acceptBooking(
      String rentalId,
      String rentMethod,
      ) async {
    return _performAction(
          () => RentalsApiRoutes.acceptRental(
        rentalId,
        rentMethod,
      ),
    );
  }

  // --------------------------------------------------
  // REJECT BOOKING
  // --------------------------------------------------

  Future<bool> rejectBooking(
      String id,
      String reason,
      ) async {
    return _performAction(
          () => RentalsApiRoutes.rejectRental(id, reason),
    );
  }

  // --------------------------------------------------
  // CANCEL BOOKING
  // --------------------------------------------------

  Future<bool> cancelBooking(
      String id,
      String reason,
      ) async {
    return _performAction(
          () => RentalsApiRoutes.cancelOwnerRental(id, reason),
    );
  }

  // --------------------------------------------------
  // CONFIRM HANDOVER
  // --------------------------------------------------

  Future<bool> handoverBooking(String id) async {
    return _performAction(
          () => RentalsApiRoutes.handoverRental(id),
    );
  }

  // --------------------------------------------------
  // COMPLETE BOOKING
  // --------------------------------------------------

  Future<bool> completeBooking(String id) async {
    return _performAction(
          () => RentalsApiRoutes.completeRental(id),
    );
  }

  // --------------------------------------------------
  // COMMON ACTION HANDLER
  // --------------------------------------------------

  Future<bool> _performAction(
      Future<Map<String, dynamic>> Function() action,
      ) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadBookings();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }
}
