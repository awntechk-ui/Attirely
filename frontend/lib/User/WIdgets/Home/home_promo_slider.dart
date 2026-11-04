
import 'dart:async';
import 'package:flutter/material.dart';

class HomePromoSlider extends StatefulWidget {
  final VoidCallback onExploreRentals;

  const HomePromoSlider({
    super.key,
    required this.onExploreRentals,
  });

  @override
  State<HomePromoSlider> createState() => _HomePromoSliderState();
}

class _HomePromoSliderState extends State<HomePromoSlider> {
  static const Color burgundy = Color(0xFF8E2945);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color ivory = Color(0xFFFFFCF8);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8E2945),
      Color(0xFF64172F),
      Color(0xFF4C1026),
    ],
  );

  final PageController _controller = PageController();

  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'image': 'assets/images/dummy.png',
      'eyebrow': 'CURATED LUXURY',
      'title': 'Your Next Occasion\nDeserves Something\nSpecial',
      'subtitle': 'Discover beautiful outfits without buying them.',
      'button': 'Explore Rentals',
    },
    {
      'image': 'assets/images/dummy.png',
      'eyebrow': 'YOUR STYLE, YOUR MOMENT',
      'title': 'Find the Look\nThat Makes You\nFeel Beautiful',
      'subtitle': 'Explore unique styles for every celebration.',
      'button': 'Discover Your Style',
    },
    {
      'image': 'assets/images/dummy.png',
      'eyebrow': 'LUXURY MADE SMARTER',
      'title': 'More Looks.\nMore Moments.\nLess Spending.',
      'subtitle': 'Make every occasion a stylish one.',
      'button': 'Explore Collection',
    },
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_controller.hasClients) return;

        _controller.nextPage(
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSlideButton(int index) {
    if (index == 0) {
      widget.onExploreRentals();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Discover more Attirely styles soon.'),
          backgroundColor: burgundy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Container(
          height: 228,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(

            gradient: cardGradient,
            borderRadius: BorderRadius.circular(22),
            // border: Border.all(
            //   color: gold,
            //   width: 1.1,
            // ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: gold,
              width: 1.3,
            ),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: null,
                onPageChanged: (index) {
                  if (!mounted) return;

                  setState(() {
                    _currentPage = index % _slides.length;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index % _slides.length];

                  return _buildSlide(
                    slide,
                    width,
                    index % _slides.length,
                  );
                },
              ),

              // PAGE INDICATORS
              Positioned(
                bottom: 13,
                right: 17,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _slides.length,
                        (index) {
                      final selected = _currentPage == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 5),
                        height: 6,
                        width: selected ? 20 : 6,
                        decoration: BoxDecoration(
                          color: selected
                              ? gold
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlide(
      Map<String, dynamic> slide,
      double width,
      int index,
      ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // BACKGROUND IMAGE
        Image.asset(
          slide['image'] as String,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              decoration: const BoxDecoration(
                gradient: cardGradient,
              ),
              child: const Center(
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 65,
                  color: Colors.white38,
                ),
              ),
            );
          },
        ),

        // BURGUNDY CONTRAST OVERLAY
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.52, 1.0],
              colors: [
                const Color(0xFF500D25).withOpacity(0.96),
                burgundy.withOpacity(0.78),
                burgundy.withOpacity(0.04),
              ],
            ),
          ),
        ),

        // BOTTOM SHADING
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF4B1024).withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // RESPONSIVE PROMOTIONAL CONTENT
        Positioned(
          left: 18,
          right: 62,
          top: 14,
          bottom: 32,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width * 0.68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EYEBROW
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: width * 0.68,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slide['eyebrow'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // MAIN TITLE
                  Text(
                    slide['title'] as String,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ivory,
                      fontSize: 23,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 9),

                  // SUBTITLE
                  Text(
                    slide['subtitle'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ivory.withOpacity(0.93),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // CTA BUTTON
                  _buildButton(
                    slide['button'] as String,
                        () => _onSlideButton(index),
                    width,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
      String text,
      VoidCallback onTap,
      double width,
      ) {
    return Material(
      color: gold,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width * 0.48,
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.arrow_forward_rounded,
                color: burgundy,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
