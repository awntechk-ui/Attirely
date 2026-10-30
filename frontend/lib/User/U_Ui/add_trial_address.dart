
import 'package:flutter/material.dart';

import '../U_Ui_Logic/trial_address_logic.dart';

class AddTrialAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddTrialAddressPage({
    super.key,
    this.address,
  });

  @override
  State<AddTrialAddressPage> createState() =>
      _AddTrialAddressPageState();
}

class _AddTrialAddressPageState
    extends State<AddTrialAddressPage> {
  static const Color burgundy = Color(0xFF8E2945);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String addressType = 'Home';
  bool isSaving = false;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    if (address != null) {
      _nameController.text =
          address['full_name']?.toString() ?? '';
      _mobileController.text =
          address['mobile']?.toString() ?? '';
      _houseController.text =
          address['house']?.toString() ?? '';
      _streetController.text =
          address['street']?.toString() ?? '';
      _landmarkController.text =
          address['landmark']?.toString() ?? '';
      _cityController.text =
          address['city']?.toString() ?? '';
      _stateController.text =
          address['state']?.toString() ?? '';
      _pincodeController.text =
          address['pincode']?.toString() ?? '';

      addressType =
          address['address_type']?.toString() ?? 'Home';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // =========================================================
  // SAVE ADDRESS THROUGH BACKEND
  // =========================================================

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final address = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'landmark': _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'address_type': addressType,
      'latitude': widget.address?['latitude'],
      'longitude': widget.address?['longitude'],
    };

    setState(() => isSaving = true);

    try {
      final logic = TrialAddressLogic.instance;

      final Map<String, dynamic> savedAddress;

      if (isEditing) {
        final id = widget.address!['id']?.toString();

        if (id == null || id.isEmpty) {
          throw Exception('Address ID is missing.');
        }

        savedAddress = await logic.updateAddress(id, address);
      } else {
        savedAddress = await logic.addAddress(address);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Address updated successfully.'
                : 'Address saved successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, savedAddress);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: burgundy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Current location feature is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        int maxLength = 100,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator ?? _required,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: burgundy,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: burgundy,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EDF1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: burgundy,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Where should we arrange your outfit trial?',
                      style: TextStyle(
                        color: burgundy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _comingSoon,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: burgundy),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Contact Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            _field('Full Name', _nameController),

            _field(
              'Mobile Number',
              _mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[0-9]{10}$')
                        .hasMatch(value.trim())) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Address Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            _field('House / Flat / Building', _houseController),
            _field('Street / Area', _streetController),
            _field(
              'Landmark (Optional)',
              _landmarkController,
              validator: (_) => null,
            ),
            _field('City', _cityController),
            _field('State', _stateController),

            _field(
              'Pincode',
              _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[0-9]{6}$')
                        .hasMatch(value.trim())) {
                  return 'Enter a valid 6-digit pincode';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Save address as',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 9,
              children: ['Home', 'Work', 'Other'].map((type) {
                final selected = addressType == type;

                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: const Color(0xFFF8EDF1),
                  labelStyle: TextStyle(
                    color: selected ? burgundy : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? burgundy
                        : Colors.grey.shade300,
                  ),
                  onSelected: (_) {
                    setState(() => addressType = type);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: burgundy.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  isEditing
                      ? 'Update Address'
                      : 'Save and Continue',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
