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

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.white70,
          width: 1,
        ),
      ),
    );
  }

  TextStyle get inputTextStyle => const TextStyle(
    color: Colors.white,
    fontSize: 15,
  );

  TextStyle get shadowTextStyle => const TextStyle(
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black87,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  void goToLogin() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        // Swipe right on Register → Login
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            goToLogin();
          }
        },

        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen Register background
            Positioned.fill(
              child: Image.asset(
                'assets/background/register_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // Register content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 35, 28, 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logos/burgandy_attirely_logo.png',
                        height: 70,
                      ),
                    ),

                    const SizedBox(height: 24),

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

                    Center(
                      child: Text(
                        'Join Attirely and Rent your style.',
                        textAlign: TextAlign.center,
                        style: shadowTextStyle.copyWith(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Full name
                    // Full name
                    TextField(
                      controller: logic.fullNameController,
                      style: inputTextStyle,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDecoration('Full name'),
                    ),

                    const SizedBox(height: 14),

// Phone number
                    TextField(
                      controller: logic.phoneNumberController,
                      style: inputTextStyle,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDecoration('Phone number').copyWith(
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

// Email
                    TextField(
                      controller: logic.emailController,
                      style: inputTextStyle,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDecoration('Email address'),
                    ),


                    const SizedBox(height: 14),

                    // Password
                    TextField(
                      controller: logic.passwordController,
                      style: inputTextStyle,
                      obscureText: !showPassword,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDecoration('Password').copyWith(
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
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Confirm password
                    TextField(
                      controller: logic.confirmPasswordController,
                      style: inputTextStyle,
                      obscureText: !showConfirmPassword,
                      textInputAction: TextInputAction.next,
                      decoration:
                      fieldDecoration('Confirm password').copyWith(
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
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date of birth
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
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(16),
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
                                  color: logic.dateOfBirth == null
                                      ? Colors.white70
                                      : Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Gender
                    DropdownButtonFormField<String>(
                      value: logic.gender,
                      dropdownColor: Colors.black87,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: fieldDecoration('Gender'),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          logic.gender = value;
                        });
                      },
                    ),

                    const SizedBox(height: 22),

                    // Store question
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

                    const SizedBox(height: 28),

                    // Register button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: logic.isLoading
                              ? null
                              : () {
                            setState(() {
                              logic.isLoading = true;
                            });

                            logic.register(context).whenComplete(() {
                              if (mounted) {
                                setState(() {
                                  logic.isLoading = false;
                                });
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            side: const BorderSide(
                              color: gold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: logic.isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                              : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login
                    Center(
                      child: TextButton(
                        onPressed: goToLogin,
                        child: const Text(
                          'Already have an account? Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                              ),
                            ],
                          ),
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

class _StoreOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoreOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.92)
              : Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white30,
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
              color: selected ? Colors.black : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}