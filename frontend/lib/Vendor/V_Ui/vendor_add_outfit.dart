import 'package:flutter/material.dart';

import '../V_Ui_Logic/add_outfit_logic.dart';

class VendorAddOutfitPage extends StatefulWidget {
  const VendorAddOutfitPage({super.key});

  @override
  State<VendorAddOutfitPage> createState() =>
      _VendorAddOutfitPageState();
}

class _VendorAddOutfitPageState
    extends State<VendorAddOutfitPage> {
  late final AddOutfitLogic logic;

  static const Color burgundy = Color(0xFF800020);
  static const Color background = Color(0xFFFFF9F5);
  static const Color softBorder = Color(0xFFE5DCD7);

  @override
  void initState() {
    super.initState();
    logic = AddOutfitLogic();
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
            return Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: Form(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('1. Add Photos'),
                          const SizedBox(height: 10),
                          _buildPhotoSection(),

                          const SizedBox(height: 28),

                          _sectionTitle('2. Outfit Information'),
                          const SizedBox(height: 12),

                          _buildLabel(
                            'Outfit Name',
                            required: true,
                          ),
                          _buildTextField(
                            controller: logic.nameController,
                            hint: 'E.g. Rose Embroidered Lehenga',
                          ),

                          const SizedBox(height: 16),

                          _buildLabel(
                            'Description',
                            required: true,
                          ),
                          _buildTextField(
                            controller:
                            logic.descriptionController,
                            hint:
                            'Describe the outfit, design and details...',
                            maxLines: 4,
                          ),

                          const SizedBox(height: 16),

                          _buildLabel(
                            'Outfit Gender',
                            required: true,
                          ),
                          _buildDropdown(
                            value: logic.selectedGender,
                            hint: 'Select Gender',
                            items: logic.genders,
                            onChanged: (value) {
                              logic.selectedGender = value;
                              logic.notifyListeners();
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildLabel('Brand'),
                          _buildTextField(
                            controller: logic.brandController,
                            hint: 'E.g. Attirely Studio',
                          ),

                          const SizedBox(height: 16),

                          _buildLabel(
                            'Category',
                            required: true,
                          ),
                          _buildDropdown(
                            value: logic.selectedCategory,
                            hint: 'Select Category',
                            items: logic.categories,
                            onChanged: (value) {
                              logic.selectedCategory = value;
                              logic.notifyListeners();
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildLabel(
                            'Occasion',
                            required: true,
                          ),
                          _buildDropdown(
                            value: logic.selectedOccasion,
                            hint: 'Select Occasion',
                            items: logic.occasions,
                            onChanged: (value) {
                              logic.selectedOccasion = value;
                              logic.notifyListeners();
                            },
                          ),

                          const SizedBox(height: 28),

                          _sectionTitle('3. Pricing'),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(
                                      'Rental Price (₹)',
                                      required: true,
                                    ),
                                    _buildTextField(
                                      controller:
                                      logic.rentalPriceController,
                                      hint: '2500',
                                      keyboardType:
                                      TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('MRP (₹)'),
                                    _buildTextField(
                                      controller:
                                      logic.mrpController,
                                      hint: '8000',
                                      keyboardType:
                                      TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildLabel(
                            'Security Deposit (₹)',
                            required: true,
                          ),
                          _buildTextField(
                            controller:
                            logic.securityDepositController,
                            hint: '5000',
                            keyboardType:
                            TextInputType.number,
                          ),

                          const SizedBox(height: 28),

                          _sectionTitle('4. Color'),
                          const SizedBox(height: 12),
                          _buildColorSelector(),

                          const SizedBox(height: 28),

                          _sectionTitle('5. Size'),
                          const SizedBox(height: 12),
                          _buildSizeSection(),

                          const SizedBox(height: 28),

                          _sectionTitle('6. Material & Sleeve'),
                          const SizedBox(height: 12),

                          _buildLabel(
                            'Material',
                            required: true,
                          ),
                          // _buildMaterialField(),
                          _buildDropdown(
                            value: logic.materialController.text.isEmpty
                                ? null
                                : logic.materialController.text,
                            hint: 'Select Material',
                            items: logic.materials,
                            onChanged: (value) {
                              logic.materialController.text = value ?? '';
                              logic.notifyListeners();
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildLabel('Sleeve'),
                          _buildDropdown(
                            value: logic.selectedSleeve,
                            hint: 'Select Sleeve',
                            items: logic.sleeves,
                            onChanged: (value) {
                              logic.selectedSleeve = value;
                              logic.notifyListeners();
                            },
                          ),

                          const SizedBox(height: 30),

                          _buildPublishButton(),
                        ],
                      ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
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
                'Add New Outfit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLabel(
      String text, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: burgundy,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ButtonTheme(
      alignedDropdown: true,

      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: softBorder,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: softBorder,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: burgundy,
              width: 1.3,
            ),
          ),
        ),

        hint: Text(
          hint,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
        ),

        items: items.map(
              (item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            );
          },
        ).toList(),

        onChanged: onChanged,

        // Optional: prevents the menu becoming too tall
        menuMaxHeight: 300,

        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: logic.pickPhotos,
          child: Container(
            width: double.infinity,
            height: 125,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload Photos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Add up to 5 images',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'JPG, PNG (Max 5MB each)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (logic.selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: logic.selectedPhotos.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        logic.selectedPhotos[index],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () =>
                            logic.removePhoto(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration:
                          const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 3,
                        bottom: 3,
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration:
                          BoxDecoration(
                            color: burgundy,
                            borderRadius:
                            BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
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

  Widget _buildColorSelector() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: softBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: logic.selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Color',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    logic.selectedColorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
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
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Outfit Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the color that best matches the outfit.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: logic.colorOptions.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final option =
                    logic.colorOptions[index];
                    final color =
                    option['color'] as Color;
                    final name =
                    option['name'] as String;

                    final isSelected =
                        logic.selectedColor == color;

                    return GestureDetector(
                      onTap: () {
                        logic.setColor(
                          color: color,
                          name: name,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? burgundy
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                          Icons.check,
                          size: 18,
                          color: color.computeLuminance() > 0.55
                              ? Colors.black
                              : Colors.white,
                        )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sizeTypeButton(
                title: 'Standard Sizes',
                value: 'standard',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _sizeTypeButton(
                title: 'Measurements',
                value: 'measurements',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (logic.sizeType == 'standard')
          _buildStandardSizes()
        else
          _buildMeasurements(),
      ],
    );
  }

  Widget _sizeTypeButton({
    required String title,
    required String value,
  }) {
    final selected = logic.sizeType == value;

    return GestureDetector(
      onTap: () => logic.setSizeType(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? burgundy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? burgundy : softBorder,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardSizes() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: logic.sizes.map(
            (size) {
          final selected =
          logic.selectedSizes.contains(size);

          return GestureDetector(
            onTap: () => logic.toggleSize(size),
            child: Container(
              width: 52,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                selected ? burgundy : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color:
                  selected ? burgundy : softBorder,
                ),
              ),
              child: Text(
                size,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildMeasurements() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _measurementField(
                controller: logic.bustController,
                label: 'Bust',
                hint: '36',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _measurementField(
                controller: logic.waistController,
                label: 'Waist',
                hint: '30',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _measurementField(
                controller: logic.hipController,
                label: 'Hip',
                hint: '38',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _measurementField(
                controller: logic.shoulderController,
                label: 'Shoulder',
                hint: '15',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _measurementField(
          controller: logic.lengthController,
          label: 'Length',
          hint: '52',
        ),
      ],
    );
  }

  Widget _measurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: softBorder),
        ),
      ),
    );
  }

  // Widget _buildMaterialField() {
  //   return DropdownButtonFormField<String>(
  //     value: logic.materialController.text.isEmpty
  //         ? null
  //         : logic.materialController.text,
  //     isExpanded: true,
  //     decoration: InputDecoration(
  //       filled: true,
  //       fillColor: Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 14,
  //         vertical: 2,
  //       ),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide:
  //         const BorderSide(color: softBorder),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide:
  //         const BorderSide(color: softBorder),
  //       ),
  //     ),
  //     hint: Text(
  //       'Select Material',
  //       style: TextStyle(
  //         color: Colors.grey.shade500,
  //         fontSize: 13,
  //       ),
  //     ),
  //     items: logic.materials
  //         .map(
  //           (material) => DropdownMenuItem<String>(
  //         value: material,
  //         child: Text(
  //           material,
  //           style: const TextStyle(fontSize: 13),
  //         ),
  //       ),
  //     )
  //         .toList(),
  //     onChanged: (value) {
  //       logic.materialController.text = value ?? '';
  //       logic.notifyListeners();
  //     },
  //   );
  // }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: logic.isPublishing
            ? null
            : () async {
          final error = logic.validateForm();

          if (error != null) {
            _showMessage(error);
            return;
          }

          try {
            final success = await logic.publishOutfit();

            if (!mounted) return;

            if (success) {
              _showMessage(
                'Outfit published successfully.',
              );
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (!mounted) return;

            _showMessage(
              e.toString().replaceFirst('Exception: ', ''),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: burgundy,
          disabledBackgroundColor:
          burgundy.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: logic.isPublishing
            ? const SizedBox(
          width: 23,
          height: 23,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Publish Outfit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
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
