import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../UI_Logic/outfit_logic.dart';
import 'add_accessories.dart';
import 'add_kids_outfit.dart';
import 'add_outfit.dart';
import 'add_men_outfit.dart';
import 'outfit_details.dart';

class Outfits extends StatefulWidget {
  const Outfits({super.key});

  @override
  State<Outfits> createState() => _OutfitsState();
}

class _OutfitsState extends State<Outfits> {
  late final OutfitsLogic logic;

  static const Color burgundy = Color(0xFF690020);
  static const Color burgundyDark = Color(0xFF4E1025);
  static const Color gold = Color(0xFFD9B66F);
  static const Color background = Color(0xFFFCF9F6);
  static const Color palePink = Color(0xFFF5E8E8);
  static const Color mutedText = Color(0xFF858080);

  static const SystemUiOverlayStyle systemStyle =
  SystemUiOverlayStyle(
    statusBarColor: burgundy,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  void initState() {
    super.initState();

    logic = OutfitsLogic();
    logic.loadCollections();

    SystemChrome.setSystemUIOverlayStyle(systemStyle);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemStyle,
          child: Container(
        color: burgundy,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            color: background,
            child: AnimatedBuilder(
              animation: logic,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Background image with a soft cream overlay.
                    Positioned.fill(
                      child: Image.asset(
                        'assets/background/login_bg.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(color: background);
                        },
                      ),
                    ),

                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFFCF9F6)
                            .withValues(alpha: 0.90),
                      ),
                    ),

