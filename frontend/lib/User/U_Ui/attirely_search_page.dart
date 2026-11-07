
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../U_Ui_Logic/home_logic.dart';

class AttirelySearchPage extends StatefulWidget {
  final HomeLogic logic;

  const AttirelySearchPage({
    super.key,
    required this.logic,
  });

  @override
  State<AttirelySearchPage> createState() =>
      _AttirelySearchPageState();
}

class _AttirelySearchPageState extends State<AttirelySearchPage> {
  static const Color burgundy = Color(0xFF8E2945);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);
  static const Color pale = Color(0xFFF2E5E8);

  final TextEditingController _controller = TextEditingController();

  final List<String> _recentSearches = [];

  final List<String> _popularSearches = [
    'Lehenga',
    'Saree',
    'Wedding',
    'Party wear',
    'Anarkali',
    'Western',
  ];

  final List<String> _categories = [
    'All',
    'Ethnic',
    'Lehenga',
    'Saree',
    'Western',
    'Men',
  ];

  String _query = '';
  String _selectedCategory = 'All';
  String _sort = 'Recommended';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _value(
      Map<String, dynamic> outfit,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = outfit[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  double? _price(Map<String, dynamic> outfit) {
    for (final key in [
      'rental_price',
      'rentalPrice',
      'price',
    ]) {
      final value = outfit[key];
      if (value != null) {
        return double.tryParse(
          value.toString().replaceAll(',', '').replaceAll('₹', '').trim(),
        );
      }
    }
    return null;
  }

  String? _image(Map<String, dynamic> outfit) {
    final cover = outfit['cover_image_url'];

    if (cover != null && cover.toString().trim().isNotEmpty) {
      return cover.toString();
    }

    final images = outfit['images'];

    if (images is List && images.isNotEmpty && images.first is Map) {
      final url = images.first['image_url'];
      if (url != null && url.toString().trim().isNotEmpty) {
        return url.toString();
      }
    }

    return null;
  }

  List<Map<String, dynamic>> get _results {
    final all = widget.logic.featuredOutfits;
    final query = _query.toLowerCase().trim();

    final filtered = all.where((outfit) {
      final fields = [
        outfit['name'],
        outfit['title'],
        outfit['outfit_name'],
        outfit['category'],
        outfit['subcategory'],
        outfit['occasion'],
        outfit['description'],
        outfit['brand_name'],
      ];

      final matchesQuery = query.isEmpty ||
          fields.any(
                (value) =>
            value != null &&
                value.toString().toLowerCase().contains(query),
          );

      final category = _selectedCategory.toLowerCase();

      final matchesCategory = category == 'all' ||
          [
            outfit['category'],
            outfit['subcategory'],
          ].any(
                (value) =>
            value != null &&
                value.toString().toLowerCase().contains(category),
          );

      return matchesQuery && matchesCategory;
    }).toList();

    if (_sort == 'Price: Low to High') {
      filtered.sort(
            (a, b) => (_price(a) ?? double.infinity)
            .compareTo(_price(b) ?? double.infinity),
      );
    } else if (_sort == 'Price: High to Low') {
      filtered.sort(
            (a, b) => (_price(b) ?? 0).compareTo(_price(a) ?? 0),
      );
    }

    return filtered;
  }

  void _search(String value) {
    setState(() {
      _query = value;
    });
  }

  void _selectSearch(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(
      offset: value.length,
    );

    setState(() {
      _query = value;

      if (value.trim().isNotEmpty &&
          !_recentSearches.contains(value)) {
        _recentSearches.insert(0, value);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  void _openPreview(Map<String, dynamic> outfit) {
    final id = outfit['id'] ?? outfit['outfit_id'];

    if (id == null || id.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit ID is missing. Unable to open details.'),
          backgroundColor: burgundy,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.outfitDetails,
      arguments: {
        'outfitId': id.toString(),
        'initialOutfit': outfit,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: burgundy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cream,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // SEARCH HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      burgundy,
                      Color(0xFF64172F),
                      darkBurgundy,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Find your perfect look',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 51,
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _search,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search outfits, occasions, styles...',
                          hintStyle: TextStyle(
                            color: burgundy.withOpacity(0.55),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: burgundy,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _controller.clear();
                              _search('');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: burgundy,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: AnimatedBuilder(
                  animation: widget.logic,
                  builder: (context, _) {
                    if (widget.logic.isLoadingCatalogue &&
                        widget.logic.featuredOutfits.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: burgundy,
                        ),
                      );
                    }

                    if (widget.logic.catalogueError != null &&
                        widget.logic.featuredOutfits.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: burgundy,
                                size: 42,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.logic.catalogueError!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: widget.logic.loadCatalogue,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 30,
                      ),
                      children: [
                        // RECENT SEARCHES
                        if (_query.isEmpty && _recentSearches.isNotEmpty) ...[
                          _sectionTitle('Recent Searches'),
                          const SizedBox(height: 10),
                          ..._recentSearches.map(
                                (item) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.history_rounded,
                                color: burgundy,
                              ),
                              title: Text(
                                item,
                                style: const TextStyle(
                                  color: darkBurgundy,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.north_west_rounded,
                                size: 17,
                                color: burgundy,
                              ),
                              onTap: () => _selectSearch(item),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // POPULAR SEARCHES
                        if (_query.isEmpty) ...[
                          _sectionTitle('Popular Searches'),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              children: _popularSearches.map((item) {
                                return ActionChip(
                                  label: Text(item),
                                  avatar: const Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: burgundy,
                                  ),
                                  backgroundColor: pale,
                                  side: BorderSide(
                                    color: gold.withOpacity(0.8),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: burgundy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () => _selectSearch(item),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // CATEGORY FILTERS
                        _sectionTitle(
                          _query.isEmpty ? 'Explore by Category' : 'Categories',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 39,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(width: 9),
                            itemBuilder: (context, index) {
                              final item = _categories[index];
                              final selected = _selectedCategory == item;

                              return ChoiceChip(
                                label: Text(item),
                                selected: selected,
                                selectedColor: burgundy,
                                backgroundColor: pale,
                                side: BorderSide(
                                  color: selected ? burgundy : gold,
                                ),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : burgundy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = item;
                                  });
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // RESULTS TITLE + SORT
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _query.isEmpty
                                      ? 'Discover Outfits'
                                      : 'Search Results (${_results.length})',
                                  style: const TextStyle(
                                    color: darkBurgundy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                initialValue: _sort,
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: burgundy,
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    _sort = value;
                                  });
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'Recommended',
                                    child: Text('Recommended'),
                                  ),
                                  PopupMenuItem(
                                    value: 'Price: Low to High',
                                    child: Text('Price: Low to High'),
                                  ),
                                  PopupMenuItem(
                                    value: 'Price: High to Low',
                                    child: Text('Price: High to Low'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (_results.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(35),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  size: 55,
                                  color: burgundy,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No outfits found',
                                  style: TextStyle(
                                    color: darkBurgundy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try another style, category or occasion.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF92717A),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _results.length,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.64,
                              ),
                              itemBuilder: (context, index) {
                                final outfit = _results[index];
                                return _buildOutfitCard(outfit);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: darkBurgundy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    final name = _value(
      outfit,
      ['name', 'title', 'outfit_name'],
      fallback: 'Rental Outfit',
    );

    final brand = _value(
      outfit,
      ['brand_name', 'store_name', 'vendor_name'],
      fallback: 'Attirely Collection',
    );

    final image = _image(outfit);
    final price = _price(outfit);

    final discount = _value(
      outfit,
      ['discount_percentage', 'discount_percent'],
    );

    return GestureDetector(
      onTap: () => _openPreview(outfit),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: gold.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: burgundy.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image == null
                      ? Container(
                    color: pale,
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: burgundy,
                      size: 45,
                    ),
                  )
                      : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: pale,
                      child: const Icon(
                        Icons.checkroom_rounded,
                        color: burgundy,
                        size: 45,
                      ),
                    ),
                  ),
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: burgundy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  const Positioned(
                    top: 7,
                    right: 7,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xCCFFFFFE),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: burgundy,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkBurgundy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF92717A),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    if (price != null)
                      Text(
                        '₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} / rental',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
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
}
