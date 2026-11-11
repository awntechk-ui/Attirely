
import 'package:flutter/material.dart';

class AboutAttirely extends StatefulWidget {
  const AboutAttirely({super.key});

  @override
  State<AboutAttirely> createState() => _AboutAttirelyState();
}

class _AboutAttirelyState extends State<AboutAttirely> {
  static const Color burgundy = Color(0xFF8E2945);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: darkBurgundy,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'About Attirely',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _heroSection(),
                _reveal(
                  child: _storySection(),
                ),
                _reveal(
                  child: _missionVisionSection(),
                ),
                _reveal(
                  child: _howItWorksSection(),
                ),
                _reveal(
                  child: _whyAttirelySection(),
                ),
                _reveal(
                  child: _closingSection(),
                ),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSection() {
    return SizedBox(
      height: 440,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1539109136881-3be0616acf4b',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: darkBurgundy,
              child: const Icon(
                Icons.checkroom_outlined,
                color: gold,
                size: 85,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  darkBurgundy.withOpacity(0.12),
                  darkBurgundy.withOpacity(0.35),
                  darkBurgundy.withOpacity(0.95),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            right: 25,
            bottom: 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE ART OF\nDRESSING DIFFERENTLY',
                  style: TextStyle(
                    color: gold,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Style is yours.\nThe outfit is borrowed.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w300,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover a more thoughtful way to experience fashion.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 38, 22, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('OUR STORY'),
          const SizedBox(height: 12),
          const Text(
            'Fashion should be experienced, not stored away.',
            style: TextStyle(
              color: darkBurgundy,
              fontSize: 25,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 15),
          _body(
            'Attirely is a fashion rental platform created to make '
                'beautiful outfits more accessible. We bring customers '
                'and fashion vendors together, making it easier to discover '
                'and experience outfits for special moments.',
          ),
          const SizedBox(height: 12),
          _body(
            'From celebrations and weddings to parties and memorable '
                'occasions, Attirely encourages people to explore more styles '
                'without needing to own every outfit they wear.',
          ),
          const SizedBox(height: 22),
          _photoBanner(
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d',
            'A wardrobe of possibilities.',
            height: 220,
          ),
        ],
      ),
    );
  }

  Widget _missionVisionSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBurgundy, Color(0xFF64172F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('WHAT WE BELIEVE', light: true),
          const SizedBox(height: 23),
          const Icon(Icons.auto_awesome, color: gold, size: 28),
          const SizedBox(height: 12),
          const Text(
            'Our Mission',
            style: TextStyle(
              color: gold,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          _body(
            'To make fashion more accessible by connecting people '
                'with outfits they love and helping vendors reach customers '
                'who appreciate their collections.',
            light: true,
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white24),
          const SizedBox(height: 25),
          const Icon(Icons.visibility_outlined, color: gold, size: 28),
          const SizedBox(height: 12),
          const Text(
            'Our Vision',
            style: TextStyle(
              color: gold,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          _body(
            'To build a trusted fashion rental community where '
                'customers discover new looks and vendors grow their '
                'businesses through meaningful connections.',
            light: true,
          ),
        ],
      ),
    );
  }

  Widget _howItWorksSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 38, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('THE EXPERIENCE'),
          const SizedBox(height: 10),
          const Text(
            'How Attirely works',
            style: TextStyle(
              color: darkBurgundy,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 23),
          _step(
            '01',
            Icons.search,
            'Discover',
            'Explore outfits and accessories from different vendors.',
          ),
          _step(
            '02',
            Icons.favorite_border,
            'Choose your style',
            'Find an outfit that matches your occasion and taste.',
          ),
          _step(
            '03',
            Icons.shopping_bag_outlined,
            'Request and rent',
            'Follow the rental process and booking details shown on the platform.',
          ),
          _step(
            '04',
            Icons.replay,
            'Return',
            'Return the rented item according to the agreed rental terms.',
          ),
        ],
      ),
    );
  }

  Widget _whyAttirelySection() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      color: const Color(0xFFF3EAE4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('WHY ATTIRELY'),
          const SizedBox(height: 12),
          const Text(
            'More style. More possibilities.',
            style: TextStyle(
              color: darkBurgundy,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _benefit(
            Icons.style_outlined,
            'Explore more styles',
            'Discover different looks for different occasions.',
          ),
          _benefit(
            Icons.storefront_outlined,
            'Support fashion vendors',
            'Connect with vendors and explore their collections.',
          ),
          _benefit(
            Icons.recycling_outlined,
            'Thoughtful fashion choices',
            'Give outfits more opportunities to be enjoyed.',
          ),
          _benefit(
            Icons.auto_awesome_outlined,
            'Make every occasion special',
            'Find a look that makes your moment memorable.',
          ),
        ],
      ),
    );
  }

  Widget _closingSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(22, 32, 22, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkBurgundy, burgundy],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: gold,
            size: 30,
          ),
          const SizedBox(height: 14),
          const Text(
            'Wear the moment.\nKeep the memories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Attirely — Your style, your story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBanner(
      String url,
      String caption, {
        double height = 200,
      }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: burgundy.withOpacity(0.15),
                child: const Icon(
                  Icons.image_outlined,
                  color: burgundy,
                  size: 45,
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    darkBurgundy.withOpacity(0.75),
                  ],
                ),
              ),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(
      String number,
      IconData icon,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: burgundy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: const TextStyle(
                    color: darkBurgundy,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _body(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(
      IconData icon,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: burgundy, size: 23),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkBurgundy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                _body(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String text, {bool light = false}) {
    return Text(
      text,
      style: TextStyle(
        color: light ? gold : burgundy,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _body(String text, {bool light = false}) {
    return Text(
      text,
      style: TextStyle(
        color: light ? Colors.white70 : Colors.black54,
        fontSize: 13,
        height: 1.75,
      ),
    );
  }

  Widget _reveal({required Widget child}) {
    return _ScrollReveal(
      controller: _scrollController,
      child: child,
    );
  }
}

class _ScrollReveal extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const _ScrollReveal({
    required this.controller,
    required this.child,
  });

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal> {
  final GlobalKey _key = GlobalKey();
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;

    final renderObject = _key.currentContext?.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final position = renderObject.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    final isVisible = position.dy < screenHeight * 0.88 &&
        position.dy + renderObject.size.height > 70;

    if (isVisible) {
      setState(() => _visible = true);
      widget.controller.removeListener(_checkVisibility);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: _key,
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.10),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
