
import 'package:flutter/material.dart';

import '../V_UI_Logic/v_kids_outfit_logic.dart';


class VAddKidsOutfitPage extends StatefulWidget {
  const VAddKidsOutfitPage({super.key});

  @override
  State<VAddKidsOutfitPage> createState() => _VAddKidsOutfitPageState();
}

class _VAddKidsOutfitPageState extends State<VAddKidsOutfitPage> {
  late final VAddKidsOutfitLogic logic;

  static const burgundy = Color(0xFF800020);
  static const background = Color(0xFFFFF9F5);
  static const gold = Color(0xFFD4AF37);
  static const border = Color(0xFFE5DCD7);

  @override
  void initState() {
    super.initState();
    logic = VAddKidsOutfitLogic();
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
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(19, 10, 19, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(),

                        const SizedBox(height: 25),

                        _sectionTitle(
                          '01',
                          'Little looks, lovely memories.',
                          'Upload clear pictures of the outfit',
                        ),

                        const SizedBox(height: 13),
                        _photoPicker(),

                        const SizedBox(height: 27),

                        _sectionTitle(
                          '02',
                          'Outfit identity',
                          'Tell us about this little look',
                        ),

                        const SizedBox(height: 15),

                        _label('Outfit name', required: true),
                        _field(
                          logic.nameController,
                          'E.g. Floral princess frock',
                        ),

                        const SizedBox(height: 15),

                        _label('Description', required: true),
                        _field(
                          logic.descriptionController,
                          'Describe the outfit, fabric and detailing...',
                          maxLines: 4,
                        ),

                        const SizedBox(height: 15),

                        _label('Brand / Designer'),
                        _field(
                          logic.brandController,
                          'E.g. Attirely Kids',
                        ),

                        const SizedBox(height: 15),

                        _label('Collection for', required: true),
                        _dropdown(
                          logic.selectedGender,
                          'Select collection',
                          logic.genders,
                          logic.setGender,
                        ),

                        const SizedBox(height: 15),

                        _label('Age group', required: true),
                        _dropdown(
                          logic.selectedAge,
                          'Select age group',
                          logic.ages,
                          logic.setAge,
                        ),

                        const SizedBox(height: 15),

                        _label('Style category', required: true),
                        _dropdown(
                          logic.selectedCategory,
                          'Select category',
                          logic.categories,
                          logic.setCategory,
                        ),

                        const SizedBox(height: 15),

                        _label('Occasion', required: true),
                        _dropdown(
                          logic.selectedOccasion,
                          'Select occasion',
                          logic.occasions,
                          logic.setOccasion,
                        ),

                        const SizedBox(height: 15),

                        _label('Material'),
                        _dropdown(
                          logic.selectedMaterial,
                          'Select material',
                          logic.materials,
                          logic.setMaterial,
                        ),

                        const SizedBox(height: 15),

                        _label('Available size', required: true),
                        _dropdown(
                          logic.selectedSize,
                          'Select size',
                          logic.sizes,
                          logic.setSize,
                        ),

                        const SizedBox(height: 27),

                        _sectionTitle(
                          '03',
                          'Rental & pricing',
                          'Set the rental price and refundable deposit',
                        ),

                        const SizedBox(height: 15),

                        _label('Rental price (₹)', required: true),
                        _field(
                          logic.rentalController,
                          'E.g. 750',
                          keyboard: TextInputType.number,
                        ),

                        const SizedBox(height: 15),

                        _label('MRP (₹)'),
                        _field(
                          logic.mrpController,
                          'E.g. 3500',
                          keyboard: TextInputType.number,
                        ),

                        const SizedBox(height: 15),

                        _label(
                          'Refundable security deposit (₹)',
                          required: true,
                        ),
                        _field(
                          logic.depositController,
                          'E.g. 1500',
                          keyboard: TextInputType.number,
                        ),

                        const SizedBox(height: 28),

                        _publishButton(),

                        const SizedBox(height: 12),

                        const Center(
                          child: Text(
                            'Attirely Kids Collection',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
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

  // Top navigation
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 17, 7),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: burgundy,
              size: 19,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Add Kids Outfit',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Hero banner
  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF800020),
            Color(0xFF4E1022),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE LITTLE EDIT',
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Little outfits.\nBig memories.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Beautiful looks for every little celebration.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.child_care_outlined,
            color: gold,
            size: 52,
          ),
        ],
      ),
    );
  }

  // Section heading
  Widget _sectionTitle(
      String number,
      String title,
      String subtitle,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: burgundy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: burgundy,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF292323),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Photo upload
  Widget _photoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: logic.photos.length < VAddKidsOutfitLogic.maxPhotos
              ? logic.pickPhotos
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: burgundy,
                  size: 32,
                ),
                SizedBox(height: 9),
                Text(
                  'Upload kids outfit photos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Up to 5 images · JPG or PNG',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (logic.photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: logic.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (_, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        logic.photos[index],
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => logic.removePhoto(index),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      const Positioned(
                        left: 4,
                        bottom: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: burgundy,
                            borderRadius: BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: Text(
                              'COVER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
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

  // Field label
  Widget _label(String value, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF292323),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                color: burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  // Text input
  Widget _field(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 12),
      decoration: _decoration(hint),
    );
  }

  // Dropdown
  Widget _dropdown(
      String? value,
      String hint,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: _decoration(hint),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Common decoration
  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.black38,
        fontSize: 11,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
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
          width: 1.3,
        ),
      ),
    );
  }

  // Publish button
  Widget _publishButton() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: logic.isPublishing ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: burgundy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: burgundy.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(
              color: gold,
              width: 1,
            ),
          ),
        ),
        child: logic.isPublishing
            ? const SizedBox(
          height: 21,
          width: 21,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 17),
            SizedBox(width: 9),
            Text(
              'Publish Kids Outfit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Publish action
  Future<void> _publish() async {
    final error = logic.validate();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await logic.publishOutfit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kids outfit published successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}