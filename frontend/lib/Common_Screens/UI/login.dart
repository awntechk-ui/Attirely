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

  // Attirely colors
  static const Color burgundy = Color(0xFF800020);
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

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: burgundy,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.72),
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
          color: burgundy,
          width: 1,
        ),
      ),
    );
  }

  void goToRegister() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.register,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        // Swipe left on Login → Register
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -300) {
            goToRegister();
          }
        },

        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen Login background
            Positioned.fill(
              child: Image.asset(
                'assets/background/login_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // Login content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 35),
                child: Column(
                  children: [
                    // Top Login / Sign Up navigation
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                  color: burgundy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 1.5,
                                color: burgundy,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: goToRegister,
                            child: Column(
                              children: [
                                const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: burgundy,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 1,
                                  color: Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logos/burgandy_attirely_logo.png',
                        height: 75,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Welcome Back
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: burgundy,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Sign in to continue to Attirely',
                      style: TextStyle(
                        color: burgundy,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email
                    TextField(
                      controller: logic.emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: burgundy,
                      ),
                      decoration: fieldDecoration(
                        'Email address',
                      ).copyWith(
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: burgundy,
                          size: 19,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password
                    TextField(
                      controller: logic.passwordController,
                      obscureText: !showPassword,
                      style: const TextStyle(
                        color: burgundy,
                      ),
                      decoration: fieldDecoration(
                        'Password',
                      ).copyWith(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: burgundy,
                          size: 19,
                        ),
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
                            size: 19,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Will be implemented later.
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: logic.isLoading
                            ? null
                            : () async {
                          setState(() {
                            logic.isLoading = true;
                          });

                          await logic.login(context);

                          if (mounted) {
                            setState(() {
                              logic.isLoading = false;
                            });
                          }
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
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: logic.isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: burgundy,
                          ),
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: burgundy.withOpacity(0.35),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              color: burgundy,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: burgundy.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Social buttons - UI only
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          icon: Icons.g_mobiledata,
                          onTap: () {},
                        ),
                        const SizedBox(width: 14),
                        _SocialButton(
                          icon: Icons.apple,
                          onTap: () {},
                        ),
                        const SizedBox(width: 14),
                        _SocialButton(
                          icon: Icons.facebook,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: goToRegister,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: burgundy,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Terms text
                    const Text(
                      'By continuing, you agree to our',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: burgundy,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 2),

                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          color: burgundy,
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFF800020);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: burgundy.withOpacity(0.25),
          ),
        ),
        child: Icon(
          icon,
          color: burgundy,
          size: 25,
        ),
      ),
    );
  }
}