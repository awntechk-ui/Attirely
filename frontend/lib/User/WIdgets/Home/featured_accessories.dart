
import 'package:flutter/material.dart';

class FeaturedAccessories extends StatelessWidget {
  final List<Map<String, dynamic>> accessories;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const FeaturedAccessories({
    super.key,
    required this.accessories,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  static const burgundy = Color(0xFF800020);
  static const mutedText = Color(0xFF82777A);

  @override
  Widget build(BuildContext context) {
    // Keep the homepage unchanged when there are no accessories.
    if (!isLoading && accessories.isEmpty && error == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Featured Accessories',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: burgundy,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The little details that complete your look.',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (isLoading)
          const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(color: burgundy),
            ),
          )
        else if (error != null)
          SizedBox(
            height: 120,
            child: Center(
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: burgundy),
                label: const Text(
                  'Could not load accessories. Try again',
                  style: TextStyle(color: burgundy),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 224,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: accessories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final accessory = accessories[index];

                final imageUrl =
                    accessory['cover_image_url']?.toString() ?? '';

                final name =
                    accessory['name']?.toString() ?? 'Accessory';

                final category =
                    accessory['category']?.toString() ?? '';

                final price =
                    accessory['rental_price']?.toString() ?? '0';

                final brand =
                    accessory['brand']?.toString() ?? '';

                return Container(
                  width: 148,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFEDE5E1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 137,
                        width: double.infinity,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                            : _imagePlaceholder(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF302629),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              brand.isNotEmpty ? brand : category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: mutedText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '₹$price / rental',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: burgundy,
                              ),
                            ),
                          ],
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

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF5EEEA),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 35,
          color: Color(0xFFB9A5A9),
        ),
      ),
    );
  }
}
