import 'package:flutter/material.dart';

import '../U_Ui_Logic/rent_outfit_details_logic.dart';
import 'user_cart.dart';
import '../U_Ui_Logic/user_cart_logic.dart';

class RentOutfitDetails extends StatefulWidget {
  final String outfitId;
  final Map<String, dynamic>? initialOutfit;

  const RentOutfitDetails({
    super.key,
    required this.outfitId,
    this.initialOutfit,
  });

  @override
  State<RentOutfitDetails> createState() => _RentOutfitDetailsPageState();
}

class _RentOutfitDetailsPageState extends State<RentOutfitDetails> {
  static const Color burgundy = Color(0xFF741D35);
  static const Color deepBurgundy = Color(0xFF5D172B);
  static const Color background = Color(0xFFFFF9F6);
  static const Color paleRose = Color(0xFFF7EDE9);
  static const Color muted = Color(0xFF806F6B);
  static const Color border = Color(0xFFEDE2DE);

  final PageController _pageController = PageController();
  int currentImage = 0;
  late final RentOutfitDetailsLogic logic;


  @override
  void initState() {
    super.initState();

    logic = RentOutfitDetailsLogic();

    logic.loadDetails(
      widget.outfitId,
      initialOutfit: widget.initialOutfit,
    );
  }

  @override
  void dispose() {
    logic.dispose();
    _pageController.dispose();
    super.dispose();
  }



