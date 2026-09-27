import 'package:flutter/material.dart';

import '../U_Ui_Logic/profile_logic.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileLogic logic = ProfileLogic();

  static const Color burgundy = Color(0xFF6B1E2E);
  static const Color gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: burgundy,
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: burgundy,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // =====================================================
          // BACKGROUND
          // =====================================================

          Image.asset(
            'assets/background/app_bg.png',
            fit: BoxFit.cover,
          ),

          // =====================================================
          // CONTENT
          // =====================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // =================================================
                  // PROFILE ICON
                  // =================================================

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.85),
                      border: Border.all(
                        color: gold,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 55,
                      color: burgundy,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your account details',
                    style: TextStyle(
                      fontSize: 14,
                      color: burgundy.withOpacity(0.75),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // =================================================
                  // LOGOUT BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        logic.logout(context);
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: burgundy,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: burgundy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: gold,
                          width: 1.5,
                        ),
                        backgroundColor:
                        Colors.white.withOpacity(0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
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
    );
  }
}