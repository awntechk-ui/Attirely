import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../U_Ui_Logic/home_logic.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeLogic logic;

  // Attirely colors
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    logic = HomeLogic();
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
          // HOME CONTENT
          // =========================================================

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TOP BAR
                  // =================================================

                  Row(
                    children: [
                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: burgundy,
                              size: 22,
                            ),

                            const SizedBox(width: 6),

                            Flexible(
                              child: Text(
                                'Your Location',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: burgundy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 3),

                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: burgundy,
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      // Notifications
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: burgundy,
                        ),
                      ),

                      // Profile
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                              AppRoutes.profile,
                          );
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          color: burgundy,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // SEARCH BAR
                  // =================================================

                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: burgundy.withOpacity(0.15),
                      ),
                    ),
                    child: TextField(
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText:
                        'Search dresses, styles and more...',
                        hintStyle: TextStyle(
                          color: burgundy.withOpacity(0.55),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: burgundy,
                          size: 22,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.tune,
                            color: burgundy,
                            size: 21,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // OWNER BANNER
                  // =================================================

                  GestureDetector(
                    onTap: () {
                      logic.openVendorSection(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: gold,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: burgundy.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Want to become an owner?',
                              style: TextStyle(
                                color: burgundy,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'List your dresses and start sharing '
                                  'your style with the Attirely community.',
                              style: TextStyle(
                                color: burgundy.withOpacity(0.75),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: burgundy,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Become an Owner',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  SizedBox(width: 7),

                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // TEMPORARY HOME CONTENT PLACEHOLDER
                  // =================================================

                  Center(
                    child: Text(
                      'Discover styles you love',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: burgundy.withOpacity(0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =========================================================
          // BOTTOM NAVIGATION BAR
          // =========================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: burgundy.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: burgundy.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    selected: true,
                    onTap: () {},
                  ),

                  _BottomNavItem(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    onTap: () {},
                  ),

                  _BottomNavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Rentals',
                    onTap: () {},
                  ),

                  _BottomNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {},
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

// ===============================================================
// BOTTOM NAV ITEM
// ===============================================================

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFF800020);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? burgundy
                  : burgundy.withOpacity(0.55),
              size: 23,
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? burgundy
                    : burgundy.withOpacity(0.55),
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}