                    RefreshIndicator(
                      color: burgundy,
                      backgroundColor: Colors.white,
                      displacement: 38,
                      triggerMode: RefreshIndicatorTriggerMode.onEdge,
                      onRefresh: logic.refreshOutfits,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            _buildStatistics(),
                            const SizedBox(height: 9),
                            _buildMainContent(),

                            // Space above the shared floating navigation.
                            SizedBox(
                              height: 145 +
                                  MediaQuery.of(context).viewPadding.bottom,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
          ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [burgundyDark, burgundy, burgundyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(43),
          bottomRight: Radius.circular(43),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Attirely',
                style: TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.circle, color: gold, size: 4),
              const SizedBox(width: 5),
              const Text(
                'CURATION',
                style: TextStyle(
                  color: gold,
                  fontSize: 9,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _contactSupport,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withValues(alpha: 0.65),
                    ),
                  ),
                  child: const Icon(
                    Icons.headset_mic_outlined,
                    size: 19,
                    color: gold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'CURATION STUDIO',
            style: TextStyle(
              color: gold,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Your Outfits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              height: 1.1,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Your wardrobe deserves a second life.',
            style: TextStyle(
              color: gold,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontFamily: 'serif',
            ),
          ),

          const SizedBox(height: 17),

          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _categoryCard(
                  icon: Icons.female,
                  title: 'WOMEN',
                  subtitle: "Add women's wear",
                  onTap: _openWomen,
                ),
                _categoryCard(
                  icon: Icons.male,
                  title: 'MEN',
                  subtitle: "Add men's wear",
                  onTap: _openMen,
                ),
                _categoryCard(
                  icon: Icons.diamond_outlined,
                  title: 'ACCESSORIES',
                  subtitle: 'Complete the look',
                  onTap: _openAccessories,
                ),
                _categoryCard(
                  icon: Icons.child_care_outlined,
                  title: 'KIDS',
                  subtitle: 'Add kids wear',
                  onTap: _openKids,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 126,
      margin: const EdgeInsets.only(right: 9),
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: gold.withValues(alpha: 0.40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 25),
                const SizedBox(height: 5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: burgundyDark,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATISTICS
  // =========================================================


  Widget _buildStatistics() {
    final isAccessories = logic.showAccessories;

    final total = isAccessories
        ? logic.accessoryCount
        : logic.allCount;

    final active = isAccessories
        ? logic.availableAccessoryCount
        : logic.availableCount;

    final categories = isAccessories
        ? _accessoryCategoryCount
        : _categoryCount;

    return Transform.translate(
      offset: const Offset(0, -21),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _stat(
                  'Total Listed',
                  total.toString(),
                  Icons.grid_view_rounded,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _stat(
                  isAccessories ? 'Active Accessories' : 'Active Outfits',
                  active.toString(),
                  Icons.check_circle_outline,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _stat(
                  'Categories',
                  categories.toString(),
                  Icons.category_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  int get _accessoryCategoryCount {
    return logic.accessories
        .map((item) => (item['category'] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  int get _categoryCount {
    return logic.outfits
        .map((item) => (item['category'] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: gold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  color: mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: burgundy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFFF0E9E7),
    );
  }

  // =========================================================
  // MAIN CONTENT
  // =========================================================

  Widget _buildMainContent() {
    if (logic.showAccessories) {
      if (logic.isLoadingAccessories && logic.accessories.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 65),
          child: Center(
            child: CircularProgressIndicator(color: burgundy),
          ),
        );
      }

      if (logic.accessoriesError != null &&
          logic.accessories.isEmpty) {
        return _accessoryErrorContent();
      }
    } else {
      if (logic.isLoading && logic.outfits.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 65),
          child: Center(
            child: CircularProgressIndicator(color: burgundy),
          ),
        );
      }

      if (logic.error != null && logic.outfits.isEmpty) {
        return _errorContent();
      }
    }

    return _populatedWardrobeContent();
  }

  // =========================================================
  // EMPTY WARDROBE
  // =========================================================

  Widget _emptyWardrobeContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Column(
        children: [
          const SizedBox(height: 3),
          Container(
            height: 125,
            width: 125,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFF1E7E2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: burgundy.withValues(alpha: 0.06),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.checkroom_outlined,
                size: 57,
                color: burgundy,
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Your wardrobe is waiting! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              color: burgundy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your beautiful outfits and give them '
                'a second life with Attirely.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // POPULATED COLLECTION
  // =========================================================


  Widget _populatedWardrobeContent() {
    final isAccessories = logic.showAccessories;

    final items = isAccessories
        ? logic.filteredAccessories
        : logic.filteredOutfits;

    final totalCount = isAccessories
        ? logic.accessoryCount
        : logic.allCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLLECTION SWITCHER
          Row(
            children: [
              Expanded(
                child: _collectionTab(
                  title: 'Your Collection',
                  selected: !isAccessories,
                  onTap: () => logic.selectCollection(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _collectionTab(
                  title: 'Accessories',
                  selected: isAccessories,
                  onTap: () => logic.selectCollection(true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: Text(
                  isAccessories ? 'Your Accessories' : 'Your Collection',
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palePink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount ${isAccessories ? 'Accessories' : 'Outfits'}',
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            isAccessories
                ? 'The finishing touches in your collection.'
                : 'Every piece has a story. Here’s yours.',
            style: const TextStyle(
              color: mutedText,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 12),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 45),
              child: Center(
                child: Text(
                  isAccessories
                      ? 'No accessories found.'
                      : 'No outfits found.',
                  style: const TextStyle(color: mutedText),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 11,
                mainAxisSpacing: 13,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                return isAccessories
                    ? _accessoryCard(items[index])
                    : _outfitCard(items[index]);
              },
            ),

          const SizedBox(height: 17),
          _thankYouMessage(),
        ],
      ),
    );
  }

  Widget _collectionTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? burgundy : const Color(0xFFEAE6E5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? burgundy : const Color(0xFFE0DAD8),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _accessoryCard(Map<String, dynamic> accessory) {
    final name = (accessory['name'] ?? 'Untitled accessory').toString();
    final brand = (accessory['brand'] ?? '').toString();
    final price = accessory['rental_price'];
    final active = accessory['is_available'] == true;

    final images = accessory['images'];

    String imageUrl =
    (accessory['cover_image_url'] ?? '').toString();

    if (imageUrl.isEmpty &&
        images is List &&
        images.isNotEmpty &&
        images.first is Map) {
      imageUrl = (images.first['image_url'] ?? '').toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty && imageUrl != 'null'
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(),
                )
                    : _imagePlaceholder(),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 23, 9, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                    child: Text(
                      brand.isNotEmpty
                          ? brand.toUpperCase()
                          : 'ATTIRELY ACCESSORIES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: burgundy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'ACTIVE' : 'INACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF383033),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '₹${_formatPrice(price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  '/ rental',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _editAccessory(
                  (accessory['id'] ?? '').toString(),
                ),
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 10),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: burgundy,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _accessoryErrorContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 65,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: burgundy,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            logic.accessoriesError ?? 'Unable to load accessories.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: logic.loadAccessories,
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // OUTFIT CARD
  // =========================================================

  Widget _outfitCard(Map<String, dynamic> outfit) {
    final id = (outfit['id'] ?? '').toString();
    final name = (outfit['name'] ?? 'Untitled outfit').toString();
    final brand = (outfit['brand'] ?? '').toString();
    final price = outfit['rental_price'];
    final active = outfit['is_available'] == true;

    final images = outfit['images'];

    String imageUrl =
    (outfit['cover_image_url'] ?? '').toString();

    if (imageUrl.isEmpty &&
        images is List &&
        images.isNotEmpty &&
        images.first is Map) {
      imageUrl = (images.first['image_url'] ?? '').toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty && imageUrl != 'null'
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(),
                )
                    : _imagePlaceholder(),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 23, 9, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                    child: Text(
                      brand.isNotEmpty
                          ? brand.toUpperCase()
                          : 'ATTIRELY COLLECTION',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: burgundy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'ACTIVE' : 'INACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF383033),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '₹${_formatPrice(price)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      '/ rental',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Size ${_displaySize(outfit)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _editOutfit(id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palePink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: burgundy,
                              size: 10,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: burgundy,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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
  }

  String _displaySize(Map<String, dynamic> outfit) {
    final sizes = outfit['sizes'];

    if (sizes is List && sizes.isNotEmpty) {
      return sizes.first.toString();
    }

    return '—';
  }

  Widget _imagePlaceholder() {
    return Container(
      color: palePink,
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: burgundy,
          size: 38,
        ),
      ),
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0';

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  // =========================================================
  // THANK YOU MESSAGE
  // =========================================================

  Widget _thankYouMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: palePink,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        children: [
          Icon(Icons.favorite, color: burgundy, size: 20),
          SizedBox(height: 8),
          Text(
            'Thank you for choosing Attirely ♡',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: burgundy,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Every outfit you share creates a new story. '
                'Thank you for being part of ours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _errorContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 65,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: burgundy,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            logic.error ?? 'Unable to load outfits.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: logic.loadOutfits,
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _openWomen() async {
    await Navigator.pushNamed(context, AppRoutes.addOutfit);

    if (mounted) {
      logic.loadCollections();
    }
  }

  Future<void> _openMen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMenOutfitPage(),
      ),
    );

    if (mounted) {
      logic.loadCollections();
    }
  }

  Future<void> _openAccessories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAccessoriesPage(),
      ),
    );

    if (mounted) {
      logic.loadCollections();
    }
  }

  Future<void> _openKids() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddKidsOutfitPage(),
      ),
    );

    if (mounted) {
      logic.loadCollections();
    }
  }
  Future<void> _editOutfit(String id) async {
    if (id.isEmpty) return;

    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.editListing,
      arguments: {
        'listingId': id,
        'listingType': 'outfit',
      },
    );

    if (updated == true && mounted) {
      logic.loadCollections();
    }
  }
  Future<void> _editAccessory(String id) async {
    if (id.isEmpty) return;

    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.editListing,
      arguments: {
        'listingId': id,
        'listingType': 'accessory',
      },
    );

    if (updated == true && mounted) {
      logic.loadCollections();
    }
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attirely support will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
