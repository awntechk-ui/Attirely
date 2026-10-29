import 'package:flutter/material.dart';

import '../UI_Logic/outfit_logic.dart';
import 'outfit_details.dart';




class Outfits extends StatefulWidget {
  const Outfits();

  @override
  State<Outfits> createState() => _OutfitsState();
}

class _OutfitsState extends State<Outfits> {
  late final OutfitsLogic logic;
  final TextEditingController searchController = TextEditingController();

  static const burgundy = Color(0xFF8B1E2D);
  // static const filters = ['All', 'Available', 'Unavailable'];

  @override
  void initState() {
    super.initState();
    logic = OutfitsLogic();
    logic.loadOutfits();
  }

  @override
  void dispose() {
    searchController.dispose();
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: logic,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(children: [
                Expanded(
                  child: Text('My Outfits (${logic.allCount})',
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Refresh outfits',
                  onPressed: logic.isLoading ? null : logic.loadOutfits,
                  icon: const Icon(Icons.refresh, size: 25),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: logic.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search outfits, category, brand...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE3E3E3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE3E3E3))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(0, 'All (${logic.allCount})'),
                  _filterChip(1, 'Available (${logic.availableCount})'),
                  _filterChip(2, 'Unavailable (${logic.unavailableCount})'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final selected = logic.selectedFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label), selected: selected,
        selectedColor: burgundy,
        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF555555)),
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? burgundy : const Color(0xFFE4E4E4)),
        onSelected: (_) => logic.setFilter(index),
      ),
    );
  }

  Widget _buildBody() {
    if (logic.isLoading && logic.outfits.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: burgundy));
    }
    if (logic.error != null && logic.outfits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 42, color: Colors.grey),
            const SizedBox(height: 12),
            Text(logic.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: logic.loadOutfits, child: const Text('Try again')),
          ]),
        ),
      );
    }
    final items = logic.filteredOutfits;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: logic.loadOutfits,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
          const SizedBox(height: 100),
          Icon(logic.outfits.isEmpty ? Icons.checkroom_outlined : Icons.search_off, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(child: Text(logic.outfits.isEmpty ? 'You have not uploaded any outfits yet.' : 'No outfits match your search or filter.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: logic.loadOutfits,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 11, childAspectRatio: 0.66),
        itemCount: items.length,
        itemBuilder: (context, index) => _OutfitCard(
          outfit: items[index],
          onTap: () async {
            final id = (items[index]['id'] ?? '').toString();
            if (id.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This outfit has no valid ID.')));
              return;
            }
            await Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitDetails(outfitId: id)));
            if (mounted) logic.loadOutfits();
          },
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.outfit, required this.onTap});
  final Map<String, dynamic> outfit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = outfit['is_available'] == true;
    final imageUrl = (outfit['cover_image_url'] ?? _firstImageUrl(outfit)).toString();
    final name = (outfit['name'] ?? 'Untitled outfit').toString();
    final price = outfit['rental_price'];
    final category = (outfit['category'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF0F0F0))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: Stack(fit: StackFit.expand, children: [
            imageUrl.isNotEmpty && imageUrl != 'null'
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(6)),
              child: Text(available ? 'Available' : 'Unavailable', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: available ? const Color(0xFF21834B) : const Color(0xFFD34A4A))),
            )),
          ]),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 8, 7),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
              if (category.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
              const Spacer(),
              Text('₹${_formatPrice(price)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('per rental', style: TextStyle(fontSize: 9, color: Colors.grey)),
            ]),
          ),
        ),
      ]))
    );
  }

  String _firstImageUrl(Map<String, dynamic> item) {
    final images = item['images'];
    if (images is List && images.isNotEmpty && images.first is Map) {
      return (images.first['image_url'] ?? '').toString();
    }
    return '';
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0';
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    return number == number.roundToDouble() ? number.toStringAsFixed(0) : number.toStringAsFixed(2);
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF4F1F1),
    child: const Center(child: Icon(Icons.checkroom, size: 42, color: Color(0xFFB8A6A8))),
  );
}
