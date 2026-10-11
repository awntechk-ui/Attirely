import 'package:flutter/material.dart';

import '../UI_Logic/register_logic.dart';
import '../../app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late RegisterLogic logic;

  bool showPassword = false;
  bool showConfirmPassword = false;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color burgundy = Color(0xFF8E2945);
  static const Color lightBurgundy = Color(0xFFA4536A);
  static const Color softBorder = Color(0xFFE5D6DA);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    logic = RegisterLogic();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // =========================================================
  // DATE OF BIRTH
  // =========================================================

  Future<void> selectDateOfBirth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        logic.dateOfBirth = selectedDate;
      });
    }
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: lightBurgundy,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: softBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: burgundy,
          width: 1.2,
        ),
      ),
    );
  }

  // =========================================================
  // INPUT TEXT STYLE
  // =========================================================

  TextStyle get inputTextStyle => const TextStyle(
    color: burgundy,
    fontSize: 15,
  );

  // =========================================================
  // MAIN TEXT STYLE
  // =========================================================

  TextStyle get shadowTextStyle => const TextStyle(
    color: burgundy,
    shadows: [
      Shadow(
        color: Color(0x22000000),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ],
  );

  // =========================================================
  // GO TO LOGIN
  // =========================================================

  void goToLogin() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            goToLogin();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // =====================================================
            // BACKGROUND
            // =====================================================

            Positioned.fill(
              child: Image.asset(
                'assets/background/login_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // =====================================================
            // REGISTER CONTENT
            // =====================================================

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        28,
                        35,
                        28,
                        10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // =================================================
                          // LOGO
                          // =================================================

                          Center(
                            child: Image.asset(
                              'assets/logos/burgandy_attirely_logo.png',
                              height: 70,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // =================================================
                          // TITLE
                          // =================================================

                          Center(
                            child: Text(
                              'Create your account',
                              textAlign: TextAlign.center,
                              style: shadowTextStyle.copyWith(
                                fontSize: 29,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // =================================================
                          // SUBTITLE
                          // =================================================

                          Center(
                            child: Text(
                              'Join Attirely and Rent your style.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: lightBurgundy,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // =================================================
                          // COMMON DETAILS
                          // =================================================

                          TextField(
                            controller: logic.fullNameController,
                            style: inputTextStyle,
                            textInputAction: TextInputAction.next,
                            decoration: fieldDecoration(
                              'Full name',
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: logic.phoneNumberController,
                            style: inputTextStyle,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration:
                            fieldDecoration('Phone number').copyWith(
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: burgundy,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: logic.emailController,
                            style: inputTextStyle,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: fieldDecoration(
                              'Email address',
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: logic.passwordController,
                            style: inputTextStyle,
                            obscureText: !showPassword,
                            textInputAction: TextInputAction.next,
                            decoration:
                            fieldDecoration('Password').copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: burgundy,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller:
                            logic.confirmPasswordController,
                            style: inputTextStyle,
                            obscureText: !showConfirmPassword,
                            textInputAction: TextInputAction.next,
                            decoration:
                            fieldDecoration('Confirm password')
                                .copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showConfirmPassword =
                                    !showConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: burgundy,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =================================================
                          // DATE OF BIRTH
                          // =================================================

                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: selectDateOfBirth,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(16),
                                border: Border.all(
                                  color: softBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      logic.dateOfBirth == null
                                          ? 'Date of birth'
                                          : '${logic.dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                          '${logic.dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                          '${logic.dateOfBirth!.year}',
                                      style: TextStyle(
                                        color:
                                        logic.dateOfBirth == null
                                            ? lightBurgundy
                                            : burgundy,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: burgundy,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =================================================
                          // GENDER
                          // =================================================

                          DropdownButtonFormField<String>(
                            value: logic.gender,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: burgundy,
                              fontSize: 15,
                            ),
                            decoration: fieldDecoration(
                              'Gender',
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: burgundy,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Female',
                                child: Text(
                                  'Female',
                                  style: TextStyle(
                                    color: burgundy,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Male',
                                child: Text(
                                  'Male',
                                  style: TextStyle(
                                    color: burgundy,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text(
                                  'Other',
                                  style: TextStyle(
                                    color: burgundy,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                logic.gender = value;
                              });
                            },
                          ),

                          const SizedBox(height: 22),

                          // =================================================
                          // STORE QUESTION
                          // =================================================

                          Text(
                            'Do you have a store?',
                            style: shadowTextStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _StoreOption(
                                  label: 'Yes',
                                  selected: logic.hasStore == true,
                                  onTap: () {
                                    setState(() {
                                      logic.hasStore = true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StoreOption(
                                  label: 'No',
                                  selected: logic.hasStore == false,
                                  onTap: () {
                                    setState(() {
                                      logic.hasStore = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          // =================================================
                          // VENDOR DETAILS
                          // =================================================

                          if (logic.hasStore == true) ...[
                            const SizedBox(height: 28),

                            Text(
                              'Store details',
                              style: shadowTextStyle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Tell us a little about your rental business.',
                              style: TextStyle(
                                color: lightBurgundy,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Store name
                            TextField(
                              controller:
                              logic.storeNameController,
                              style: inputTextStyle,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'Store / Brand name',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Business description
                            TextField(
                              controller: logic
                                  .businessDescriptionController,
                              style: inputTextStyle,
                              maxLines: 3,
                              textInputAction:
                              TextInputAction.newline,
                              decoration: fieldDecoration(
                                'Business description',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Owner type
                            DropdownButtonFormField<String>(
                              value: logic.ownerType,
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: burgundy,
                                fontSize: 15,
                              ),
                              decoration: fieldDecoration(
                                'Owner type',
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: burgundy,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'individual',
                                  child: Text(
                                    'Individual',
                                    style: TextStyle(
                                      color: burgundy,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'store_owner',
                                  child: Text(
                                    'Store owner',
                                    style: TextStyle(
                                      color: burgundy,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  logic.ownerType = value;
                                });
                              },
                            ),

                            const SizedBox(height: 14),

                            // Address
                            TextField(
                              controller: logic.addressController,
                              style: inputTextStyle,
                              maxLines: 2,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'Address',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // City
                            TextField(
                              controller: logic.cityController,
                              style: inputTextStyle,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'City',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // State
                            TextField(
                              controller: logic.stateController,
                              style: inputTextStyle,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'State',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Pincode
                            TextField(
                              controller: logic.pincodeController,
                              style: inputTextStyle,
                              keyboardType:
                              TextInputType.number,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'Pincode',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Instagram
                            TextField(
                              controller:
                              logic.instagramController,
                              style: inputTextStyle,
                              keyboardType:
                              TextInputType.url,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'Instagram username (optional)',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Aadhaar
                            TextField(
                              controller:
                              logic.aadhaarController,
                              style: inputTextStyle,
                              keyboardType:
                              TextInputType.number,
                              textInputAction:
                              TextInputAction.next,
                              decoration: fieldDecoration(
                                'Aadhaar number (optional)',
                              ),
                            ),

                            const SizedBox(height: 14),

                            // PAN
                            TextField(
                              controller: logic.panController,
                              style: inputTextStyle,
                              textInputAction:
                              TextInputAction.done,
                              decoration: fieldDecoration(
                                'PAN number (optional)',
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // =========================================================
                  // FIXED BOTTOM SECTION
                  // =========================================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      28,
                      4,
                      28,
                      12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: logic.isLoading
                                ? null
                                : () {
                              setState(() {
                                logic.isLoading = true;
                              });

                              logic
                                  .register(context)
                                  .whenComplete(() {
                                if (mounted) {
                                  setState(() {
                                    logic.isLoading = false;
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: burgundy,
                              elevation: 0,
                              side: const BorderSide(
                                color: gold,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(18),
                              ),
                            ),
                            child: logic.isLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: burgundy,
                              ),
                            )
                                : const Text(
                              'Create Account',
                              style: TextStyle(
                                color: burgundy,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: goToLogin,
                            child: const Text(
                              'Already have an account? Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: burgundy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// STORE OPTION
// =============================================================

class _StoreOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoreOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color burgundy = Color(0xFF6B1E2E);
  static const Color softBorder = Color(0xFFE5D6DA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? burgundy : softBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: burgundy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: burgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}