import 'package:flutter/material.dart';

import '../U_Ui_Logic/trial_address_logic.dart';
import 'add_trial_address.dart';

class RentOutPage extends StatefulWidget {
  final List<Map<String, dynamic>> outfits;

  const RentOutPage({
    super.key,
    required this.outfits,
  });

  @override
  State<RentOutPage> createState() => _RentOutPageState();
}

class _RentOutPageState extends State<RentOutPage> {
  // Theme
  static const Color green = Color(0xFF064C32);
  static const Color darkGreen = Color(0xFF073F2B);
  static const Color lightGreen = Color(0xFFEAF3E9);
  static const Color background = Color(0xFFF7F8F5);
  static const Color border = Color(0xFFE5E9E4);
  static const Color muted = Color(0xFF777E79);

  final TrialAddressLogic addressLogic = TrialAddressLogic.instance;

  Map<String, dynamic>? selectedAddress;

  // A page-local copy lets the user remove outfits from this rental
  // without mutating the cart's original list.
  late final List<Map<String, dynamic>> selectedOutfits;

  int selectedDuration = 4;

  DateTime deliveryDate = DateTime.now().add(
    const Duration(days: 1),
  );

  bool backupSize = true;
  bool coutureCare = true;

  static const double careFee = 299;
  static const double defaultSecurityDeposit = 1000;

  DateTime get returnDate =>
      deliveryDate.add(Duration(days: selectedDuration));

  @override
  void initState() {
    super.initState();
    selectedOutfits = widget.outfits
        .map((outfit) => Map<String, dynamic>.from(outfit))
        .toList();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    await addressLogic.loadAddresses(refresh: true);

    if (!mounted) return;

    setState(() {
      selectedAddress = addressLogic.selectedAddress;
    });
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '₹${_number(value).toStringAsFixed(0)}';
  }

