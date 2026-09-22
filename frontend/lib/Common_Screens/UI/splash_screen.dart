import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ================================================================
  // CURRENT SPLASH PAGE
  // ================================================================

  int _currentPage = 0;

  Timer? _pageTimer;

  // ================================================================
  // SPLASH IMAGES
  // ================================================================

  final List<String> _splashImages = [
    'assets/background/splash_background.png',
    'assets/background/casual_outfit_bg.png',
  ];

  @override
  void initState() {
    super.initState();

    // ================================================================
    // REAL DEVICE STATUS BAR
    // ================================================================

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        // Android
        statusBarIconBrightness: Brightness.light,

        // iOS
        statusBarBrightness: Brightness.dark,

        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // ================================================================
    // SPLASH PAGE TIMER
    //
    // Page 1 -> 2 seconds
    // Page 2 -> 2 seconds
    // Then -> LoginPage
    // ================================================================

    _pageTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) {
        if (!mounted) return;

        // ------------------------------------------------------------
        // PAGE 1 -> PAGE 2
        // ------------------------------------------------------------

        if (_currentPage == 0) {
          setState(() {
            _currentPage = 1;
          });
        }

        // ------------------------------------------------------------
        // PAGE 2 -> LOGIN
        // ------------------------------------------------------------

        else {
          timer.cancel();

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  ) =>
              const LoginPage(),

              transitionDuration:
              const Duration(milliseconds: 600),

              transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                  ) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _pageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      extendBodyBehindAppBar: true,

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [

              // ==========================================================
              // BACKGROUND IMAGE
              // ==========================================================

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),

                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,

                child: Image.asset(
                  _splashImages[_currentPage],

                  key: ValueKey(
                    _splashImages[_currentPage],
                  ),

                  width: width,
                  height: height,

                  fit: BoxFit.cover,

                  alignment: Alignment.center,
                ),
              ),

              // ==========================================================
              // MAIN DARK GRADIENT
              //
              // Bottom Left -> Center
              // ==========================================================

              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.center,

                        colors: [
                          Colors.black.withOpacity(0.82),
                          Colors.black.withOpacity(0.48),
                          Colors.transparent,
                        ],

                        stops: const [
                          0.0,
                          0.42,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================================
              // CONTENT
              // ==========================================================

              SafeArea(
                bottom: true,

                child: Stack(
                  children: [

                    // ====================================================
                    // LOGO + BRAND NAME + TAGLINE
                    // ====================================================

                    Positioned(
                      top: height * 0.07,
                      left: 0,
                      right: 0,

                      child: Center(
                        child: Column(
                          children: [

                            // ------------------------------------------------
                            // LOGO
                            // ------------------------------------------------

                            Image.asset(
                              'assets/logos/white_attirely_logo.png',

                              width: width * 0.19,

                              fit: BoxFit.contain,
                            ),

                            SizedBox(
                              height: height * 0.006,
                            ),

                            // ------------------------------------------------
                            // DARK GRADIENT BEHIND BRAND NAME + TAGLINE
                            // ------------------------------------------------

                            Column(
                              children: [
                                Text(
                                  'Attirely',
                                  style: GoogleFonts.cormorantGaramond(
                                    color: Colors.white,
                                    fontSize: width * 0.10,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.90),
                                        blurRadius: 18,
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: Colors.black.withOpacity(0.70),
                                        blurRadius: 8,
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: Colors.black.withOpacity(0.55),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: height * 0.007),

                                Text(
                                  'RENT. WEAR. CELEBRATE.',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: width * 0.02,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: width * 0.004,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.90),
                                        blurRadius: 12,
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: Colors.black.withOpacity(0.70),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ====================================================
                    // SMALL LINE
                    // ====================================================

                    Positioned(
                      left: width * 0.102,
                      bottom: height * 0.38,

                      child: Container(
                        width: width * 0.20,
                        height: 1,

                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    // ====================================================
                    // MAIN HEADING
                    // ====================================================

                    Positioned(
                      left: width * 0.102,
                      bottom: height * 0.205,

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          // ------------------------------------------------
                          // WEAR
                          // ------------------------------------------------

                          Text(
                            'Wear',
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: width * 0.122,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.90),
                                  blurRadius: 18,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.70),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.55),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          // ------------------------------------------------
                          // THE MOMENT
                          // ------------------------------------------------

                          Text(
                            'the moment.',
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: width * 0.122,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.90),
                                  blurRadius: 18,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.70),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.55),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: height * 0.002,
                          ),

                          // ------------------------------------------------
                          // NOT THE PRICE TAG
                          // ------------------------------------------------

                          Text(
                            'Not the price tag.',
                            style: GoogleFonts.cormorantGaramond(
                              color: const Color(0xFFE5B2A5),
                              fontSize: width * 0.085,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ====================================================
                    // DESCRIPTION
                    // ====================================================

                    Positioned(
                      left: width * 0.102,
                      bottom: height * 0.105,

                      child: Text(
                        'Premium outfits for\n'
                            'your special occasions.',

                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: width * 0.033,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),

                    // ====================================================
                    // PAGE INDICATORS
                    // ONLY 2
                    // ====================================================

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: height * 0.052,

                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,

                        children: [

                          // ----------------------------------------------
                          // FIRST INDICATOR
                          // ----------------------------------------------

                          _indicator(
                            active: _currentPage == 0,
                            size: width * 0.020,
                          ),

                          SizedBox(
                            width: width * 0.025,
                          ),

                          // ----------------------------------------------
                          // SECOND INDICATOR
                          // ----------------------------------------------

                          _indicator(
                            active: _currentPage == 1,
                            size: width * 0.017,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // INDICATOR
  // ================================================================

  Widget _indicator({
    required bool active,
    required double size,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),

      width: size,
      height: size,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: active
            ? Colors.white
            : Colors.transparent,

        border: active
            ? null
            : Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
    );
  }
}