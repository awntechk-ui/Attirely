import 'package:flutter/material.dart';

import '../../app_routes.dart';

class UserOutfits extends StatelessWidget {
  const UserOutfits({super.key});

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text(
          'My Outfits',
          style: TextStyle(
            color: burgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: burgundy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your wardrobe, your earnings.',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: burgundy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'List your dresses for rent without needing a store.',
              style: TextStyle(
                color: burgundy.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: burgundy.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 64,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No outfits listed yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first dress and start renting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Connect the Add Outfit form here.
                        // From the User Outfits section
                        Navigator.pushNamed(
                          context,
                          AppRoutes.addOutfit,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Outfit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
