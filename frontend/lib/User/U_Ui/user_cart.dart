
import 'package:flutter/material.dart';

import '../../User/U_Ui_Logic/user_cart_logic.dart';
import '../../User/U_API_Routes/u_outfit_api_routes.dart';
import '../../User/U_Ui/rent_outfit_details.dart';
import 'book_trial.dart';

class UserCartPage extends StatefulWidget {
  const UserCartPage({super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final UserCartLogic cart = UserCartLogic.instance;

  static const Color green = Color(0xFF087443);
  static const Color darkGreen = Color(0xFF075C36);
  static const Color lightGreen = Color(0xFFEAF6EF);
  static const Color background = Color(0xFFF5F7F5);
  static const Color trialGreen = Color(0xFF176B45);

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

  // ---------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '₹${_number(value).toStringAsFixed(0)}';
  }

  Map<String, dynamic> _outfit(Map<String, dynamic> item) {
    final value = item['outfit'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    // Also supports a flat outfit response as a fallback.
    return Map<String, dynamic>.from(item);
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

  bool _available(Map<String, dynamic> item) {
    return item['can_rent'] == true;
  }

  int get _availableCount {
    return cart.items.where(_available).length;
  }

  List<Map<String, dynamic>> get _availableOutfits {
    return cart.items
        .where(_available)
        .map(_outfit)
        .where((outfit) => outfit['id'] != null)
        .toList();
  }

  double get _rentalTotal {
    return cart.items.fold<double>(0, (total, item) {
      if (!_available(item)) return total;

      return total + _number(_outfit(item)['rental_price']);
    });
  }

  double get _depositTotal {
    return cart.items.fold<double>(0, (total, item) {
      if (!_available(item)) return total;

      return total + _number(_outfit(item)['security_deposit']);
    });
  }

  double get _grandTotal => _rentalTotal + _depositTotal;

  int get _trialTotal => _availableCount * trialFee.toInt();

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ---------------------------------------------------------
  // REMOVE ITEM
  // ---------------------------------------------------------

  Future<void> _removeItem(String id) async {
    if (id.isEmpty || cart.isUpdating) return;

    final success = await cart.removeOutfit(id);

    if (!mounted) return;

    if (success) {
      _message('Outfit removed from your cart.');

      await cart.loadSimilarOutfits();
    } else {
      _message(cart.errorMessage ?? 'Could not remove outfit.');
    }
  }

  // ---------------------------------------------------------
  // CLEAR CART
  // ---------------------------------------------------------

  Future<void> _clearCart() async {
    if (cart.isUpdating) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text(
          'All outfits will be removed from your cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Cart'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await cart.clearCart();

    if (!mounted) return;

    _message(success ? 'Cart cleared.' : 'Could not clear cart.');
  }

  // ---------------------------------------------------------
  // RENT OUT
  // ---------------------------------------------------------

  void _rentOut() {
    if (_availableCount == 0) {
      _message('No available outfits to rent.');
      return;
    }

    _message('Rental checkout will be available soon!');
  }

  // ---------------------------------------------------------
  // BOOK A TRIAL PAGE
  // ---------------------------------------------------------


  void _openTrialPage() {
    final outfits = _availableOutfits;

    if (outfits.isEmpty) {
      _message('No available outfits for trial.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookTrialPage(outfits: outfits),
      ),
    );
  }


  // ---------------------------------------------------------
  // COUPONS PAGE
  // ---------------------------------------------------------

  void _openCoupons() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CouponsPage(),
      ),
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: darkGreen,
            elevation: 0,
            title: const Text(
              'My Cart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: cart.isUpdating ? null : _clearCart,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (cart.isLoading && cart.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: green),
      );
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
        onPressed: () => Navigator.pop(context),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: green,
          onRefresh: _initializeCart,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 190),
            children: [
              _cartHeader(),

              const SizedBox(height: 14),

              ...cart.items.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _cartProductCard(item),
                ),
              ),

              const SizedBox(height: 5),

              _couponSection(),

              const SizedBox(height: 16),

              _priceDetails(),

              const SizedBox(height: 22),

              _similarOutfits(),
            ],
          ),
        ),

        if (cart.isUpdating)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: green,
              backgroundColor: lightGreen,
            ),
          ),

        _bottomActions(),
      ],
    );
  }

  // ---------------------------------------------------------
  // CART HEADER
  // ---------------------------------------------------------

  Widget _cartHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: green,
            size: 25,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} in your cart',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Your favourite styles, all in one place.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            color: green,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // PRODUCT CARD
  // ---------------------------------------------------------

  Widget _cartProductCard(Map<String, dynamic> item) {
    final outfit = _outfit(item);

    final id = outfit['id']?.toString() ?? '';
    final name = outfit['name']?.toString() ?? 'Outfit';
    final brand = outfit['brand']?.toString() ?? '';
    final image = _imageUrl(outfit);

    final mrp = _number(outfit['mrp']);
    final rental = _number(outfit['rental_price']);
    final deposit = _number(outfit['security_deposit']);

    final available = _available(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: available
              ? Colors.grey.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentOutfitDetails(
                          outfitId: id,
                          initialOutfit: outfit,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: _productImage(
                      image,
                      width: 112,
                      height: 137,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      const SizedBox(height: 9),

                      if (mrp > 0)
                        Row(
                          children: [
                            Text(
                              _money(mrp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'MRP',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 3),

                      Text(
                        _money(rental),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),

                      const Text(
                        'Rental price',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Security deposit: ${_money(deposit)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 13,
                            color: green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Refundable deposit',
                            style: TextStyle(
                              color: green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      if (available)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 13,
                              color: green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Available',
                              style: TextStyle(
                                color: green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Currently unavailable',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!available) _unavailableMessage(),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentOutfitDetails(
                          outfitId: id,
                          initialOutfit: outfit,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View details'),
                  style: TextButton.styleFrom(
                    foregroundColor: darkGreen,
                  ),
                ),

                const Spacer(),

                TextButton.icon(
                  onPressed: cart.isUpdating ? null : () => _removeItem(id),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unavailableMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF6E8),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.deepOrange,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'This outfit is currently unavailable.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'You cannot rent or book a trial for this item right now. '
                'Remove it from your cart to continue with available outfits. '
                'Wishlist saving is not available yet.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // COUPONS
  // ---------------------------------------------------------

  Widget _couponSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: green,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Offers & Coupons',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openCoupons,
                child: const Text(
                  'View More',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: green,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME ATTIRELY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Exciting offers coming soon!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // PRICE DETAILS
  // ---------------------------------------------------------

  Widget _priceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _priceRow(
            'Available outfits',
            '$_availableCount',
          ),

          const SizedBox(height: 11),

          _priceRow(
            'Rental subtotal',
            _money(_rentalTotal),
          ),

          const SizedBox(height: 11),

          _priceRow(
            'Security deposit',
            _money(_depositTotal),
          ),

          const SizedBox(height: 4),

          const Text(
            'Your security deposit is refundable.',
            style: TextStyle(
              fontSize: 11,
              color: green,
            ),
          ),

          const Divider(height: 25),

          _priceRow(
            'Total rental amount',
            _money(_grandTotal),
            bold: true,
          ),

          const SizedBox(height: 9),

          const Text(
            'MRP is shown for reference only. Rental price and refundable '
                'deposit are used in this total.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: bold ? green : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // SIMILAR OUTFITS
  // ---------------------------------------------------------

  Widget _similarOutfits() {
    if (cart.isLoadingSimilar) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: green),
        ),
      );
    }

    if (cart.similarOutfits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop more like this',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Discover styles similar to your cart.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 13),

        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cart.similarOutfits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _similarCard(cart.similarOutfits[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _similarCard(Map<String, dynamic> outfit) {
    final id = outfit['id']?.toString() ?? '';
    final name = outfit['name']?.toString() ?? 'Outfit';
    final image = _imageUrl(outfit);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productImage(
            image,
            width: 160,
            height: 140,
          ),

          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _money(outfit['rental_price']),
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 33,
                  child: OutlinedButton(
                    onPressed: cart.isUpdating
                        ? null
                        : () => _addSimilar(outfit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: green,
                      side: const BorderSide(color: green),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSimilar(Map<String, dynamic> outfit) async {
    final success = await cart.addOutfit(outfit);

    if (!mounted) return;

    _message(
      success
          ? 'Outfit added to cart.'
          : cart.errorMessage ?? 'Could not add outfit.',
    );

    if (success) {
      await cart.loadSimilarOutfits();
    }
  }

  // ---------------------------------------------------------
  // IMAGE
  // ---------------------------------------------------------

  Widget _productImage(
      String url, {
        required double width,
        required double height,
      }) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: lightGreen,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          size: 40,
          color: green,
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          color: lightGreen,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: green,
            size: 35,
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          width: width,
          height: height,
          color: lightGreen,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: green,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // STICKY BOTTOM ACTIONS
  // ---------------------------------------------------------

  Widget _bottomActions() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          14,
          12,
          14,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total rental amount',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _money(_grandTotal),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 11),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 47,
                    child: ElevatedButton(
                      onPressed: cart.isUpdating || _availableCount == 0
                          ? null
                          : _rentOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Rent Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SizedBox(
                    height: 47,
                    child: OutlinedButton(
                      onPressed: cart.isUpdating || _availableCount == 0
                          ? null
                          : _openTrialPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: green,
                        side: const BorderSide(
                          color: green,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_available_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Book a Trial',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '₹$_trialTotal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            const Text(
              'Trial fee: ₹200 per outfit',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------

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
            Icon(icon, size: 65, color: green),

            const SizedBox(height: 17),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
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

// =============================================================
// BOOK A TRIAL PAGE
// =============================================================

class BookATrialPage extends StatefulWidget {
  final List<Map<String, dynamic>> outfits;

  const BookATrialPage({
    super.key,
    required this.outfits,
  });

  @override
  State<BookATrialPage> createState() => _BookATrialPageState();
}

class _BookATrialPageState extends State<BookATrialPage> {
  static const Color green = Color(0xFF087443);
  static const Color background = Color(0xFFF5F7F5);

  static const double trialFee = 200;

  late List<Map<String, dynamic>> selectedOutfits;

  @override
  void initState() {
    super.initState();
    selectedOutfits = List<Map<String, dynamic>>.from(widget.outfits);
  }

  double get total => selectedOutfits.length * trialFee;

  String _image(Map<String, dynamic> outfit) {
    final cover = outfit['cover_image_url']?.toString() ?? '';

    if (cover.isNotEmpty) return cover;

    final images = outfit['images'];

    if (images is List) {
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          return image['image_url']?.toString() ?? '';
        }
      }

      if (images.isNotEmpty && images.first is Map) {
        return images.first['image_url']?.toString() ?? '';
      }
    }

    return '';
  }

  void _remove(int index) {
    setState(() {
      selectedOutfits.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: green,
        elevation: 0,
        title: const Text(
          'Book a Trial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: selectedOutfits.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: green,
              size: 60,
            ),
            const SizedBox(height: 14),
            const Text(
              'No outfits selected',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Go back to your cart and select outfits for trial.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Cart'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.checkroom_outlined,
                  color: green,
                  size: 28,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Trial Selection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedOutfits.length} outfits selected',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          ...selectedOutfits.asMap().entries.map((entry) {
            final index = entry.key;
            final outfit = entry.value;

            final image = _image(outfit);
            final name = outfit['name']?.toString() ?? 'Outfit';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.isEmpty
                        ? Container(
                      width: 76,
                      height: 90,
                      color: const Color(0xFFEAF6EF),
                      child: const Icon(
                        Icons.checkroom,
                        color: green,
                      ),
                    )
                        : Image.network(
                      image,
                      width: 76,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 76,
                          height: 90,
                          color: const Color(0xFFEAF6EF),
                          child: const Icon(
                            Icons.broken_image,
                            color: green,
                          ),
                        );
                      },
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Trial fee: ₹200',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Remove from trial only',
                    onPressed: () => _remove(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _trialRow(
                  'Number of outfits',
                  '${selectedOutfits.length}',
                ),
                const SizedBox(height: 12),
                _trialRow(
                  'Trial fee per outfit',
                  '₹200',
                ),
                const Divider(height: 26),
                _trialRow(
                  'Total trial amount',
                  '₹${total.toStringAsFixed(0)}',
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Removing an outfit here only changes your trial selection. '
                'It will remain in your shopping cart.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
      bottomNavigationBar: selectedOutfits.isEmpty
          ? null
          : SafeArea(
        minimum: const EdgeInsets.all(14),
        child: SizedBox(
          height: 49,
          child: ElevatedButton(
            // Payment integration will be added later.
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(
              'Pay ₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trialRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: bold ? 18 : 14,
            color: bold ? green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// COUPONS PAGE
// =============================================================

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  static const Color green = Color(0xFF087443);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: green,
        elevation: 0,
        title: const Text(
          'Offers & Coupons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF6EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 55,
                  color: green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No coupons yet!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'There are no coupons yet, sorry!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                ),
                child: const Text('Back to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
