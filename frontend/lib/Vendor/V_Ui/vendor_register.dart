import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../V_Ui_Logic/vendor_register_logic.dart';


class VendorRegisterPage extends StatefulWidget {
  const VendorRegisterPage({super.key});

  @override
  State<VendorRegisterPage> createState() =>
      _VendorRegisterPageState();
}

class _VendorRegisterPageState
    extends State<VendorRegisterPage> {
  late VendorRegisterLogic logic;

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    logic = VendorRegisterLogic();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================================================
          // BACKGROUND
          // =========================================================

          Positioned.fill(
            child: Image.asset(
              'assets/background/app_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // =========================================================
          // CONTENT
          // =========================================================

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                35,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // BACK BUTTON
                  // =================================================

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gold,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: burgundy,
                        size: 21,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // HEADER
                  // =================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: gold,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Become an Owner',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Create your owner profile and start '
                              'sharing your style on Attirely.',
                          style: TextStyle(
                            color: burgundy.withOpacity(0.72),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // PERSONAL DETAILS
                  // =================================================

                  _buildSectionCard(
                    title: 'Personal Details',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller:
                          logic.fullNameController,
                          label: 'Full Name *',
                          hint: 'Enter your full name',
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller:
                          logic.aadhaarController,
                          label: 'Aadhaar Number',
                          hint: 'Optional',
                          keyboardType:
                          TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller:
                          logic.panController,
                          label: 'PAN',
                          hint: 'Optional',
                          textCapitalization:
                          TextCapitalization.characters,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // OWNER TYPE
                  // =================================================

                  _buildSectionCard(
                    title: 'Owner Type *',
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose how you want to list on Attirely.',
                          style: TextStyle(
                            color: burgundy.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleOption(
                                title: 'Individual',
                                value: 'individual',
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildRoleOption(
                                title: 'Store Owner',
                                value: 'store_owner',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // BUSINESS DETAILS
                  // =================================================

                  _buildSectionCard(
                    title: 'Business Details',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller:
                          logic.storeNameController,
                          label: 'Store / Brand Name *',
                          hint:
                          'Enter your store or brand name',
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller:
                          logic
                              .businessDescriptionController,
                          label:
                          'Business Description *',
                          hint:
                          'Tell us about what you offer',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // ADDRESS
                  // =================================================

                  _buildSectionCard(
                    title: 'Your Address',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller:
                          logic.addressController,
                          label: 'Address *',
                          hint:
                          'Enter your complete address',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller:
                                logic.cityController,
                                label: 'City *',
                                hint: 'City',
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildTextField(
                                controller:
                                logic.stateController,
                                label: 'State *',
                                hint: 'State',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller:
                          logic.pincodeController,
                          label: 'Pincode *',
                          hint: 'Enter pincode',
                          keyboardType:
                          TextInputType.number,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // SOCIAL MEDIA
                  // =================================================

                  _buildSectionCard(
                    title: 'Social Media',
                    child: _buildTextField(
                      controller:
                      logic.instagramController,
                      label: 'Instagram',
                      hint: 'Optional',
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // SUBMIT BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: logic.isLoading
                          ? null
                          : () async {
                        final success =
                        await logic.createVendorProfile(context);

                        if (!success) return;

                        if (!context.mounted) return;

                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.vendorDashboard,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                          side: const BorderSide(
                            color: gold,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Create Owner Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: Text(
                      'You can update your profile later.',
                      style: TextStyle(
                        color: burgundy.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SECTION CARD
  // ===============================================================

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: burgundy.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: burgundy.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: burgundy,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  // ===============================================================
  // TEXT FIELD
  // ===============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: burgundy,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: burgundy.withOpacity(0.72),
        ),
        hintStyle: TextStyle(
          color: burgundy.withOpacity(0.38),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.82),
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: burgundy.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: burgundy.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: gold,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ROLE OPTION
  // ===============================================================

  Widget _buildRoleOption({
    required String title,
    required String value,
  }) {
    final isSelected = logic.role == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          logic.role = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? burgundy.withOpacity(0.08)
              : Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? gold
                : burgundy.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? burgundy
                      : burgundy.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                  const BoxDecoration(
                    color: burgundy,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: burgundy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}