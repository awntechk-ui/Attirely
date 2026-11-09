import 'package:attirely/User/U_Ui/rent_out.dart';
import 'package:flutter/material.dart';

import '../../User/U_Ui_Logic/user_cart_logic.dart';
import '../../User/U_API_Routes/u_outfit_api_routes.dart';
import '../../User/U_Ui/rent_outfit_details.dart';
import '../../app_routes.dart';
import 'book_trial.dart';

class UserCartPage extends StatefulWidget {
  const UserCartPage({super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final UserCartLogic cart = UserCartLogic.instance;

  static const Color burgundy = Color(0xFF65001D);
  static const Color deepBurgundy = Color(0xFF570018);
  static const Color cream = Color(0xFFFBF7F5);
  static const Color mutedRose = Color(0xFFFCE9E9);
  static const Color gold = Color(0xFF79621B);
  static const Color mutedText = Color(0xFF796B6B);

  static const double trialFee = 200;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await cart.loadCart();
    if (!mounted) return;
    await cart.loadSimilarOutfits();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) => '₹${_number(value).toStringAsFixed(0)}';

  Map<String, dynamic> _outfit(Map<String, dynamic> item) {
    final value = item['outfit'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return Map<String, dynamic>.from(item);
  }

  String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }

  String _imageUrl(Map<String, dynamic> outfit) {
    String url = outfit['cover_image_url']?.toString() ?? '';
    if (url.isNotEmpty) return url;

    final images = outfit['images'];
    if (images is List) {
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          url = image['image_url']?.toString() ?? '';
          if (url.isNotEmpty) return url;
        }
      }
      if (images.isNotEmpty && images.first is Map) {
        return images.first['image_url']?.toString() ?? '';
      }
    }
    return '';
  }

  bool _available(Map<String, dynamic> item) => item['can_rent'] == true;

  int get _availableCount => cart.items.where(_available).length;

  List<Map<String, dynamic>> get _availableOutfits => cart.items
      .where(_available)
      .map(_outfit)
      .where((outfit) => outfit['id'] != null)
      .toList();

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _removeItem(String id) async {
    if (id.isEmpty || cart.isUpdating) return;
    final success = await cart.removeOutfit(id);
    if (!mounted) return;
    _message(success
        ? 'Outfit removed from your cart.'
        : cart.errorMessage ?? 'Could not remove outfit.');
    if (success) await cart.loadSimilarOutfits();
  }

  Future<void> _clearCart() async {
    if (cart.isUpdating || cart.items.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text('All outfits will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Cart'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: burgundy),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final success = await cart.clearCart();
    if (!mounted) return;
    _message(success ? 'Cart cleared.' : 'Could not clear cart.');
  }

  void _rentOut() {
    final outfits = cart.items
        .where(_available)
        .map((item) {
      final outfit = _outfit(item);

      // Preserve the size selected in the cart.
      outfit['selected_size'] = _firstText([
        item['selected_size'],
        item['size'],
        outfit['selected_size'],
        outfit['size'],
      ]);

      return outfit;
    })
        .where((outfit) => outfit['id'] != null)
        .toList();

    if (outfits.isEmpty) {
      _message('No available outfits to rent.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentOutPage(
          outfits: outfits,
        ),
      ),
    );
  }

  void _openTrialPage() {
    final outfits = _availableOutfits;
    if (outfits.isEmpty) {
      _message('No available outfits for trial.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookTrialPage(outfits: outfits)),
    );
  }

  // void _openCoupons() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const CouponsPage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          body: _buildBody(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 91,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      title: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back,
              color: deepBurgundy,
              size: 27,
            ),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'My Cart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 27,
                          height: 1,
                          color: Color(0xFF201819),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 9),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBDCDD),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'Outfit' : 'Outfits'}',
                        style: const TextStyle(
                          color: deepBurgundy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Text(
                  'Your selected styles, all in one place.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF65595A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          TextButton(
            onPressed: cart.items.isEmpty || cart.isUpdating
                ? null
                : _clearCart,
            style: TextButton.styleFrom(
              foregroundColor: deepBurgundy,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'CLEAR ALL',
              style: TextStyle(
                letterSpacing: 1,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (cart.isLoading && cart.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: burgundy));
    }

    if (cart.errorMessage != null && cart.items.isEmpty) {
      return _emptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load your cart',
        subtitle: cart.errorMessage!,
        buttonText: 'Try Again',
        onPressed: _initializeCart,
      );
    }

    if (cart.items.isEmpty) {
      return _emptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        subtitle: 'Discover beautiful outfits and add your favourites.',
        buttonText: 'Explore Outfits',
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userRentals,
                (route) => false,
          );
        },
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: burgundy,
          onRefresh: _initializeCart,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 190),
            children: [
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _cartProductCard(item),
              )),
              // const SizedBox(height: 2),
              // _orderSummary(),
            ],
          ),
        ),
        if (cart.isUpdating)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: burgundy,
              backgroundColor: mutedRose,
            ),
          ),
        _bottomActions(),
      ],
    );
  }

  Widget _cartProductCard(Map<String, dynamic> item) {
    final outfit = _outfit(item);
    final id = outfit['id']?.toString() ?? '';
    final name = _firstText([outfit['name']], fallback: 'Outfit');
    final brand = _firstText([outfit['brand'], outfit['brand_name']]);
    final image = _imageUrl(outfit);
    final mrp = _number(outfit['mrp']);
    final rental = _number(outfit['rental_price']);
    final available = _available(item);

    // Use values from the cart/outfit response when the backend supplies them.
    final selectedSize = _firstText([
      item['selected_size'],
      item['size'],
      outfit['selected_size'],
      outfit['size'],
    ]);
    // final selectedColor = _firstText([
    //   item['selected_color'],
    //   item['color'],
    //   outfit['selected_color'],
    //   outfit['color'],
    // ]);
    // final period = _firstText([
    //   item['rental_period'],
    //   item['duration'],
    //   outfit['rental_period'],
    //   outfit['rental_duration'],
    //   outfit['duration'],
    // ]);
    final discount = mrp > 0 && rental > 0
        ? (((mrp - rental) / mrp) * 100).round().clamp(0, 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E8E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B2630).withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentOutfitDetails(outfitId: id, initialOutfit: outfit),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _productImage(image, width: 98, height: 132),
                ),
                // if (period.isNotEmpty)
                //   Positioned(
                //     top: 7,
                //     left: 6,
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                //       decoration: BoxDecoration(
                //         color: Colors.white.withOpacity(.94),
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //       child: Text(
                //         period.toUpperCase(),
                //         style: const TextStyle(
                //           color: deepBurgundy,
                //           fontSize: 10,
                //           fontWeight: FontWeight.bold,
                //           letterSpacing: .5,
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (brand.isNotEmpty)
                            Text(
                              brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: gold,
                                fontSize: 10,
                                letterSpacing: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              color: Color(0xFF21191A),
                              fontSize: 18,
                              height: 1.12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: cart.isUpdating ? null : () => _removeItem(id),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, top: 1),
                        child: Icon(Icons.delete_outline, color: Color(0xFF8A7779), size: 21),
                      ),
                    ),
                  ],
                ),
                if (selectedSize.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Size: $selectedSize',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF55494A),
                    ),
                  ),
                ],
                // Keep Rental Outfit container commented