  Future<void> _addToCart() async {
    final outfit = logic.outfit;

    if (outfit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit details are not available.'),
        ),
      );
      return;
    }

    // Prevent duplicate requests
    final cartLogic = UserCartLogic.instance;

    if (cartLogic.isUpdating) return;

    // Validate selected size
    final selectedSize = logic.selectedSize;

    if (selectedSize == null || selectedSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an outfit size.'),
        ),
      );
      return;
    }

    // Prepare outfit data
    final itemForCart = Map<String, dynamic>.from(outfit);

    itemForCart['selected_size'] = selectedSize;

    // Call backend and WAIT for result
    final success = await cartLogic.addOutfit(itemForCart);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Outfit added to your cart successfully!'),
          backgroundColor: deepBurgundy,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: _openCart,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cartLogic.errorMessage ?? 'Unable to add outfit to cart.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserCartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logic,
      builder: (context, child) {
        final item = logic.outfit;

        if (logic.isLoading && item == null) {
          return const Scaffold(
            backgroundColor: background,
            body: Center(
              child: CircularProgressIndicator(color: burgundy),
            ),
          );
        }

        if (item == null) {
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              title: const Text('Outfit details'),
              backgroundColor: background,
              foregroundColor: deepBurgundy,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 46,
                      color: burgundy,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      logic.errorMessage ?? 'Unable to load this outfit.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => logic.loadDetails(widget.outfitId),
                      style: FilledButton.styleFrom(
                        backgroundColor: burgundy,
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final images = logic.images();
        final sizes = logic.sizes();
        final measurements = logic.measurements();

        final price = logic.number(item['rental_price']);
        final mrp = logic.number(item['mrp']);
        final deposit = logic.number(item['security_deposit']);
        final discount = logic.discountPercentage(
          item['mrp'],
          item['rental_price'],
        );

        final brand = logic.text(item['brand'], 'Attirely Boutique');
        final colorName = logic.text(item['color_name'], 'Not specified');
        final material = logic.text(item['material'], 'Not specified');
        final sleeve = logic.text(item['sleeve'], 'Not specified');
        final description = logic.text(
          item['description'],
          'No description has been provided for this outfit yet.',
        );

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: deepBurgundy,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'ATTIRELY',
              style: TextStyle(
                color: deepBurgundy,
                fontSize: 15,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              AnimatedBuilder(
                animation: UserCartLogic.instance,
                builder: (context, _) {
                  final count = UserCartLogic.instance.itemCount;
                  return IconButton(
                    tooltip: 'Cart',
                    onPressed: _openCart,
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 21,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
            ],
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                color: burgundy,
                onRefresh: () => logic.loadDetails(widget.outfitId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 118),
                  children: [
                    _buildGallery(images),
                    const SizedBox(height: 16),
                    _buildBrandAndTitle(brand, item),
                    const SizedBox(height: 15),
                    _buildPriceCard(price, mrp, deposit, discount),
                    const SizedBox(height: 12),
                    _buildFabricCard(material, sleeve, colorName, item),
                    const SizedBox(height: 10),
                    _buildSizesCard(sizes, measurements, item),
                    const SizedBox(height: 10),
                    _buildExpandableCard(
                      title: 'Outfit Description',
                      icon: Icons.inventory_2_outlined,
                      initiallyExpanded: false,
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: muted,
                          height: 1.6,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildExpandableCard(
                      title: 'Measurements & Size Guide',
                      icon: Icons.straighten,
                      initiallyExpanded: false,
                      child: measurements.isEmpty
                          ? const Text(
                        'Measurement details are not available for this outfit.',
                        style: TextStyle(color: muted, fontSize: 12),
                      )
                          : Column(
                        children: measurements.entries.map((entry) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  logic.prettyLabel(entry.key),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    color: deepBurgundy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildComingSoonSection(
                      title: 'Real Brides & Reviews',
                      subtitle:
                      'Customer ratings and verified rental experiences',
                      icon: Icons.star_outline_rounded,
                      message:
                      'Reviews will appear here once the reviews API is connected.',
                    ),
                    const SizedBox(height: 18),
                    _buildMoreFromVendor(brand),
                    const SizedBox(height: 20),
                    _buildExperienceCard(),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 17),
                      label: const Text('Explore More Outfits'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: deepBurgundy,
                        side: const BorderSide(color: deepBurgundy),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (logic.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Could not refresh details: ${logic.errorMessage}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (logic.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: burgundy,
                    backgroundColor: paleRose,
                  ),
                ),
              _buildBottomAction(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGallery(List<Map<String, dynamic>> images) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 430,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  Container(
                    color: paleRose,
                    child: const Icon(
                      Icons.checkroom_outlined,
                      size: 80,
                      color: burgundy,
                    ),
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => currentImage = index);
                    },
                    itemBuilder: (context, index) {
                      final url = logic.text(images[index]['image_url']);
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: paleRose,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 55,
                            color: burgundy,
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: paleRose,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: burgundy,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      );
                    },
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            color: burgundy, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'PREMIUM COLLECTION',
                          style: TextStyle(
                            color: deepBurgundy,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (images.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: deepBurgundy.withOpacity(.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentImage + 1} / ${images.length.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 9),
          SizedBox(
            height: 67,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final selected = currentImage == index;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 57,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: selected ? burgundy : border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        logic.text(images[index]['image_url']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: paleRose,
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBrandAndTitle(String brand, Map<String, dynamic> item) {
    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BRAND + VERIFIED ICON + BADGE
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: burgundy,
                size: 18,
              ),
              const SizedBox(width: 7),

              // Brand name and verified icon
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        brand, // Don't use toUpperCase()
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_outlined,
                      color: burgundy,
                      size: 18,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Collection badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBD5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EXCLUSIVE ARCHIVE',
                  style: TextStyle(
                    color: Color(0xFF80612E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // OUTFIT NAME
          Text(
            logic.text(item['name'], 'Beautiful Outfit'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 29,
              height: 1.12,
              fontWeight: FontWeight.w700,
              color: deepBurgundy,
            ),
          ),

          const SizedBox(height: 9),

          // DESCRIPTION
          Text(
            logic.text(
              item['description'],
              'Discover this beautiful outfit from our collection.',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              height: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
  }

  Widget _buildPriceCard(
      double price,
      double mrp,
      double deposit,
      int discount,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF3EFEB),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT: RENTAL RATE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _priceColumn(
                    'RENTAL RATE',
                    '₹${logic.money(price)}',
                    trailing: ' / day',
                  ),

                  const SizedBox(height: 10),

                  // MRP + SAVING BADGE
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      if (mrp > 0)
                        Text(
                          'MRP: ₹${logic.money(mrp)}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8E5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$discount% SAVING',
                            style: const TextStyle(
                              color: burgundy,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // VERTICAL DIVIDER
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              color: const Color(0xFFEAE5E1),
            ),

            // RIGHT: SECURITY DEPOSIT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _priceColumn(
                    'SECURITY DEPOSIT',
                    '₹${logic.money(deposit)}',
                    icon: Icons.shield_outlined,
                  ),

                  const SizedBox(height: 10),

                  // REFUNDABLE BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF8B815F),
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '100% Refundable',
                          style: TextStyle(
                            color: Color(0xFF817655),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PRICE COLUMN
  Widget _priceColumn(String label, String value, {String trailing = '', IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: muted,
              ),
              const SizedBox(width: 5),
            ],

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        // PRICE
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: deepBurgundy,
                  fontFamily: 'serif',
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),

              if (trailing.isNotEmpty)
                TextSpan(
                  text: trailing,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFabricCard(String material, String sleeve, String colorName, Map<String, dynamic> item) {
    return _buildExpandableCard(
      title: 'Fabric and Material',
      icon: Icons.texture_outlined,
      initiallyExpanded: false,
      child: Column(
        children: [
          // FIRST ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _detailGridItem(
                  'FABRIC',
                  material,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _detailGridItem(
                  'COLOUR HERITAGE',
                  colorName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// INDIVIDUAL DETAIL ITEM
  Widget _detailGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF454044),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSizesCard(List<String> sizes, Map<String, dynamic> measurements, Map<String, dynamic> item) {
    // All standard sizes
    const List<String> allSizes = [
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      'XXXL',
    ];

// Map available sizes from the database
    final Map<String, String> availableSizes = {};

    for (final size in sizes) {
      final key = size
          .trim()
          .toUpperCase()
          .split(RegExp(r'[\s(]'))
          .first;

      availableSizes[key] = size;
    }
    return _buildExpandableCard(
      title: 'Available Sizes',
      icon: Icons.straighten_outlined,
      initiallyExpanded: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INSTRUCTION TEXT
        Text(
          logic.text(item['size_type']) == 'measurements'
              ? 'This outfit uses custom measurements.'
              : 'Select standard sizing for optimal fit adjustments :',
          style: const TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 13),

        // SIZE OPTIONS
        Wrap(
          spacing: 9,
          runSpacing: 10,
          children: allSizes.map((size) {
            final isAvailable = availableSizes.containsKey(size);

            // Keep the original database value for selection
            final actualSize = availableSizes[size] ?? size;

            final selected = isAvailable &&
                logic.selectedSize == actualSize;

            return InkWell(
              borderRadius: BorderRadius.circular(25),

              // Disable unavailable sizes
              onTap: !isAvailable
                  ? null
                  : () {
                logic.selectSize(
                  selected ? '' : actualSize,
                );
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,

                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),

                decoration: BoxDecoration(
                  color: selected
                      ? burgundy
                      : isAvailable
                      ? Colors.white
                      : const Color(0xFFF1F0EE),

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(
                    color: selected
                        ? burgundy
                        : isAvailable
                        ? const Color(0xFFE9E5E2)
                        : const Color(0xFFF1F0EE),
                  ),

                  boxShadow: selected
                      ? [
                    BoxShadow(
                      color: burgundy.withOpacity(0.12),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAvailable ? actualSize : size,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : isAvailable
                            ? deepBurgundy
                            : const Color(0xFFB8B4B0),

                        fontSize: 12,

                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),


        // MEASUREMENT INFORMATION
        if (measurements.isNotEmpty) ...[
          const SizedBox(height: 13),
          Text(
            '${measurements.length} measurement details available. '
                'Open the size guide below.',
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
      ),
    );
  }


  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool initiallyExpanded,
  }) {
    return Container(
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            5,
            16,
            18,
          ),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          visualDensity: VisualDensity.compact,

          leading: Icon(
            icon,
            color: burgundy,
            size: 19,
          ),

          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          iconColor: burgundy,
          collapsedIconColor: muted,

          children: [child],
        ),
      ),
    );
  }

  Widget _buildComingSoonSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: burgundy, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: deepBurgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFromVendor(String brand) {
    if (logic.isLoadingVendorOutfits) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 25),
        child: Center(
          child: CircularProgressIndicator(
            color: burgundy,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (logic.vendorOutfits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // SECTION HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'More from this Vendor',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: deepBurgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Curated collection by $brand',
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Visit Boutique',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // HORIZONTAL OUTFIT CARDS
          SizedBox(
            height: 315,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: logic.vendorOutfits.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final outfit = logic.vendorOutfits[index];

                return _buildVendorOutfitCard(outfit);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorOutfitCard(Map<String, dynamic> outfit,) {
    final name = logic.text(
      outfit['name'],
      'Outfit',
    );

    final category = logic.text(
      outfit['category'],
      'COLLECTION',
    );

    final price = logic.number(
      outfit['rental_price'],
    );

    final rating = outfit['rating'];

    final imageUrl = _getVendorOutfitImage(outfit);

    return GestureDetector(
      onTap: () {
        final outfitId = outfit['id']?.toString();

        if (outfitId == null || outfitId.isEmpty) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RentOutfitDetails(
              outfitId: outfitId,
              initialOutfit: outfit,
            ),
          ),
        );
      },
      child: Container(
        width: 195,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: border,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // OUTFIT IMAGE
            SizedBox(
              height: 190,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl.isEmpty
                        ? Container(
                      color: paleRose,
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 50,
                        color: burgundy,
                      ),
                    )
                        : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: paleRose,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: burgundy,
                            size: 35,
                          ),
                        );
                      },
                      loadingBuilder: (
                          context,
                          child,
                          progress,
                          ) {
                        if (progress == null) return child;

                        return Container(
                          color: paleRose,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: burgundy,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),

                  // HEART ICON
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: burgundy,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // OUTFIT INFORMATION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  11, 9, 11, 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // CATEGORY AND RATING
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF987A48),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        if (rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFAA8A3D),
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                logic.number(rating)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: deepBurgundy,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // OUTFIT NAME
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: deepBurgundy,
                      ),
                    ),

                    const Spacer(),

                    // RENTAL PRICE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${logic.money(price)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: deepBurgundy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text(
                            '/ day',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
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

  String _getVendorOutfitImage(Map<String, dynamic> outfit,) {
    final cover = logic.text(
      outfit['cover_image_url'],
    );

    if (cover.isNotEmpty) return cover;

    final images = outfit['images'];

    if (images is List && images.isNotEmpty) {
      // Prefer cover image
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          final url = logic.text(image['image_url']);

          if (url.isNotEmpty) return url;
        }
      }

      // Otherwise use first image
      for (final image in images) {
        if (image is Map) {
          final url = logic.text(image['image_url']);

          if (url.isNotEmpty) return url;
        }
      }
    }

    return '';
  }

  Widget _buildExperienceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF0E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER SECTION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDF0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: burgundy,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Experience Matters!',
                      style: TextStyle(
                        color: deepBurgundy,
                        fontFamily: 'serif',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Rent this outfit to unlock the option '
                          'to share your experience.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // DIVIDER
          const Divider(
            height: 1,
            color: Color(0xFFF0EAEA),
          ),

          const SizedBox(height: 20),

          // RATING HEADER
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RATE YOUR EXPERIENCE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),

              // DISABLED STARS
              Row(
                children: List.generate(
                  5,
                      (index) => const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE5E0E0),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // REVIEW TEXT FIELD
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F7),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFFECE6E4),
                width: 1,
              ),
            ),
            child: const TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                'Share details on comfort, fitting, and compliments...',
                hintStyle: TextStyle(
                  color: Color(0xFFC3BBBB),
                  fontSize: 13,
                  height: 1.5,
                ),
                contentPadding: EdgeInsets.all(15),
                border: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 17),

          // BOTTOM ACTIONS
          Row(
            children: [
              // ATTACH PHOTOS
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 17,
                      color: Color(0xFFC0B7B7),
                    ),

                    const SizedBox(width: 7),

                    Flexible(
                      child: Text(
                        'Attach Bridal Photos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB8AEAE),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // DISABLED SUBMIT BUTTON
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECEC),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Submit Review',
                  style: TextStyle(
                    color: Color(0xFFB8AEAE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: UserCartLogic.instance,
        builder: (context, child) {
          // Check whether this outfit is already in cart
          final isAdded = UserCartLogic.instance.contains(
            widget.outfitId,
          );

          return Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.07),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isAdded ? _openCart : _addToCart,

                      icon: Icon(
                        isAdded
                            ? Icons.check_circle_outline
                            : Icons.shopping_bag_outlined,
                        size: 18,
                      ),

                      label: Text(
                        isAdded ? 'ADDED' : 'ADD TO CART',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),

                      style: FilledButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isAdded
                        ? 'This outfit is already in your cart'
                        : 'Review rental details before checkout',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFF2EAE6), width: .7),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4A1B25).withOpacity(.025),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

}
