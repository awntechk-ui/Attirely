import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Ethnic', 'icon': Icons.auto_awesome},
    {'name': 'Lehengas', 'icon': Icons.checkroom},
    {'name': 'Sarees', 'icon': Icons.dry_cleaning},
    {'name': 'Western', 'icon': Icons.style},
    {'name': 'Men', 'icon': Icons.person_outline},
    {'name': 'Accessories', 'icon': Icons.diamond_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            color: burgundy,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = categories[index];

              return SizedBox(
                width: 76,
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gold.withOpacity(0.85),
                        ),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: burgundy,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}