
import 'package:attirely/User/U_Ui/rent_outfit_details.dart';
import 'package:flutter/material.dart';

import '../../Common_Screens/UI/user_cart.dart';
import '../U_Ui_Logic/user_cart_logic.dart';
import '../U_Ui_Logic/user_rentals_logic.dart';
import '../U_Ui_Logic/user_wishlist_logic.dart';



class UserRentals extends StatefulWidget {
  const UserRentals({super.key});

  @override
  State<UserRentals> createState() => _UserRentalsState();
}

class _UserRentalsState extends State<UserRentals> {
  late final UserRentalsLogic logic;

  static const Color burgundy = Color(0xFF8B1E2D);
  static const Color background = Color(0xFFFFF8F5);

  @override
  void initState() {
    super.initState();
    logic = UserRentalsLogic();
    logic.loadOutfits();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  double _price(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserCartPage()),
    );
  }

  void _openDetails(Map<String, dynamic> outfit) {
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
        elevation: 0,
        foregroundColor: burgundy,
        title: const Text(
          'Rent Your Style',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          AnimatedBuilder(
            animation: UserCartLogic.instance,
            builder: (context, _) {
              final count = UserCartLogic.instance.itemCount;

              return IconButton(
                tooltip: 'My Cart',
                onPressed: _openCart,
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: logic,
        builder: (context, _) {
          if (logic.isLoading && logic.outfits.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: burgundy),
            );
          }

          if (logic.errorMessage != null && logic.outfits.isEmpty) {
            return _message(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load outfits',
              subtitle: logic.errorMessage!,
              buttonText: 'Try Again',
              onPressed: () => logic.loadOutfits(refresh: true),
            );
          }

          if (logic.outfits.isEmpty) {
            return _message(
              icon: Icons.checkroom_outlined,
              title: 'No outfits available yet',
              subtitle: 'Published and available outfits will appear here.',
              buttonText: 'Refresh',
              onPressed: () => logic.loadOutfits(refresh: true),
            );
          }

          final outfits = logic.filteredOutfits;

          return RefreshIndicator(
            color: burgundy,
            onRefresh: () => logic.loadOutfits(refresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find your perfect look',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: burgundy,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${logic.outfits.length} outfits available to explore',
                          style: TextStyle(color: Colors.brown.shade400),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Category',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _filterChips(
                          values: logic.categories,
                          selected: logic.selectedCategory,
                          onSelected: logic.setCategory,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gender',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _filterChips(
                          values: logic.genders,
                          selected: logic.selectedGender,
                          onSelected: logic.setGender,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text(
                              'Explore Outfits',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${outfits.length} items',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (outfits.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No outfits match these filters.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 325,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final outfit = outfits[index];
                          return _outfitCard(outfit);
                        },
                        childCount: outfits.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChips({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((value) {
          final active = value == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(value),
              selected: active,
              onSelected: (_) => onSelected(value),
              selectedColor: burgundy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: active ? Colors.white : burgundy,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(
                color: active ? burgundy : Colors.brown.shade100,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _outfitCard(Map<String, dynamic> outfit) {
    final id = outfit['id']?.toString() ?? '';
    final imageUrl = outfit['cover_image_url']?.toString() ?? '';
    final name = outfit['name']?.toString() ?? 'Outfit';
    final price = _price(outfit['rental_price']);

    return AnimatedBuilder(
      animation: Listenable.merge([
        UserCartLogic.instance,
        UserWishlistLogic.instance,
      ]),
      builder: (context, _) {
        final added = UserCartLogic.instance.contains(id);
        final wishlisted = UserWishlistLogic.instance.contains(id);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentOutfitDetails(
                  outfitId: outfit['id'].toString(),
                  initialOutfit: outfit,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _outfitImage(imageUrl),

                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: wishlisted
                                  ? 'Remove from wishlist'
                                  : 'Add to wishlist',
                              constraints: const BoxConstraints(
                                minWidth: 38,
                                minHeight: 38,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                wishlisted ? Icons.favorite : Icons.favorite_border,
                                color: wishlisted
                                    ? const Color(0xFF8B1E2D)
                                    : Colors.grey.shade700,
                                size: 21,
                              ),
                              onPressed: () {
                                UserWishlistLogic.instance.toggleOutfit(outfit);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      wishlisted
                                          ? '$name removed from wishlist'
                                          : '$name added to wishlist',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'RENT',
                              style: TextStyle(
                                color: burgundy,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 5),
                        Text(
                          '₹${price.toStringAsFixed(0)} / rental',
                          style: const TextStyle(
                            color: burgundy,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () {
                              if (added) {
                                _openCart();
                              } else {
                                UserCartLogic.instance.addOutfit(outfit);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to cart'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: added
                                  ? Colors.green.shade700
                                  : burgundy,
                              side: BorderSide(
                                color: added
                                    ? Colors.green.shade600
                                    : burgundy,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    added ? Icons.check : Icons.add,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(added ? 'Added' : 'Add to Cart'),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _outfitImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF0E5E1),
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 48,
            color: burgundy,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0E5E1),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: burgundy,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: const Color(0xFFF0E5E1),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: burgundy,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: burgundy),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: burgundy,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: burgundy),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
