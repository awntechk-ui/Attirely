import 'package:flutter/material.dart';
import '../UI_Logic/add_men_outfit_logic.dart';

class AddMenOutfitPage extends StatefulWidget {
  const AddMenOutfitPage({super.key});

  @override
  State<AddMenOutfitPage> createState() => _AddMenOutfitPageState();
}

class _AddMenOutfitPageState extends State<AddMenOutfitPage> {
  late final AddMenOutfitLogic logic;

  static const burgundy = Color(0xFF800020);
  static const background = Color(0xFFFFF9F5);
  static const border = Color(0xFFE5DCD7);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    logic = AddMenOutfitLogic();
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
          builder: (context, _) => Column(
            children: [
              _topBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _intro(),
                      const SizedBox(height: 24),
                      _sectionTitle('01', 'Product photographs', 'Show the fit, fabric and finishing'),
                      const SizedBox(height: 12),
                      _photoPicker(),
                      const SizedBox(height: 28),
                      _sectionTitle('02', 'Outfit identity', 'Tell customers exactly what you are listing'),
                      const SizedBox(height: 14),
                      _label('Outfit name', required: true),
                      _field(logic.nameController, 'E.g. Ivory embroidered groom sherwani'),
                      const SizedBox(height: 14),
                      _label('Description', required: true),
                      _field(logic.descriptionController, 'Describe the silhouette, detailing, fabric and finish...', maxLines: 4),
                      const SizedBox(height: 14),
                      _label('Brand / Designer'),
                      _field(logic.brandController, 'E.g. Attirely Studio'),
                      const SizedBox(height: 14),
                      _label('Style category', required: true),
                      _dropdown(logic.category, 'Choose a category', logic.categories, logic.setCategory),
                      const SizedBox(height: 14),
                      _label('Outfit type', required: true),
                      _dropdown(logic.outfitType, 'Choose an outfit type', logic.availableOutfitTypes, (v) => setState(() => logic.outfitType = v)),
                      const SizedBox(height: 14),
                      _label('Occasion', required: true),
                      _dropdown(logic.occasion, 'Where would this be worn?', logic.occasions, (v) => setState(() => logic.occasion = v)),
                      const SizedBox(height: 28),
                      _sectionTitle('03', 'The fit & finish', 'Details that help customers choose confidently'),
                      const SizedBox(height: 14),
                      _label('Fit'),
                      _choiceDropdown(logic.fit, 'Select fit', logic.fits, (v) => setState(() => logic.fit = v)),
                      const SizedBox(height: 14),
                      _label('Pattern / detailing'),
                      _choiceDropdown(logic.pattern, 'Select pattern', logic.patterns, (v) => setState(() => logic.pattern = v)),
                      const SizedBox(height: 14),
                      _label('Collar / neckline'),
                      _choiceDropdown(logic.collar, 'Select collar style', logic.collars, (v) => setState(() => logic.collar = v)),
                      const SizedBox(height: 14),
                      _label('Sleeve style'),
                      _choiceDropdown(logic.sleeve, 'Select sleeve style', logic.sleeves, (v) => setState(() => logic.sleeve = v)),
                      const SizedBox(height: 14),
                      _label('Fabric', required: true),
                      _choiceDropdown(logic.material, 'Select fabric', logic.materials, (v) => setState(() => logic.material = v)),
                      const SizedBox(height: 14),
                      _label('Primary colour'),
                      _colorSelector(),
                      const SizedBox(height: 28),
                      _sectionTitle('04', 'Size & measurements', 'Choose standard sizing or add garment measurements'),
                      const SizedBox(height: 14),
                      _segmentedSizeMode(),
                      const SizedBox(height: 16),
                      if (logic.sizeMode == 'Standard sizes') _standardSizes() else _measurements(),
                      const SizedBox(height: 28),
                      _sectionTitle('05', 'Rental pricing', 'Keep the rental value and deposit transparent'),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _priceField('Rental price (₹)', logic.rentalPriceController, '2500', required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _priceField('MRP (₹)', logic.mrpController, '8000')),
                      ]),
                      const SizedBox(height: 14),
                      _label('Refundable security deposit (₹)', required: true),
                      _field(logic.securityDepositController, 'E.g. 5000', keyboard: TextInputType.number),
                      const SizedBox(height: 26),
                      _publishButton(),
                      const SizedBox(height: 10),
                      // const Center(child: Text('UI preview only · Backend connection will be added later', style: TextStyle(fontSize: 10, color: Colors.black45))),
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

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 19)),
      const Expanded(child: Center(child: Text('Add Men’s Outfit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _intro() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(colors: [Color(0xFF800020), Color(0xFF4E1022)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('THE GENTLEMEN’S EDIT', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
        SizedBox(height: 7),
        Text('Make every detail\ncount.', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w700)),
        SizedBox(height: 7),
        Text('List occasionwear, everyday essentials and statement looks.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
      ])),
      const Icon(Icons.checkroom_rounded, color: Color(0xFFD9B86C), size: 52),
    ]),
  );

  Widget _sectionTitle(String number, String title, String subtitle) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: burgundy.withOpacity(.08), borderRadius: BorderRadius.circular(9)), child: Text(number, style: const TextStyle(color: burgundy, fontWeight: FontWeight.w800, fontSize: 11))),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF292323))),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ])),
  ]);

  Widget _photoPicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkWell(
      onTap: logic.photos.length < AddMenOutfitLogic.maxPhotos ? logic.pickPhotos : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 126, width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border),),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined, color: burgundy, size: 30),
          SizedBox(height: 8),
          Text('Add outfit photographs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(height: 4),
          Text('Upload up to 5 images · JPG or PNG', style: TextStyle(color: Colors.black45, fontSize: 10)),
        ]),
      ),
    ),
    if (logic.photos.isNotEmpty) ...[
      const SizedBox(height: 10),
      SizedBox(height: 82, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: logic.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) => Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(logic.photos[i], width: 76, height: 76, fit: BoxFit.cover)),
          Positioned(right: 2, top: 2, child: GestureDetector(onTap: () => logic.removePhoto(i), child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)))),
          if (i == 0) const Positioned(left: 4, bottom: 4, child: DecoratedBox(decoration: BoxDecoration(color: burgundy, borderRadius: BorderRadius.all(Radius.circular(4))), child: Padding(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), child: Text('COVER', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))))),
        ]),
      )),
    ],
  ]);

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: RichText(text: TextSpan(style: const TextStyle(color: Color(0xFF332D2D), fontSize: 12, fontWeight: FontWeight.w700), children: [
      TextSpan(text: text),
      if (required) const TextSpan(text: ' *', style: TextStyle(color: burgundy)),
    ])),
  );

  Widget _field(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboard}) => TextField(
    controller: controller, maxLines: maxLines, keyboardType: keyboard,
    style: const TextStyle(fontSize: 13),
    decoration: _decoration(hint),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: burgundy, width: 1.4)),
  );

  Widget _dropdown(String? value, String hint, List<String> items, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null, isExpanded: true, menuMaxHeight: 320,
    decoration: _decoration(''), hint: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.black38)),
    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
    onChanged: onChanged,
  );

  Widget _choiceDropdown(String? value, String hint, List<String> items, ValueChanged<String?> onChanged) => _dropdown(value, hint, items, onChanged);

  Widget _colorSelector() => InkWell(
    onTap: _showColors,
    borderRadius: BorderRadius.circular(11),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border), borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        Container(width: 29, height: 29, decoration: BoxDecoration(color: logic.selectedColor, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
        const SizedBox(width: 11),
        Expanded(child: Text(logic.selectedColorName ?? 'Choose colour', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      ]),
    ),
  );

  void _showColors() => showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (sheetContext) => SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choose the primary colour', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Wrap(spacing: 17, runSpacing: 17, children: logic.colors.map((item) {
          final color = item['color'] as Color;
          final name = item['name'] as String;
          final selected = logic.selectedColorName == name;
          return GestureDetector(onTap: () { logic.setColor(name, color); Navigator.pop(sheetContext); }, child: SizedBox(width: 64, child: Column(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected ? burgundy : Colors.black12, width: selected ? 3 : 1)), child: selected ? Icon(Icons.check, size: 18, color: color.computeLuminance() > .5 ? Colors.black : Colors.white) : null),
            const SizedBox(height: 5), Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
          ])));
        }).toList()),
        const SizedBox(height: 10),
      ]),
    )),
  );

  Widget _segmentedSizeMode() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: const Color(0xFFF0E9E5), borderRadius: BorderRadius.circular(12)),
    child: Row(children: ['Standard sizes', 'Measurements'].map((mode) {
      final active = logic.sizeMode == mode;
      return Expanded(child: GestureDetector(onTap: () => setState(() => logic.sizeMode = mode), child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: active ? burgundy : Colors.transparent, borderRadius: BorderRadius.circular(9)),
        child: Text(mode, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.w700)),
      )));
    }).toList()),
  );

  Widget _standardSizes() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Available sizes', style: TextStyle(fontSize: 11, color: Colors.black54)),
    const SizedBox(height: 10),
    Wrap(spacing: 9, runSpacing: 9, children: logic.sizes.map((size) {
      final selected = logic.selectedSizes.contains(size);
      return GestureDetector(onTap: () => logic.toggleSize(size), child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), width: 49, height: 43, alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? burgundy : Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: selected ? burgundy : border)),
        child: Text(size, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)),
      ));
    }).toList()),
  ]);

  Widget _measurements() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Enter garment measurements (in inches)', style: TextStyle(fontSize: 11, color: Colors.black54)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _measurementField('Chest', logic.chestController, '40')),
      const SizedBox(width: 10),
      Expanded(child: _measurementField('Waist', logic.waistController, '34')),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _measurementField('Shoulder', logic.shoulderController, '18')),
      const SizedBox(width: 10),
      Expanded(child: _measurementField('Sleeve length', logic.sleeveLengthController, '25')),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _measurementField('Garment length', logic.garmentLengthController, '30')),
      const SizedBox(width: 10),
      Expanded(child: _measurementField('Hip', logic.hipController, '40')),
    ]),
    const SizedBox(height: 10),
    _measurementField('Inseam', logic.inseamController, '30'),
  ]);

  Widget _measurementField(String label, TextEditingController c, String hint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
    const SizedBox(height: 6),
    TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 12), decoration: _decoration(hint)),
  ]);

  Widget _priceField(String label, TextEditingController c, String hint, {bool required = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label, required: required),
    _field(c, hint, keyboard: TextInputType.number),
  ]);

  Widget _publishButton() => SizedBox(
    width: double.infinity,
    height: 53,
    child: ElevatedButton(
      onPressed: logic.isPublishing
          ? null
          : () async {
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
          final result = await logic.publishOutfit();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Men’s outfit published successfully!'),
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
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: burgundy.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: gold, width: 1),
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
            'Publish Outfit',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
