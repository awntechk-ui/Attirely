
import 'package:flutter/material.dart';

class WhyRentSection extends StatelessWidget {
  const WhyRentSection({super.key});

  static const Color burgundy = Color(0xFF8E2945);
  static const Color gold = Color(0xFFD7B66D);
  static const Color cream = Color(0xFFFFFCF8);
  static const Color pale = Color(0xFFF7EAED);
  static const Color muted = Color(0xFF806B70);

  static const List<Map<String, dynamic>> benefits = [
    {
      'icon': Icons.workspace_premium_outlined,
      'title': 'Wear More, Spend Less',
      'description': 'Enjoy beautiful outfits without the big price tag.',
    },
    {
      'icon': Icons.dry_cleaning_outlined,
      'title': 'Fresh & Ready to Wear',
      'description': 'Professionally cleaned and carefully maintained.',
    },
    {
      'icon': Icons.eco_outlined,
      'title': 'Style More Sustainably',
      'description': 'Give outfits more occasions and reduce fashion waste.',
    },
    {
      'icon': Icons.local_shipping_outlined,
      'title': 'Easy Doorstep Returns',
      'description': 'Enjoy your look and return it with ease.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Rent with Attirely?',
            style: TextStyle(
              color: burgundy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'A smarter way to dress for every occasion.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: benefits.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              mainAxisExtent: 132,
            ),
            itemBuilder: (context, index) {
              final item = benefits[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: index.isEven ? pale : cream,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: gold, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: burgundy.withOpacity(0.045),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: burgundy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item['description'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
