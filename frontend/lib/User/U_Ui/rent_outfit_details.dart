
import 'package:flutter/material.dart';

import 'user_cart.dart';
import '../U_API_Routes/u_outfit_api_routes.dart';
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
  State<RentOutfitDetails> createState() =>
      _RentOutfitDetailsPageState();
}

class _RentOutfitDetailsPageState extends State<RentOutfitDetails> {
  static const Color burgundy = Color(0xFF8B1E2D);
  static const Color background = Color(0xFFFFF8F5);

  Map<String, dynamic>? outfit;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    outfit = widget.initialOutfit;
    loadDetails();
  }

  Future<void> loadDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await UOutfitApiRoutes.getOutfitDetails(
        widget.outfitId,
      );

      if (!mounted) return;

      setState(() {
        outfit = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _images() {
    final result = <Map<String, dynamic>>[];
    final rawImages = outfit?['images'];

    if (rawImages is List) {
      for (final image in rawImages) {
        if (image is Map) {
          result.add(Map<String, dynamic>.from(image));
        }
      }
    }

    if (result.isEmpty) {
      final cover = outfit?['cover_image_url']?.toString() ?? '';
      if (cover.isNotEmpty) result.add({'image_url': cover});
    }

    return result;
  }

  List<String> _sizes() {
    final raw = outfit?['sizes'];

    if (raw is List) {
      return raw.map((value) => value.toString()).toList();
    }

    return [];
  }

  Map<String, dynamic> _measurements() {
    final raw = outfit?['measurements'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  void _addToCart() {
    if (outfit == null) return;

    UserCartLogic.instance.addOutfit(outfit!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outfit added to your cart'),
        duration: Duration(seconds: 1),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && outfit == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(color: burgundy),
        ),
      );
    }

    if (outfit == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Outfit Details'),
          backgroundColor: background,
          foregroundColor: burgundy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: burgundy),
                const SizedBox(height: 12),
                Text(
                  errorMessage ?? 'Unable to load outfit.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loadDetails,
                  style: FilledButton.styleFrom(backgroundColor: burgundy),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = outfit!;
    final name = item['name']?.toString() ?? 'Outfit';
    final price = _number(item['rental_price']);
    final deposit = _number(item['security_deposit']);
    final images = _images();
    final sizes = _sizes();
    final measurements = _measurements();
    final added = UserCartLogic.instance.contains(widget.outfitId);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: burgundy,
        elevation: 0,
        title: const Text('Outfit Details'),
        actions: [
          IconButton(
            tooltip: 'My Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserCartPage(),
                ),
              );
            },
            icon: AnimatedBuilder(
              animation: UserCartLogic.instance,
              builder: (context, _) {
                final count = UserCartLogic.instance.itemCount;

                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 112),
            children: [
              SizedBox(
                height: 380,
                child: images.isEmpty
                    ? Container(
                  color: const Color(0xFFF0E5E1),
                  child: const Icon(
                    Icons.checkroom_outlined,
                    size: 90,
                    color: burgundy,
                  ),
                )
                    : PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final url =
                        images[index]['image_url']?.toString() ?? '';

                    return url.isEmpty
                        ? Container(
                      color: const Color(0xFFF0E5E1),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 60,
                      ),
                    )
                        : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF0E5E1),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    if ((item['brand']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text('Brand: ${item['brand']}'),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      '₹${price.toStringAsFixed(2)} rental price',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Security deposit: ₹${deposit.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.brown.shade600),
                    ),
                    const Divider(height: 32),
                    _section('Description',
                        item['description']?.toString() ?? 'No description provided.'),
                    _section('Category',
                        item['category']?.toString() ?? 'Not specified'),
                    _section('Occasion',
                        item['occasion']?.toString() ?? 'Not specified'),
                    _section('Gender',
                        item['gender']?.toString() ?? 'Not specified'),
                    _section('Material',
                        item['material']?.toString() ?? 'Not specified'),
                    _section('Sleeve',
                        item['sleeve']?.toString() ?? 'Not specified'),
                    _section('Colour',
                        item['color_name']?.toString() ?? 'Not specified'),
                    const SizedBox(height: 12),
                    const Text(
                      'Available Sizes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sizes.isEmpty)
                      const Text('Size information not provided.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sizes
                            .map(
                              (size) => Chip(
                            label: Text(size),
                            backgroundColor: Colors.white,
                          ),
                        )
                            .toList(),
                      ),
                    if (measurements.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Measurements',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...measurements.entries.map(
                            (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (errorMessage != null)
                      Text(
                        'Latest refresh failed: $errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (isLoading)
                      const LinearProgressIndicator(color: burgundy),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: added
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserCartPage(),
                            ),
                          );
                        }
                            : _addToCart,
                        icon: Icon(
                          added ? Icons.check : Icons.add_shopping_cart,
                        ),
                        label: Text(added ? 'View Cart' : 'Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: burgundy,
                          side: const BorderSide(color: burgundy),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (!added) {
                            UserCartLogic.instance.addOutfit(item);
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserCartPage(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: burgundy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Go to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(value),
        ],
      ),
    );
  }
}
