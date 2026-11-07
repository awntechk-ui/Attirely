
import 'dart:io';

import 'package:flutter/material.dart';

import '../UI_Logic/edit_listing_logic.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;
  final String listingType;

  const EditListingPage({
    super.key,
    required this.listingId,
    required this.listingType,
  });

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late final EditListingLogic logic;

  static const burgundy = Color(0xFF800020);
  static const darkBurgundy = Color(0xFF4E1022);
  static const background = Color(0xFFFFF9F5);
  static const border = Color(0xFFE8DDD8);
  static const gold = Color(0xFFD4AF37);

  bool get isOutfit => widget.listingType.toLowerCase() == 'outfit';

  @override
  void initState() {
    super.initState();

    logic = EditListingLogic(
      listingId: widget.listingId,
      listingType: widget.listingType,
    );

    logic.loadListing();
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
      body: SafeArea(
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            if (logic.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: burgundy),
              );
            }

            if (logic.errorMessage != null &&
                logic.nameController.text.isEmpty) {
              return _errorView();
            }

            return Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _introCard(),
                        const SizedBox(height: 22),

                        _sectionTitle('Listing photographs'),
                        const SizedBox(height: 10),
                        _photoSection(),

                        const SizedBox(height: 26),
                        _sectionTitle('Basic information'),
                        const SizedBox(height: 14),

                        _field(
                          'Listing name',
                          logic.nameController,
                          hint: 'Enter listing name',
                        ),
                        _field(
                          'Description',
                          logic.descriptionController,
                          hint: 'Describe your listing',
                          maxLines: 4,
                        ),
                        _field(
                          'Brand',
                          logic.brandController,
                          hint: 'Enter brand name',
                        ),

                        if (isOutfit) ...[
                          const SizedBox(height: 22),
                          _sectionTitle('Outfit details'),
                          const SizedBox(height: 14),
                          _dropdown(
                            'Gender',
                            logic.gender,
                            const ['men', 'women', 'kids', 'unisex'],
                                (v) => setState(() => logic.gender = v),
                          ),
                          _field(
                            'Category',
                            _controllerForValue(logic.category),
                            hint: 'Enter outfit category',
                            onChanged: (v) => logic.category = v,
                          ),
                          _field(
                            'Occasion',
                            _controllerForValue(logic.occasion),
                            hint: 'Enter occasion',
                            onChanged: (v) => logic.occasion = v,
                          ),
                          _field(
                            'Sleeve',
                            _controllerForValue(logic.sleeve),
                            hint: 'Enter sleeve style',
                            onChanged: (v) => logic.sleeve = v,
                          ),
                          _field(
                            'Material',
                            logic.materialController,
                            hint: 'Enter material',
                          ),
                          _dropdown(
                            'Size type',
                            logic.sizeType,
                            const ['standard', 'measurements'],
                                (v) => setState(() => logic.sizeType = v),
                          ),
                          if (logic.sizeType == 'standard') ...[
                            _sizeSelector(),
                          ] else ...[
                            _field('Bust', logic.bustController),
                            _field('Waist', logic.waistController),
                            _field('Hip', logic.hipController),
                            _field('Shoulder', logic.shoulderController),
                            _field('Length', logic.lengthController),
                          ],
                        ] else ...[
                          const SizedBox(height: 22),
                          _sectionTitle('Accessory details'),
                          const SizedBox(height: 14),
                          _field(
                            'Category',
                            _controllerForValue(logic.category),
                            hint: 'Enter category',
                            onChanged: (v) => logic.category = v,
                          ),
                          _field(
                            'Accessory type',
                            _controllerForValue(logic.accessoryType),
                            hint: 'Enter accessory type',
                            onChanged: (v) => logic.accessoryType = v,
                          ),
                          _dropdown(
                            'Collection',
                            logic.collection,
                            const ['men', 'women', 'all'],
                                (v) => setState(() => logic.collection = v),
                          ),
                          _field(
                            'Quantity',
                            logic.quantityController,
                            keyboardType: TextInputType.number,
                          ),
                          _field(
                            'Material',
                            logic.materialController,
                            hint: 'Enter material',
                          ),
                        ],

                        const SizedBox(height: 22),
                        _sectionTitle('Pricing'),
                        const SizedBox(height: 14),
                        _field(
                          'Rental price (₹)',
                          logic.rentalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _field(
                          'MRP (₹)',
                          logic.mrpController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        _field(
                          'Refundable security deposit (₹)',
                          logic.securityDepositController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),

                        const SizedBox(height: 22),
                        _sectionTitle('Appearance'),
                        const SizedBox(height: 14),
                        _field(
                          'Colour name',
                          _controllerForValue(logic.colorName),
                          hint: 'E.g. Burgundy',
                          onChanged: (v) => logic.colorName = v,
                        ),
                        _field(
                          'Colour hex code',
                          _controllerForValue(logic.colorHex),
                          hint: 'E.g. #800020',
                          onChanged: (v) => logic.colorHex = v,
                        ),

                        if (logic.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            logic.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),
                        _saveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TOP BAR
  // --------------------------------------------------

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Listing',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: darkBurgundy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [darkBurgundy, burgundy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR LISTING, YOUR WAY',
            style: TextStyle(
              color: gold,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOutfit ? 'Refine your outfit.' : 'Perfect your accessory.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Update the details and keep your listing looking its best.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // PHOTOS
  // --------------------------------------------------

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${logic.totalPhotos}/5 photos',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...logic.existingImages.asMap().entries.map((entry) {
                final image = entry.value;
                return _photoTile(
                  image['image_url']?.toString() ?? '',
                  onRemove: () => logic.removeExistingImage(entry.key),
                );
              }),
              ...logic.newPhotos.asMap().entries.map((entry) {
                return _photoTile(
                  entry.value.path,
                  isLocal: true,
                  onRemove: () => logic.removeNewPhoto(entry.key),
                );
              }),
              if (logic.canAddPhotos)
                GestureDetector(
                  onTap: logic.pickPhotos,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EAE5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: burgundy, size: 25),
                        SizedBox(height: 6),
                        Text('Add photo',
                            style: TextStyle(
                                color: burgundy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'You can keep, remove or add photos. At least one photo is required.',
          style: TextStyle(color: Colors.black45, fontSize: 10),
        ),
      ],
    );
  }

  Widget _photoTile(
      String path, {
        bool isLocal = false,
        required VoidCallback onRemove,
      }) {
    return Container(
      width: 100,
      height: 105,
      margin: const EdgeInsets.only(right: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isLocal)
            Image.file(File(path), fit: BoxFit.cover)
          else
            Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFF0E8E4),
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: burgundy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FORM COMPONENTS
  // --------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: darkBurgundy,
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        String? hint,
        int maxLines = 1,
        TextInputType? keyboardType,
        ValueChanged<String>? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkBurgundy,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black38,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: burgundy, width: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
      String label,
      String? value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    final safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkBurgundy,
            ),
          ),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: safeValue,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: border),
              ),
            ),
            hint: Text('Select $label',
                style: const TextStyle(fontSize: 12)),
            items: items
                .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item,
                  style: const TextStyle(fontSize: 12)),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sizeSelector() {
    const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available sizes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkBurgundy,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final selected = logic.selectedSizes.contains(size);

              return ChoiceChip(
                label: Text(size),
                selected: selected,
                selectedColor: burgundy,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : darkBurgundy,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                side: const BorderSide(color: border),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      logic.selectedSizes.add(size);
                    } else {
                      logic.selectedSizes.remove(size);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SAVE BUTTON
  // --------------------------------------------------

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: logic.isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: burgundy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: burgundy.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: gold, width: 1),
          ),
        ),
        child: logic.isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Save Changes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final success = await logic.saveChanges();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing updated successfully.'),
          backgroundColor: burgundy,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(logic.errorMessage ?? 'Unable to update listing.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: burgundy, size: 38),
            const SizedBox(height: 12),
            Text(
              logic.errorMessage ?? 'Unable to load listing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: logic.loadListing,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  TextEditingController _controllerForValue(String? value) {
    return TextEditingController(text: value ?? '');
  }
}
