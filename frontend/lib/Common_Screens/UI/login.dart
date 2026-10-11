import 'package:flutter/material.dart';

import '../UI_Logic/login_logic.dart';
import '../../app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late LoginLogic logic;

  bool showPassword = false;

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
    logic = LoginLogic();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
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
  // LOGIN
  // =========================================================

  void performLogin() {
    setState(() {
      logic.isLoading = true;
    });

    logic.login(context).whenComplete(() {
      if (mounted) {
        setState(() {
          logic.isLoading = false;
        });
      }
    });
  }

  // =========================================================
  // REGISTER
  // =========================================================

  void goToRegister() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.register,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -300) {
            goToRegister();
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
            // CONTENT
            // =====================================================

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  28,
                  45,
                  28,
                  25,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

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

                    const SizedBox(height: 28),

                    // =================================================
                    // TITLE
                    // =================================================

                    Center(
                      child: Text(
                        'Welcome to Attirely',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Color(0x22000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // =================================================
                    // SUBTITLE
                    // =================================================

                    Center(
                      child: Text(
                        'Rent your style. Share your wardrobe.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: lightBurgundy,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // =================================================
                    // WHO ARE YOU?
                    // =================================================

                    Center(
                      child: Text(
                        'Who are you?',
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // USER / VENDOR
                    // =================================================

                    Row(
                      children: [
                        Expanded(
                          child: _RoleOption(
                            icon: Icons.person_outline,
                            label: 'User',
                            selected:
                            logic.selectedRole == 'user',
                            onTap: () {
                              setState(() {
                                logic.selectedRole = 'user';
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: _RoleOption(
                            icon: Icons.storefront_outlined,
                            label: 'Vendor',
                            selected:
                            logic.selectedRole == 'vendor',
                            onTap: () {
                              setState(() {
                                logic.selectedRole = 'vendor';
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // EMAIL
                    // =================================================

                    TextField(
                      controller: logic.emailController,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 15,
                      ),
                      keyboardType:
                      TextInputType.emailAddress,
                      textInputAction:
                      TextInputAction.next,
                      decoration:
                      fieldDecoration('Email address'),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // PASSWORD
                    // =================================================

                    TextField(
                      controller: logic.passwordController,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 15,
                      ),
                      obscureText: !showPassword,
                      textInputAction:
                      TextInputAction.done,
                      onSubmitted: (_) {
                        if (!logic.isLoading) {
                          performLogin();
                        }
                      },
                      decoration:
                      fieldDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              showPassword =
                              !showPassword;
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

                    const SizedBox(height: 25),

                    // =================================================
                    // LOGIN BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: logic.isLoading
                            ? null
                            : performLogin,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: burgundy,
                          elevation: 0,

                          side: const BorderSide(
                            color: gold,
                            width: 1.5,
                          ),

                          shape:
                          RoundedRectangleBorder(
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
                          'Login',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // REGISTER
                    // =================================================

                    Center(
                      child: TextButton(
                        onPressed: goToRegister,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                        ),
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 14,
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


// =============================================================
// ROLE OPTION
// =============================================================

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color burgundy =
  Color(0xFF6B1E2E);

  static const Color softBorder =
  Color(0xFFE5D6DA);

  static const Color gold =
  Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(16),

      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),

        height: 70,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? burgundy
                : softBorder,

            width: selected ? 1.5 : 1,
          ),

          boxShadow: selected
              ? [
            BoxShadow(
              color:
              gold.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              color: burgundy,
              size: 23,
            ),

            const SizedBox(width: 9),

            Text(
              label,
              style: const TextStyle(
                color: burgundy,
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            if (selected) ...[
              const SizedBox(width: 7),

              const Icon(
                Icons.check_circle,
                color: burgundy,
                size: 17,
              ),
            ],
          ],
        ),
      ),
    );
  }
}