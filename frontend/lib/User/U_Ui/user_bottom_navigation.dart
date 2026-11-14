
import 'package:flutter/material.dart';

class UserBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const UserBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFE9D8B0);

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home'),
      (Icons.checkroom_outlined, 'My Outfits'),
      (Icons.shopping_bag_outlined, 'Rentals'),
      (Icons.shopping_cart_outlined, 'Cart'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gold, width: 1.7),
            boxShadow: [
              BoxShadow(
                color: burgundy.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[index].$1,
                          size: 23,
                          color: selected
                              ? burgundy
                              : burgundy.withOpacity(0.50),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[index].$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? burgundy
                                : burgundy.withOpacity(0.50),
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
