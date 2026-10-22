import 'package:flutter/material.dart';

import '../../Common_Screens/UI/outfits.dart';
import 'home.dart';
import 'profile.dart';

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  static const Color burgundy = Color(0xFF800020);

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const Outfits(),
    const UserWishlistPage(),
    const UserRentalsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.checkroom_outlined,
                        label: 'Outfits',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.favorite_border,
                        label: 'Wishlist',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Rentals',
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        index: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 23,
                color: selected
                    ? burgundy
                    : burgundy.withOpacity(0.50),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? burgundy
                      : burgundy.withOpacity(0.50),
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Temporary placeholders until these screens are implemented.
class UserWishlistPage extends StatelessWidget {
  const UserWishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8F5),
      body: Center(child: Text('My Wishlist')),
    );
  }
}

class UserRentalsPage extends StatelessWidget {
  const UserRentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8F5),
      body: Center(child: Text('My Rentals')),
    );
  }
}
