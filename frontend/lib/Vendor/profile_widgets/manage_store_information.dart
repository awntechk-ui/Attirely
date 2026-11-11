
import 'package:flutter/material.dart';

import 'package:attirely/Common_Screens/session_manager.dart';

import '../Vendor_API_Routes/vendor_auth_api_routes.dart';

// Import VendorAuthApiRoutes from your existing API file.

class ManageStoreInformation extends StatefulWidget {
  const ManageStoreInformation({super.key});

  @override
  State<ManageStoreInformation> createState() =>
      _ManageStoreInformationState();
}

class _ManageStoreInformationState
    extends State<ManageStoreInformation> {

  static const Color burgundy = Color(0xFF8E2945);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);

  static const LinearGradient topGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C1026),
      Color(0xFF64172F),
      Color(0xFF4C1026),
    ],
  );

  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> controllers = {};

  final List<String> requiredFields = [
    'full_name',
    'store_name',
    'phone_number',
    'address',
    'city',
    'state',
    'pincode',
  ];

  String ownerType = 'individual';

  bool isLoading = true;
  bool isSaving = false;
  bool showAadhaar = false;
  bool showPan = false;

  Map<String, dynamic> originalVendor = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadVendor();
  }

  void _initializeControllers() {
    const fields = [
      'full_name',
      'store_name',
      'business_description',
      'phone_number',
      'address',
      'city',
      'state',
      'pincode',
      'instagram',
      'aadhaar',
      'pan',
    ];

    for (final field in fields) {
      controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVendor() async {
    try {
      final token = SessionManager.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final result = await VendorAuthApiRoutes.getMyVendor(
        accessToken: token,
      );

      final vendorResponse = result['vendor'];

      if (vendorResponse is! Map) {
        throw Exception('Invalid vendor profile response.');
      }

      // Existing GET endpoint returns:
      // {success: true, vendor: vendor_object}

      final vendor = vendorResponse['vendor'] is Map
          ? Map<String, dynamic>.from(vendorResponse['vendor'])
          : Map<String, dynamic>.from(vendorResponse);

      originalVendor = vendor;

      for (final entry in controllers.entries) {
        entry.value.text =
            vendor[entry.key]?.toString() ?? '';
      }

      ownerType = vendor['owner_type']?.toString() ??
          'individual';

      if (ownerType != 'individual' &&
          ownerType != 'store_owner') {
        ownerType = 'individual';
      }

    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final token = SessionManager.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final updatedData = <String, dynamic>{};

      for (final entry in controllers.entries) {
        final key = entry.key;
        final value = entry.value.text.trim();

        // Only send fields which have actually changed.
        if (value !=
            (originalVendor[key]?.toString() ?? '')) {
          updatedData[key] = value.isEmpty ? null : value;
        }
      }

      if (ownerType != originalVendor['owner_type']) {
        updatedData['owner_type'] = ownerType;
      }

      if (updatedData.isEmpty) {
        _showMessage('No changes to save.');
        return;
      }

      final result = await VendorAuthApiRoutes.updateMyVendor(
        accessToken: token,
        vendorData: updatedData,
      );

      if (result['success'] == true) {
        final vendor = result['vendor'];

        if (vendor is Map) {
          originalVendor =
          Map<String, dynamic>.from(vendor);
        }

        _showMessage('Store information updated successfully.');

      } else {
        throw Exception('Unable to update store information.');
      }

    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade700 : burgundy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: burgundy, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: darkBurgundy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _inputField(
      String key,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool required = false,
        bool obscure = false,
        VoidCallback? toggleObscure,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controllers[key],
        maxLines: obscure ? 1 : maxLines,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
          color: darkBurgundy,
          fontSize: 14,
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }

          if (key == 'pincode' &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^\d{6}$').hasMatch(value)) {
            return 'Enter a valid 6-digit pincode';
          }

          if (key == 'phone_number' &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^\+?[0-9]{10,15}$')
                  .hasMatch(value.replaceAll(' ', ''))) {
            return 'Enter a valid phone number';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: burgundy, size: 20),
          suffixIcon: toggleObscure == null
              ? null
              : IconButton(
            onPressed: toggleObscure,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: burgundy,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: burgundy,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE9D8B0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE9E0D8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: burgundy,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEFE5DE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _ownerTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner Type',
            style: TextStyle(
              color: burgundy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            value: ownerType,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.business_outlined,
                color: burgundy,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFE9E0D8),
                ),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'individual',
                child: Text('Individual'),
              ),
              DropdownMenuItem(
                value: 'store_owner',
                child: Text('Store Owner'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => ownerType = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 25),
      decoration: const BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                ),
              ),
              const Expanded(
                child: Text(
                  'Manage Store Information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: gold,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Store, Your Identity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Keep your business details up to date',
            style: TextStyle(
              color: Color(0xFFE9D8B0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: burgundy,
          ),
        )
            : Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16, 22, 16, 25,
                  ),
                  children: [
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                            'Business Details',
                            Icons.store_outlined,
                          ),
                          const SizedBox(height: 20),
                          _inputField(
                            'full_name',
                            'Full Name',
                            Icons.person_outline,
                            required: true,
                          ),
                          _inputField(
                            'store_name',
                            'Store Name',
                            Icons.storefront_outlined,
                            required: true,
                          ),
                          _inputField(
                            'business_description',
                            'Business Description',
                            Icons.description_outlined,
                            maxLines: 3,
                          ),
                          _ownerTypeSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                            'Contact & Location',
                            Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 20),
                          _inputField(
                            'phone_number',
                            'Phone Number',
                            Icons.phone_outlined,
                            required: true,
                            keyboardType: TextInputType.phone,
                          ),
                          _inputField(
                            'address',
                            'Business Address',
                            Icons.home_outlined,
                            required: true,
                            maxLines: 2,
                          ),
                          _inputField(
                            'city',
                            'City',
                            Icons.location_city_outlined,
                            required: true,
                          ),
                          _inputField(
                            'state',
                            'State',
                            Icons.map_outlined,
                            required: true,
                          ),
                          _inputField(
                            'pincode',
                            'Pincode',
                            Icons.pin_outlined,
                            required: true,
                            keyboardType: TextInputType.number,
                          ),
                          _inputField(
                            'instagram',
                            'Instagram Profile',
                            Icons.camera_alt_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                            'Verification Details',
                            Icons.verified_user_outlined,
                          ),
                          const SizedBox(height: 20),
                          _inputField(
                            'aadhaar',
                            'Aadhaar Number',
                            Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            obscure: !showAadhaar,
                            toggleObscure: () {
                              setState(() {
                                showAadhaar = !showAadhaar;
                              });
                            },
                          ),
                          _inputField(
                            'pan',
                            'PAN Number',
                            Icons.credit_card_outlined,
                            obscure: !showPan,
                            toggleObscure: () {
                              setState(() {
                                showPan = !showPan;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                        isSaving ? null : _saveChanges,
                        icon: isSaving
                            ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.save_outlined,
                        ),
                        label: Text(
                          isSaving
                              ? 'Saving Changes...'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundy,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          burgundy.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'ATTIRELY • VENDOR PORTAL',
                        style: TextStyle(
                          color: burgundy,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
