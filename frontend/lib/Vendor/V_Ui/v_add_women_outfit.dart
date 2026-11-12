
import 'dart:io';

import 'package:flutter/material.dart';

import '../V_UI_Logic/add_women_logic.dart';

class VAddWomenOutfit extends StatefulWidget {
  final String? outfitId;

  const VAddWomenOutfit({
    super.key,
    this.outfitId,
  });

  bool get isEditMode => outfitId != null;

  @override
  State<VAddWomenOutfit> createState() => _VAddWomenOutfitState();
}

class _VAddWomenOutfitState extends State<VAddWomenOutfit> {
  late final AddWomenLogic logic;

  static const burgundy = Color(0xFF800020);
  static const deepBurgundy = Color(0xFF581329);
  static const ivory = Color(0xFFFFF9F5);
  static const gold = Color(0xFFD4AF37);
  static const muted = Color(0xFF8A7775);
  static const border = Color(0xFFE9DFDA);

  @override
  void initState() {
    super.initState();
    logic = AddWomenLogic();

    if (widget.isEditMode) {
      logic.loadOutfitForEditing(widget.outfitId!);
    }
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            if (logic.isLoadingOutfit) {
              return const Center(
                child: CircularProgressIndicator(color: burgundy),
              );
            }

            if (logic.loadingError != null) {
              return _loadingError();
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
                        _hero(),
                        const SizedBox(height: 25),
                        _sectionHeading(
                          '01',
                          'The photographs',
                          'First impressions begin with beautiful pictures.',
                        ),
                        const SizedBox(height: 13),
                        _photoSection(),
                        const SizedBox(height: 27),
                        _sectionHeading(
                          '02',
                          'Outfit identity',
                          'Give this piece its own story.',
                        ),
                        const SizedBox(height: 15),
                        _label('Outfit name', required: true),
                        _field(
                          logic.nameController,
                          'E.g. Rose embroidered lehenga',
                        ),
                        const SizedBox(height: 15),
                        _label('Description', required: true),
                        _field(
                          logic.descriptionController,
                          'Describe the design, detailing and finish...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 15),
                        _label('Collection', required: true),
                        _dropdown(
                          value: logic.selectedGender,
                          hint: 'Choose collection',
                          items: logic.genders,
                          onChanged: (value) {
                            logic.selectedGender = value;
                            logic.notifyListeners();
                          },
                        ),
                        const SizedBox(height: 15),
                        _label('Brand / Designer'),
                        _field(
                          logic.brandController,
                          'E.g. Attirely Studio',
                        ),
                        const SizedBox(height: 15),
                        _label('Style category', required: true),
                        _dropdown(
                          value: logic.selectedCategory,
                          hint: 'Choose category',
                          items: logic.categories,
                          onChanged: (value) {
                            logic.selectedCategory = value;
                            logic.notifyListeners();
                          },
                        ),
                        const SizedBox(height: 15),
                        _label('Occasion', required: true),
                        _dropdown(
                          value: logic.selectedOccasion,
                          hint: 'Choose occasion',
                          items: logic.occasions,
                          onChanged: (value) {
                            logic.selectedOccasion = value;
                            logic.notifyListeners();
                          },
                        ),
                        const SizedBox(height: 27),
                        _sectionHeading(
                          '03',
                          'Rental & pricing',
                          'Set a rental price and refundable deposit.',
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _priceField(
                                'Rental price',
                                logic.rentalPriceController,
                                '₹ 2,500',
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _priceField(
                                'MRP',
                                logic.mrpController,
                                '₹ 8,000',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _priceField(
                          'Security deposit',
                          logic.securityDepositController,
                          '₹ 5,000',
                          required: true,
                        ),
                        const SizedBox(height: 27),
                        _sectionHeading(
                          '04',
                          'Colour & details',
                          'Help customers find their perfect match.',
                        ),
                        const SizedBox(height: 15),
                        _label('Outfit colour'),
                        _colorSelector(),
                        const SizedBox(height: 15),
                        _label('Material', required: true),
                        _dropdown(
                          value: logic.materialController.text.isEmpty
                              ? null
                              : logic.materialController.text,
                          hint: 'Choose material',
                          items: logic.materials,
                          onChanged: (value) {
                            logic.materialController.text = value ?? '';
                            logic.notifyListeners();
                          },
                        ),
                        const SizedBox(height: 15),
                        _label('Sleeve style', required: true),
                        _dropdown(
                          value: logic.selectedSleeve,
                          hint: 'Choose sleeve style',
                          items: logic.sleeves,
                          onChanged: (value) {
                            logic.selectedSleeve = value;
                            logic.notifyListeners();
                          },
                        ),
                        const SizedBox(height: 27),
                        _sectionHeading(
                          '05',
                          'Size & fit',
                          'Choose standard sizes or enter measurements.',
                        ),
                        const SizedBox(height: 15),
                        _sizeSelector(),
                        const SizedBox(height: 17),
                        if (logic.sizeType == 'standard')
                          _standardSizes()
                        else
                          _measurements(),
                        const SizedBox(height: 30),
                        _publishButton(),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Your listing will be reviewed according to Attirely policies.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
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
    );
  }

  // =========================================================
  // TOP BAR
  // =========================================================

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
              color: deepBurgundy,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.isEditMode ? 'EDIT LISTING' : 'NEW LISTING',
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.isEditMode
                      ? 'Refine your collection'
                      : 'Women’s collection',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 45),
        ],
      ),
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepBurgundy, burgundy, Color(0xFF9C405B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE ART OF DRESSING',
                  style: TextStyle(
                    color: Color(0xFFE9D8B0),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isEditMode
                      ? 'Give your piece a fresh touch.'
                      : 'Every outfit deserves its moment.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'serif',
                    fontSize: 21,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a listing that makes someone fall in love with the look.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFE9D8B0),
            size: 43,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION HEADING
  // =========================================================

  Widget _sectionHeading(
      String number,
      String title,
      String subtitle,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: burgundy,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: deepBurgundy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LABELS AND FIELDS
  // =========================================================

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: deepBurgundy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          children: required
              ? const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: burgundy),
            ),
          ]
              : null,
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: deepBurgundy,
        fontSize: 13,
      ),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _priceField(
      String label,
      TextEditingController controller,
      String hint, {
        bool required = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        _field(
          controller,
          hint,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB6A9A4),
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
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
        borderSide: const BorderSide(
          color: burgundy,
          width: 1.4,
        ),
      ),
    );
  }

  // =========================================================
  // DROPDOWN
  // =========================================================

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: _inputDecoration(''),
      hint: Text(
        hint,
        style: const TextStyle(
          color: Color(0xFFB6A9A4),
          fontSize: 12,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: burgundy,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              color: deepBurgundy,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // =========================================================
  // PHOTOS
  // =========================================================

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: logic.canAddMorePhotos ? logic.pickPhotos : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 23),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: burgundy.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EDEF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: burgundy,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add outfit photographs',
                  style: TextStyle(
                    color: deepBurgundy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${logic.totalImageCount} / ${AddWomenLogic.maxPhotos} selected',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG or WebP · Maximum 5 MB each',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (logic.totalImageCount > 0) ...[
          const SizedBox(height: 13),
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: logic.totalImageCount,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isExisting =
                    index < logic.existingImages.length;

                final imageUrl = isExisting
                    ? logic.existingImages[index]['image_url']
                    ?.toString() ??
                    ''
                    : '';

                final newIndex =
                    index - logic.existingImages.length;

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isExisting
                          ? Image.network(
                        imageUrl,
                        width: 91,
                        height: 91,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(),
                      )
                          : Image.file(
                        logic.selectedPhotos[newIndex],
                        width: 91,
                        height: 91,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          if (isExisting) {
                            logic.removeExistingImage(index);
                          } else {
                            logic.removePhoto(newIndex);
                          }
                        },
                        child: Container(
                          width: 23,
                          height: 23,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: burgundy,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'COVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 91,
      height: 91,
      color: const Color(0xFFF4E9E8),
      child: const Icon(
        Icons.broken_image_outlined,
        color: burgundy,
      ),
    );
  }

  // =========================================================
  // COLOUR
  // =========================================================

  Widget _colorSelector() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: logic.selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected colour',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    logic.selectedColorName,
                    style: const TextStyle(
                      color: deepBurgundy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: burgundy,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose outfit colour',
                  style: TextStyle(
                    color: deepBurgundy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Select the closest colour to your product.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 22),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logic.colorOptions.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                  ),
                  itemBuilder: (context, index) {
                    final option = logic.colorOptions[index];
                    final color = option['color'] as Color;
                    final name = option['name'] as String;
                    final selected = logic.selectedColor == color;

                    return GestureDetector(
                      onTap: () {
                        logic.setColor(
                          color: color,
                          name: name,
                        );
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? burgundy : border,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: selected
                            ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.55
                              ? Colors.black
                              : Colors.white,
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SIZE
  // =========================================================

  Widget _sizeSelector() {
    return Row(
      children: [
        Expanded(
          child: _sizeModeButton(
            'Standard sizes',
            'standard',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _sizeModeButton(
            'Measurements',
            'measurements',
          ),
        ),
      ],
    );
  }

  Widget _sizeModeButton(String title, String value) {
    final selected = logic.sizeType == value;

    return GestureDetector(
      onTap: () => logic.setSizeType(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? burgundy : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? burgundy : border,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : deepBurgundy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _standardSizes() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: logic.sizes.map((size) {
        final selected = logic.selectedSizes.contains(size);

        return GestureDetector(
          onTap: () => logic.toggleSize(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 53,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? burgundy : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? burgundy : border,
              ),
            ),
            child: Text(
              size,
              style: TextStyle(
                color: selected ? Colors.white : deepBurgundy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _measurements() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _measurementField(
                'Bust',
                logic.bustController,
                '36',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _measurementField(
                'Waist',
                logic.waistController,
                '30',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _measurementField(
                'Hip',
                logic.hipController,
                '38',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _measurementField(
                'Shoulder',
                logic.shoulderController,
                '15',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _measurementField(
          'Length',
          logic.lengthController,
          '52',
        ),
        const SizedBox(height: 7),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Measurements are in inches.',
            style: TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _measurementField(
      String label,
      TextEditingController controller,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: true),
        _field(
          controller,
          hint,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PUBLISH
  // =========================================================

  Widget _publishButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: logic.isPublishing ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: burgundy,
          disabledBackgroundColor: burgundy.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: gold,
              width: 1,
            ),
          ),
        ),
        child: logic.isPublishing
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Color(0xFFE9D8B0),
              size: 17,
            ),
            const SizedBox(width: 9),
            Text(
              widget.isEditMode
                  ? 'SAVE LISTING'
                  : 'PUBLISH WOMEN’S OUTFIT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final validationError = logic.validateForm();

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    try {
      final success = await logic.publishOutfit(
        outfitId: widget.outfitId,
      );

      if (!mounted) return;

      if (success) {
        _showMessage(
          widget.isEditMode
              ? 'Outfit updated successfully.'
              : 'Women’s outfit published successfully.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // =========================================================
  // ERROR / MESSAGE
  // =========================================================

  Widget _loadingError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: burgundy,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              logic.loadingError ?? 'Unable to load this outfit.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                logic.loadOutfitForEditing(widget.outfitId!);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
