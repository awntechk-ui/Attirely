import 'package:flutter/material.dart';

import 'outfit_horizontal_card.dart';

class FeaturedOutfitsSection extends StatelessWidget {
  final List<Map<String, dynamic>> outfits;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onViewMore;

  const FeaturedOutfitsSection({
    super.key,
    required this.outfits,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onViewMore,
  });

  static const Color burgundy = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Featured Outfits',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewMore,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View More',
                    style: TextStyle(
                      color: burgundy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: burgundy,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(color: burgundy),
            ),
          )
        else if (error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: burgundy,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Could not load outfits.',
                  style: TextStyle(
                    color: burgundy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: burgundy.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Try again',
                    style: TextStyle(color: burgundy),
                  ),
                ),
              ],
            ),
          )
        else if (outfits.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 26,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.checkroom_outlined,
                    color: burgundy,
                    size: 38,
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'New styles are coming soon',
                    style: TextStyle(
                      color: burgundy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Published and available outfits will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: burgundy.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: outfits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return OutfitHorizontalCard(
                    outfit: outfits[index],
                  );
                },
              ),
            ),
      ],
    );
  }
}