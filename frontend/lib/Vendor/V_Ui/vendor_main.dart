import 'package:attirely/Common_Screens/UI/add_outfit.dart';
import 'package:attirely/Vendor/V_Ui/vendor_bookings.dart';
import 'package:attirely/Vendor/V_Ui/vendor_dashboard.dart';
import 'package:attirely/Common_Screens/UI/outfits.dart';
import 'package:attirely/Vendor/V_Ui/vendor_profile.dart';
import 'package:attirely/Vendor/V_Ui/vendor_requests.dart';
import 'package:flutter/material.dart';

class VendorMain extends StatefulWidget {
  const VendorMain({super.key});

  @override
  State<VendorMain> createState() => _VendorMainState();
}

class _VendorMainState extends State<VendorMain> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  static const Color burgundy = Color(0xFF800020);

  @override
  void initState() {
    super.initState();

    _pages = [
      const VendorDashboard(),
      const Outfits(),
      const VendorRequests(),
      const VendorBookings(),
      const VendorProfile(),
    ];
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddOutfit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddOutfit(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8DF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/vendor_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Color(0xFFF8E8DF),
              );
            },
          ),

          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          if (_currentIndex == 1)
            Positioned(
              left: 32,
              right: 32,
              bottom: 100,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _openAddOutfit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('＋ Add Outfit'),
                ),
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
                child: _buildFloatingBottomNavigation(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =============================================================
  // FLOATING NAVIGATION BAR
  // =============================================================

  Widget _buildFloatingBottomNavigation() {
    return Container(
      height: 70,

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: burgundy.withOpacity(0.08),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,
        bottom: false,

        child: Row(
          children: [

            _navItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
            ),

            _navItem(
              index: 1,
              icon: Icons.checkroom_outlined,
              selectedIcon: Icons.checkroom_rounded,
              label: 'Outfits',
            ),

            _navItem(
              index: 2,
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
              label: 'Requests',
            ),

            _navItem(
              index: 3,
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag_rounded,
              label: 'Bookings',
            ),

            _navItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // NAVIGATION ITEM
  // =============================================================

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTap: () {
          _onNavigationTap(index);
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              selected ? selectedIcon : icon,
              size: 22,

              color: selected
                  ? burgundy
                  : burgundy.withOpacity(0.50),
            ),

            const SizedBox(height: 3),

            Text(
              label,

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 9.5,

                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,

                color: selected
                    ? burgundy
                    : burgundy.withOpacity(0.50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}