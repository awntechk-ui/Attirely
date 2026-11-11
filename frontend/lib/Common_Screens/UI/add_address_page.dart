
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../User/U_API_Routes/u_address_api_routes.dart';
import 'location_picker_page.dart';

class AddAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddAddressPage({
    super.key,
    this.address,
  });

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _addressType = 'Home';

  double? _latitude;
  double? _longitude;

  bool _isSaving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    if (address != null) {
      _fullNameController.text =
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

      _addressType =
          address['address_type']?.toString() ?? 'Home';

      _latitude = (address['latitude'] as num?)?.toDouble();
      _longitude = (address['longitude'] as num?)?.toDouble();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  Future<void> _chooseLocation() async {
    // The map picker must return a LatLng object.
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(
          returnLocationOnly: true,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map location selected successfully.'),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (requiredField &&
              (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }

          return null;
        },
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose your location on the map.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final addressData = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'house': _houseController.text.trim(),
        'street': _streetController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'address_type': _addressType,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (_isEditing) {
        final addressId = widget.address!['id'].toString();

        await UserAddressApiRoutes.updateAddress(
          addressId: addressId,
          address: addressData,
        );
      } else {
        await UserAddressApiRoutes.addAddress(
          address: addressData,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Address updated successfully.'
                : 'Address added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7B263A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F7),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Address' : 'Add Address',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: 'Full Name',
                controller: _fullNameController,
              ),

              _buildTextField(
                label: 'Mobile Number',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 8),

              const Text(
                'Address Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: 'House / Flat / Building',
                controller: _houseController,
              ),

              _buildTextField(
                label: 'Street / Area',
                controller: _streetController,
              ),

              _buildTextField(
                label: 'Landmark (Optional)',
                controller: _landmarkController,
                requiredField: false,
              ),

              _buildTextField(
                label: 'City',
                controller: _cityController,
              ),

              _buildTextField(
                label: 'State',
                controller: _stateController,
              ),

              _buildTextField(
                label: 'Pincode',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),

              const Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                children: ['Home', 'Work', 'Other'].map((type) {
                  final selected = _addressType == type;

                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    selectedColor: primaryColor.withValues(alpha: 0.15),
                    onSelected: (_) {
                      setState(() => _addressType = type);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Pin Your Address',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose the exact location of this address on the map.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: _chooseLocation,
                icon: const Icon(Icons.location_on),
                label: Text(
                  _latitude == null
                      ? 'Choose Location on Map'
                      : 'Change Selected Location',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location selected\n'
                              'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                              'Lng: ${_longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text(
                  _isEditing
                      ? 'Update Address'
                      : 'Save Address',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
