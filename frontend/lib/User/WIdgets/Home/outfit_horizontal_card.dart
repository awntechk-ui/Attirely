
import 'package:flutter/material.dart';

class OutfitHorizontalCard extends StatelessWidget {
  final Map<String, dynamic> outfit;
  final VoidCallback? onTap;

  const OutfitHorizontalCard({
    super.key,
    required this.outfit,
    this.onTap,
  });

  static const Color burgundy = Color(0xFF8E2945);
  static const Color gold = Color(0xFFD7B66D);
  static const Color cream = Color(0xFFFFFCF8);
  static const Color pale = Color(0xFFF2E5E8);

  String _textValue(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = outfit[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  double? _numberValue(List<String> keys) {
    for (final key in keys) {
      final value = outfit[key];
      if (value == null) continue;

      final parsed = double.tryParse(
        value.toString().replaceAll(',', '').replaceAll('₹', '').trim(),
      );

      if (parsed != null) return parsed;
    }
    return null;
  }

  String _price(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  String? get _imageUrl {
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

  @override
  Widget build(BuildContext context) {
    final name = _textValue(
      ['name', 'title', 'outfit_name'],
      fallback: 'Rental Outfit',
    );

    final price = _numberValue(['rental_price', 'rentalPrice', 'price']);
    final mrp = _numberValue(['original_price', 'mrp', 'originalPrice']);
    final discount = _numberValue([
      'discount_percentage',
      'discount_percent',
    ]);

    final imageUrl = _imageUrl;
    final width = ((MediaQuery.of(context).size.width - 40 - 20) / 2.5)
        .clamp(112.0, 150.0);

    return Material(
      color: cream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: burgundy.withOpacity(0.07),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: width * 1.12,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl == null
                        ? Image.asset(
                      'assets/images/dummy.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: pale,
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: burgundy,
                          size: 38,
                        ),
                      ),
                    )
                        : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/dummy.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: pale,
                          child: const Icon(
                            Icons.checkroom_rounded,
                            color: burgundy,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    if (discount != null && discount > 0)
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
                            '${_price(discount)}% OFF',
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 11,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (price != null)
                        Text(
                          '₹${_price(price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: burgundy,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      if (mrp != null && price != null && mrp > price)
                        Text(
                          '₹${_price(mrp)}',
                          style: TextStyle(
                            color: burgundy.withOpacity(0.55),
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
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
}
