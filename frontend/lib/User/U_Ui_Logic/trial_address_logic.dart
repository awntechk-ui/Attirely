
import 'package:flutter/foundation.dart';

import '../U_API_Routes/u_address_api_routes.dart';

class TrialAddressLogic extends ChangeNotifier {
  TrialAddressLogic._();

  static final TrialAddressLogic instance = TrialAddressLogic._();

  final List<Map<String, dynamic>> _addresses = [];

  List<Map<String, dynamic>> get addresses =>
      List.unmodifiable(_addresses);

  Map<String, dynamic>? selectedAddress;

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // =========================================================
  // LOAD ADDRESSES FROM BACKEND
  // =========================================================

  Future<void> loadAddresses({bool refresh = false}) async {
    if (isLoading) return;

    if (_addresses.isNotEmpty && !refresh) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await UserAddressApiRoutes.getAddresses();

      final data = response['addresses'];

      _addresses.clear();

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            _addresses.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      // Restore selected address if it still exists.
      if (selectedAddress != null) {
        final selectedId = selectedAddress!['id']?.toString();

        final matching = _addresses.where(
              (address) => address['id']?.toString() == selectedId,
        );

        selectedAddress =
        matching.isNotEmpty ? matching.first : null;
      }

      // Otherwise select the default address.
      selectedAddress ??= _getDefaultAddress();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _getDefaultAddress() {
    for (final address in _addresses) {
      if (address['is_default'] == true) {
        return address;
      }
    }

    return _addresses.isNotEmpty ? _addresses.first : null;
  }

  // =========================================================
  // ADD ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> addAddress(
      Map<String, dynamic> address,
      ) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await UserAddressApiRoutes.addAddress(
        address: address,
      );

      final saved = response['address'];

      if (saved is! Map) {
        throw Exception('Invalid address response from server.');
      }

      final newAddress = Map<String, dynamic>.from(saved);

      _addresses.removeWhere(
            (item) => item['id']?.toString() ==
            newAddress['id']?.toString(),
      );

      _addresses.insert(0, newAddress);
      selectedAddress = newAddress;

      return newAddress;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // =========================================================
  // UPDATE ADDRESS
  // =========================================================

  Future<Map<String, dynamic>> updateAddress(
      String addressId,
      Map<String, dynamic> address,
      ) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await UserAddressApiRoutes.updateAddress(
        addressId: addressId,
        address: address,
      );

      final updated = response['address'];

      if (updated is! Map) {
        throw Exception('Invalid address response from server.');
      }

      final updatedAddress = Map<String, dynamic>.from(updated);

      final index = _addresses.indexWhere(
            (item) => item['id']?.toString() == addressId,
      );

      if (index != -1) {
        _addresses[index] = updatedAddress;
      } else {
        _addresses.insert(0, updatedAddress);
      }

      if (selectedAddress?['id']?.toString() == addressId) {
        selectedAddress = updatedAddress;
      }

      return updatedAddress;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // =========================================================
  // SELECT ADDRESS
  // =========================================================

  void selectAddress(Map<String, dynamic> address) {
    selectedAddress = address;
    notifyListeners();
  }

  // =========================================================
  // SET DEFAULT ADDRESS
  // =========================================================

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await UserAddressApiRoutes.setDefaultAddress(
        addressId: addressId,
      );

      for (final address in _addresses) {
        address['is_default'] =
            address['id']?.toString() == addressId;
      }

      final selected = _addresses.where(
            (address) => address['id']?.toString() == addressId,
      );

      if (selected.isNotEmpty) {
        selectedAddress = selected.first;
      }

      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    }
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  Future<void> deleteAddress(String addressId) async {
    try {
      await UserAddressApiRoutes.deleteAddress(
        addressId: addressId,
      );

      _addresses.removeWhere(
            (address) => address['id']?.toString() == addressId,
      );

      if (selectedAddress?['id']?.toString() == addressId) {
        selectedAddress = _getDefaultAddress();
      }

      // Refresh server-side default status after deletion.
      await loadAddresses(refresh: true);

      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    }
  }
}
