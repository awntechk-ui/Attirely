
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../UI_Logic/splash_logic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _pageTimer;

  final SplashLogic _logic = SplashLogic();

  // Single splash image
  static const String _splashImage =
      'assets/background/splash_bg.png';

  // Attirely brand colours
  static const Color _champagne = Color(0xFFE5C5A2);
  static const Color _gold = Color(0xFFD6B477);
  static const Color _burgundy = Color(0xFF641C32);
  static const Color _rosegold = Color(0xFFE8C5B0);
  static const Color _white = Color(0xFFFFFFFF);


  @override
  void initState() {
    super.initState();

    // System UI styling
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Show the single splash image for 5 seconds.
    // Then check session and navigate.
    _pageTimer = Timer(
      const Duration(seconds: 5),
          () {
        if (!mounted) return;
        _logic.checkSession(context);
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

          final horizontalPadding = width * 0.095;

          final headingSize =
          (width * 0.145).clamp(48.0, 66.0).toDouble();

          final brandSize =
          (width * 0.105).clamp(36.0, 48.0).toDouble();

          final logoSize =
          (width * 0.19).clamp(65.0, 88.0).toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [

              // =========================================
              // SINGLE BACKGROUND IMAGE
              // =========================================

              Image.asset(
                _splashImage,
                width: width,
                height: height,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // =========================================
              // EDITORIAL DARK OVERLAY
              // =========================================

              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.30),
                          Colors.black.withOpacity(0.12),
                          Colors.black.withOpacity(0.30),
                          Colors.black.withOpacity(0.70),
                        ],
                        stops: const [
                          0.0,
                          0.30,
                          0.58,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // =========================================
              // MAIN CONTENT
              // =========================================

              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                    ),

                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: height * 0.025,
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          // =====================================
                          // TOP BRAND STATEMENT
                          // GOLD BORDER
                          // =====================================

                          const Spacer(flex: 2),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _gold.withOpacity(0.85),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'A NEW WAY TO DRESS',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: _rosegold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.045),

                          // =====================================
                          // ATTIRELY LOGO IMAGE
                          // =====================================

                          Center(
                            child: Image.asset(
                              'assets/logos/white_attirely_logo.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // =====================================
                          // ATTIRELY BRAND NAME
                          // BOLD AND ELEGANT
                          // =====================================

                          Center(
                            child: Text(
                              'Attirely',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: brandSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.8,
                                height: 1.05,
                                color: _white,
                                shadows: [
                                  Shadow(
                                    color: _gold.withOpacity(0.40),
                                    blurRadius: 14,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.065),

                          // =====================================
                          // WEAR THE MOMENT
                          // BOLD EDITORIAL TYPOGRAPHY
                          // =====================================

                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'WEAR THE\nMOMENT.',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: brandSize,
                                fontWeight: FontWeight.w900,
                                height: 0.98,
                                letterSpacing: 0.2,
                                color: _rosegold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // =====================================
                          // EDITORIAL DIVIDER
                          // =====================================

                          Container(
                            width: 48,
                            height: 1,
                            color: _champagne.withOpacity(0.9),
                          ),

                          const SizedBox(height: 16),

                          // =====================================
                          // SUPPORTING BRAND STATEMENT
                          // =====================================

                          Text(
                            'Not the price tag.',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.instrumentSerif(
                              color: _white,
                              fontSize: 28,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 13),

                          // =====================================
                          // DESCRIPTION
                          // =====================================

                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 285,
                            ),
                            child: Text(
                              'Premium outfits for your special '
                                  'occasions. Discover a new way to '
                                  'dress beautifully.',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.dmSans(
                                color: _rosegold.withOpacity(0.91),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.65,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ),

                          // =====================================
                          // BOTTOM BRAND LINE
                          // =====================================

                          const Spacer(flex: 2),

                          Center(
                            child: Text(
                              'RENT. WEAR. REPEAT.',
                              style: GoogleFonts.dmSans(
                                color: _rosegold.withOpacity(0.88),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
