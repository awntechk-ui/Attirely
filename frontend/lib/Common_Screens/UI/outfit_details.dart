import 'package:flutter/material.dart';
import '../UI_Logic/outfit_details_logic.dart';
import 'add_outfit.dart';

class OutfitDetails extends StatefulWidget {
  const OutfitDetails({super.key, required this.outfitId});

  final String outfitId;

  @override
  State<OutfitDetails> createState() => _OutfitDetailsState();
}

class _OutfitDetailsState extends State<OutfitDetails> {
  late final OutfitDetailsLogic logic;

  static const burgundy = Color(0xFF800020);
  static const background = Color(0xFFFFF7F1);
  static const border = Color(0xFFF0E6E0);

  @override
  void initState() {
    super.initState();
    logic = OutfitDetailsLogic(widget.outfitId);
    logic.load();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: logic,
        builder: (context, _) {
          if (logic.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: burgundy),
            );
          }

          if (logic.error != null || logic.outfit == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      logic.error ?? 'Outfit not found.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: logic.load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final o = logic.outfit!;
          final images = logic.images;
          final sizes = (o['sizes'] is List)
              ? (o['sizes'] as List)
              .map((e) => e.toString())
              .toList()
              : <String>[];
          final measurements = o['measurements'] is Map
              ? Map<String, dynamic>.from(o['measurements'])
              : <String, dynamic>{};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 19,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Outfit Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddOutfit(
                              outfitId: widget.outfitId,
                            ),
                          ),
                        );

                        if (updated == true && mounted) {
                          await logic.load();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: burgundy,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    _gallery(images),
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment:
                            WrapCrossAlignment.center,
                            children: [
                              if ((o['brand'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                _pill(
                                  o['brand'].toString().toUpperCase(),
                                  background: const Color(0xFFF8EEE7),
                                ),
                              const Text(
                                '•',
                                style: TextStyle(color: burgundy),
                              ),
                              Text(
                                '${o['category'] ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              _pill(
                                '${o['gender'] ?? ''}',
                                background: const Color(0xFFF5ECE7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${o['name'] ?? 'Untitled outfit'}',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _price(
                                  'RENTAL PRICE',
                                  '₹${_money(o['rental_price'])}',
                                  'per rental',
                                ),
                              ),
                              Expanded(
                                child: _price(
                                  'SECURITY DEPOSIT',
                                  '₹${_money(o['security_deposit'])}',
                                  'Refundable',
                                ),
                              ),
                              Expanded(
                                child: _price(
                                  'ESTIMATED MRP',
                                  o['mrp'] == null
                                      ? '—'
                                      : '₹${_money(o['mrp'])}',
                                  'Retail price',
                                  muted: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6F7EC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF17683A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active for Rental',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  logic.isAvailable
                                      ? 'Listing appears in search and discovery feeds'
                                      : 'This outfit is currently unavailable',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (logic.isUpdatingAvailability)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: burgundy,
                              ),
                            )
                          else
                            Switch(
                              value: logic.isAvailable,
                              activeColor: burgundy,
                              onChanged: (v) async {
                                try {
                                  await logic.setAvailability(v);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeading(
                            'Specifications',
                            trailing: 'Verified Schema',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _spec('Occasion', o['occasion']),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _spec('Material', o['material']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _spec('Sleeve Style', o['sleeve']),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _colorSpec(
                                  o['color_name'],
                                  o['color_hex'],
                                ),
                              ),
                            ],
                          ),
                          if (sizes.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Available Sizing Tags',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: sizes
                                  .map(
                                    (s) => _pill(
                                  '✓  $s',
                                  background: burgundy,
                                  foreground: Colors.white,
                                ),
                              )
                                  .toList(),
                            ),
                          ],
                          if (o['size_type'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Size type: ${o['size_type']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (measurements.isNotEmpty) ...[
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeading(
                              'Garment Measurements',
                              trailing: 'Size details',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: measurements.entries
                                  .map(
                                    (e) => SizedBox(
                                  width: (MediaQuery.of(context)
                                      .size
                                      .width -
                                      64) /
                                      2,
                                  child: _measurement(e.key, e.value),
                                ),
                              )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Measurements are shown as saved for this outfit.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeading('Description & Styling Story'),
                          const SizedBox(height: 12),
                          Text(
                            '${o['description'] ?? 'No description provided.'}',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: Color(0xFF5F5551),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeading('Listing Information'),
                          const SizedBox(height: 12),
                          _infoRow('Status', '${o['status'] ?? '—'}'),
                          _infoRow(
                            'Uploaded by role',
                            '${o['role'] ?? '—'}',
                          ),
                          _infoRow('Created', _date(o['created_at'])),
                          _infoRow(
                            'Last updated',
                            _date(o['updated_at']),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: background,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: Row(
                  children: [
                    // _bottomIcon(
                    //   Icons.share_outlined,
                    //       () => ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text('Share action can be connected next.'),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 8),
                    // _bottomIcon(
                    //   Icons.calendar_month_outlined,
                    //       () => ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text(
                    //         'Booking calendar can be connected next.',
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddOutfit(
                                  outfitId: widget.outfitId,
                                ),
                              ),
                            );

                            if (updated == true && mounted) {
                              await logic.load();
                            }
                          },
                          icon: const Icon(Icons.edit_square, size: 17),
                          label: const Text(
                            'Edit Outfit Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: burgundy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _gallery(List<Map<String, dynamic>> images) {
    final selected = images.isEmpty
        ? ''
        : (images[logic.selectedImageIndex]['image_url'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 330,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                selected.isNotEmpty
                    ? Image.network(
                  selected,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                    : _placeholder(),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _pill(
                    logic.isAvailable ? '● Available' : '● Unavailable',
                    background: Colors.white,
                    foreground: logic.isAvailable
                        ? const Color(0xFF267446)
                        : Colors.red,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _pill(
                    '▧ ${images.isEmpty ? 0 : logic.selectedImageIndex + 1}/${images.length}',
                    background: Colors.black54,
                    foreground: Colors.white,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == logic.selectedImageIndex
                                ? burgundy
                                : Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final url = (images[i]['image_url'] ?? '').toString();

                  return GestureDetector(
                    onTap: () => logic.selectImage(i),
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i == logic.selectedImageIndex
                              ? burgundy
                              : border,
                          width: i == logic.selectedImageIndex ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: url.isEmpty
                          ? _placeholder()
                          : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF3EAE4),
    child: const Center(
      child: Icon(
        Icons.checkroom_outlined,
        size: 48,
        color: Color(0xFFB9A8A0),
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF5ECE7)),
    ),
    child: child,
  );

  Widget _pill(
      String text, {
        required Color background,
        Color foreground = const Color(0xFF493B36),
      }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 9,
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _price(
      String label,
      String price,
      String subtitle, {
        bool muted = false,
      }) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.black54,
            letterSpacing: .3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: muted ? Colors.grey : burgundy,
            decoration: muted && price != '—'
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, {String? trailing}) => Row(
    children: [
      const Icon(Icons.tune, size: 15, color: burgundy),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF7A5B50),
          ),
        ),
    ],
  );

  Widget _spec(String label, dynamic value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFAF2EC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        Text(
          (value == null || value.toString().isEmpty)
              ? '—'
              : value.toString(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _colorSpec(dynamic name, dynamic hex) {
    Color swatch = const Color(0xFF7B5146);
    final raw = (hex ?? '').toString().replaceFirst('#', '');

    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)) {
      swatch = Color(int.parse('FF$raw', radix: 16));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Swatch',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
                const SizedBox(height: 5),
                Text(
                  '${name ?? '—'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurement(String label, dynamic value) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8F4),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: border),
    ),
    child: Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        Text(
          '$value${value.toString().trim().isEmpty ? '' : ' in'}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _bottomIcon(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 42,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 19, color: burgundy),
      ),
    ),
  );

  String _money(dynamic value) {
    final n = double.tryParse('$value');

    if (n == null) return value?.toString() ?? '0';

    return n == n.roundToDouble()
        ? n.toStringAsFixed(0)
        : n.toStringAsFixed(2);
  }

  String _date(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return '${parsed.day.toString().padLeft(2, '0')} ${_month(parsed.month)} ${parsed.year}';
  }

  String _month(int n) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][n - 1];
}












// import 'package:flutter/material.dart';
// import '../UI_Logic/outfit_details_logic.dart';
// import 'add_outfit.dart';
//
// class OutfitDetails extends StatefulWidget {
//   const OutfitDetails({super.key, required this.outfitId});
//   final String outfitId;
//   @override
//   State<OutfitDetails> createState() => _OutfitDetailsState();
// }
//
// class _OutfitDetailsState extends State<OutfitDetails> {
//   late final OutfitDetailsLogic logic;
//   static const burgundy = Color(0xFF800020);
//   static const background = Color(0xFFFFF7F1);
//   static const border = Color(0xFFF0E6E0);
//   @override
//   void initState() { super.initState(); logic = OutfitDetailsLogic(widget.outfitId); logic.load(); }
//   @override
//   void dispose() { logic.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: background,
//     body: SafeArea(child: AnimatedBuilder(animation: logic, builder: (context, _) {
//       if (logic.isLoading) return const Center(child: CircularProgressIndicator(color: burgundy));
//       if (logic.error != null || logic.outfit == null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey), const SizedBox(height: 12),
//         Text(logic.error ?? 'Outfit not found.', textAlign: TextAlign.center), const SizedBox(height: 14),
//         ElevatedButton(onPressed: logic.load, child: const Text('Try again')),
//       ])));
//       final o = logic.outfit!;
//       final images = logic.images;
//       final sizes = (o['sizes'] is List) ? (o['sizes'] as List).map((e) => e.toString()).toList() : <String>[];
//       final measurements = o['measurements'] is Map ? Map<String, dynamic>.from(o['measurements']) : <String, dynamic>{};
//       return Column(children: [
//         Padding(padding: const EdgeInsets.fromLTRB(8, 4, 12, 8), child: Row(children: [
//           IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 19)),
//           const Expanded(child: Center(child: Text('Outfit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
//           TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit screen can be connected next.'))), icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Edit'), style: TextButton.styleFrom(foregroundColor: burgundy)),
//         ])),
//         Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), children: [
//           _gallery(images), const SizedBox(height: 12),
//           _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
//               if ((o['brand'] ?? '').toString().trim().isNotEmpty) _pill(o['brand'].toString().toUpperCase(), background: const Color(0xFFF8EEE7)),
//               const Text('•', style: TextStyle(color: burgundy)), Text('${o['category'] ?? ''}', style: const TextStyle(fontSize: 12)),
//               _pill('${o['gender'] ?? ''}', background: const Color(0xFFF5ECE7)),
//             ]), const SizedBox(height: 8),
//             Text('${o['name'] ?? 'Untitled outfit'}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, height: 1.15)),
//             const SizedBox(height: 14),
//             Row(children: [
//               Expanded(child: _price('RENTAL PRICE', '₹${_money(o['rental_price'])}', 'per rental')),
//               Expanded(child: _price('SECURITY DEPOSIT', '₹${_money(o['security_deposit'])}', 'Refundable')),
//               Expanded(child: _price('ESTIMATED MRP', o['mrp'] == null ? '—' : '₹${_money(o['mrp'])}', 'Retail price', muted: true)),
//             ]),
//           ])), const SizedBox(height: 12),
//           _card(child: Row(children: [
//             Container(width: 38, height: 38, decoration: const BoxDecoration(color: Color(0xFFE6F7EC), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Color(0xFF17683A))),
//             const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Active for Rental', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 3), Text(logic.isAvailable ? 'Listing appears in search and discovery feeds' : 'This outfit is currently unavailable', style: const TextStyle(fontSize: 10, color: Colors.black54))])),
//             if (logic.isUpdatingAvailability) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: burgundy)) else Switch(value: logic.isAvailable, activeColor: burgundy, onChanged: (v) async { try { await logic.setAvailability(v); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }),
//           ])), const SizedBox(height: 12),
//           _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             _sectionHeading('Specifications', trailing: 'Verified Schema'), const SizedBox(height: 12),
//             Row(children: [Expanded(child: _spec('Occasion', o['occasion'])), const SizedBox(width: 8), Expanded(child: _spec('Material', o['material']))]), const SizedBox(height: 8),
//             Row(children: [Expanded(child: _spec('Sleeve Style', o['sleeve'])), const SizedBox(width: 8), Expanded(child: _colorSpec(o['color_name'], o['color_hex']))]),
//             if (sizes.isNotEmpty) ...[const SizedBox(height: 14), const Text('Available Sizing Tags', style: TextStyle(fontSize: 11, color: Colors.black54)), const SizedBox(height: 8), Wrap(spacing: 7, runSpacing: 7, children: sizes.map((s) => _pill('✓  $s', background: burgundy, foreground: Colors.white)).toList())],
//             if (o['size_type'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Size type: ${o['size_type']}', style: const TextStyle(fontSize: 10, color: Colors.black54))),
//           ])), const SizedBox(height: 12),
//           if (measurements.isNotEmpty) ...[_card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             _sectionHeading('Garment Measurements', trailing: 'Size details'), const SizedBox(height: 12),
//             Wrap(spacing: 8, runSpacing: 8, children: measurements.entries.map((e) => SizedBox(width: (MediaQuery.of(context).size.width - 64) / 2, child: _measurement(e.key, e.value))).toList()),
//             const SizedBox(height: 8), const Text('Measurements are shown as saved for this outfit.', style: TextStyle(fontSize: 10, color: Colors.black54, fontStyle: FontStyle.italic)),
//           ])), const SizedBox(height: 12)],
//           _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _sectionHeading('Description & Styling Story'), const SizedBox(height: 12), Text('${o['description'] ?? 'No description provided.'}', style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF5F5551))) ])),
//           const SizedBox(height: 12),
//           _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ _sectionHeading('Listing Information'), const SizedBox(height: 12), _infoRow('Status', '${o['status'] ?? '—'}'), _infoRow('Uploaded by role', '${o['role'] ?? '—'}'), _infoRow('Created', _date(o['created_at'])), _infoRow('Last updated', _date(o['updated_at'])) ])),
//           const SizedBox(height: 16),
//         ])),
//         Container(padding: const EdgeInsets.fromLTRB(14, 10, 14, 12), decoration: const BoxDecoration(color: background, border: Border(top: BorderSide(color: border))), child: Row(children: [
//           _bottomIcon(Icons.share_outlined, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share action can be connected next.')))), const SizedBox(width: 8),
//           _bottomIcon(Icons.calendar_month_outlined, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking calendar can be connected next.')))), const SizedBox(width: 8),
//           Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(onPressed: () async {
//             final updated = await Navigator.push<bool>(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => AddOutfit(
//                   outfitId: widget.outfitId,
//                 ),
//               ),
//             );
//
//             if (updated == true && mounted) {
//               await logic.load();
//             }
//           }, icon: const Icon(Icons.edit_square, size: 17), label: const Text('Edit Outfit Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: burgundy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)))),
//         ])),
//       ]);
//     })),
//   );
//
//   Widget _gallery(List<Map<String, dynamic>> images) {
//     final selected = images.isEmpty ? '' : (images[logic.selectedImageIndex]['image_url'] ?? '').toString();
//     return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)), clipBehavior: Clip.antiAlias, child: Column(children: [
//       SizedBox(height: 330, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
//         selected.isNotEmpty ? Image.network(selected, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()) : _placeholder(),
//         Positioned(top: 10, left: 10, child: _pill(logic.isAvailable ? '● Available' : '● Unavailable', background: Colors.white, foreground: logic.isAvailable ? const Color(0xFF267446) : Colors.red)),
//         Positioned(top: 10, right: 10, child: _pill('▧ ${images.isEmpty ? 0 : logic.selectedImageIndex + 1}/${images.length}', background: Colors.black54, foreground: Colors.white)),
//         if (images.length > 1) Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: i == logic.selectedImageIndex ? burgundy : Colors.white70, shape: BoxShape.circle))))),
//       ])),
//       if (images.isNotEmpty) SizedBox(height: 72, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), itemCount: images.length, separatorBuilder: (_, __) => const SizedBox(width: 7), itemBuilder: (_, i) { final url = (images[i]['image_url'] ?? '').toString(); return GestureDetector(onTap: () => logic.selectImage(i), child: Container(width: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: i == logic.selectedImageIndex ? burgundy : border, width: i == logic.selectedImageIndex ? 2 : 1)), clipBehavior: Clip.antiAlias, child: url.isEmpty ? _placeholder() : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))); })),
//     ]));
//   }
//   Widget _placeholder() => Container(color: const Color(0xFFF3EAE4), child: const Center(child: Icon(Icons.checkroom_outlined, size: 48, color: Color(0xFFB9A8A0))));
//   Widget _card({required Widget child}) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF5ECE7))), child: child);
//   Widget _pill(String text, {required Color background, Color foreground = const Color(0xFF493B36)}) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(fontSize: 9, color: foreground, fontWeight: FontWeight.w600)));
//   Widget _price(String label, String price, String subtitle, {bool muted = false}) => Padding(padding: const EdgeInsets.only(right: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 2, style: const TextStyle(fontSize: 8, color: Colors.black54, letterSpacing: .3)), const SizedBox(height: 5), Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: muted ? Colors.grey : burgundy, decoration: muted && price != '—' ? TextDecoration.lineThrough : null)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.black54))]));
//   Widget _sectionHeading(String title, {String? trailing}) => Row(children: [const Icon(Icons.tune, size: 15, color: burgundy), const SizedBox(width: 7), Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))), if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 9, color: Color(0xFF7A5B50)))]);
//   Widget _spec(String label, dynamic value) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFAF2EC), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)), const SizedBox(height: 5), Text((value == null || value.toString().isEmpty) ? '—' : value.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]));
//   Widget _colorSpec(dynamic name, dynamic hex) { Color swatch = const Color(0xFF7B5146); final raw = (hex ?? '').toString().replaceFirst('#', ''); if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)) swatch = Color(int.parse('FF$raw', radix: 16)); return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFAF2EC), borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Color Swatch', style: TextStyle(fontSize: 9, color: Colors.black54)), const SizedBox(height: 5), Text('${name ?? '—'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])), Container(width: 16, height: 16, decoration: BoxDecoration(color: swatch, shape: BoxShape.circle, border: Border.all(color: Colors.black12))) ])); }
//   Widget _measurement(String label, dynamic value) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFFFF8F4), borderRadius: BorderRadius.circular(9), border: Border.all(color: border)), child: Column(children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.black54)), const SizedBox(height: 5), Text('$value${value.toString().trim().isEmpty ? '' : ' in'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))]));
//   Widget _infoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]));
//   Widget _bottomIcon(IconData icon, VoidCallback onTap) => Material(color: Colors.white, borderRadius: BorderRadius.circular(11), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(11), child: Container(width: 42, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: border)), child: Icon(icon, size: 19, color: burgundy))));
//   String _money(dynamic value) { final n = double.tryParse('$value'); if (n == null) return value?.toString() ?? '0'; return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2); }
//   String _date(dynamic value) { if (value == null) return '—'; final parsed = DateTime.tryParse(value.toString()); if (parsed == null) return value.toString(); return '${parsed.day.toString().padLeft(2, '0')} ${_month(parsed.month)} ${parsed.year}'; }
//   String _month(int n) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][n-1];
// }