// Container(
//   padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
//   decoration: BoxDecoration(
//     color: mutedRose,
//     borderRadius: BorderRadius.circular(20),
//   ),
//   child: Text(
//     available ? 'Rental Outfit' : 'Currently Unavailable',
//     maxLines: 1,
//     overflow: TextOverflow.ellipsis,
//     style: const TextStyle(
//       color: deepBurgundy,
//       fontSize: 10,
//       fontWeight: FontWeight.w500,
//     ),
//   ),
// ),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rental Price
                    Text(
                      _money(rental),
                      style: const TextStyle(
                        color: deepBurgundy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(width: 5),

                    const Text(
                      'Rental Price',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

// MRP and discount below rental price
                if (mrp > 0) ...[
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        _money(mrp),
                        style: const TextStyle(
                          color: Color(0xFF8D7E7F),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),

                      if (discount > 0) ...[
                        const SizedBox(width: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$discount% Off MRP',
                            style: const TextStyle(
                              color: deepBurgundy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                if (!available) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'This outfit cannot currently be rented or booked for a trial.',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _orderSummary() {
  //   return Container(
  //     padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: const Color(0xFFF0E8E6)),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             const Icon(Icons.lock_outline, color: deepBurgundy, size: 22),
  //             const SizedBox(width: 10),
  //             const Expanded(
  //               child: Text(
  //                 'Rental Order\nSummary',
  //                 style: TextStyle(
  //                   fontFamily: 'serif',
  //                   fontSize: 19,
  //                   height: 1.15,
  //                   fontWeight: FontWeight.w600,
  //                   color: Color(0xFF201819),
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               constraints: const BoxConstraints(maxWidth: 145),
  //               padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFFFF6D9),
  //                 borderRadius: BorderRadius.circular(3),
  //               ),
  //               child: const Text(
  //                 'COMPLIMENTARY FIT',
  //                 style: TextStyle(
  //                   color: Color(0xFF776018),
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w700,
  //                   letterSpacing: 1,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const Divider(height: 25, color: Color(0xFFF0EAE8)),
  //         _summaryRow('Total Outfits', '${cart.itemCount} Items'),
  //         const SizedBox(height: 12),
  //         _summaryRow('Total Original Retail Value', _money(_mrpTotal)),
  //         const SizedBox(height: 12),
  //         _summaryRow('Rental Subtotal', _money(_rentalTotal)),
  //         const SizedBox(height: 12),
  //         _summaryRow('Refundable Security Deposit', _money(_depositTotal)),
  //         const Divider(height: 25, color: Color(0xFFF0EAE8)),
  //         _summaryRow('Total Rental Amount', _money(_grandTotal), bold: true),
  //         const SizedBox(height: 8),
  //         const Align(
  //           alignment: Alignment.centerLeft,
  //           child: Text(
  //             'Security deposit is refundable. MRP is shown for reference only.',
  //             style: TextStyle(color: mutedText, fontSize: 10, height: 1.4),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _summaryRow(String label, String value, {bool bold = false}) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             color: bold ? const Color(0xFF21191A) : const Color(0xFF66595A),
  //             fontSize: bold ? 13 : 12,
  //             fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
  //           ),
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: TextStyle(
  //           color: bold ? deepBurgundy : const Color(0xFF201819),
  //           fontSize: bold ? 17 : 13,
  //           fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _productImage(String url, {required double width, required double height}) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF5ECE9),
        alignment: Alignment.center,
        child: const Icon(Icons.checkroom_outlined, size: 36, color: burgundy),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF5ECE9),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: burgundy, size: 30),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFF5ECE9),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: burgundy, strokeWidth: 2),
        );
      },
    );
  }

  Widget _bottomActions() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 80 + MediaQuery.of(context).padding.bottom,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        // decoration: BoxDecoration(
        //   color: cream,
        //   border: const Border(top: BorderSide(color: Color(0xFFECE2DF))),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(.055),
        //       blurRadius: 13,
        //       offset: const Offset(0, -3),
        //     ),
        //   ],
        // ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 47,
                    child: OutlinedButton.icon(
                      onPressed: cart.isUpdating || _availableCount == 0 ? null : _openTrialPage,
                      icon: const Icon(Icons.calendar_month_outlined, size: 19),
                      label: const Text('Book a Trail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: deepBurgundy,
                        side: const BorderSide(color: deepBurgundy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: SizedBox(
                    height: 47,
                    child: ElevatedButton.icon(
                      onPressed: cart.isUpdating || _availableCount == 0 ? null : _rentOut,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                      label: const Text('Rent Outfits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 10),
            // const Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Icon(Icons.shield_outlined, color: Color(0xFF776018), size: 15),
            //     SizedBox(width: 6),
            //     Flexible(
            //       child: Text(
            //         'Free cancellation & doorstep trial available',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(color: Color(0xFF66595A), fontSize: 11),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
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
            Icon(icon, size: 65, color: burgundy),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: deepBurgundy,
              ),
            ),
            const SizedBox(height: 9),
            Text(subtitle, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}