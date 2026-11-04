
import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  static const Color burgundy = Color(0xFF8E2945);
  static const Color gold = Color(0xFFE9D8B0);

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Ethnic', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Lehengas', 'icon': Icons.checkroom_rounded},
    {'name': 'Sarees', 'icon': Icons.dry_cleaning_rounded},
    {'name': 'Western', 'icon': Icons.style_rounded},
    {'name': 'Men', 'icon': Icons.person_outline_rounded},
    {'name': 'Accessories', 'icon': Icons.diamond_outlined},
  ];

  void _showMessage(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$name collection coming soon.'),
          backgroundColor: burgundy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Collections',
                      style: TextStyle(
                        color: burgundy,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Find the look that speaks to you.',
                      style: TextStyle(
                        color: Color(0xFF92717A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showMessage(context, 'All'),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: burgundy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: burgundy,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final name = category['name'] as String;

              return GestureDetector(
                onTap: () => _showMessage(context, name),
                child: Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2E5E8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: gold,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: burgundy.withOpacity(0.08),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/dummy.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF2E5E8),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 30,
                            color: burgundy,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xDD4D1025),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 7,
                        left: 3,
                        right: 3,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