  String _image(Map<String, dynamic> outfit) {
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

  double _depositFor(Map<String, dynamic> outfit) {
    final deposit = _number(
      outfit['security_deposit'] ??
          outfit['security_price'] ??
          outfit['deposit_amount'] ??
          outfit['security'],
    );

    return deposit > 0 ? deposit : defaultSecurityDeposit;
  }

  // Rental price is charged per day for each outfit.
  double get rentalTotal {
    return selectedOutfits.fold<double>(
      0,
          (sum, outfit) =>
      sum + (_number(outfit['rental_price']) * selectedDuration),
    );
  }

  double get securityDeposit {
    return selectedOutfits.fold<double>(
      0,
          (sum, outfit) => sum + _depositFor(outfit),
    );
  }

  void _removeOutfit(int index) {
    if (index < 0 || index >= selectedOutfits.length) return;

    final removedName =
        selectedOutfits[index]['name']?.toString() ?? 'Outfit';

    setState(() {
      selectedOutfits.removeAt(index);
    });

    _message('$removedName removed from this rental.');
  }

  double get careTotal => coutureCare ? careFee : 0;

  double get totalPayable =>
      rentalTotal + securityDeposit + careTotal;

  String _date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  String _fullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _addressText(Map<String, dynamic> address) {
    final parts = [
      address['house'],
      address['street'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ];

    return parts
        .where((part) =>
    part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _addAddress({
    Map<String, dynamic>? address,
  }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTrialAddressPage(
          address: address,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedAddress = result;
    });
  }

  void _chooseAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: addressLogic,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Delivery Address',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (addressLogic.isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: green,
                        ),
                      )
                    else if (addressLogic.addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text('No saved addresses found.'),
                      )
                    else
                      ...addressLogic.addresses.map((address) {
                        final id = address['id']?.toString() ?? '';

                        final selected =
                            selectedAddress?['id']?.toString() == id;

                        final isDefault =
                            address['is_default'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: selected ? lightGreen : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? green : border,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              addressLogic.selectAddress(address);

                              setState(() {
                                selectedAddress = address;
                              });

                              Navigator.pop(sheetContext);
                            },
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: green,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    address['full_name']?.toString() ??
                                        'Address',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              _addressText(address),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: selected
                                ? const Icon(
                              Icons.check_circle,
                              color: green,
                            )
                                : const Icon(
                              Icons.chevron_right,
                              color: muted,
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _addAddress();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          side: const BorderSide(color: green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changeDeliveryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      deliveryDate = selected;
    });
  }

  void _proceedToPayment() {
    if (selectedOutfits.isEmpty) {
      _message('Please add outfits to your cart.');
      return;
    }

    if (selectedAddress == null) {
      _message('Please select a delivery address.');
      return;
    }

    // Connect the actual rental booking/payment API here.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Coming Soon'),
        content: const Text(
          'Rental booking and payment integration '
              'will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Okay',
              style: TextStyle(color: green),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // COMMON UI
  // ---------------------------------------------------------

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(15),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeading(
      String title, {
        IconData? icon,
        Widget? trailing,
      }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: green),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202522),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _smallLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: muted,
        fontSize: 10,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _outfitImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: lightGreen,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          color: green,
          size: 28,
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: lightGreen,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: green,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------

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
                icon: const Icon(
                  Icons.arrow_back,
                  color: darkGreen,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Rent Outfits',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            color: Color(0xFF202522),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9BC87),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Select dates & delivery details',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'STEP 1 OF 2',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Dates & Delivery',
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
              value: 0.5,
              minHeight: 3,
              backgroundColor: Color(0xFFE1E6E0),
              valueColor: AlwaysStoppedAnimation(green),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // WARDROBE BAG
  // ---------------------------------------------------------

  Widget _wardrobeBag() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.checkroom_outlined,
              color: green,
              size: 17,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'WARDROBE BAG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Text(
                '${selectedOutfits.length} Outfits Selected',
                style: const TextStyle(
                  fontSize: 10,
                  color: darkGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedOutfits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Text(
              'Your wardrobe bag is empty. Go back to your cart and add an outfit.',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          )
        else
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedOutfits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final outfit = selectedOutfits[index];

                final name = outfit['name']?.toString() ?? 'Outfit';
                final brand = outfit['brand']?.toString() ??
                    outfit['brand_name']?.toString() ??
                    '';
                final size = outfit['selected_size']?.toString() ??
                    outfit['size']?.toString() ??
                    '';
                final dailyRental = _number(outfit['rental_price']);
                final deposit = _depositFor(outfit);

                return Container(
                  width: 290,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 72,
                          height: 122,
                          child: _outfitImage(_image(outfit)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      if (brand.isNotEmpty)
                                        Text(
                                          brand.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: darkGreen,
                                            fontSize: 9,
                                            letterSpacing: 0.7,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 3),
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _removeOutfit(index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.only(
                                      left: 5,
                                      bottom: 4,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Color(0xFF8A7779),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (size.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                'Size: $size',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Rental / day',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Text(
                                  _money(dailyRental),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: darkGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Security deposit',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Text(
                                  _money(deposit),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------
  // RENTAL DURATION
  // ---------------------------------------------------------

  Widget _durationSection() {
    final durations = [
      {'days': 3, 'name': 'Quick Soirée'},
      {'days': 4, 'name': 'Standard'},
      {'days': 7, 'name': 'Extended'},
      {'days': 10, 'name': 'Destination'},
    ];

    return _card(
      child: Column(
        children: [
          _sectionHeading(
            'Rental Duration',
            icon: Icons.access_time,
            trailing: _smallLabel('DRY CLEANING INCLUDED'),
          ),
          const SizedBox(height: 19),

          SizedBox(
            height: 104,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < durations.length; index++) ...[
                    if (index > 0) const SizedBox(width: 12),
                    _durationOption(
                      days: durations[index]['days'] as int,
                      name: durations[index]['name'] as String,
                      popular: durations[index]['days'] == 4,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 19),

          Row(
            children: [
              Expanded(
                child: _dateInfoCard(
                  title: 'DELIVERY DATE',
                  icon: Icons.local_shipping_outlined,
                  date: _date(deliveryDate),
                  subtitle: 'Delivered by 12:00 PM',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateInfoCard(
                  title: 'RETURN PICKUP',
                  icon: Icons.event_available_outlined,
                  date: _date(returnDate),
                  subtitle: 'Complimentary pickup courier',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: darkGreen,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullDate(deliveryDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$selectedDuration-Day Booking Window active',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _changeDeliveryDate,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHANGE DATES',
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        width: 82,
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationOption({
    required int days,
    required String name,
    required bool popular,
  }) {
    final selected = selectedDuration == days;

    return SizedBox(
      width: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            // Keeps the POPULAR badge separate from the selectable card.
            padding: const EdgeInsets.only(top: 11),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedDuration = days;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 78,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? darkGreen : background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? green : border,
                    width: selected ? 1.3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                      color: green.withOpacity(0.13),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$days Days',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.15,
                        color: selected ? Colors.white70 : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (popular)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4D9A8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF65481B),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateInfoCard({
    required String title,
    required IconData icon,
    required String date,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, color: darkGreen, size: 17),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              height: 1.3,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // DELIVERY ADDRESS
  // ---------------------------------------------------------

  Widget _addressSection() {
    final address = selectedAddress;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Delivery Address',
            icon: Icons.location_on_outlined,
            trailing: TextButton(
              onPressed: address == null
                  ? () => _addAddress()
                  : _chooseAddress,
              child: Text(
                address == null ? 'ADD' : 'CHANGE',
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          if (address == null)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add a delivery address for your rental.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _addAddress(),
                    child: const Text(
                      'ADD ADDRESS',
                      style: TextStyle(color: green),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB6EBD0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: green,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 7,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              address['full_name']?.toString() ??
                                  'Customer',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (address['is_default'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                color: const Color(0xFFE8EAE7),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(fontSize: 9),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _addressText(address),
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '+91 ${address['mobile'] ?? ''}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 13),

          // Express delivery
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F0),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: Color(0xFF70541B),
                  size: 19,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Express White-Glove Hand Delivery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '(Complimentary)',
                        style: TextStyle(
                          fontSize: 11,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // Backup size
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox(
                    value: backupSize,
                    activeColor: green,
                    onChanged: (value) {
                      setState(() {
                        backupSize = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Include Free Backup Size',
                            style: TextStyle(fontSize: 11),
                          ),
                          SizedBox(width: 7),
                          _FreeTag(),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Complimentary Fit Guarantee! We'll include "
                            "an alternate size for eligible pieces at no added fee.",
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // COUTURE CARE
  // ---------------------------------------------------------

  Widget _coutureCareSection() {
    return _card(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 33,
                width: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBDD),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: darkGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'ATTIRELY Couture Care™',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          color: const Color(0xFFB8EBCF),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 8,
                              color: darkGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Cover accidental stains, minor seam tears, '
                          'beadwork looseness, and zipper mishaps up to ₹5,000.',
                      style: TextStyle(
                        fontSize: 11,
                        color: muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: coutureCare,
                activeColor: Colors.white,
                activeTrackColor: green,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: (value) {
                  setState(() {
                    coutureCare = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 13),
          const Divider(height: 1, color: border),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Peace of Mind Fee',
                  style: TextStyle(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ),
              Text(
                coutureCare ? '₹299' : '₹0',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // ORDER SUMMARY
  // ---------------------------------------------------------

  Widget _priceRow(
      String label,
      String value, {
        bool bold = false,
        String? subtitle,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: bold ? 14 : 11,
                    fontWeight:
                    bold ? FontWeight.w700 : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 19 : 12,
              fontWeight: FontWeight.w600,
              color: bold ? darkGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary() {
    return _card(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Order Summary',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 12),

          _priceRow(
            'Rental Fee (${selectedOutfits.length} Outfits, '
                '$selectedDuration-Day Period)',
            _money(rentalTotal),
          ),

          _priceRow(
            'Refundable Security Deposit',
            _money(securityDeposit),
            subtitle: '100% Refundable on return pickup',
          ),

          if (coutureCare)
            _priceRow(
              'Couture Care™ Damage Protection',
              _money(careTotal),
            ),

          _priceRow(
            'White-Glove Delivery & Pickup',
            'FREE',
          ),

          const Divider(height: 22, color: border),

          _priceRow(
            'Total Payable',
            _money(totalPayable),
            bold: true,
          ),

          const Text(
            'Includes refundable security deposit.',
            style: TextStyle(
              fontSize: 10,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // CONCIERGE
  // ---------------------------------------------------------

  Widget _conciergeSection() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: darkGreen,
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dedicated Atelier Concierge',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your garments arrive professionally steamed '
                      'in reusable couture garment bags.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // BOTTOM PAYMENT BAR
  // ---------------------------------------------------------

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 13,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: darkGreen,
                  size: 13,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '100% Refundable Deposit · Free Doorstep Pickup & Cleaning Included',
                    style: TextStyle(
                      fontSize: 9,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL DUE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _money(totalPayable),
                        style: const TextStyle(
                          fontSize: 22,
                          color: darkGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_money(securityDeposit)} refundable',
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SizedBox(
                    height: 49,
                    child: ElevatedButton(
                      onPressed: _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Proceed to Payment',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.arrow_forward,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: null,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/app_bg.png'),
              fit: BoxFit.cover,
              opacity: 0.35,
            ),
          ),
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    19, 17, 19, 25,
                  ),
                  children: [
                    _wardrobeBag(),

                    // Show rental configuration only when the bag has outfits.
                    if (selectedOutfits.isNotEmpty) ...[
                      const SizedBox(height: 27),
                      _durationSection(),
                      const SizedBox(height: 24),
                      _addressSection(),
                      const SizedBox(height: 24),
                      _coutureCareSection(),
                      const SizedBox(height: 24),
                      _orderSummary(),
                      const SizedBox(height: 23),
                      _conciergeSection(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
      selectedOutfits.isNotEmpty ? _bottomBar() : null,
    );
  }
}

class _FreeTag extends StatelessWidget {
  const _FreeTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3B8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Color(0xFF65481B),
        ),
      ),
    );
  }
}