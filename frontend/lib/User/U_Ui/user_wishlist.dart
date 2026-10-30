
import 'package:flutter/material.dart';

import '../U_Ui_Logic/user_wishlist_logic.dart';
import 'rent_outfit_details.dart';

class UserWishlist extends StatelessWidget {
  const UserWishlist({super.key});

  static const Color burgundy = Color(0xFF8B1E2D);
  static const Color background = Color(0xFFFFF8F5);

  double _price(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openDetails(
      BuildContext context,
      Map<String, dynamic> outfit,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentOutfitDetails(
          outfitId: outfit['id'].toString(),
          initialOutfit: outfit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: burgundy,
        elevation: 0,
        title: const Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: UserWishlistLogic.instance,
        builder: (context, _) {
          final outfits = UserWishlistLogic.instance.outfits;

          if (outfits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 66,
                      color: burgundy,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your wishlist is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart on any outfit you love '
                          'to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    '${outfits.length} saved outfit'
                        '${outfits.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.brown.shade500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 290,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final outfit = outfits[index];
                      final id = outfit['id'].toString();
                      final name =
                          outfit['name']?.toString() ?? 'Outfit';
                      final imageUrl =
                          outfit['cover_image_url']?.toString() ?? '';
                      final price = _price(outfit['rental_price']);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openDetails(context, outfit),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.brown.shade100,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.checkroom_outlined,
                                              size: 44,
                                              color: burgundy,
                                            ),
                                          ),
                                        )
                                      else
                                        const Center(
                                          child: Icon(
                                            Icons.checkroom_outlined,
                                            size: 44,
                                            color: burgundy,
                                          ),
                                        ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Material(
                                          color: Colors.white,
                                          shape: const CircleBorder(),
                                          child: IconButton(
                                            tooltip: 'Remove from wishlist',
                                            iconSize: 21,
                                            constraints:
                                            const BoxConstraints(
                                              minWidth: 38,
                                              minHeight: 38,
                                            ),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              UserWishlistLogic.instance
                                                  .removeOutfit(id);
                                            },
                                            icon: const Icon(
                                              Icons.favorite,
                                              color: burgundy,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${price.toStringAsFixed(0)} / rental',
                                        style: const TextStyle(
                                          color: burgundy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                            color: burgundy,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'View details',
                                            style: TextStyle(
                                              color: burgundy,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: outfits.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
