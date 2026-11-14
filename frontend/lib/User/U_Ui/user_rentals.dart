import 'package:flutter/material.dart';
import 'package:attirely/User/U_Ui/user_bottom_navigation.dart';
import '../../app_routes.dart';

import 'package:attirely/User/U_Ui/rent_outfit_details.dart';
import 'user_cart.dart';
import '../U_Ui_Logic/user_cart_logic.dart';
import '../U_Ui_Logic/user_rentals_logic.dart';

class UserRentals extends StatefulWidget {
  final VoidCallback onBackToHome;

  const UserRentals({
    super.key,
    required this.onBackToHome,
  });

  @override
  State<UserRentals> createState() => _UserRentalsState();
}

class _UserRentalsState extends State<UserRentals> {
  late final UserRentalsLogic logic;
  final TextEditingController _searchController = TextEditingController();

  static const Color burgundy = Color(0xFF52051F);
  static const Color burgundyLight = Color(0xFF76243A);
  static const Color background = Color(0xFFFCFAF7);
  static const Color muted = Color(0xFF81716F);
  static const Color gold = Color(0xFFC49A55);

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    logic = UserRentalsLogic();
    logic.loadOutfits();
    UserCartLogic.instance.loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    logic.dispose();
    super.dispose();
  }

  double _price(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _visibleOutfits() {
    final query = _searchQuery.trim().toLowerCase();
    return logic.filteredOutfits.where((outfit) {
      if (query.isEmpty) return true;
      final searchable = [
        outfit['name'],
        outfit['brand'],
        outfit['category'],
        outfit['gender'],
        outfit['occasion'],
        outfit['material'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  int get _activeFilterCount {
    var count = 0;
    if (logic.selectedCategory != 'All') count++;
    if (logic.selectedGender != 'All') count++;
    return count;
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserCartPage()),
    );
  }

  // Each main tab owns its own page, background and bottom navigation.
  void _openTab(int index) {
    switch (index) {
      case 0:
        widget.onBackToHome();
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.userOutfits);
        break;
      case 2:
      // This is already the Rentals tab.
        break;
      case 3:
        _openCart();
        break;
    }
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

  Future<void> _showFilters() async {
    var category = logic.selectedCategory;
    var gender = logic.selectedGender;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget options(String title, List<String> values, String selected,
                ValueChanged<String> onSelect) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: burgundy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((value) {
                      final active = value == selected;
                      return ChoiceChip(
                        label: Text(value),
                        selected: active,
                        onSelected: (_) => onSelect(value),
                        selectedColor: burgundy,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : burgundy,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                            color: active ? burgundy : const Color(0xFFE7DCD6)),
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9CBC5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Refine your search',
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: burgundy)),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              category = 'All';
                              gender = 'All';
                            });
                          },
                          child: const Text('Reset',
                              style: TextStyle(color: burgundy)),
                        )
                      ],
                    ),
                    const SizedBox(height: 18),
                    options('Category', logic.categories, category,
                            (value) => setSheetState(() => category = value)),
                    const SizedBox(height: 22),
                    options('Gender', logic.genders, gender,
                            (value) => setSheetState(() => gender = value)),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          logic.setCategory(category);
                          logic.setGender(gender);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Show Outfits',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: burgundy,
            size: 20,
          ),
          onPressed: widget.onBackToHome,
        ),
        title: const Text(
          'Discover Rentals',
          style: TextStyle(
            color: burgundy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: background,
          image: DecorationImage(
            image: AssetImage('assets/background/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            if (logic.isLoading && logic.outfits.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: burgundy));
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

            final outfits = _visibleOutfits();

            return RefreshIndicator(
                color: burgundy,
                onRefresh: () => logic.loadOutfits(refresh: true),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _searchBar(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                          child: _featuredBanner(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 17, 16, 0),
                          child: _filterButton(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Explore All Outfits',
                                        style: TextStyle(
                                            color: burgundy,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4)),
                                    const SizedBox(height: 3),
                                    const Text('Handpicked couture from premier ateliers',
                                        style: TextStyle(color: muted, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (outfits.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('No outfits match your search or filters.',
                                style: TextStyle(color: muted)),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverGrid(
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 370,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) => _outfitCard(outfits[index]),
                              childCount: outfits.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 2, 16, 24),
                          child: _GuaranteeBanner(),
                        ),
                      ),
                    ],
                  ),
                )
            );
          },
        ),
      ),
      bottomNavigationBar: UserBottomNavigation(
        currentIndex: 2,
        onTap: _openTab,
      ),
    );
  }


  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF0E8E3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            const Icon(Icons.search, color: muted, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(fontSize: 13, color: burgundy),
                decoration: const InputDecoration(
                  hintText: 'Search outfits, styles, designers...',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close, color: muted, size: 19),
              ),
          ],
        ),
      ),
    );
  }

  Widget _featuredBanner() {
    final featured = logic.outfits.first;
    final image = featured['cover_image_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openDetails(featured),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: burgundy,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
                color: burgundy.withValues(alpha: 0.14),
                blurRadius: 15,
                offset: const Offset(0, 7))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (image.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 155,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: burgundyLight),
                ),
              )
            else
              const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 155,
                  child: ColoredBox(color: burgundyLight)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      burgundy,
                      burgundy.withValues(alpha: 0.98),
                      burgundy.withValues(alpha: 0.88),
                      burgundy.withValues(alpha: 0.12),
                    ],
                    stops: const [0, 0.48, 0.69, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 22,
              bottom: 18,
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: burgundyLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB8787C)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFFFFD58B), size: 7),
                        SizedBox(width: 6),
                        Text('TRENDING THIS WEEK',
                            style: TextStyle(
                                color: Color(0xFFFFD9A0),
                                fontSize: 9,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Most Loved Styles',
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Curated couture pieces crafted for your special moments.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Color(0xFFF5E5E6), fontSize: 12, height: 1.35),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Outfit',
                            style: TextStyle(
                                color: burgundy,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: burgundy, size: 16),
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

  Widget _filterButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: burgundy,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: burgundy.withValues(alpha: 0.2),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune_rounded, color: Color(0xFFFFD58B), size: 20),
            const SizedBox(width: 12),
            const Text('Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (_activeFilterCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFD58B),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$_activeFilterCount Active',
                    style: const TextStyle(
                        color: burgundy,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _outfitCard(Map<String, dynamic> outfit) {
    final imageUrl = outfit['cover_image_url']?.toString() ?? '';
    final name = outfit['name']?.toString() ?? 'Outfit';
    final brand = outfit['brand']?.toString().trim() ?? '';
    final price = _price(outfit['rental_price']);
    final mrp = _price(outfit['mrp']);
    final discount = mrp > price && mrp > 0
        ? (((mrp - price) / mrp) * 100).round()
        : 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(outfit),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFEFE7E2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _outfitImage(imageUrl),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.isNotEmpty
                            ? brand.toUpperCase()
                            : 'COUTURE COLLECTION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF21191A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      // const Spacer(),
                      const Divider(height: 12, color: Color(0xFFF0EBE7)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Rental price on left
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: burgundy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                '/day',
                                style: TextStyle(color: muted, fontSize: 13),
                              ),
                            ],
                          ),

                          // MRP on right
                          if (mrp > price && mrp > 0)
                            Text(
                              '₹${mrp.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outfitImage(String url) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFF0E5E1),
        child: Center(
          child: Icon(Icons.checkroom_outlined, size: 48, color: burgundy),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFF0E5E1),
        child: Center(
          child: Icon(Icons.broken_image_outlined, size: 42, color: burgundy),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFF0E5E1),
          child: Center(
              child: CircularProgressIndicator(
                  color: burgundy, strokeWidth: 2)),
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
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: burgundy)),
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
class _GuaranteeBanner extends StatelessWidget {
  const _GuaranteeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFECE5DE)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFF7E8C9),
            child: Icon(Icons.verified_outlined,
                color: Color(0xFF8B672D), size: 23),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Couture Dry Cleaning & Fit Guarantee',
                    style: TextStyle(
                        color: Color(0xFF52051F),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                SizedBox(height: 4),
                Text(
                  'Complimentary insurance & doorstep delivery included with every luxury rental.',
                  style: TextStyle(
                      color: Color(0xFF81716F), fontSize: 10, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// import 'package:attirely/User/U_Ui/rent_outfit_details.dart';
// import 'user_cart.dart';
// import '../U_Ui_Logic/user_cart_logic.dart';
// import '../U_Ui_Logic/user_rentals_logic.dart';
//
// class UserRentals extends StatefulWidget {
//   final VoidCallback onBackToHome;
//
//   const UserRentals({
//     super.key,
//     required this.onBackToHome,
//   });
//
//   @override
//   State<UserRentals> createState() => _UserRentalsState();
// }
//
// class _UserRentalsState extends State<UserRentals> {
//   late final UserRentalsLogic logic;
//   final TextEditingController _searchController = TextEditingController();
//
//   static const Color burgundy = Color(0xFF52051F);
//   static const Color burgundyLight = Color(0xFF76243A);
//   static const Color background = Color(0xFFFCFAF7);
//   static const Color muted = Color(0xFF81716F);
//   static const Color gold = Color(0xFFC49A55);
//
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     logic = UserRentalsLogic();
//     logic.loadOutfits();
//     UserCartLogic.instance.loadCart();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     logic.dispose();
//     super.dispose();
//   }
//
//   double _price(dynamic value) {
//     if (value is num) return value.toDouble();
//     return double.tryParse(value?.toString() ?? '') ?? 0;
//   }
//
//   List<Map<String, dynamic>> _visibleOutfits() {
//     final query = _searchQuery.trim().toLowerCase();
//     return logic.filteredOutfits.where((outfit) {
//       if (query.isEmpty) return true;
//       final searchable = [
//         outfit['name'],
//         outfit['brand'],
//         outfit['category'],
//         outfit['gender'],
//         outfit['occasion'],
//         outfit['material'],
//       ].where((value) => value != null).join(' ').toLowerCase();
//       return searchable.contains(query);
//     }).toList();
//   }
//
//   int get _activeFilterCount {
//     var count = 0;
//     if (logic.selectedCategory != 'All') count++;
//     if (logic.selectedGender != 'All') count++;
//     return count;
//   }
//
//   void _openCart() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const UserCartPage()),
//     );
//   }
//
//   void _openDetails(Map<String, dynamic> outfit) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => RentOutfitDetails(
//           outfitId: outfit['id'].toString(),
//           initialOutfit: outfit,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _showFilters() async {
//     var category = logic.selectedCategory;
//     var gender = logic.selectedGender;
//
//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: background,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
//       ),
//       builder: (sheetContext) {
//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             Widget options(String title, List<String> values, String selected,
//                 ValueChanged<String> onSelect) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                           color: burgundy,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 10),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: values.map((value) {
//                       final active = value == selected;
//                       return ChoiceChip(
//                         label: Text(value),
//                         selected: active,
//                         onSelected: (_) => onSelect(value),
//                         selectedColor: burgundy,
//                         backgroundColor: Colors.white,
//                         labelStyle: TextStyle(
//                           color: active ? Colors.white : burgundy,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         side: BorderSide(
//                             color: active ? burgundy : const Color(0xFFE7DCD6)),
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               );
//             }
//
//             return SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 42,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFD9CBC5),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Text('Refine your search',
//                               style: TextStyle(
//                                   fontSize: 21,
//                                   fontWeight: FontWeight.w700,
//                                   color: burgundy)),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             setSheetState(() {
//                               category = 'All';
//                               gender = 'All';
//                             });
//                           },
//                           child: const Text('Reset',
//                               style: TextStyle(color: burgundy)),
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 18),
//                     options('Category', logic.categories, category,
//                             (value) => setSheetState(() => category = value)),
//                     const SizedBox(height: 22),
//                     options('Gender', logic.genders, gender,
//                             (value) => setSheetState(() => gender = value)),
//                     const SizedBox(height: 28),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 52,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: burgundy,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30)),
//                         ),
//                         onPressed: () {
//                           logic.setCategory(category);
//                           logic.setGender(gender);
//                           Navigator.pop(sheetContext);
//                         },
//                         child: const Text('Show Outfits',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w700, fontSize: 15)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             color: burgundy,
//             size: 20,
//           ),
//           onPressed: widget.onBackToHome,
//         ),
//         title: const Text(
//           'Discover Rentals',
//           style: TextStyle(
//             color: burgundy,
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//             letterSpacing: -0.4,
//           ),
//         ),
//         centerTitle: false,
//       ),
//
//       body: AnimatedBuilder(
//         animation: logic,
//         builder: (context, _) {
//           if (logic.isLoading && logic.outfits.isEmpty) {
//             return const Center(
//                 child: CircularProgressIndicator(color: burgundy));
//           }
//
//           if (logic.errorMessage != null && logic.outfits.isEmpty) {
//             return _message(
//               icon: Icons.cloud_off_outlined,
//               title: 'Could not load outfits',
//               subtitle: logic.errorMessage!,
//               buttonText: 'Try Again',
//               onPressed: () => logic.loadOutfits(refresh: true),
//             );
//           }
//
//           if (logic.outfits.isEmpty) {
//             return _message(
//               icon: Icons.checkroom_outlined,
//               title: 'No outfits available yet',
//               subtitle: 'Published and available outfits will appear here.',
//               buttonText: 'Refresh',
//               onPressed: () => logic.loadOutfits(refresh: true),
//             );
//           }
//
//           final outfits = _visibleOutfits();
//
//           return RefreshIndicator(
//             color: burgundy,
//             onRefresh: () => logic.loadOutfits(refresh: true),
//             child: SafeArea(
//               child: CustomScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 slivers: [
//                   SliverToBoxAdapter(
//                     child: _searchBar(),
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
//                       child: _featuredBanner(),
//                     ),
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 17, 16, 0),
//                       child: _filterButton(),
//                     ),
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text('Explore All Outfits',
//                                     style: TextStyle(
//                                         color: burgundy,
//                                         fontSize: 19,
//                                         fontWeight: FontWeight.w700,
//                                         letterSpacing: -0.4)),
//                                 const SizedBox(height: 3),
//                                 const Text('Handpicked couture from premier ateliers',
//                                     style: TextStyle(color: muted, fontSize: 11)),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   if (outfits.isEmpty)
//                     const SliverFillRemaining(
//                       hasScrollBody: false,
//                       child: Center(
//                         child: Text('No outfits match your search or filters.',
//                             style: TextStyle(color: muted)),
//                       ),
//                     )
//                   else
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//                       sliver: SliverGrid(
//                         gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 14,
//                           mainAxisExtent: 370,
//                         ),
//                         delegate: SliverChildBuilderDelegate(
//                               (context, index) => _outfitCard(outfits[index]),
//                           childCount: outfits.length,
//                         ),
//                       ),
//                     ),
//                   const SliverToBoxAdapter(
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(16, 2, 16, 140),
//                       child: _GuaranteeBanner(),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           );
//         },
//       ),
//     );
//   }
//
//
//   Widget _searchBar() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
//       child: Container(
//         height: 54,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(color: const Color(0xFFF0E8E3)),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.025),
//                 blurRadius: 10,
//                 offset: const Offset(0, 3))
//           ],
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 18),
//             const Icon(Icons.search, color: muted, size: 21),
//             const SizedBox(width: 12),
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) => setState(() => _searchQuery = value),
//                 style: const TextStyle(fontSize: 13, color: burgundy),
//                 decoration: const InputDecoration(
//                   hintText: 'Search outfits, styles, designers...',
//                   hintStyle: TextStyle(color: muted, fontSize: 14),
//                   border: InputBorder.none,
//                   isCollapsed: true,
//                 ),
//               ),
//             ),
//             if (_searchQuery.isNotEmpty)
//               IconButton(
//                 visualDensity: VisualDensity.compact,
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() => _searchQuery = '');
//                 },
//                 icon: const Icon(Icons.close, color: muted, size: 19),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _featuredBanner() {
//     final featured = logic.outfits.first;
//     final image = featured['cover_image_url']?.toString() ?? '';
//
//     return GestureDetector(
//       onTap: () => _openDetails(featured),
//       child: Container(
//         height: 210,
//         decoration: BoxDecoration(
//           color: burgundy,
//           borderRadius: BorderRadius.circular(19),
//           boxShadow: [
//             BoxShadow(
//                 color: burgundy.withValues(alpha: 0.14),
//                 blurRadius: 15,
//                 offset: const Offset(0, 7))
//           ],
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: Stack(
//           children: [
//             if (image.isNotEmpty)
//               Positioned(
//                 right: 0,
//                 top: 0,
//                 bottom: 0,
//                 width: 155,
//                 child: Image.network(
//                   image,
//                   fit: BoxFit.cover,
//                   alignment: Alignment.topCenter,
//                   errorBuilder: (_, __, ___) =>
//                   const ColoredBox(color: burgundyLight),
//                 ),
//               )
//             else
//               const Positioned(
//                   right: 0,
//                   top: 0,
//                   bottom: 0,
//                   width: 155,
//                   child: ColoredBox(color: burgundyLight)),
//             Positioned.fill(
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                     colors: [
//                       burgundy,
//                       burgundy.withValues(alpha: 0.98),
//                       burgundy.withValues(alpha: 0.88),
//                       burgundy.withValues(alpha: 0.12),
//                     ],
//                     stops: const [0, 0.48, 0.69, 1],
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               left: 18,
//               top: 22,
//               bottom: 18,
//               width: 225,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: burgundyLight,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: const Color(0xFFB8787C)),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.circle, color: Color(0xFFFFD58B), size: 7),
//                         SizedBox(width: 6),
//                         Text('TRENDING THIS WEEK',
//                             style: TextStyle(
//                                 color: Color(0xFFFFD9A0),
//                                 fontSize: 9,
//                                 letterSpacing: 0.8,
//                                 fontWeight: FontWeight.w700)),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 13),
//                   const Text(
//                     'Most Loved Styles',
//                     maxLines: 2,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       height: 1.1,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 7),
//                   const Text(
//                     'Curated couture pieces crafted for your special moments.',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         color: Color(0xFFF5E5E6), fontSize: 12, height: 1.35),
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
//                     decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(25)),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text('View Outfit',
//                             style: TextStyle(
//                                 color: burgundy,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700)),
//                         SizedBox(width: 8),
//                         Icon(Icons.arrow_forward, color: burgundy, size: 16),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _filterButton() {
//     return SizedBox(
//       height: 50,
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _showFilters,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: burgundy,
//           foregroundColor: Colors.white,
//           elevation: 4,
//           shadowColor: burgundy.withValues(alpha: 0.2),
//           shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.tune_rounded, color: Color(0xFFFFD58B), size: 20),
//             const SizedBox(width: 12),
//             const Text('Apply Filters',
//                 style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
//             if (_activeFilterCount > 0) ...[
//               const SizedBox(width: 10),
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                     color: const Color(0xFFFFD58B),
//                     borderRadius: BorderRadius.circular(20)),
//                 child: Text('$_activeFilterCount Active',
//                     style: const TextStyle(
//                         color: burgundy,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700)),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _outfitCard(Map<String, dynamic> outfit) {
//     final imageUrl = outfit['cover_image_url']?.toString() ?? '';
//     final name = outfit['name']?.toString() ?? 'Outfit';
//     final brand = outfit['brand']?.toString().trim() ?? '';
//     final price = _price(outfit['rental_price']);
//     final mrp = _price(outfit['mrp']);
//     final discount = mrp > price && mrp > 0
//         ? (((mrp - price) / mrp) * 100).round()
//         : 0;
//
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(15),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () => _openDetails(outfit),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             border: Border.all(color: const Color(0xFFEFE7E2)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.025),
//                 blurRadius: 9,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     _outfitImage(imageUrl),
//                   ],
//                 ),
//               ),
//               SizedBox(
//                 height: 100,
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         brand.isNotEmpty
//                             ? brand.toUpperCase()
//                             : 'COUTURE COLLECTION',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: muted,
//                           fontSize: 10,
//                           letterSpacing: 0.8,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         name,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: Color(0xFF21191A),
//                           fontSize: 18,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                       // const Spacer(),
//                       const Divider(height: 12, color: Color(0xFFF0EBE7)),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           // Rental price on left
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 '₹${price.toStringAsFixed(0)}',
//                                 style: const TextStyle(
//                                   color: burgundy,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w900,
//                                 ),
//                               ),
//                               const SizedBox(width: 3),
//                               const Text(
//                                 '/day',
//                                 style: TextStyle(color: muted, fontSize: 13),
//                               ),
//                             ],
//                           ),
//
//                           // MRP on right
//                           if (mrp > price && mrp > 0)
//                             Text(
//                               '₹${mrp.toStringAsFixed(0)}',
//                               style: const TextStyle(
//                                 color: muted,
//                                 fontSize: 12,
//                                 decoration: TextDecoration.lineThrough,
//                               ),
//                             ),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _outfitImage(String url) {
//     if (url.isEmpty) {
//       return const ColoredBox(
//         color: Color(0xFFF0E5E1),
//         child: Center(
//           child: Icon(Icons.checkroom_outlined, size: 48, color: burgundy),
//         ),
//       );
//     }
//
//     return Image.network(
//       url,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => const ColoredBox(
//         color: Color(0xFFF0E5E1),
//         child: Center(
//           child: Icon(Icons.broken_image_outlined, size: 42, color: burgundy),
//         ),
//       ),
//       loadingBuilder: (context, child, progress) {
//         if (progress == null) return child;
//         return const ColoredBox(
//           color: Color(0xFFF0E5E1),
//           child: Center(
//               child: CircularProgressIndicator(
//                   color: burgundy, strokeWidth: 2)),
//         );
//       },
//     );
//   }
//
//   Widget _message({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String buttonText,
//     required VoidCallback onPressed,
//   }) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 58, color: burgundy),
//             const SizedBox(height: 16),
//             Text(title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontSize: 19,
//                     fontWeight: FontWeight.bold,
//                     color: burgundy)),
//             const SizedBox(height: 8),
//             Text(subtitle, textAlign: TextAlign.center),
//             const SizedBox(height: 18),
//             FilledButton(
//               onPressed: onPressed,
//               style: FilledButton.styleFrom(backgroundColor: burgundy),
//               child: Text(buttonText),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class _GuaranteeBanner extends StatelessWidget {
//   const _GuaranteeBanner();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F2ED),
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: const Color(0xFFECE5DE)),
//       ),
//       child: const Row(
//         children: [
//           CircleAvatar(
//             radius: 23,
//             backgroundColor: Color(0xFFF7E8C9),
//             child: Icon(Icons.verified_outlined,
//                 color: Color(0xFF8B672D), size: 23),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Couture Dry Cleaning & Fit Guarantee',
//                     style: TextStyle(
//                         color: Color(0xFF52051F),
//                         fontWeight: FontWeight.w700,
//                         fontSize: 12)),
//                 SizedBox(height: 4),
//                 Text(
//                   'Complimentary insurance & doorstep delivery included with every luxury rental.',
//                   style: TextStyle(
//                       color: Color(0xFF81716F), fontSize: 10, height: 1.35),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }