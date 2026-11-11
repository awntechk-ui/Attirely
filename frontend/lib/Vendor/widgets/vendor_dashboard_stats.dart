
import 'package:flutter/material.dart';

class VendorDashboardStats extends StatelessWidget {
  final int activeOutfits;
  final int totalOutfits;
  final int activeAccessories;
  final int totalAccessories;
  final int totalListings;

  const VendorDashboardStats({
    super.key,
    required this.activeOutfits,
    required this.totalOutfits,
    required this.activeAccessories,
    required this.totalAccessories,
    required this.totalListings,
  });


  @override
  Widget build(BuildContext context) {
    const double centreTile = 92;
    const double cardHeight = 112;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth;
        final cardWidth = (boardWidth - 12) / 2;
        final boardHeight = cardHeight * 2;

        final centreLeft = (boardWidth - centreTile) / 2;
        final centreTop = (boardHeight - centreTile) / 2;

        return SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: _statTile(
                  cardWidth,
                  cardHeight,
                  activeOutfits,
                  'Active Outfits',
                  Icons.checkroom_rounded,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _statTile(
                  cardWidth,
                  cardHeight,
                  totalOutfits,
                  'Total Outfits',
                  Icons.inventory_2_outlined,
                  alignRight: true,
                ),
              ),
              Positioned(
                left: 0,
                top: cardHeight,
                child: _statTile(
                  cardWidth,
                  cardHeight,
                  activeAccessories,
                  'Active Accessories',
                  Icons.shopping_bag_outlined,
                ),
              ),
              Positioned(
                right: 0,
                top: cardHeight,
                child: _statTile(
                  cardWidth,
                  cardHeight,
                  totalAccessories,
                  'Total Accessories',
                  Icons.style_outlined,
                  alignRight: true,
                ),
              ),

              // Centre Total Listings card
              Positioned(
                left: centreLeft,
                top: centreTop,
                child: Container(
                  width: centreTile,
                  height: centreTile,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C1026),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xFFE9D8B0),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C1026).withOpacity(0.28),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.widgets_rounded,
                        color: Color(0xFFE9D8B0),
                        size: 19,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalListings',
                        style: const TextStyle(
                          color: Color(0xFFFFFCF8),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TOTAL LISTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE9D8B0),
                          fontSize: 8,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  Widget _statTile(
      double width,
      double height,
      int value,
      String label,
      IconData icon, {
        bool alignRight = false,
      }
  ) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8).withOpacity(0.98),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE9D8B0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1026).withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
  crossAxisAlignment: alignRight
  ? CrossAxisAlignment.end
      : CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE9D8B0).withOpacity(0.55),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8E2945),
              size: 18,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF4C1026),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
  textAlign: alignRight ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8E2945),
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
