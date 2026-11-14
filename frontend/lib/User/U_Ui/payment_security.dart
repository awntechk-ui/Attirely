import 'package:flutter/material.dart';

import '../U_API_Routes/u_rental_api_routes.dart';
import '../U_Ui_Logic/user_cart_logic.dart';
import '../U_Ui_Logic/payment_security_logic.dart';

class PaymentSecurityPage extends StatefulWidget {
  final List<Map<String, dynamic>> outfits;
  final Map<String, dynamic> deliveryAddress;
  final double rentalFee;
  final double securityDeposit;
  final double coutureCareFee;
  final bool coutureCareEnabled;
  final bool backupSizeIncluded;

  const PaymentSecurityPage({
    super.key,
    required this.outfits,
    required this.deliveryAddress,
    required this.rentalFee,
    required this.securityDeposit,
    required this.coutureCareFee,
    required this.coutureCareEnabled,
    required this.backupSizeIncluded,
  });

  @override
  State<PaymentSecurityPage> createState() => _PaymentSecurityPageState();
}

class _PaymentSecurityPageState extends State<PaymentSecurityPage> {
  static const Color green = Color(0xFF064C32);
  static const Color darkGreen = Color(0xFF073F2B);
  static const Color background = Color(0xFFF7F8F5);
  static const Color border = Color(0xFFE5E9E4);
  static const Color muted = Color(0xFF777E79);
  static const Color paleGreen = Color(0xFFEAF3E9);

  late final PaymentSecurityLogic logic;

  String get selectedMethod => logic.selectedMethod;
  set selectedMethod(String value) => logic.selectMethod(value);
  String get couponInput => logic.couponInput;
  set couponInput(String value) => logic.setCoupon(value);
  bool get couponApplied => logic.couponApplied;
  set couponApplied(bool value) => logic.setCouponApplied(value);
  bool get wardrobeExpanded => logic.wardrobeExpanded;
  set wardrobeExpanded(bool value) {
    if (logic.wardrobeExpanded != value) logic.toggleWardrobe();
  }
  bool get isSubmitting => logic.isSubmitting;
  set isSubmitting(bool value) => logic.setSubmitting(value);
  String get selectedSavedCard => logic.selectedSavedCard;
  set selectedSavedCard(String value) => logic.selectSavedCard(value);

  final TextEditingController cvvController = TextEditingController();
  final TextEditingController couponController =
  TextEditingController(text: 'HAUTE10');

  double get discount => logic.discount;

  static const double platformFeePerOutfit = 50;

  double get platformFee =>
      widget.outfits.length * platformFeePerOutfit;

  double get totalDue =>
      widget.rentalFee -
          discount +
          widget.coutureCareFee +
          widget.securityDeposit +
          platformFee;

  @override
  void initState() {
    super.initState();
    logic = PaymentSecurityLogic(
      rentalFee: widget.rentalFee,
      securityDeposit: widget.securityDeposit,
      coutureCareFee: widget.coutureCareFee,
      deliveryAddress: widget.deliveryAddress,
    );
  }

  String money(num amount) => '₹${amount.round()}';

  String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  DateTime startFor(Map<String, dynamic> outfit) =>
      DateTime.tryParse(outfit['rental_start_date']?.toString() ?? '') ?? DateTime.now();

  int daysFor(Map<String, dynamic> outfit) {
    final value = outfit['rental_days'];
    final days = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    return (days == null || days < 1) ? 4 : days;
  }

  DateTime returnFor(Map<String, dynamic> outfit) =>
      startFor(outfit).add(Duration(days: daysFor(outfit) - 1));

  String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

