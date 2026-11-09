import 'package:flutter/material.dart';
import '../UI_Logic/add_accessories_logic.dart';
import '../session_manager.dart';

class AddAccessoriesPage extends StatefulWidget {
  const AddAccessoriesPage({super.key});

  @override
  State<AddAccessoriesPage> createState() => _AddAccessoriesPageState();
}

class _AddAccessoriesPageState extends State<AddAccessoriesPage> {
  late final AddAccessoriesLogic logic;

  static const burgundy = Color(0xFF800020);
  static const background = Color(0xFFFFF9F5);
  static const border = Color(0xFFE5DCD7);
  static const gold = Color(0xFFD4AF37);

  final stepTitles = const ['Photos', 'Details', 'Pricing', 'Variants', 'Review'];

  @override
  void initState() {
    super.initState();
    logic = AddAccessoriesLogic();
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
        builder: (context, _) => Column(children: [
          _topBar(),
          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _hero(),
              const SizedBox(height: 22),
              _stepProgress(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _stepContent(key: ValueKey(logic.step)),
              ),
              const SizedBox(height: 24),
              _navigationButtons(),
              const SizedBox(height: 10),
              const Center(child: Text('UI preview only · Backend connection will be added later', style: TextStyle(fontSize: 10, color: Colors.black45))),
            ]),
          )),
        ]),
      ),
    ),
  );

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 19)),
      const Expanded(child: Center(child: Text('Add Accessories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _hero() => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(colors: [Color(0xFF800020), Color(0xFF4E1022)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('THE FINISHING TOUCH', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
        SizedBox(height: 7),
        Text('Little details.\nBig statements.', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w700)),
        SizedBox(height: 7),
        Text('List the pieces that complete the look.', style: TextStyle(color: Colors.white70, fontSize: 11)),
      ])),
      const Icon(Icons.diamond_outlined, color: Color(0xFFD9B86C), size: 51),
    ]),
  );

  Widget _stepProgress() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
    child: Column(children: [
      Row(children: List.generate(5, (i) => Expanded(child: Container(
        height: 4, margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
        decoration: BoxDecoration(color: i <= logic.step ? burgundy : const Color(0xFFECE5E1), borderRadius: BorderRadius.circular(10)),
      )))),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(5, (i) => Text(stepTitles[i], style: TextStyle(fontSize: 9, fontWeight: i == logic.step ? FontWeight.w800 : FontWeight.w500, color: i == logic.step ? burgundy : Colors.black45)))),
    ]),
  );

  Widget _stepContent({Key? key}) {
    switch (logic.step) {
      case 0: return _photosStep(key: key);
      case 1: return _detailsStep(key: key);
      case 2: return _pricingStep(key: key);
      case 3: return _variantsStep(key: key);
      default: return _reviewStep(key: key);
    }
  }

  Widget _sectionHeading(String eyebrow, String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(eyebrow.toUpperCase(), style: const TextStyle(color: burgundy, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
    const SizedBox(height: 5),
    Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF292323))),
    const SizedBox(height: 5),
    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.4)),
  ]);

  Widget _photosStep({Key? key}) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeading('Step 01 · Visuals', 'Make it irresistible.', 'Add clear product photos from different angles. Your first image becomes the cover.'),
    const SizedBox(height: 18),
    InkWell(
      onTap: logic.photos.length < AddAccessoriesLogic.maxPhotos ? logic.pickPhotos : null,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 155, width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: border)),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_a_photo_outlined, color: burgundy, size: 32),
          SizedBox(height: 10),
          Text('Upload accessory photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          SizedBox(height: 5),
          Text('Up to 5 images · JPG or PNG', style: TextStyle(fontSize: 10, color: Colors.black45)),
        ]),
      ),
    ),
    if (logic.photos.isNotEmpty) ...[
      const SizedBox(height: 13),
      SizedBox(height: 91, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: logic.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) => Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(logic.photos[i], width: 82, height: 82, fit: BoxFit.cover)),
          Positioned(right: 2, top: 2, child: GestureDetector(onTap: () => logic.removePhoto(i), child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)))),
          if (i == 0) const Positioned(left: 4, bottom: 4, child: DecoratedBox(decoration: BoxDecoration(color: burgundy, borderRadius: BorderRadius.all(Radius.circular(4))), child: Padding(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), child: Text('COVER', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))))),
        ]),
      )),
    ],
    const SizedBox(height: 18),
    _hintCard(Icons.lightbulb_outline, 'Photo tip', 'Use a clean background and show important details such as closures, texture, embellishments and scale.'),
  ]);

  Widget _detailsStep({Key? key}) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeading('Step 02 · Identity', 'Tell its story.', 'Add the details customers need to understand the piece.'),
    const SizedBox(height: 18),
    _label('Product name', required: true),
    _field(logic.nameController, 'E.g. Pearl embellished potli bag'),
    const SizedBox(height: 14),
    _label('Who is it for?', required: true),
    _choiceChips(logic.genders, logic.gender, (v) => setState(() => logic.gender = v)),
    const SizedBox(height: 16),
    _label('Category', required: true),
    _dropdown(logic.category, 'Choose accessory category', logic.categories, (v) => setState(() { logic.category = v; logic.subcategory = null; })),
    const SizedBox(height: 14),
    _label('Accessory type', required: true),
    _dropdown(logic.subcategory, 'Choose product type', logic.availableSubcategories, (v) => setState(() => logic.subcategory = v)),
    const SizedBox(height: 14),
    _label('Brand / Designer'),
    _field(logic.brandController, 'E.g. Attirely Studio'),
    const SizedBox(height: 14),
    _label('Description', required: true),
    _field(logic.descriptionController, 'Describe the design, finish, details and how it can be styled...', maxLines: 4),
    const SizedBox(height: 14),
    _label('Material'),
    _dropdown(logic.material, 'Choose material', logic.materials, (v) => setState(() => logic.material = v)),
    const SizedBox(height: 14),
    _label('Primary colour'),
    _dropdown(logic.colour, 'Choose colour', logic.colours, (v) => setState(() => logic.colour = v)),
  ]);

  Widget _pricingStep({Key? key}) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeading('Step 03 · Rental value', 'Set your pricing.', 'Keep the rental amount and refundable deposit clear.'),
    const SizedBox(height: 18),
    Row(children: [
      Expanded(child: _priceField('Rental price (₹)', logic.rentalPriceController, '499', required: true)),
      const SizedBox(width: 12),
      Expanded(child: _priceField('MRP (₹)', logic.mrpController, '2499')),
    ]),
    const SizedBox(height: 16),
    _label('Refundable security deposit (₹)', required: true),
    _field(logic.securityDepositController, 'E.g. 1000', keyboard: TextInputType.number),
    const SizedBox(height: 18),
    _hintCard(Icons.verified_user_outlined, 'Deposit clarity', 'The security deposit is separate from the rental price. You can configure refund and return policies during backend integration.'),
  ]);

  Widget _variantsStep({Key? key}) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeading('Step 04 · Availability', 'Make the fit clear.', 'Add available quantity and any useful size or variant information.'),
    const SizedBox(height: 18),
    _label('Available quantity', required: true),
    _field(logic.quantityController, '1', keyboard: TextInputType.number),
    const SizedBox(height: 14),
    _label('Size / variant'),
    _dropdown(logic.sizeOption, 'Choose if applicable', const ['One Size', 'Adjustable', 'Small', 'Medium', 'Large', 'Free Size', 'Multiple Sizes', 'Not Applicable'], (v) => setState(() => logic.sizeOption = v)),
    const SizedBox(height: 14),
    _label('Variant notes'),
    _field(logic.variantNotesController, 'E.g. 18-inch strap, adjustable clasp, 6.5 shoe size...', maxLines: 3),
    const SizedBox(height: 18),
    _hintCard(Icons.tune_rounded, 'Flexible variants', 'Use this field for shoe sizes, bag dimensions, bracelet length, watch strap size or other category-specific details.'),
  ]);

  Widget _reviewStep({Key? key}) => Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeading('Step 05 · Final check', 'Ready to review.', 'Check the information below before connecting the publish workflow.'),
    const SizedBox(height: 18),
    if (logic.photos.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(logic.photos.first, height: 190, width: double.infinity, fit: BoxFit.cover)),
    const SizedBox(height: 14),
    _reviewCard('Product', [
      _reviewRow('Name', _value(logic.nameController.text)),
      _reviewRow('Gender', _value(logic.gender)),
      _reviewRow('Category', _value(logic.category)),
      _reviewRow('Type', _value(logic.subcategory)),
      _reviewRow('Brand', _value(logic.brandController.text)),
      _reviewRow('Material', _value(logic.material)),
      _reviewRow('Colour', _value(logic.colour)),
    ]),
    const SizedBox(height: 12),
    _reviewCard('Rental pricing', [
      _reviewRow('Rental price', _rupees(logic.rentalPriceController.text)),
      _reviewRow('MRP', _rupees(logic.mrpController.text)),
      _reviewRow('Security deposit', _rupees(logic.securityDepositController.text)),
    ]),
    const SizedBox(height: 12),
    _reviewCard('Availability', [
      _reviewRow('Quantity', _value(logic.quantityController.text)),
      _reviewRow('Size / variant', _value(logic.sizeOption)),
      _reviewRow('Photos', '${logic.photos.length} added'),
    ]),
  ]);

  String _value(String? v) => (v == null || v.trim().isEmpty) ? 'Not added' : v.trim();
  String _rupees(String v) => v.trim().isEmpty ? 'Not added' : '₹${v.trim()}';

  Widget _reviewCard(String title, List<Widget> children) => Container(
    width: double.infinity, padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: burgundy)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _reviewRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _navigationButtons() => Row(
    children: [
      if (logic.step > 0)
        Expanded(
          child: OutlinedButton(
            onPressed: logic.isPublishing ? null : logic.previousStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: burgundy,
              side: const BorderSide(color: burgundy),
              minimumSize: const Size(0, 51),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),

      if (logic.step > 0) const SizedBox(width: 10),

      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: logic.isPublishing ? null : _handleNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: burgundy.withOpacity(0.6),
            elevation: 0,
            side: const BorderSide(color: gold),
            minimumSize: const Size(0, 51),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: logic.isPublishing
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                logic.step == 4 ? 'Publish Accessory' : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Icon(
                logic.step == 4
                    ? Icons.cloud_upload_outlined
                    : Icons.arrow_forward_rounded,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _handleNext() async {
    // Final step: publish accessory
    if (logic.step == 4) {
      await _publishAccessory();
      return;
    }

    final error = logic.validateStep();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    logic.nextStep();
  }

  Future<void> _publishAccessory() async {
    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await logic.publishAccessory(
      accessToken: accessToken,
    );

    if (!mounted) return;
    if (success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Accessory Published!'),
          content: const Text(
            'Your accessory has been successfully added.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: burgundy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            logic.errorMessage ?? 'Failed to publish accessory.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: burgundy,
        ),
      );
    }
  }
  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: RichText(text: TextSpan(style: const TextStyle(color: Color(0xFF332D2D), fontSize: 12, fontWeight: FontWeight.w700), children: [
      TextSpan(text: text),
      if (required) const TextSpan(text: ' *', style: TextStyle(color: burgundy)),
    ])),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: burgundy, width: 1.4)),
  );

  Widget _field(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboard}) => TextField(
    controller: controller, maxLines: maxLines, keyboardType: keyboard, style: const TextStyle(fontSize: 13), decoration: _decoration(hint),
  );

  Widget _dropdown(String? value, String hint, List<String> items, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null, isExpanded: true, menuMaxHeight: 320,
    decoration: _decoration(''), hint: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.black38)),
    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
    onChanged: onChanged,
  );

  Widget _choiceChips(List<String> values, String? selected, ValueChanged<String> onSelected) => Wrap(spacing: 8, runSpacing: 8, children: values.map((v) {
    final active = selected == v;
    return ChoiceChip(
      label: Text(v), selected: active, onSelected: (_) => onSelected(v),
      selectedColor: burgundy, backgroundColor: Colors.white, side: BorderSide(color: active ? burgundy : border),
      labelStyle: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    );
  }).toList());

  Widget _priceField(String label, TextEditingController c, String hint, {bool required = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label, required: required),
    _field(c, hint, keyboard: TextInputType.number),
  ]);

  Widget _hintCard(IconData icon, String title, String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF3EAE6), borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: burgundy, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(message, style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.45)),
      ])),
    ]),
  );
}
