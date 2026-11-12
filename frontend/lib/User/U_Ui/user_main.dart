import 'package:attirely/User/U_Ui/user_cart.dart';
import 'package:attirely/User/U_Ui/user_rentals.dart';
import 'package:flutter/material.dart';

import 'outfits.dart';
import 'home.dart';

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  static const Color burgundy = Color(0xFF800020);

  int _currentIndex = 0;

  // late final List<Widget> _pages = [
  //   HomePage(
  //     onOpenTab: (index) {
  //       setState(() {
  //         _currentIndex = index;
  //       });
  //     },
  //   ),
  //   const Outfits(),
  //   UserRentals(
  //     onBackToHome: () {
  //       setState(() {
  //         _currentIndex = 0;
  //       });
  //     },
  //   ),
  //   const UserCartPage()
  // ];

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
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


