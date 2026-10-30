import 'package:flutter/material.dart';

class OutfitHorizontalCard extends StatelessWidget {
  final Map<String, dynamic> outfit;
  final VoidCallback? onTap;

  const OutfitHorizontalCard({
    super.key,
    required this.outfit,
    this.onTap,
  });

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);


  String _textValue(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = outfit[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String? get _imageUrl {
    final cover = outfit['cover_image_url'];
    if (cover != null && cover.toString().trim().isNotEmpty) {
      return cover.toString();
    }

    final images = outfit['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;

      if (first is Map) {
        final url = first['image_url'];
        if (url != null && url.toString().trim().isNotEmpty) {
          return url.toString();
        }
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

    final price = _textValue(
      ['rental_price', 'rentalPrice', 'price'],
      fallback: '',
    );

    final imageUrl = _imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 172,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withOpacity(0.65)),
          boxShadow: [
            BoxShadow(
              color: burgundy.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 155,
              width: double.infinity,
              child: imageUrl == null
                  ? Container(
                color: const Color(0xFFF5EDEF),
                child: const Icon(
                  Icons.checkroom,
                  color: burgundy,
                  size: 48,
                ),
              )
                  : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF5EDEF),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: burgundy,
                    size: 40,
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFFF5EDEF),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: burgundy,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (price.isNotEmpty)
                    Text(
                      '₹$price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      'Price on details',
                      style: TextStyle(
                        color: burgundy.withOpacity(0.65),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}