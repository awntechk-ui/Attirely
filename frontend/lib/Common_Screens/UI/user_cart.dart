
import 'package:flutter/material.dart';

import '../../User/U_Ui/rent_outfit_details.dart';
import '../../User/U_Ui_Logic/user_cart_logic.dart';


class UserCartPage extends StatelessWidget {
  const UserCartPage({super.key});

  static const Color burgundy = Color(0xFF8B1E2D);
  static const Color background = Color(0xFFFFF8F5);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cart = UserCartLogic.instance;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: burgundy,
        elevation: 0,
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          final items = cart.items;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 76,
                      color: burgundy,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore rentals and add your favourite outfits here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: burgundy,
                      ),
                      child: const Text('Explore Outfits'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final outfit = items[index];
                    final id = outfit['id']?.toString() ?? '';
                    final name = outfit['name']?.toString() ?? 'Outfit';
                    final imageUrl =
                        outfit['cover_image_url']?.toString() ?? '';
                    final price = _number(outfit['rental_price']);
                    final deposit = _number(outfit['security_deposit']);

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.brown.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 96,
                              height: 124,
                              child: imageUrl.isEmpty
                                  ? Container(
                                color: const Color(0xFFF0E5E1),
                                child: const Icon(
                                  Icons.checkroom_outlined,
                                  size: 40,
                                  color: burgundy,
                                ),
                              )
                                  : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                      color: const Color(0xFFF0E5E1),
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: burgundy,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rental: ₹${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: burgundy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deposit: ₹${deposit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.brown.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RentOutfitDetails(
                                                  outfitId: id,
                                                  initialOutfit: outfit,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(color: burgundy),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        cart.removeOutfit(id);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 17,
                                      ),
                                      label: const Text('Remove'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
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
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _priceRow('Outfits', '${items.length}'),
                      const SizedBox(height: 10),
                      _priceRow(
                        'Rental subtotal',
                        '₹${cart.rentalSubtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _priceRow(
                        'Security deposits',
                        '₹${cart.securityDepositTotal.toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _priceRow(
                        'Rental + deposit preview',
                        '₹${(cart.rentalSubtotal + cart.securityDepositTotal).toStringAsFixed(2)}',
                        bold: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Book a Trial'),
                                content: const Text(
                                  'Your selected outfits are ready for the '
                                      'next step. Trial scheduling, date selection '
                                      'and store coordination are not connected yet.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.event_available_outlined),
                          label: const Text('Book a Trial'),
                          style: FilledButton.styleFrom(
                            backgroundColor: burgundy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Final rental terms and deposit are subject to store confirmation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 15 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: bold ? 16 : 14,
            color: bold ? burgundy : Colors.black87,
          ),
        ),
      ],
    );
  }
}