  String addressText() {
    final parts = [
      widget.deliveryAddress['house'],
      widget.deliveryAddress['street'],
      widget.deliveryAddress['landmark'],
      widget.deliveryAddress['city'],
      widget.deliveryAddress['state'],
      widget.deliveryAddress['pincode'],
    ];
    return parts
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  String outfitImage(Map<String, dynamic> outfit) {
    final cover = outfit['cover_image_url']?.toString() ?? '';
    if (cover.isNotEmpty) return cover;

    final images = outfit['images'];
    if (images is List) {
      for (final image in images) {
        if (image is Map && image['is_cover'] == true) {
          final url = image['image_url']?.toString() ?? '';
          if (url.isNotEmpty) return url;
        }
      }
      if (images.isNotEmpty && images.first is Map) {
        return images.first['image_url']?.toString() ?? '';
      }
    }
    return '';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    cvvController.dispose();
    couponController.dispose();
    logic.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Header — matches the Rent Out page, now showing step 2 of 2.
  // ---------------------------------------------------------------------------

  Widget _header() {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(13, 5, 15, 13),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: darkGreen),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment & Security',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        color: Color(0xFF202522),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Choose payment method & verify',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'STEP 2 OF 2',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Payment & Booking',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 3,
              backgroundColor: Color(0xFFE1E6E0),
              valueColor: AlwaysStoppedAnimation(green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _wardrobeBagCard() {
    return _panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => wardrobeExpanded = !wardrobeExpanded),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4EF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.workspace_premium_outlined,
                      color: darkGreen, size: 17),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wardrobe Bag (${widget.outfits.length} Items)',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          color: Color(0xFF202522),
                        ),
                      ),
                      Text(
                        '${widget.outfits.length} INDIVIDUAL RENTAL SCHEDULES',
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: .7,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  wardrobeExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  color: darkGreen,
                ),
              ],
            ),
          ),
          if (wardrobeExpanded) ...[
            const SizedBox(height: 15),
            const Divider(height: 1, color: border),
            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  width: 94,
                  height: 48,
                  child: Stack(
                    children: [
                      for (int i = 0; i < widget.outfits.length && i < 3; i++)
                        Positioned(
                          left: i * 28,
                          child: Container(
                            width: 32,
                            height: 46,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _image(widget.outfits[i]),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.outfits.length} outfits • dates selected individually',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.near_me_outlined, size: 11, color: darkGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              addressText().isEmpty
                                  ? 'Delivery address selected'
                                  : addressText(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...widget.outfits.map((outfit) {
              final start = startFor(outfit);
              final end = returnFor(outfit);
              final days = daysFor(outfit);
              final name = outfit['name']?.toString() ?? 'Outfit';
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkGreen)),
                    const SizedBox(height: 4),
                    Text('${shortDate(start)} – ${shortDate(end)}  •  $days days',
                        style: const TextStyle(fontSize: 10, color: muted)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _image(Map<String, dynamic> outfit) {
    final url = outfitImage(outfit);
    if (url.isEmpty) {
      return Container(
        color: paleGreen,
        child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: paleGreen,
        child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
      ),
    );
  }

  Widget _securityDepositCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F0),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE8DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_outlined, color: darkGreen, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '100% Refundable Security Deposit',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      money(widget.securityDeposit),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Held safely and automatically released back to your original payment source within 24 hours of return pickup inspection.',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentHeading() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'SELECT PAYMENT\nINSTRUMENT',
              style: TextStyle(fontSize: 11, letterSpacing: .7, height: 1.35, color: darkGreen),
            ),
          ),
          Text(
            'ENCRYPTED & PCI\nCOMPLIANT',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 10, letterSpacing: .8, height: 1.4, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _methodRadio(String value) {
    return Radio<String>(
      value: value,
      groupValue: selectedMethod,
      activeColor: darkGreen,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onChanged: (next) {
        if (next != null) setState(() => selectedMethod = next);
      },
    );
  }

  Widget _cardPaymentMethod() {
    final selected = selectedMethod == 'card';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.4 : 1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => selectedMethod = 'card'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
              child: Row(
                children: [
                  _methodRadio('card'),
                  const SizedBox(width: 3),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Luxury Credit & Debit Cards',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        SizedBox(height: 3),
                        Text('VISA  •  MASTERCARD  •  AMEX  •  DINERS',
                            style: TextStyle(fontSize: 9, letterSpacing: .7, color: muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.credit_card_outlined, color: darkGreen, size: 19),
                ],
              ),
            ),
          ),
          if (selected) ...[
            const Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SAVED ATELIER CARDS',
                      style: TextStyle(fontSize: 9, letterSpacing: .9, color: muted)),
                  const SizedBox(height: 12),
                  _savedCard(
                    name: 'HDFC Bank Infinia Metal',
                    number: '•••• •••• •••• 4092',
                    brand: 'INFINIA',
                    selected: selectedSavedCard == 'HDFC Bank Infinia Metal',
                    color: const Color(0xFF073F2B),
                  ),
                  const SizedBox(height: 10),
                  _savedCard(
                    name: 'ICICI Bank Emerald Card',
                    number: '•••• •••• •••• 8821',
                    brand: 'EMERALD',
                    selected: selectedSavedCard == 'ICICI Bank Emerald Card',
                    color: const Color(0xFF806B4D),
                  ),
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addCard,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('ADD ANOTHER CARD',
                          style: TextStyle(fontSize: 9, letterSpacing: .5)),
                      style: TextButton.styleFrom(
                        foregroundColor: darkGreen,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _savedCard({
    required String name,
    required String number,
    required String brand,
    required bool selected,
    required Color color,
  }) {
    return InkWell(
      onTap: () => setState(() => selectedSavedCard = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F2),
          border: Border.all(color: selected ? const Color(0xFF9EB6A7) : border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              child: Text(brand, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(number, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: .5)),
                ],
              ),
            ),
            if (selected)
              SizedBox(
                width: 64,
                height: 32,
                child: TextField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, letterSpacing: 2),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'CVV',
                    hintStyle: TextStyle(fontSize: 11, color: muted),
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: border),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: darkGreen),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border)),
                child: const Text('CVV', style: TextStyle(fontSize: 11, color: muted)),
              ),
            const SizedBox(width: 7),
            Icon(selected ? Icons.circle : Icons.circle_outlined,
                size: 8, color: selected ? green : border),
          ],
        ),
      ),
    );
  }

  Widget _simpleMethod({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    String? tag,
    String? trailingTag,
  }) {
    final selected = selectedMethod == value;
    return InkWell(
      onTap: () => setState(() => selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.3 : 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            _methodRadio(value),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15)),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          color: const Color(0xFFE1EEDF),
                          child: Text(tag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      if (trailingTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          color: const Color(0xFFFFE0B5),
                          child: Text(trailingTag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4)),
                ],
              ),
            ),
            Icon(icon, size: 18, color: darkGreen),
          ],
        ),
      ),
    );
  }

  Widget _couponSection() {
    return _panel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COUTURE INVITE OR VOUCHER',
              style: TextStyle(fontSize: 10, letterSpacing: .7, color: muted)),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: couponController,
                    onChanged: (value) => couponInput = value,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .5),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen), borderRadius: BorderRadius.zero),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen, width: 1.4), borderRadius: BorderRadius.zero),
                      suffixIcon: couponApplied ? const Icon(Icons.check_circle_outline, size: 15, color: darkGreen) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 72,
                child: ElevatedButton(
                  onPressed: () {
                    final valid = couponInput.trim().toUpperCase() == 'HAUTE10';
                    setState(() => couponApplied = valid);
                    showMessage(valid ? 'HAUTE10 applied successfully.' : 'Invalid voucher code.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('APPLY', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          if (couponApplied) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              color: const Color(0xFFEAF3E9),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 12, color: darkGreen),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text("VIP Code 'HAUTE10' applied",
                        style: TextStyle(fontSize: 10, color: darkGreen)),
                  ),
                  Text('- ${money(discount)} (10%)',
                      style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceLine(String label, String amount, {bool emphasized = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasized ? 16 : 13,
                color: emphasized ? darkGreen : const Color(0xFF555D57),
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (trailing != null) trailing else Text(
            amount,
            style: TextStyle(
              fontSize: emphasized ? 23 : 13,
              color: emphasized ? darkGreen : Colors.black87,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _investmentBreakdown() {
    return _panel(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atelier Investment Breakdown',
              style: TextStyle(fontFamily: 'serif', fontSize: 18, color: Color(0xFF24352C))),
          const Divider(height: 19, color: border),
          _priceLine('Rental Fee (individual outfit durations)', money(widget.rentalFee)),
          if (couponApplied)
            _priceLine('HAUTE10 Special Privilege', '- ${money(discount)}'),
          if (widget.coutureCareEnabled)
            _priceLine('Couture Care™ Damage Protection  ⓘ', money(widget.coutureCareFee)),
          _priceLine(
            'Platform Fee (${widget.outfits.length} outfits)',
            money(platformFee),
          ),
          _priceLine(
            'White-Glove Hand Courier & Pickup',
            'COMPLIMENTARY',
            trailing: const Text('COMPLIMENTARY',
                style: TextStyle(fontSize: 8, color: darkGreen, letterSpacing: .5, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 18, color: border),
          _priceLine(
            'Refundable Security Deposit',
            money(widget.securityDeposit),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('(Returned post-\nrental)',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 8, color: muted, height: 1.3)),
                const SizedBox(height: 2),
                Text(money(widget.securityDeposit),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 18, color: border),
          _priceLine(
            'Total Due Now',
            '',
            emphasized: true,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(totalDue),
                    style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('INCLUDES REFUNDABLE DEPOSIT',
                    style: TextStyle(fontSize: 7, color: muted, letterSpacing: .3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustGrid() {
    final items = [
      (Icons.verified_user_outlined, '256-BIT PROTECTION', 'PCI-DSS bank grade security'),
      (Icons.straighten_outlined, 'FIT GUARANTEE', 'Doorstep styling & swap backup'),
      (Icons.support_agent_outlined, '24/7 CONCIERGE', 'Dedicated atelier stylist assistance'),
      (Icons.refresh, 'INSTANT RELEASE', 'Automatic deposit refund in 24h'),
    ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F0),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 2.7,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$1, size: 16, color: darkGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .35)),
                    const SizedBox(height: 3),
                    Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: muted, height: 1.3)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('NET PAYABLE',
                      style: TextStyle(fontSize: 10, letterSpacing: .9, color: muted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  color: paleGreen,
                  child: Text('${money(widget.securityDeposit)} REFUNDABLE',
                      style: const TextStyle(fontSize: 9, color: darkGreen, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Row(
              children: [
                Text(money(totalDue),
                    style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 51,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : _confirmBooking,
                icon: isSubmitting
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 15),
                label: Text(isSubmitting ? 'PLACING RENTAL REQUESTS...' : 'CONFIRM DEMO BOOKING',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .3)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 8, color: muted),
                children: [
                  TextSpan(text: 'By confirming, you agree to ATTIRELY’s '),
                  TextSpan(text: 'Rental Agreement', style: TextStyle(decoration: TextDecoration.underline)),
                  TextSpan(text: ' & '),
                  TextSpan(text: 'Care Policy', style: TextStyle(decoration: TextDecoration.underline)),
                  TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a card'),
        content: const Text(
          'Connect your payment gateway here to securely add and tokenize a new card. Card details should not be stored directly in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE', style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (isSubmitting) return;

    if (widget.outfits.isEmpty) {
      showMessage('There are no outfits to book.');
      return;
    }

    // Validate the data required by RentalItemRequest before sending.
    final requestItems = <Map<String, dynamic>>[];

    for (final outfit in widget.outfits) {
      final outfitId = outfit['id']?.toString() ?? '';
      final selectedSize = outfit['selected_size']?.toString().trim() ?? '';

      if (outfitId.isEmpty || selectedSize.isEmpty) {
        showMessage('An outfit is missing its ID or selected size.');
        return;
      }

      requestItems.add({
        'outfit_id': outfitId,
        'selected_size': selectedSize,
        'rental_start_date': isoDate(startFor(outfit)),
        'rental_days': daysFor(outfit),
      });
    }

    setState(() => isSubmitting = true);

    try {
      if (widget.deliveryAddress.isEmpty) {
        showMessage('Please select a delivery address.');
        return;
      }
      // This is a simulated booking confirmation only.
      // No card details/CVV are sent and no real payment is collected.
      final response = await RentalsApiRoutes.createRentalBooking(
        items: requestItems,
        deliveryAddress: Map<String, dynamic>.from(widget.deliveryAddress),
      );

      final successfulItems =
      (response['successful_items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final failedItems =
      (response['failed_items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final successfulCount =
          (response['successful_count'] as num?)?.toInt() ??
              successfulItems.length;
      final failedCount =
          (response['failed_count'] as num?)?.toInt() ??
              failedItems.length;

      if (successfulCount == 0 || successfulItems.isEmpty) {
        await _showBookingResultDialog(
          successfulCount: 0,
          failedItems: failedItems,
          message: response['message']?.toString() ??
              'No outfits could be booked.',
          hasSuccess: false,
        );
        return;
      }

      // // Remove only outfits confirmed by the backend.
      // // Failed outfits remain in the cart for another attempt.
      // final cart = UserCartLogic.instance;
      // final cartRemovalFailures = <String>[];
      //
      // for (final item in successfulItems) {
      //   final outfitId = item['outfit_id']?.toString() ?? '';
      //   if (outfitId.isEmpty) continue;
      //
      //   final removed = await cart.removeOutfit(outfitId);
      //   if (!removed) {
      //     cartRemovalFailures.add(outfitId);
      //   }
      // }
      //
      // if (cartRemovalFailures.isNotEmpty) {
      //   // Refresh server cart state if any cleanup call failed.
      //   await cart.loadCart(refresh: true);
      // }

      if (!mounted) return;

      await _showBookingResultDialog(
        successfulCount: successfulCount,
        failedItems: failedItems,
        message: response['message']?.toString() ??
            '$successfulCount outfit(s) booked successfully.',
        hasSuccess: true,
        // cartRemovalFailures: cartRemovalFailures,
      );

    } catch (error) {
      if (mounted) {
        showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _showBookingResultDialog({
    required int successfulCount,
    required List<Map<String, dynamic>> failedItems,
    required String message,
    required bool hasSuccess,
    List<String> cartRemovalFailures = const [],
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasSuccess ? Icons.check_circle : Icons.error_outline,
              color: hasSuccess ? green : Colors.red.shade700,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hasSuccess ? 'Booking Result' : 'Booking Unsuccessful',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                if (hasSuccess) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$successfulCount outfit(s) booked successfully.',
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (failedItems.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Could not book:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ...failedItems.map((item) {
                    final outfitId = item['outfit_id']?.toString() ?? '';
                    final outfit = widget.outfits.firstWhere(
                          (outfit) => outfit['id']?.toString() == outfitId,
                      orElse: () => <String, dynamic>{},
                    );
                    final name = outfit['name']?.toString() ?? 'Outfit';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $name: ${item['message'] ?? 'Booking failed.'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ],
                if (cartRemovalFailures.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Some booked outfits could not be removed from your cart. '
                        'Please refresh your cart before trying again.',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Demo booking only. No real payment was collected.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (hasSuccess && mounted) {
      // Return to Rent Out; it will return to the cart after this result.
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/app_bg.png'),
              fit: BoxFit.cover,
              opacity: .30,
            ),
          ),
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 205),
                  children: [
                    _wardrobeBagCard(),
                    const SizedBox(height: 18),
                    _securityDepositCard(),
                    const SizedBox(height: 21),
                    _paymentHeading(),
                    const SizedBox(height: 12),
                    _cardPaymentMethod(),
                    const SizedBox(height: 12),
                    _simpleMethod(
                      value: 'upi',
                      title: 'UPI / Instant Pay',
                      subtitle: 'GOOGLE PAY  •  PHONEPE  •  CRED UPI',
                      icon: Icons.qr_code_2,
                      tag: 'POPULAR',
                    ),
                    const SizedBox(height: 12),
                    _simpleMethod(
                      value: 'emi',
                      title: 'No-Cost Couture EMI',
                      subtitle: 'FROM ₹3,965/MO FOR 3 MONTHS',
                      icon: Icons.calendar_month_outlined,
                      trailingTag: '0% INTEREST',
                    ),
                    const SizedBox(height: 12),
                    _simpleMethod(
                      value: 'netbanking',
                      title: 'Net Banking',
                      subtitle: 'HDFC, ICICI, SBI, AXIS & 40+ BANKS',
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 19),
                    _couponSection(),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      color: paleGreen,
                      child: const Text(
                        'DEMO PAYMENT — No real charge will be made. Card/CVV details are not collected.',
                        style: TextStyle(fontSize: 11, color: darkGreen),
                      ),
                    ),
                    const SizedBox(height: 19),
                    _investmentBreakdown(),
                    const SizedBox(height: 15),
                    _trustGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }
}


// import 'package:flutter/material.dart';
//
// class PaymentSecurityPage extends StatefulWidget {
//   final List<Map<String, dynamic>> outfits;
//   final int rentalDuration;
//   final DateTime deliveryDate;
//   final DateTime returnDate;
//   final Map<String, dynamic> deliveryAddress;
//   final double rentalFee;
//   final double securityDeposit;
//   final double coutureCareFee;
//   final bool coutureCareEnabled;
//   final bool backupSizeIncluded;
//
//   const PaymentSecurityPage({
//     super.key,
//     required this.outfits,
//     required this.rentalDuration,
//     required this.deliveryDate,
//     required this.returnDate,
//     required this.deliveryAddress,
//     required this.rentalFee,
//     required this.securityDeposit,
//     required this.coutureCareFee,
//     required this.coutureCareEnabled,
//     required this.backupSizeIncluded,
//   });
//
//   @override
//   State<PaymentSecurityPage> createState() => _PaymentSecurityPageState();
// }
//
// class _PaymentSecurityPageState extends State<PaymentSecurityPage> {
//   static const Color green = Color(0xFF064C32);
//   static const Color darkGreen = Color(0xFF073F2B);
//   static const Color background = Color(0xFFF7F8F5);
//   static const Color border = Color(0xFFE5E9E4);
//   static const Color muted = Color(0xFF777E79);
//   static const Color paleGreen = Color(0xFFEAF3E9);
//
//   String selectedMethod = 'card';
//   String couponInput = 'HAUTE10';
//   bool couponApplied = true;
//   bool wardrobeExpanded = true;
//   String selectedSavedCard = 'HDFC Bank Infinia Metal';
//   final TextEditingController cvvController = TextEditingController();
//   final TextEditingController couponController =
//   TextEditingController(text: 'HAUTE10');
//
//   double get discount => couponApplied ? widget.rentalFee * 0.10 : 0;
//   double get totalDue =>
//       widget.rentalFee -
//           discount +
//           widget.coutureCareFee +
//           widget.securityDeposit;
//
//   String money(num amount) => '₹${amount.round()}';
//
//   String shortDate(DateTime date) {
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return '${months[date.month - 1]} ${date.day}';
//   }
//
//   String addressText() {
//     final parts = [
//       widget.deliveryAddress['house'],
//       widget.deliveryAddress['street'],
//       widget.deliveryAddress['landmark'],
//       widget.deliveryAddress['city'],
//       widget.deliveryAddress['state'],
//       widget.deliveryAddress['pincode'],
//     ];
//     return parts
//         .where((part) => part != null && part.toString().trim().isNotEmpty)
//         .join(', ');
//   }
//
//   String outfitImage(Map<String, dynamic> outfit) {
//     final cover = outfit['cover_image_url']?.toString() ?? '';
//     if (cover.isNotEmpty) return cover;
//
//     final images = outfit['images'];
//     if (images is List) {
//       for (final image in images) {
//         if (image is Map && image['is_cover'] == true) {
//           final url = image['image_url']?.toString() ?? '';
//           if (url.isNotEmpty) return url;
//         }
//       }
//       if (images.isNotEmpty && images.first is Map) {
//         return images.first['image_url']?.toString() ?? '';
//       }
//     }
//     return '';
//   }
//
//   void showMessage(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//   }
//
//   @override
//   void dispose() {
//     cvvController.dispose();
//     couponController.dispose();
//     super.dispose();
//   }
//
//   // ---------------------------------------------------------------------------
//   // Header — matches the Rent Out page, now showing step 2 of 2.
//   // ---------------------------------------------------------------------------
//
//   Widget _header() {
//     return Container(
//       color: background,
//       padding: const EdgeInsets.fromLTRB(13, 5, 15, 13),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back, color: darkGreen),
//               ),
//               const SizedBox(width: 4),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Payment & Security',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontFamily: 'serif',
//                         fontSize: 22,
//                         color: Color(0xFF202522),
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     const Text(
//                       'Choose payment method & verify',
//                       style: TextStyle(color: muted, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: const [
//                   Text(
//                     'STEP 2 OF 2',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 3),
//                   Text(
//                     'Payment & Booking',
//                     style: TextStyle(
//                       color: muted,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 9),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(5),
//             child: const LinearProgressIndicator(
//               value: 1,
//               minHeight: 3,
//               backgroundColor: Color(0xFFE1E6E0),
//               valueColor: AlwaysStoppedAnimation(green),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
//     return Container(
//       padding: padding,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.025),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
//
//   Widget _wardrobeBagCard() {
//     return _panel(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => setState(() => wardrobeExpanded = !wardrobeExpanded),
//             child: Row(
//               children: [
//                 Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF1F4EF),
//                     borderRadius: BorderRadius.circular(7),
//                   ),
//                   child: const Icon(Icons.workspace_premium_outlined,
//                       color: darkGreen, size: 17),
//                 ),
//                 const SizedBox(width: 13),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Wardrobe Bag (${widget.outfits.length} Items)',
//                         style: const TextStyle(
//                           fontFamily: 'serif',
//                           fontSize: 18,
//                           color: Color(0xFF202522),
//                         ),
//                       ),
//                       Text(
//                         '${widget.outfits.length} INDIVIDUAL RENTAL SCHEDULES',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           letterSpacing: .7,
//                           color: muted,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   wardrobeExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
//                   color: darkGreen,
//                 ),
//               ],
//             ),
//           ),
//           if (wardrobeExpanded) ...[
//             const SizedBox(height: 15),
//             const Divider(height: 1, color: border),
//             const SizedBox(height: 15),
//             Row(
//               children: [
//                 SizedBox(
//                   width: 94,
//                   height: 48,
//                   child: Stack(
//                     children: [
//                       for (int i = 0; i < widget.outfits.length && i < 3; i++)
//                         Positioned(
//                           left: i * 28,
//                           child: Container(
//                             width: 32,
//                             height: 46,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.white, width: 1.2),
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                             clipBehavior: Clip.antiAlias,
//                             child: _image(widget.outfits[i]),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 13),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${widget.outfits.length} outfits • dates selected individually',
//                         style: const TextStyle(fontSize: 14, color: Colors.black87),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.near_me_outlined, size: 11, color: darkGreen),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               addressText().isEmpty
//                                   ? 'Delivery address selected'
//                                   : addressText(),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 11, color: muted),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _image(Map<String, dynamic> outfit) {
//     final url = outfitImage(outfit);
//     if (url.isEmpty) {
//       return Container(
//         color: paleGreen,
//         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
//       );
//     }
//     return Image.network(
//       url,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Container(
//         color: paleGreen,
//         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
//       ),
//     );
//   }
//
//   Widget _securityDepositCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F3F0),
//         borderRadius: BorderRadius.circular(5),
//         border: Border.all(color: border),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: const BoxDecoration(
//               color: Color(0xFFDCE8DF),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.lock_clock_outlined, color: darkGreen, size: 17),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         '100% Refundable Security Deposit',
//                         style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Text(
//                       money(widget.securityDeposit),
//                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 5),
//                 const Text(
//                   'Held safely and automatically released back to your original payment source within 24 hours of return pickup inspection.',
//                   style: TextStyle(fontSize: 12, color: muted, height: 1.5),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _paymentHeading() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 3),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Text(
//               'SELECT PAYMENT\nINSTRUMENT',
//               style: TextStyle(fontSize: 11, letterSpacing: .7, height: 1.35, color: darkGreen),
//             ),
//           ),
//           Text(
//             'ENCRYPTED & PCI\nCOMPLIANT',
//             textAlign: TextAlign.left,
//             style: TextStyle(fontSize: 10, letterSpacing: .8, height: 1.4, color: muted),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _methodRadio(String value) {
//     return Radio<String>(
//       value: value,
//       groupValue: selectedMethod,
//       activeColor: darkGreen,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: VisualDensity.compact,
//       onChanged: (next) {
//         if (next != null) setState(() => selectedMethod = next);
//       },
//     );
//   }
//
//   Widget _cardPaymentMethod() {
//     final selected = selectedMethod == 'card';
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.4 : 1),
//         borderRadius: BorderRadius.circular(7),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => setState(() => selectedMethod = 'card'),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
//               child: Row(
//                 children: [
//                   _methodRadio('card'),
//                   const SizedBox(width: 3),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Luxury Credit & Debit Cards',
//                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
//                         SizedBox(height: 3),
//                         Text('VISA  •  MASTERCARD  •  AMEX  •  DINERS',
//                             style: TextStyle(fontSize: 9, letterSpacing: .7, color: muted)),
//                       ],
//                     ),
//                   ),
//                   const Icon(Icons.credit_card_outlined, color: darkGreen, size: 19),
//                 ],
//               ),
//             ),
//           ),
//           if (selected) ...[
//             const Divider(height: 1, color: border),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('SAVED ATELIER CARDS',
//                       style: TextStyle(fontSize: 9, letterSpacing: .9, color: muted)),
//                   const SizedBox(height: 12),
//                   _savedCard(
//                     name: 'HDFC Bank Infinia Metal',
//                     number: '•••• •••• •••• 4092',
//                     brand: 'INFINIA',
//                     selected: selectedSavedCard == 'HDFC Bank Infinia Metal',
//                     color: const Color(0xFF073F2B),
//                   ),
//                   const SizedBox(height: 10),
//                   _savedCard(
//                     name: 'ICICI Bank Emerald Card',
//                     number: '•••• •••• •••• 8821',
//                     brand: 'EMERALD',
//                     selected: selectedSavedCard == 'ICICI Bank Emerald Card',
//                     color: const Color(0xFF806B4D),
//                   ),
//                   const SizedBox(height: 9),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton.icon(
//                       onPressed: _addCard,
//                       icon: const Icon(Icons.add, size: 14),
//                       label: const Text('ADD ANOTHER CARD',
//                           style: TextStyle(fontSize: 9, letterSpacing: .5)),
//                       style: TextButton.styleFrom(
//                         foregroundColor: darkGreen,
//                         padding: EdgeInsets.zero,
//                         minimumSize: Size.zero,
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _savedCard({
//     required String name,
//     required String number,
//     required String brand,
//     required bool selected,
//     required Color color,
//   }) {
//     return InkWell(
//       onTap: () => setState(() => selectedSavedCard = name),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F5F2),
//           border: Border.all(color: selected ? const Color(0xFF9EB6A7) : border),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 21,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
//               child: Text(brand, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 12)),
//                   const SizedBox(height: 2),
//                   Text(number, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: .5)),
//                 ],
//               ),
//             ),
//             if (selected)
//               SizedBox(
//                 width: 64,
//                 height: 32,
//                 child: TextField(
//                   controller: cvvController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 4,
//                   obscureText: true,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 10, letterSpacing: 2),
//                   decoration: const InputDecoration(
//                     counterText: '',
//                     hintText: 'CVV',
//                     hintStyle: TextStyle(fontSize: 11, color: muted),
//                     contentPadding: EdgeInsets.symmetric(vertical: 6),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.zero),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: border),
//                       borderRadius: BorderRadius.zero,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: darkGreen),
//                       borderRadius: BorderRadius.zero,
//                     ),
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 width: 56,
//                 height: 29,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border)),
//                 child: const Text('CVV', style: TextStyle(fontSize: 11, color: muted)),
//               ),
//             const SizedBox(width: 7),
//             Icon(selected ? Icons.circle : Icons.circle_outlined,
//                 size: 8, color: selected ? green : border),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _simpleMethod({
//     required String value,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     String? tag,
//     String? trailingTag,
//   }) {
//     final selected = selectedMethod == value;
//     return InkWell(
//       onTap: () => setState(() => selectedMethod = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.3 : 1),
//           borderRadius: BorderRadius.circular(4),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 6, offset: const Offset(0, 2)),
//           ],
//         ),
//         child: Row(
//           children: [
//             _methodRadio(value),
//             const SizedBox(width: 3),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Wrap(
//                     spacing: 7,
//                     crossAxisAlignment: WrapCrossAlignment.center,
//                     children: [
//                       Text(title, style: const TextStyle(fontSize: 15)),
//                       if (tag != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                           color: const Color(0xFFE1EEDF),
//                           child: Text(tag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//                         ),
//                       if (trailingTag != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                           color: const Color(0xFFFFE0B5),
//                           child: Text(trailingTag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(subtitle, style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4)),
//                 ],
//               ),
//             ),
//             Icon(icon, size: 18, color: darkGreen),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _couponSection() {
//     return _panel(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('COUTURE INVITE OR VOUCHER',
//               style: TextStyle(fontSize: 10, letterSpacing: .7, color: muted)),
//           const SizedBox(height: 9),
//           Row(
//             children: [
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: TextField(
//                     controller: couponController,
//                     onChanged: (value) => couponInput = value,
//                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .5),
//                     decoration: InputDecoration(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 10),
//                       border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
//                       enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen), borderRadius: BorderRadius.zero),
//                       focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen, width: 1.4), borderRadius: BorderRadius.zero),
//                       suffixIcon: couponApplied ? const Icon(Icons.check_circle_outline, size: 15, color: darkGreen) : null,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               SizedBox(
//                 height: 44,
//                 width: 72,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     final valid = couponInput.trim().toUpperCase() == 'HAUTE10';
//                     setState(() => couponApplied = valid);
//                     showMessage(valid ? 'HAUTE10 applied successfully.' : 'Invalid voucher code.');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: green,
//                     foregroundColor: Colors.white,
//                     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//                     padding: EdgeInsets.zero,
//                   ),
//                   child: const Text('APPLY', style: TextStyle(fontSize: 12)),
//                 ),
//               ),
//             ],
//           ),
//           if (couponApplied) ...[
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
//               color: const Color(0xFFEAF3E9),
//               child: Row(
//                 children: [
//                   const Icon(Icons.sell_outlined, size: 12, color: darkGreen),
//                   const SizedBox(width: 6),
//                   const Expanded(
//                     child: Text("VIP Code 'HAUTE10' applied",
//                         style: TextStyle(fontSize: 10, color: darkGreen)),
//                   ),
//                   Text('- ${money(discount)} (10%)',
//                       style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _priceLine(String label, String amount, {bool emphasized = false, Widget? trailing}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 9),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: emphasized ? 16 : 13,
//                 color: emphasized ? darkGreen : const Color(0xFF555D57),
//                 fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ),
//           if (trailing != null) trailing else Text(
//             amount,
//             style: TextStyle(
//               fontSize: emphasized ? 23 : 13,
//               color: emphasized ? darkGreen : Colors.black87,
//               fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _investmentBreakdown() {
//     return _panel(
//       padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Atelier Investment Breakdown',
//               style: TextStyle(fontFamily: 'serif', fontSize: 18, color: Color(0xFF24352C))),
//           const Divider(height: 19, color: border),
//           _priceLine('Rental Fee (individual outfit durations)', money(widget.rentalFee)),
//           if (couponApplied)
//             _priceLine('HAUTE10 Special Privilege', '- ${money(discount)}'),
//           if (widget.coutureCareEnabled)
//             _priceLine('Couture Care™ Damage Protection  ⓘ', money(widget.coutureCareFee)),
//           _priceLine(
//             'White-Glove Hand Courier & Pickup',
//             'COMPLIMENTARY',
//             trailing: const Text('COMPLIMENTARY',
//                 style: TextStyle(fontSize: 8, color: darkGreen, letterSpacing: .5, fontWeight: FontWeight.w600)),
//           ),
//           const Divider(height: 18, color: border),
//           _priceLine(
//             'Refundable Security Deposit',
//             money(widget.securityDeposit),
//             trailing: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 const Text('(Returned post-\nrental)',
//                     textAlign: TextAlign.right,
//                     style: TextStyle(fontSize: 8, color: muted, height: 1.3)),
//                 const SizedBox(height: 2),
//                 Text(money(widget.securityDeposit),
//                     style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
//               ],
//             ),
//           ),
//           const Divider(height: 18, color: border),
//           _priceLine(
//             'Total Due Now',
//             '',
//             emphasized: true,
//             trailing: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(money(totalDue),
//                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 2),
//                 const Text('INCLUDES REFUNDABLE DEPOSIT',
//                     style: TextStyle(fontSize: 7, color: muted, letterSpacing: .3)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _trustGrid() {
//     final items = [
//       (Icons.verified_user_outlined, '256-BIT PROTECTION', 'PCI-DSS bank grade security'),
//       (Icons.straighten_outlined, 'FIT GUARANTEE', 'Doorstep styling & swap backup'),
//       (Icons.support_agent_outlined, '24/7 CONCIERGE', 'Dedicated atelier stylist assistance'),
//       (Icons.refresh, 'INSTANT RELEASE', 'Automatic deposit refund in 24h'),
//     ];
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F3F0),
//         borderRadius: BorderRadius.circular(5),
//         border: Border.all(color: border),
//       ),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: items.length,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 16,
//           crossAxisSpacing: 8,
//           childAspectRatio: 2.7,
//         ),
//         itemBuilder: (context, index) {
//           final item = items[index];
//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(item.$1, size: 16, color: darkGreen),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .35)),
//                     const SizedBox(height: 3),
//                     Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 9, color: muted, height: 1.3)),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _bottomBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 12, offset: const Offset(0, -3)),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 const Expanded(
//                   child: Text('NET PAYABLE',
//                       style: TextStyle(fontSize: 10, letterSpacing: .9, color: muted)),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//                   color: paleGreen,
//                   child: Text('${money(widget.securityDeposit)} REFUNDABLE',
//                       style: const TextStyle(fontSize: 9, color: darkGreen, fontWeight: FontWeight.w600)),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 Text(money(totalDue),
//                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               height: 51,
//               child: ElevatedButton.icon(
//                 onPressed: _confirmBooking,
//                 icon: const Icon(Icons.lock_outline, size: 15),
//                 label: Text('PAY ${money(totalDue)} & CONFIRM BOOKING',
//                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .3)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: green,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                   elevation: 0,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text.rich(
//               TextSpan(
//                 style: TextStyle(fontSize: 8, color: muted),
//                 children: [
//                   TextSpan(text: 'By confirming, you agree to ATTIRELY’s '),
//                   TextSpan(text: 'Rental Agreement', style: TextStyle(decoration: TextDecoration.underline)),
//                   TextSpan(text: ' & '),
//                   TextSpan(text: 'Care Policy', style: TextStyle(decoration: TextDecoration.underline)),
//                   TextSpan(text: '.'),
//                 ],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _addCard() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Add a card'),
//         content: const Text(
//           'Connect your payment gateway here to securely add and tokenize a new card. Card details should not be stored directly in the app.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('CLOSE', style: TextStyle(color: green)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmBooking() {
//     if (selectedMethod == 'card' && cvvController.text.isNotEmpty && cvvController.text.length < 3) {
//       showMessage('Please enter a valid CVV.');
//       return;
//     }
//
//     // Payment gateway / booking API integration belongs here.
//     showMessage('Payment gateway integration is required to confirm this booking.');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: background,
//       body: SafeArea(
//         top: true,
//         bottom: false,
//         child: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/images/app_bg.png'),
//               fit: BoxFit.cover,
//               opacity: .30,
//             ),
//           ),
//           child: Column(
//             children: [
//               _header(),
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 205),
//                   children: [
//                     _wardrobeBagCard(),
//                     const SizedBox(height: 18),
//                     _securityDepositCard(),
//                     const SizedBox(height: 21),
//                     _paymentHeading(),
//                     const SizedBox(height: 12),
//                     _cardPaymentMethod(),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'upi',
//                       title: 'UPI / Instant Pay',
//                       subtitle: 'GOOGLE PAY  •  PHONEPE  •  CRED UPI',
//                       icon: Icons.qr_code_2,
//                       tag: 'POPULAR',
//                     ),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'emi',
//                       title: 'No-Cost Couture EMI',
//                       subtitle: 'FROM ₹3,965/MO FOR 3 MONTHS',
//                       icon: Icons.calendar_month_outlined,
//                       trailingTag: '0% INTEREST',
//                     ),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'netbanking',
//                       title: 'Net Banking',
//                       subtitle: 'HDFC, ICICI, SBI, AXIS & 40+ BANKS',
//                       icon: Icons.account_balance_outlined,
//                     ),
//                     const SizedBox(height: 19),
//                     _couponSection(),
//                     const SizedBox(height: 19),
//                     _investmentBreakdown(),
//                     const SizedBox(height: 15),
//                     _trustGrid(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: _bottomBar(),
//     );
//   }
// }


// import 'package:flutter/material.dart';
//
// import '../U_API_Routes/u_rental_api_routes.dart';
// import '../U_Ui_Logic/user_cart_logic.dart';
//
// class PaymentSecurityPage extends StatefulWidget {
//   final List<Map<String, dynamic>> outfits;
//   final Map<String, dynamic> deliveryAddress;
//   final double rentalFee;
//   final double securityDeposit;
//   final double coutureCareFee;
//   final bool coutureCareEnabled;
//   final bool backupSizeIncluded;
//
//   const PaymentSecurityPage({
//     super.key,
//     required this.outfits,
//     required this.deliveryAddress,
//     required this.rentalFee,
//     required this.securityDeposit,
//     required this.coutureCareFee,
//     required this.coutureCareEnabled,
//     required this.backupSizeIncluded,
//   });
//
//   @override
//   State<PaymentSecurityPage> createState() => _PaymentSecurityPageState();
// }
//
// class _PaymentSecurityPageState extends State<PaymentSecurityPage> {
//   static const Color green = Color(0xFF064C32);
//   static const Color darkGreen = Color(0xFF073F2B);
//   static const Color background = Color(0xFFF7F8F5);
//   static const Color border = Color(0xFFE5E9E4);
//   static const Color muted = Color(0xFF777E79);
//   static const Color paleGreen = Color(0xFFEAF3E9);
//
//   String selectedMethod = 'card';
//   String couponInput = 'HAUTE10';
//   bool couponApplied = true;
//   bool wardrobeExpanded = true;
//   bool isSubmitting = false;
//   String selectedSavedCard = 'HDFC Bank Infinia Metal';
//   final TextEditingController cvvController = TextEditingController();
//   final TextEditingController couponController =
//   TextEditingController(text: 'HAUTE10');
//
//   double get discount => couponApplied ? widget.rentalFee * 0.10 : 0;
//   double get totalDue =>
//       widget.rentalFee -
//           discount +
//           widget.coutureCareFee +
//           widget.securityDeposit;
//
//   String money(num amount) => '₹${amount.round()}';
//
//   String shortDate(DateTime date) {
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     return '${months[date.month - 1]} ${date.day}';
//   }
//
//   DateTime startFor(Map<String, dynamic> outfit) =>
//       DateTime.tryParse(outfit['rental_start_date']?.toString() ?? '') ?? DateTime.now();
//
//   int daysFor(Map<String, dynamic> outfit) {
//     final value = outfit['rental_days'];
//     final days = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
//     return (days == null || days < 1) ? 4 : days;
//   }
//
//   DateTime returnFor(Map<String, dynamic> outfit) =>
//       startFor(outfit).add(Duration(days: daysFor(outfit) - 1));
//
//   String isoDate(DateTime date) =>
//       '${date.year.toString().padLeft(4, '0')}-'
//           '${date.month.toString().padLeft(2, '0')}-'
//           '${date.day.toString().padLeft(2, '0')}';
//
//   String addressText() {
//     final parts = [
//       widget.deliveryAddress['house'],
//       widget.deliveryAddress['street'],
//       widget.deliveryAddress['landmark'],
//       widget.deliveryAddress['city'],
//       widget.deliveryAddress['state'],
//       widget.deliveryAddress['pincode'],
//     ];
//     return parts
//         .where((part) => part != null && part.toString().trim().isNotEmpty)
//         .join(', ');
//   }
//
//   String outfitImage(Map<String, dynamic> outfit) {
//     final cover = outfit['cover_image_url']?.toString() ?? '';
//     if (cover.isNotEmpty) return cover;
//
//     final images = outfit['images'];
//     if (images is List) {
//       for (final image in images) {
//         if (image is Map && image['is_cover'] == true) {
//           final url = image['image_url']?.toString() ?? '';
//           if (url.isNotEmpty) return url;
//         }
//       }
//       if (images.isNotEmpty && images.first is Map) {
//         return images.first['image_url']?.toString() ?? '';
//       }
//     }
//     return '';
//   }
//
//   void showMessage(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//   }
//
//   @override
//   void dispose() {
//     cvvController.dispose();
//     couponController.dispose();
//     super.dispose();
//   }
//
//   // ---------------------------------------------------------------------------
//   // Header — matches the Rent Out page, now showing step 2 of 2.
//   // ---------------------------------------------------------------------------
//
//   Widget _header() {
//     return Container(
//       color: background,
//       padding: const EdgeInsets.fromLTRB(13, 5, 15, 13),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back, color: darkGreen),
//               ),
//               const SizedBox(width: 4),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Payment & Security',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontFamily: 'serif',
//                         fontSize: 22,
//                         color: Color(0xFF202522),
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     const Text(
//                       'Choose payment method & verify',
//                       style: TextStyle(color: muted, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: const [
//                   Text(
//                     'STEP 2 OF 2',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 3),
//                   Text(
//                     'Payment & Booking',
//                     style: TextStyle(
//                       color: muted,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 9),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(5),
//             child: const LinearProgressIndicator(
//               value: 1,
//               minHeight: 3,
//               backgroundColor: Color(0xFFE1E6E0),
//               valueColor: AlwaysStoppedAnimation(green),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
//     return Container(
//       padding: padding,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.025),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
//
//   Widget _wardrobeBagCard() {
//     return _panel(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => setState(() => wardrobeExpanded = !wardrobeExpanded),
//             child: Row(
//               children: [
//                 Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF1F4EF),
//                     borderRadius: BorderRadius.circular(7),
//                   ),
//                   child: const Icon(Icons.workspace_premium_outlined,
//                       color: darkGreen, size: 17),
//                 ),
//                 const SizedBox(width: 13),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Wardrobe Bag (${widget.outfits.length} Items)',
//                         style: const TextStyle(
//                           fontFamily: 'serif',
//                           fontSize: 18,
//                           color: Color(0xFF202522),
//                         ),
//                       ),
//                       Text(
//                         '${widget.outfits.length} INDIVIDUAL RENTAL SCHEDULES',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           letterSpacing: .7,
//                           color: muted,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   wardrobeExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
//                   color: darkGreen,
//                 ),
//               ],
//             ),
//           ),
//           if (wardrobeExpanded) ...[
//             const SizedBox(height: 15),
//             const Divider(height: 1, color: border),
//             const SizedBox(height: 15),
//             Row(
//               children: [
//                 SizedBox(
//                   width: 94,
//                   height: 48,
//                   child: Stack(
//                     children: [
//                       for (int i = 0; i < widget.outfits.length && i < 3; i++)
//                         Positioned(
//                           left: i * 28,
//                           child: Container(
//                             width: 32,
//                             height: 46,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.white, width: 1.2),
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                             clipBehavior: Clip.antiAlias,
//                             child: _image(widget.outfits[i]),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 13),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${widget.outfits.length} outfits • dates selected individually',
//                         style: const TextStyle(fontSize: 14, color: Colors.black87),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.near_me_outlined, size: 11, color: darkGreen),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               addressText().isEmpty
//                                   ? 'Delivery address selected'
//                                   : addressText(),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 11, color: muted),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             ...widget.outfits.map((outfit) {
//               final start = startFor(outfit);
//               final end = returnFor(outfit);
//               final days = daysFor(outfit);
//               final name = outfit['name']?.toString() ?? 'Outfit';
//               return Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF7F9F6),
//                   border: Border.all(color: border),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkGreen)),
//                     const SizedBox(height: 4),
//                     Text('${shortDate(start)} – ${shortDate(end)}  •  $days days',
//                         style: const TextStyle(fontSize: 10, color: muted)),
//                   ],
//                 ),
//               );
//             }),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _image(Map<String, dynamic> outfit) {
//     final url = outfitImage(outfit);
//     if (url.isEmpty) {
//       return Container(
//         color: paleGreen,
//         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
//       );
//     }
//     return Image.network(
//       url,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Container(
//         color: paleGreen,
//         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
//       ),
//     );
//   }
//
//   Widget _securityDepositCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F3F0),
//         borderRadius: BorderRadius.circular(5),
//         border: Border.all(color: border),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: const BoxDecoration(
//               color: Color(0xFFDCE8DF),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.lock_clock_outlined, color: darkGreen, size: 17),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         '100% Refundable Security Deposit',
//                         style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                     Text(
//                       money(widget.securityDeposit),
//                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 5),
//                 const Text(
//                   'Held safely and automatically released back to your original payment source within 24 hours of return pickup inspection.',
//                   style: TextStyle(fontSize: 12, color: muted, height: 1.5),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _paymentHeading() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 3),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Text(
//               'SELECT PAYMENT\nINSTRUMENT',
//               style: TextStyle(fontSize: 11, letterSpacing: .7, height: 1.35, color: darkGreen),
//             ),
//           ),
//           Text(
//             'ENCRYPTED & PCI\nCOMPLIANT',
//             textAlign: TextAlign.left,
//             style: TextStyle(fontSize: 10, letterSpacing: .8, height: 1.4, color: muted),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _methodRadio(String value) {
//     return Radio<String>(
//       value: value,
//       groupValue: selectedMethod,
//       activeColor: darkGreen,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       visualDensity: VisualDensity.compact,
//       onChanged: (next) {
//         if (next != null) setState(() => selectedMethod = next);
//       },
//     );
//   }
//
//   Widget _cardPaymentMethod() {
//     final selected = selectedMethod == 'card';
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.4 : 1),
//         borderRadius: BorderRadius.circular(7),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () => setState(() => selectedMethod = 'card'),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
//               child: Row(
//                 children: [
//                   _methodRadio('card'),
//                   const SizedBox(width: 3),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Luxury Credit & Debit Cards',
//                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
//                         SizedBox(height: 3),
//                         Text('VISA  •  MASTERCARD  •  AMEX  •  DINERS',
//                             style: TextStyle(fontSize: 9, letterSpacing: .7, color: muted)),
//                       ],
//                     ),
//                   ),
//                   const Icon(Icons.credit_card_outlined, color: darkGreen, size: 19),
//                 ],
//               ),
//             ),
//           ),
//           if (selected) ...[
//             const Divider(height: 1, color: border),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('SAVED ATELIER CARDS',
//                       style: TextStyle(fontSize: 9, letterSpacing: .9, color: muted)),
//                   const SizedBox(height: 12),
//                   _savedCard(
//                     name: 'HDFC Bank Infinia Metal',
//                     number: '•••• •••• •••• 4092',
//                     brand: 'INFINIA',
//                     selected: selectedSavedCard == 'HDFC Bank Infinia Metal',
//                     color: const Color(0xFF073F2B),
//                   ),
//                   const SizedBox(height: 10),
//                   _savedCard(
//                     name: 'ICICI Bank Emerald Card',
//                     number: '•••• •••• •••• 8821',
//                     brand: 'EMERALD',
//                     selected: selectedSavedCard == 'ICICI Bank Emerald Card',
//                     color: const Color(0xFF806B4D),
//                   ),
//                   const SizedBox(height: 9),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton.icon(
//                       onPressed: _addCard,
//                       icon: const Icon(Icons.add, size: 14),
//                       label: const Text('ADD ANOTHER CARD',
//                           style: TextStyle(fontSize: 9, letterSpacing: .5)),
//                       style: TextButton.styleFrom(
//                         foregroundColor: darkGreen,
//                         padding: EdgeInsets.zero,
//                         minimumSize: Size.zero,
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _savedCard({
//     required String name,
//     required String number,
//     required String brand,
//     required bool selected,
//     required Color color,
//   }) {
//     return InkWell(
//       onTap: () => setState(() => selectedSavedCard = name),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F5F2),
//           border: Border.all(color: selected ? const Color(0xFF9EB6A7) : border),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 21,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
//               child: Text(brand, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 12)),
//                   const SizedBox(height: 2),
//                   Text(number, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: .5)),
//                 ],
//               ),
//             ),
//             if (selected)
//               SizedBox(
//                 width: 64,
//                 height: 32,
//                 child: TextField(
//                   controller: cvvController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 4,
//                   obscureText: true,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 10, letterSpacing: 2),
//                   decoration: const InputDecoration(
//                     counterText: '',
//                     hintText: 'CVV',
//                     hintStyle: TextStyle(fontSize: 11, color: muted),
//                     contentPadding: EdgeInsets.symmetric(vertical: 6),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.zero),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: border),
//                       borderRadius: BorderRadius.zero,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: darkGreen),
//                       borderRadius: BorderRadius.zero,
//                     ),
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 width: 56,
//                 height: 29,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border)),
//                 child: const Text('CVV', style: TextStyle(fontSize: 11, color: muted)),
//               ),
//             const SizedBox(width: 7),
//             Icon(selected ? Icons.circle : Icons.circle_outlined,
//                 size: 8, color: selected ? green : border),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _simpleMethod({
//     required String value,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     String? tag,
//     String? trailingTag,
//   }) {
//     final selected = selectedMethod == value;
//     return InkWell(
//       onTap: () => setState(() => selectedMethod = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.3 : 1),
//           borderRadius: BorderRadius.circular(4),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 6, offset: const Offset(0, 2)),
//           ],
//         ),
//         child: Row(
//           children: [
//             _methodRadio(value),
//             const SizedBox(width: 3),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Wrap(
//                     spacing: 7,
//                     crossAxisAlignment: WrapCrossAlignment.center,
//                     children: [
//                       Text(title, style: const TextStyle(fontSize: 15)),
//                       if (tag != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                           color: const Color(0xFFE1EEDF),
//                           child: Text(tag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//                         ),
//                       if (trailingTag != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                           color: const Color(0xFFFFE0B5),
//                           child: Text(trailingTag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(subtitle, style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4)),
//                 ],
//               ),
//             ),
//             Icon(icon, size: 18, color: darkGreen),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _couponSection() {
//     return _panel(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('COUTURE INVITE OR VOUCHER',
//               style: TextStyle(fontSize: 10, letterSpacing: .7, color: muted)),
//           const SizedBox(height: 9),
//           Row(
//             children: [
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: TextField(
//                     controller: couponController,
//                     onChanged: (value) => couponInput = value,
//                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .5),
//                     decoration: InputDecoration(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 10),
//                       border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
//                       enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen), borderRadius: BorderRadius.zero),
//                       focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen, width: 1.4), borderRadius: BorderRadius.zero),
//                       suffixIcon: couponApplied ? const Icon(Icons.check_circle_outline, size: 15, color: darkGreen) : null,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               SizedBox(
//                 height: 44,
//                 width: 72,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     final valid = couponInput.trim().toUpperCase() == 'HAUTE10';
//                     setState(() => couponApplied = valid);
//                     showMessage(valid ? 'HAUTE10 applied successfully.' : 'Invalid voucher code.');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: green,
//                     foregroundColor: Colors.white,
//                     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//                     padding: EdgeInsets.zero,
//                   ),
//                   child: const Text('APPLY', style: TextStyle(fontSize: 12)),
//                 ),
//               ),
//             ],
//           ),
//           if (couponApplied) ...[
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
//               color: const Color(0xFFEAF3E9),
//               child: Row(
//                 children: [
//                   const Icon(Icons.sell_outlined, size: 12, color: darkGreen),
//                   const SizedBox(width: 6),
//                   const Expanded(
//                     child: Text("VIP Code 'HAUTE10' applied",
//                         style: TextStyle(fontSize: 10, color: darkGreen)),
//                   ),
//                   Text('- ${money(discount)} (10%)',
//                       style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _priceLine(String label, String amount, {bool emphasized = false, Widget? trailing}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 9),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: emphasized ? 16 : 13,
//                 color: emphasized ? darkGreen : const Color(0xFF555D57),
//                 fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ),
//           if (trailing != null) trailing else Text(
//             amount,
//             style: TextStyle(
//               fontSize: emphasized ? 23 : 13,
//               color: emphasized ? darkGreen : Colors.black87,
//               fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _investmentBreakdown() {
//     return _panel(
//       padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Atelier Investment Breakdown',
//               style: TextStyle(fontFamily: 'serif', fontSize: 18, color: Color(0xFF24352C))),
//           const Divider(height: 19, color: border),
//           _priceLine('Rental Fee (individual outfit durations)', money(widget.rentalFee)),
//           if (couponApplied)
//             _priceLine('HAUTE10 Special Privilege', '- ${money(discount)}'),
//           if (widget.coutureCareEnabled)
//             _priceLine('Couture Care™ Damage Protection  ⓘ', money(widget.coutureCareFee)),
//           _priceLine(
//             'White-Glove Hand Courier & Pickup',
//             'COMPLIMENTARY',
//             trailing: const Text('COMPLIMENTARY',
//                 style: TextStyle(fontSize: 8, color: darkGreen, letterSpacing: .5, fontWeight: FontWeight.w600)),
//           ),
//           const Divider(height: 18, color: border),
//           _priceLine(
//             'Refundable Security Deposit',
//             money(widget.securityDeposit),
//             trailing: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 const Text('(Returned post-\nrental)',
//                     textAlign: TextAlign.right,
//                     style: TextStyle(fontSize: 8, color: muted, height: 1.3)),
//                 const SizedBox(height: 2),
//                 Text(money(widget.securityDeposit),
//                     style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
//               ],
//             ),
//           ),
//           const Divider(height: 18, color: border),
//           _priceLine(
//             'Total Due Now',
//             '',
//             emphasized: true,
//             trailing: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(money(totalDue),
//                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 2),
//                 const Text('INCLUDES REFUNDABLE DEPOSIT',
//                     style: TextStyle(fontSize: 7, color: muted, letterSpacing: .3)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _trustGrid() {
//     final items = [
//       (Icons.verified_user_outlined, '256-BIT PROTECTION', 'PCI-DSS bank grade security'),
//       (Icons.straighten_outlined, 'FIT GUARANTEE', 'Doorstep styling & swap backup'),
//       (Icons.support_agent_outlined, '24/7 CONCIERGE', 'Dedicated atelier stylist assistance'),
//       (Icons.refresh, 'INSTANT RELEASE', 'Automatic deposit refund in 24h'),
//     ];
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F3F0),
//         borderRadius: BorderRadius.circular(5),
//         border: Border.all(color: border),
//       ),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: items.length,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 16,
//           crossAxisSpacing: 8,
//           childAspectRatio: 2.7,
//         ),
//         itemBuilder: (context, index) {
//           final item = items[index];
//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(item.$1, size: 16, color: darkGreen),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .35)),
//                     const SizedBox(height: 3),
//                     Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 9, color: muted, height: 1.3)),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _bottomBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 12, offset: const Offset(0, -3)),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 const Expanded(
//                   child: Text('NET PAYABLE',
//                       style: TextStyle(fontSize: 10, letterSpacing: .9, color: muted)),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//                   color: paleGreen,
//                   child: Text('${money(widget.securityDeposit)} REFUNDABLE',
//                       style: const TextStyle(fontSize: 9, color: darkGreen, fontWeight: FontWeight.w600)),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 Text(money(totalDue),
//                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               height: 51,
//               child: ElevatedButton.icon(
//                 onPressed: isSubmitting ? null : _confirmBooking,
//                 icon: isSubmitting
//                     ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                     : const Icon(Icons.check_circle_outline, size: 15),
//                 label: Text(isSubmitting ? 'PLACING RENTAL REQUESTS...' : 'CONFIRM DEMO BOOKING',
//                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .3)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: green,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                   elevation: 0,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text.rich(
//               TextSpan(
//                 style: TextStyle(fontSize: 8, color: muted),
//                 children: [
//                   TextSpan(text: 'By confirming, you agree to ATTIRELY’s '),
//                   TextSpan(text: 'Rental Agreement', style: TextStyle(decoration: TextDecoration.underline)),
//                   TextSpan(text: ' & '),
//                   TextSpan(text: 'Care Policy', style: TextStyle(decoration: TextDecoration.underline)),
//                   TextSpan(text: '.'),
//                 ],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _addCard() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Add a card'),
//         content: const Text(
//           'Connect your payment gateway here to securely add and tokenize a new card. Card details should not be stored directly in the app.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('CLOSE', style: TextStyle(color: green)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _confirmBooking() async {
//     if (isSubmitting) return;
//
//     if (widget.outfits.isEmpty) {
//       showMessage('There are no outfits to book.');
//       return;
//     }
//
//     // Validate the data required by RentalItemRequest before sending.
//     final requestItems = <Map<String, dynamic>>[];
//
//     for (final outfit in widget.outfits) {
//       final outfitId = outfit['id']?.toString() ?? '';
//       final selectedSize = outfit['selected_size']?.toString().trim() ?? '';
//
//       if (outfitId.isEmpty || selectedSize.isEmpty) {
//         showMessage('An outfit is missing its ID or selected size.');
//         return;
//       }
//
//       requestItems.add({
//         'outfit_id': outfitId,
//         'selected_size': selectedSize,
//         'rental_start_date': isoDate(startFor(outfit)),
//         'rental_days': daysFor(outfit),
//       });
//     }
//
//     setState(() => isSubmitting = true);
//
//     try {
//       if (widget.deliveryAddress.isEmpty) {
//         showMessage('Please select a delivery address.');
//         return;
//       }
//       // This is a simulated booking confirmation only.
//       // No card details/CVV are sent and no real payment is collected.
//       final response = await RentalsApiRoutes.createRentalBooking(
//         items: requestItems,
//         deliveryAddress: Map<String, dynamic>.from(widget.deliveryAddress),
//       );
//
//       final successfulItems =
//       (response['successful_items'] as List? ?? [])
//           .whereType<Map>()
//           .map((item) => Map<String, dynamic>.from(item))
//           .toList();
//
//       final failedItems =
//       (response['failed_items'] as List? ?? [])
//           .whereType<Map>()
//           .map((item) => Map<String, dynamic>.from(item))
//           .toList();
//
//       final successfulCount =
//           (response['successful_count'] as num?)?.toInt() ??
//               successfulItems.length;
//       final failedCount =
//           (response['failed_count'] as num?)?.toInt() ??
//               failedItems.length;
//
//       if (successfulCount == 0 || successfulItems.isEmpty) {
//         await _showBookingResultDialog(
//           successfulCount: 0,
//           failedItems: failedItems,
//           message: response['message']?.toString() ??
//               'No outfits could be booked.',
//           hasSuccess: false,
//         );
//         return;
//       }
//
//       // Remove only outfits confirmed by the backend.
//       // Failed outfits remain in the cart for another attempt.
//       final cart = UserCartLogic.instance;
//       final cartRemovalFailures = <String>[];
//
//       for (final item in successfulItems) {
//         final outfitId = item['outfit_id']?.toString() ?? '';
//         if (outfitId.isEmpty) continue;
//
//         final removed = await cart.removeOutfit(outfitId);
//         if (!removed) {
//           cartRemovalFailures.add(outfitId);
//         }
//       }
//
//       if (cartRemovalFailures.isNotEmpty) {
//         // Refresh server cart state if any cleanup call failed.
//         await cart.loadCart(refresh: true);
//       }
//
//       if (!mounted) return;
//
//       await _showBookingResultDialog(
//         successfulCount: successfulCount,
//         failedItems: failedItems,
//         message: response['message']?.toString() ??
//             '$successfulCount outfit(s) booked successfully.',
//         hasSuccess: true,
//         cartRemovalFailures: cartRemovalFailures,
//       );
//
//     } catch (error) {
//       if (mounted) {
//         showMessage(
//           error.toString().replaceFirst('Exception: ', ''),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => isSubmitting = false);
//       }
//     }
//   }
//
//   Future<void> _showBookingResultDialog({
//     required int successfulCount,
//     required List<Map<String, dynamic>> failedItems,
//     required String message,
//     required bool hasSuccess,
//     List<String> cartRemovalFailures = const [],
//   }) async {
//     if (!mounted) return;
//
//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(
//               hasSuccess ? Icons.check_circle : Icons.error_outline,
//               color: hasSuccess ? green : Colors.red.shade700,
//             ),
//             const SizedBox(width: 9),
//             Expanded(
//               child: Text(
//                 hasSuccess ? 'Booking Result' : 'Booking Unsuccessful',
//               ),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(message),
//                 if (hasSuccess) ...[
//                   const SizedBox(height: 10),
//                   Text(
//                     '$successfulCount outfit(s) booked successfully.',
//                     style: const TextStyle(
//                       color: green,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//                 if (failedItems.isNotEmpty) ...[
//                   const SizedBox(height: 14),
//                   const Text(
//                     'Could not book:',
//                     style: TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 6),
//                   ...failedItems.map((item) {
//                     final outfitId = item['outfit_id']?.toString() ?? '';
//                     final outfit = widget.outfits.firstWhere(
//                           (outfit) => outfit['id']?.toString() == outfitId,
//                       orElse: () => <String, dynamic>{},
//                     );
//                     final name = outfit['name']?.toString() ?? 'Outfit';
//
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 8),
//                       child: Text(
//                         '• $name: ${item['message'] ?? 'Booking failed.'}',
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     );
//                   }),
//                 ],
//                 if (cartRemovalFailures.isNotEmpty) ...[
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Some booked outfits could not be removed from your cart. '
//                         'Please refresh your cart before trying again.',
//                     style: TextStyle(
//                       color: Colors.deepOrange,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Demo booking only. No real payment was collected.',
//                   style: TextStyle(fontSize: 11, color: muted),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//
//     if (hasSuccess && mounted) {
//       // Return to Rent Out; it will return to the cart after this result.
//       Navigator.pop(context, true);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: background,
//       body: SafeArea(
//         top: true,
//         bottom: false,
//         child: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/background/app_bg.png'),
//               fit: BoxFit.cover,
//               opacity: .30,
//             ),
//           ),
//           child: Column(
//             children: [
//               _header(),
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 205),
//                   children: [
//                     _wardrobeBagCard(),
//                     const SizedBox(height: 18),
//                     _securityDepositCard(),
//                     const SizedBox(height: 21),
//                     _paymentHeading(),
//                     const SizedBox(height: 12),
//                     _cardPaymentMethod(),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'upi',
//                       title: 'UPI / Instant Pay',
//                       subtitle: 'GOOGLE PAY  •  PHONEPE  •  CRED UPI',
//                       icon: Icons.qr_code_2,
//                       tag: 'POPULAR',
//                     ),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'emi',
//                       title: 'No-Cost Couture EMI',
//                       subtitle: 'FROM ₹3,965/MO FOR 3 MONTHS',
//                       icon: Icons.calendar_month_outlined,
//                       trailingTag: '0% INTEREST',
//                     ),
//                     const SizedBox(height: 12),
//                     _simpleMethod(
//                       value: 'netbanking',
//                       title: 'Net Banking',
//                       subtitle: 'HDFC, ICICI, SBI, AXIS & 40+ BANKS',
//                       icon: Icons.account_balance_outlined,
//                     ),
//                     const SizedBox(height: 19),
//                     _couponSection(),
//                     const SizedBox(height: 12),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(11),
//                       color: paleGreen,
//                       child: const Text(
//                         'DEMO PAYMENT — No real charge will be made. Card/CVV details are not collected.',
//                         style: TextStyle(fontSize: 11, color: darkGreen),
//                       ),
//                     ),
//                     const SizedBox(height: 19),
//                     _investmentBreakdown(),
//                     const SizedBox(height: 15),
//                     _trustGrid(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: _bottomBar(),
//     );
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// //
// // class PaymentSecurityPage extends StatefulWidget {
// //   final List<Map<String, dynamic>> outfits;
// //   final int rentalDuration;
// //   final DateTime deliveryDate;
// //   final DateTime returnDate;
// //   final Map<String, dynamic> deliveryAddress;
// //   final double rentalFee;
// //   final double securityDeposit;
// //   final double coutureCareFee;
// //   final bool coutureCareEnabled;
// //   final bool backupSizeIncluded;
// //
// //   const PaymentSecurityPage({
// //     super.key,
// //     required this.outfits,
// //     required this.rentalDuration,
// //     required this.deliveryDate,
// //     required this.returnDate,
// //     required this.deliveryAddress,
// //     required this.rentalFee,
// //     required this.securityDeposit,
// //     required this.coutureCareFee,
// //     required this.coutureCareEnabled,
// //     required this.backupSizeIncluded,
// //   });
// //
// //   @override
// //   State<PaymentSecurityPage> createState() => _PaymentSecurityPageState();
// // }
// //
// // class _PaymentSecurityPageState extends State<PaymentSecurityPage> {
// //   static const Color green = Color(0xFF064C32);
// //   static const Color darkGreen = Color(0xFF073F2B);
// //   static const Color background = Color(0xFFF7F8F5);
// //   static const Color border = Color(0xFFE5E9E4);
// //   static const Color muted = Color(0xFF777E79);
// //   static const Color paleGreen = Color(0xFFEAF3E9);
// //
// //   String selectedMethod = 'card';
// //   String couponInput = 'HAUTE10';
// //   bool couponApplied = true;
// //   bool wardrobeExpanded = true;
// //   String selectedSavedCard = 'HDFC Bank Infinia Metal';
// //   final TextEditingController cvvController = TextEditingController();
// //   final TextEditingController couponController =
// //   TextEditingController(text: 'HAUTE10');
// //
// //   double get discount => couponApplied ? widget.rentalFee * 0.10 : 0;
// //   double get totalDue =>
// //       widget.rentalFee -
// //           discount +
// //           widget.coutureCareFee +
// //           widget.securityDeposit;
// //
// //   String money(num amount) => '₹${amount.round()}';
// //
// //   String shortDate(DateTime date) {
// //     const months = [
// //       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
// //       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
// //     ];
// //     return '${months[date.month - 1]} ${date.day}';
// //   }
// //
// //   String addressText() {
// //     final parts = [
// //       widget.deliveryAddress['house'],
// //       widget.deliveryAddress['street'],
// //       widget.deliveryAddress['landmark'],
// //       widget.deliveryAddress['city'],
// //       widget.deliveryAddress['state'],
// //       widget.deliveryAddress['pincode'],
// //     ];
// //     return parts
// //         .where((part) => part != null && part.toString().trim().isNotEmpty)
// //         .join(', ');
// //   }
// //
// //   String outfitImage(Map<String, dynamic> outfit) {
// //     final cover = outfit['cover_image_url']?.toString() ?? '';
// //     if (cover.isNotEmpty) return cover;
// //
// //     final images = outfit['images'];
// //     if (images is List) {
// //       for (final image in images) {
// //         if (image is Map && image['is_cover'] == true) {
// //           final url = image['image_url']?.toString() ?? '';
// //           if (url.isNotEmpty) return url;
// //         }
// //       }
// //       if (images.isNotEmpty && images.first is Map) {
// //         return images.first['image_url']?.toString() ?? '';
// //       }
// //     }
// //     return '';
// //   }
// //
// //   void showMessage(String message) {
// //     ScaffoldMessenger.of(context)
// //       ..hideCurrentSnackBar()
// //       ..showSnackBar(
// //         SnackBar(
// //           content: Text(message),
// //           behavior: SnackBarBehavior.floating,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //   }
// //
// //   @override
// //   void dispose() {
// //     cvvController.dispose();
// //     couponController.dispose();
// //     super.dispose();
// //   }
// //
// //   // ---------------------------------------------------------------------------
// //   // Header — matches the Rent Out page, now showing step 2 of 2.
// //   // ---------------------------------------------------------------------------
// //
// //   Widget _header() {
// //     return Container(
// //       color: background,
// //       padding: const EdgeInsets.fromLTRB(13, 5, 15, 13),
// //       child: Column(
// //         children: [
// //           Row(
// //             children: [
// //               IconButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 icon: const Icon(Icons.arrow_back, color: darkGreen),
// //               ),
// //               const SizedBox(width: 4),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       'Payment & Security',
// //                       maxLines: 1,
// //                       overflow: TextOverflow.ellipsis,
// //                       style: TextStyle(
// //                         fontFamily: 'serif',
// //                         fontSize: 22,
// //                         color: Color(0xFF202522),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 3),
// //                     const Text(
// //                       'Choose payment method & verify',
// //                       style: TextStyle(color: muted, fontSize: 12),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               Column(
// //                 crossAxisAlignment: CrossAxisAlignment.end,
// //                 children: const [
// //                   Text(
// //                     'STEP 2 OF 2',
// //                     style: TextStyle(
// //                       color: darkGreen,
// //                       fontSize: 10,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   SizedBox(height: 3),
// //                   Text(
// //                     'Payment & Booking',
// //                     style: TextStyle(
// //                       color: muted,
// //                       fontSize: 10,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 9),
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(5),
// //             child: const LinearProgressIndicator(
// //               value: 1,
// //               minHeight: 3,
// //               backgroundColor: Color(0xFFE1E6E0),
// //               valueColor: AlwaysStoppedAnimation(green),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
// //     return Container(
// //       padding: padding,
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(7),
// //         border: Border.all(color: border),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.025),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: child,
// //     );
// //   }
// //
// //   Widget _wardrobeBagCard() {
// //     return _panel(
// //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
// //       child: Column(
// //         children: [
// //           InkWell(
// //             onTap: () => setState(() => wardrobeExpanded = !wardrobeExpanded),
// //             child: Row(
// //               children: [
// //                 Container(
// //                   width: 36,
// //                   height: 36,
// //                   decoration: BoxDecoration(
// //                     color: const Color(0xFFF1F4EF),
// //                     borderRadius: BorderRadius.circular(7),
// //                   ),
// //                   child: const Icon(Icons.workspace_premium_outlined,
// //                       color: darkGreen, size: 17),
// //                 ),
// //                 const SizedBox(width: 13),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         'Wardrobe Bag (${widget.outfits.length} Items)',
// //                         style: const TextStyle(
// //                           fontFamily: 'serif',
// //                           fontSize: 18,
// //                           color: Color(0xFF202522),
// //                         ),
// //                       ),
// //                       Text(
// //                         '${widget.outfits.length} INDIVIDUAL RENTAL SCHEDULES',
// //                         style: const TextStyle(
// //                           fontSize: 10,
// //                           letterSpacing: .7,
// //                           color: muted,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 Icon(
// //                   wardrobeExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
// //                   color: darkGreen,
// //                 ),
// //               ],
// //             ),
// //           ),
// //           if (wardrobeExpanded) ...[
// //             const SizedBox(height: 15),
// //             const Divider(height: 1, color: border),
// //             const SizedBox(height: 15),
// //             Row(
// //               children: [
// //                 SizedBox(
// //                   width: 94,
// //                   height: 48,
// //                   child: Stack(
// //                     children: [
// //                       for (int i = 0; i < widget.outfits.length && i < 3; i++)
// //                         Positioned(
// //                           left: i * 28,
// //                           child: Container(
// //                             width: 32,
// //                             height: 46,
// //                             decoration: BoxDecoration(
// //                               border: Border.all(color: Colors.white, width: 1.2),
// //                               borderRadius: BorderRadius.circular(2),
// //                             ),
// //                             clipBehavior: Clip.antiAlias,
// //                             child: _image(widget.outfits[i]),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(width: 13),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         '${widget.outfits.length} outfits • dates selected individually',
// //                         style: const TextStyle(fontSize: 14, color: Colors.black87),
// //                       ),
// //                       const SizedBox(height: 6),
// //                       Row(
// //                         children: [
// //                           const Icon(Icons.near_me_outlined, size: 11, color: darkGreen),
// //                           const SizedBox(width: 4),
// //                           Expanded(
// //                             child: Text(
// //                               addressText().isEmpty
// //                                   ? 'Delivery address selected'
// //                                   : addressText(),
// //                               maxLines: 1,
// //                               overflow: TextOverflow.ellipsis,
// //                               style: const TextStyle(fontSize: 11, color: muted),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _image(Map<String, dynamic> outfit) {
// //     final url = outfitImage(outfit);
// //     if (url.isEmpty) {
// //       return Container(
// //         color: paleGreen,
// //         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
// //       );
// //     }
// //     return Image.network(
// //       url,
// //       fit: BoxFit.cover,
// //       errorBuilder: (_, __, ___) => Container(
// //         color: paleGreen,
// //         child: const Icon(Icons.checkroom_outlined, size: 14, color: green),
// //       ),
// //     );
// //   }
// //
// //   Widget _securityDepositCard() {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF1F3F0),
// //         borderRadius: BorderRadius.circular(5),
// //         border: Border.all(color: border),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Container(
// //             width: 38,
// //             height: 38,
// //             decoration: const BoxDecoration(
// //               color: Color(0xFFDCE8DF),
// //               shape: BoxShape.circle,
// //             ),
// //             child: const Icon(Icons.lock_clock_outlined, color: darkGreen, size: 17),
// //           ),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   children: [
// //                     const Expanded(
// //                       child: Text(
// //                         '100% Refundable Security Deposit',
// //                         style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
// //                       ),
// //                     ),
// //                     Text(
// //                       money(widget.securityDeposit),
// //                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 5),
// //                 const Text(
// //                   'Held safely and automatically released back to your original payment source within 24 hours of return pickup inspection.',
// //                   style: TextStyle(fontSize: 12, color: muted, height: 1.5),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _paymentHeading() {
// //     return const Padding(
// //       padding: EdgeInsets.symmetric(horizontal: 3),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Expanded(
// //             child: Text(
// //               'SELECT PAYMENT\nINSTRUMENT',
// //               style: TextStyle(fontSize: 11, letterSpacing: .7, height: 1.35, color: darkGreen),
// //             ),
// //           ),
// //           Text(
// //             'ENCRYPTED & PCI\nCOMPLIANT',
// //             textAlign: TextAlign.left,
// //             style: TextStyle(fontSize: 10, letterSpacing: .8, height: 1.4, color: muted),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _methodRadio(String value) {
// //     return Radio<String>(
// //       value: value,
// //       groupValue: selectedMethod,
// //       activeColor: darkGreen,
// //       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //       visualDensity: VisualDensity.compact,
// //       onChanged: (next) {
// //         if (next != null) setState(() => selectedMethod = next);
// //       },
// //     );
// //   }
// //
// //   Widget _cardPaymentMethod() {
// //     final selected = selectedMethod == 'card';
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.4 : 1),
// //         borderRadius: BorderRadius.circular(7),
// //       ),
// //       child: Column(
// //         children: [
// //           InkWell(
// //             onTap: () => setState(() => selectedMethod = 'card'),
// //             child: Padding(
// //               padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
// //               child: Row(
// //                 children: [
// //                   _methodRadio('card'),
// //                   const SizedBox(width: 3),
// //                   const Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text('Luxury Credit & Debit Cards',
// //                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
// //                         SizedBox(height: 3),
// //                         Text('VISA  •  MASTERCARD  •  AMEX  •  DINERS',
// //                             style: TextStyle(fontSize: 9, letterSpacing: .7, color: muted)),
// //                       ],
// //                     ),
// //                   ),
// //                   const Icon(Icons.credit_card_outlined, color: darkGreen, size: 19),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           if (selected) ...[
// //             const Divider(height: 1, color: border),
// //             Padding(
// //               padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   const Text('SAVED ATELIER CARDS',
// //                       style: TextStyle(fontSize: 9, letterSpacing: .9, color: muted)),
// //                   const SizedBox(height: 12),
// //                   _savedCard(
// //                     name: 'HDFC Bank Infinia Metal',
// //                     number: '•••• •••• •••• 4092',
// //                     brand: 'INFINIA',
// //                     selected: selectedSavedCard == 'HDFC Bank Infinia Metal',
// //                     color: const Color(0xFF073F2B),
// //                   ),
// //                   const SizedBox(height: 10),
// //                   _savedCard(
// //                     name: 'ICICI Bank Emerald Card',
// //                     number: '•••• •••• •••• 8821',
// //                     brand: 'EMERALD',
// //                     selected: selectedSavedCard == 'ICICI Bank Emerald Card',
// //                     color: const Color(0xFF806B4D),
// //                   ),
// //                   const SizedBox(height: 9),
// //                   Align(
// //                     alignment: Alignment.centerLeft,
// //                     child: TextButton.icon(
// //                       onPressed: _addCard,
// //                       icon: const Icon(Icons.add, size: 14),
// //                       label: const Text('ADD ANOTHER CARD',
// //                           style: TextStyle(fontSize: 9, letterSpacing: .5)),
// //                       style: TextButton.styleFrom(
// //                         foregroundColor: darkGreen,
// //                         padding: EdgeInsets.zero,
// //                         minimumSize: Size.zero,
// //                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _savedCard({
// //     required String name,
// //     required String number,
// //     required String brand,
// //     required bool selected,
// //     required Color color,
// //   }) {
// //     return InkWell(
// //       onTap: () => setState(() => selectedSavedCard = name),
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFFF3F5F2),
// //           border: Border.all(color: selected ? const Color(0xFF9EB6A7) : border),
// //           borderRadius: BorderRadius.circular(4),
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               width: 34,
// //               height: 21,
// //               alignment: Alignment.center,
// //               decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
// //               child: Text(brand, style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
// //             ),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
// //                       style: const TextStyle(fontSize: 12)),
// //                   const SizedBox(height: 2),
// //                   Text(number, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: .5)),
// //                 ],
// //               ),
// //             ),
// //             if (selected)
// //               SizedBox(
// //                 width: 64,
// //                 height: 32,
// //                 child: TextField(
// //                   controller: cvvController,
// //                   keyboardType: TextInputType.number,
// //                   maxLength: 4,
// //                   obscureText: true,
// //                   textAlign: TextAlign.center,
// //                   style: const TextStyle(fontSize: 10, letterSpacing: 2),
// //                   decoration: const InputDecoration(
// //                     counterText: '',
// //                     hintText: 'CVV',
// //                     hintStyle: TextStyle(fontSize: 11, color: muted),
// //                     contentPadding: EdgeInsets.symmetric(vertical: 6),
// //                     border: OutlineInputBorder(borderRadius: BorderRadius.zero),
// //                     enabledBorder: OutlineInputBorder(
// //                       borderSide: BorderSide(color: border),
// //                       borderRadius: BorderRadius.zero,
// //                     ),
// //                     focusedBorder: OutlineInputBorder(
// //                       borderSide: BorderSide(color: darkGreen),
// //                       borderRadius: BorderRadius.zero,
// //                     ),
// //                   ),
// //                 ),
// //               )
// //             else
// //               Container(
// //                 width: 56,
// //                 height: 29,
// //                 alignment: Alignment.center,
// //                 decoration: BoxDecoration(color: Colors.white, border: Border.all(color: border)),
// //                 child: const Text('CVV', style: TextStyle(fontSize: 11, color: muted)),
// //               ),
// //             const SizedBox(width: 7),
// //             Icon(selected ? Icons.circle : Icons.circle_outlined,
// //                 size: 8, color: selected ? green : border),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _simpleMethod({
// //     required String value,
// //     required String title,
// //     required String subtitle,
// //     required IconData icon,
// //     String? tag,
// //     String? trailingTag,
// //   }) {
// //     final selected = selectedMethod == value;
// //     return InkWell(
// //       onTap: () => setState(() => selectedMethod = value),
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           border: Border.all(color: selected ? const Color(0xFF14251D) : border, width: selected ? 1.3 : 1),
// //           borderRadius: BorderRadius.circular(4),
// //           boxShadow: [
// //             BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 6, offset: const Offset(0, 2)),
// //           ],
// //         ),
// //         child: Row(
// //           children: [
// //             _methodRadio(value),
// //             const SizedBox(width: 3),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Wrap(
// //                     spacing: 7,
// //                     crossAxisAlignment: WrapCrossAlignment.center,
// //                     children: [
// //                       Text(title, style: const TextStyle(fontSize: 15)),
// //                       if (tag != null)
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// //                           color: const Color(0xFFE1EEDF),
// //                           child: Text(tag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
// //                         ),
// //                       if (trailingTag != null)
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// //                           color: const Color(0xFFFFE0B5),
// //                           child: Text(trailingTag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
// //                         ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(subtitle, style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4)),
// //                 ],
// //               ),
// //             ),
// //             Icon(icon, size: 18, color: darkGreen),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _couponSection() {
// //     return _panel(
// //       padding: const EdgeInsets.all(15),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text('COUTURE INVITE OR VOUCHER',
// //               style: TextStyle(fontSize: 10, letterSpacing: .7, color: muted)),
// //           const SizedBox(height: 9),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: SizedBox(
// //                   height: 44,
// //                   child: TextField(
// //                     controller: couponController,
// //                     onChanged: (value) => couponInput = value,
// //                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .5),
// //                     decoration: InputDecoration(
// //                       contentPadding: const EdgeInsets.symmetric(horizontal: 10),
// //                       border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
// //                       enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen), borderRadius: BorderRadius.zero),
// //                       focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkGreen, width: 1.4), borderRadius: BorderRadius.zero),
// //                       suffixIcon: couponApplied ? const Icon(Icons.check_circle_outline, size: 15, color: darkGreen) : null,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(width: 8),
// //               SizedBox(
// //                 height: 44,
// //                 width: 72,
// //                 child: ElevatedButton(
// //                   onPressed: () {
// //                     final valid = couponInput.trim().toUpperCase() == 'HAUTE10';
// //                     setState(() => couponApplied = valid);
// //                     showMessage(valid ? 'HAUTE10 applied successfully.' : 'Invalid voucher code.');
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: green,
// //                     foregroundColor: Colors.white,
// //                     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
// //                     padding: EdgeInsets.zero,
// //                   ),
// //                   child: const Text('APPLY', style: TextStyle(fontSize: 12)),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           if (couponApplied) ...[
// //             const SizedBox(height: 8),
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
// //               color: const Color(0xFFEAF3E9),
// //               child: Row(
// //                 children: [
// //                   const Icon(Icons.sell_outlined, size: 12, color: darkGreen),
// //                   const SizedBox(width: 6),
// //                   const Expanded(
// //                     child: Text("VIP Code 'HAUTE10' applied",
// //                         style: TextStyle(fontSize: 10, color: darkGreen)),
// //                   ),
// //                   Text('- ${money(discount)} (10%)',
// //                       style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _priceLine(String label, String amount, {bool emphasized = false, Widget? trailing}) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 9),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Expanded(
// //             child: Text(
// //               label,
// //               style: TextStyle(
// //                 fontSize: emphasized ? 16 : 13,
// //                 color: emphasized ? darkGreen : const Color(0xFF555D57),
// //                 fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
// //               ),
// //             ),
// //           ),
// //           if (trailing != null) trailing else Text(
// //             amount,
// //             style: TextStyle(
// //               fontSize: emphasized ? 23 : 13,
// //               color: emphasized ? darkGreen : Colors.black87,
// //               fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _investmentBreakdown() {
// //     return _panel(
// //       padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text('Atelier Investment Breakdown',
// //               style: TextStyle(fontFamily: 'serif', fontSize: 18, color: Color(0xFF24352C))),
// //           const Divider(height: 19, color: border),
// //           _priceLine('Rental Fee (individual outfit durations)', money(widget.rentalFee)),
// //           if (couponApplied)
// //             _priceLine('HAUTE10 Special Privilege', '- ${money(discount)}'),
// //           if (widget.coutureCareEnabled)
// //             _priceLine('Couture Care™ Damage Protection  ⓘ', money(widget.coutureCareFee)),
// //           _priceLine(
// //             'White-Glove Hand Courier & Pickup',
// //             'COMPLIMENTARY',
// //             trailing: const Text('COMPLIMENTARY',
// //                 style: TextStyle(fontSize: 8, color: darkGreen, letterSpacing: .5, fontWeight: FontWeight.w600)),
// //           ),
// //           const Divider(height: 18, color: border),
// //           _priceLine(
// //             'Refundable Security Deposit',
// //             money(widget.securityDeposit),
// //             trailing: Column(
// //               crossAxisAlignment: CrossAxisAlignment.end,
// //               children: [
// //                 const Text('(Returned post-\nrental)',
// //                     textAlign: TextAlign.right,
// //                     style: TextStyle(fontSize: 8, color: muted, height: 1.3)),
// //                 const SizedBox(height: 2),
// //                 Text(money(widget.securityDeposit),
// //                     style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
// //               ],
// //             ),
// //           ),
// //           const Divider(height: 18, color: border),
// //           _priceLine(
// //             'Total Due Now',
// //             '',
// //             emphasized: true,
// //             trailing: Column(
// //               crossAxisAlignment: CrossAxisAlignment.end,
// //               children: [
// //                 Text(money(totalDue),
// //                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 2),
// //                 const Text('INCLUDES REFUNDABLE DEPOSIT',
// //                     style: TextStyle(fontSize: 7, color: muted, letterSpacing: .3)),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _trustGrid() {
// //     final items = [
// //       (Icons.verified_user_outlined, '256-BIT PROTECTION', 'PCI-DSS bank grade security'),
// //       (Icons.straighten_outlined, 'FIT GUARANTEE', 'Doorstep styling & swap backup'),
// //       (Icons.support_agent_outlined, '24/7 CONCIERGE', 'Dedicated atelier stylist assistance'),
// //       (Icons.refresh, 'INSTANT RELEASE', 'Automatic deposit refund in 24h'),
// //     ];
// //     return Container(
// //       padding: const EdgeInsets.all(15),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF1F3F0),
// //         borderRadius: BorderRadius.circular(5),
// //         border: Border.all(color: border),
// //       ),
// //       child: GridView.builder(
// //         shrinkWrap: true,
// //         physics: const NeverScrollableScrollPhysics(),
// //         itemCount: items.length,
// //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //           crossAxisCount: 2,
// //           mainAxisSpacing: 16,
// //           crossAxisSpacing: 8,
// //           childAspectRatio: 2.7,
// //         ),
// //         itemBuilder: (context, index) {
// //           final item = items[index];
// //           return Row(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Icon(item.$1, size: 16, color: darkGreen),
// //               const SizedBox(width: 6),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
// //                         style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .35)),
// //                     const SizedBox(height: 3),
// //                     Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis,
// //                         style: const TextStyle(fontSize: 9, color: muted, height: 1.3)),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _bottomBar() {
// //     return SafeArea(
// //       top: false,
// //       child: Container(
// //         padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           boxShadow: [
// //             BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 12, offset: const Offset(0, -3)),
// //           ],
// //         ),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Row(
// //               children: [
// //                 const Expanded(
// //                   child: Text('NET PAYABLE',
// //                       style: TextStyle(fontSize: 10, letterSpacing: .9, color: muted)),
// //                 ),
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
// //                   color: paleGreen,
// //                   child: Text('${money(widget.securityDeposit)} REFUNDABLE',
// //                       style: const TextStyle(fontSize: 9, color: darkGreen, fontWeight: FontWeight.w600)),
// //                 ),
// //               ],
// //             ),
// //             Row(
// //               children: [
// //                 Text(money(totalDue),
// //                     style: const TextStyle(fontFamily: 'serif', fontSize: 25, color: darkGreen, fontWeight: FontWeight.bold)),
// //               ],
// //             ),
// //             const SizedBox(height: 8),
// //             SizedBox(
// //               width: double.infinity,
// //               height: 51,
// //               child: ElevatedButton.icon(
// //                 onPressed: _confirmBooking,
// //                 icon: const Icon(Icons.lock_outline, size: 15),
// //                 label: Text('PAY ${money(totalDue)} & CONFIRM BOOKING',
// //                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .3)),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: green,
// //                   foregroundColor: Colors.white,
// //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
// //                   elevation: 0,
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 6),
// //             const Text.rich(
// //               TextSpan(
// //                 style: TextStyle(fontSize: 8, color: muted),
// //                 children: [
// //                   TextSpan(text: 'By confirming, you agree to ATTIRELY’s '),
// //                   TextSpan(text: 'Rental Agreement', style: TextStyle(decoration: TextDecoration.underline)),
// //                   TextSpan(text: ' & '),
// //                   TextSpan(text: 'Care Policy', style: TextStyle(decoration: TextDecoration.underline)),
// //                   TextSpan(text: '.'),
// //                 ],
// //               ),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _addCard() {
// //     showDialog(
// //       context: context,
// //       builder: (dialogContext) => AlertDialog(
// //         title: const Text('Add a card'),
// //         content: const Text(
// //           'Connect your payment gateway here to securely add and tokenize a new card. Card details should not be stored directly in the app.',
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(dialogContext),
// //             child: const Text('CLOSE', style: TextStyle(color: green)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _confirmBooking() {
// //     if (selectedMethod == 'card' && cvvController.text.isNotEmpty && cvvController.text.length < 3) {
// //       showMessage('Please enter a valid CVV.');
// //       return;
// //     }
// //
// //     // Payment gateway / booking API integration belongs here.
// //     showMessage('Payment gateway integration is required to confirm this booking.');
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: background,
// //       body: SafeArea(
// //         top: true,
// //         bottom: false,
// //         child: Container(
// //           decoration: const BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage('assets/images/app_bg.png'),
// //               fit: BoxFit.cover,
// //               opacity: .30,
// //             ),
// //           ),
// //           child: Column(
// //             children: [
// //               _header(),
// //               Expanded(
// //                 child: ListView(
// //                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 205),
// //                   children: [
// //                     _wardrobeBagCard(),
// //                     const SizedBox(height: 18),
// //                     _securityDepositCard(),
// //                     const SizedBox(height: 21),
// //                     _paymentHeading(),
// //                     const SizedBox(height: 12),
// //                     _cardPaymentMethod(),
// //                     const SizedBox(height: 12),
// //                     _simpleMethod(
// //                       value: 'upi',
// //                       title: 'UPI / Instant Pay',
// //                       subtitle: 'GOOGLE PAY  •  PHONEPE  •  CRED UPI',
// //                       icon: Icons.qr_code_2,
// //                       tag: 'POPULAR',
// //                     ),
// //                     const SizedBox(height: 12),
// //                     _simpleMethod(
// //                       value: 'emi',
// //                       title: 'No-Cost Couture EMI',
// //                       subtitle: 'FROM ₹3,965/MO FOR 3 MONTHS',
// //                       icon: Icons.calendar_month_outlined,
// //                       trailingTag: '0% INTEREST',
// //                     ),
// //                     const SizedBox(height: 12),
// //                     _simpleMethod(
// //                       value: 'netbanking',
// //                       title: 'Net Banking',
// //                       subtitle: 'HDFC, ICICI, SBI, AXIS & 40+ BANKS',
// //                       icon: Icons.account_balance_outlined,
// //                     ),
// //                     const SizedBox(height: 19),
// //                     _couponSection(),
// //                     const SizedBox(height: 19),
// //                     _investmentBreakdown(),
// //                     const SizedBox(height: 15),
// //                     _trustGrid(),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //       bottomNavigationBar: _bottomBar(),
// //     );
// //   }
// // }
