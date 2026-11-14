import 'package:attirely/User/U_Ui/payment_security.dart';
import 'package:flutter/material.dart';

import '../U_Ui_Logic/trial_address_logic.dart';
import '../U_Ui_Logic/rent_out_logic.dart';
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

  late final RentOutLogic logic;

  List<Map<String, dynamic>> get selectedOutfits => logic.selectedOutfits;
  Map<String, dynamic>? get selectedAddress => logic.selectedAddress;
  set selectedAddress(Map<String, dynamic>? value) => logic.setAddress(value);
  bool get backupSize => logic.backupSize;
  set backupSize(bool value) => logic.setBackupSize(value);
  bool get coutureCare => logic.coutureCare;
  set coutureCare(bool value) => logic.setCoutureCare(value);

  static const double careFee = RentOutLogic.careFee;


  static const double defaultSecurityDeposit = RentOutLogic.defaultSecurityDeposit;

  @override
  void initState() {
    super.initState();
    logic = RentOutLogic(outfits: widget.outfits);
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    await addressLogic.loadAddresses(refresh: true);

    if (!mounted) return;

    setState(() => logic.setAddress(addressLogic.selectedAddress));
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

  DateTime _startFor(Map<String, dynamic> outfit) {
    final raw = outfit['rental_start_date']?.toString();
    return DateTime.tryParse(raw ?? '') ??
        DateTime.now().add(const Duration(days: 1));
  }

  int _daysFor(Map<String, dynamic> outfit) {
    final value = outfit['rental_days'];
    final parsed = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    return (parsed == null || parsed < 1) ? 4 : parsed;
  }

  DateTime _returnFor(Map<String, dynamic> outfit) =>
      _startFor(outfit).add(Duration(days: _daysFor(outfit) - 1));


  Future<void> _changeOutfitDate(int index) async {
    if (index < 0 || index >= selectedOutfits.length) {
      return;
    }

    final outfit = selectedOutfits[index];
    final currentDate = _startFor(outfit);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate.isBefore(today)
          ? today
          : currentDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
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

    if (selected == null || !mounted) return;

    setState(() => logic.setStartDate(index, selected));
  }


  void _setOutfitDuration(int index, int days) {
    if (index < 0 || index >= selectedOutfits.length) {
      return;
    }

    setState(() => logic.setDuration(index, days));
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
  double get rentalTotal => logic.rentalTotal;

  double get securityDeposit => logic.securityDeposit;

  void _removeOutfit(int index) {
    final removedName = logic.removeOutfit(index);
    if (removedName.isNotEmpty) {
      setState(() {});
      _message('$removedName removed from this rental.');
    }
  }

  double get careTotal => logic.careTotal;

  double get platformFee => logic.platformFee;

  double get totalPayable => logic.totalPayable;

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

  Future<void> _addAddress({Map<String, dynamic>? address,}) async {
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

  Widget _durationSection() {
    const durations = [3, 4, 7, 10];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Dates & Duration for Each Outfit',
              icon: Icons.calendar_month_outlined,
              trailing: _smallLabel('SET INDIVIDUALLY')),
          const SizedBox(height: 8),
          const Text(
            'Choose a delivery date and rental period separately for every outfit.',
            style: TextStyle(fontSize: 11, color: muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...List.generate(selectedOutfits.length, (index) {
            final outfit = selectedOutfits[index];
            final start = _startFor(outfit);
            final end = _returnFor(outfit);
            final days = _daysFor(outfit);
            final name = outfit['name']?.toString() ?? 'Outfit ${index + 1}';
            return Container(
              margin: EdgeInsets.only(bottom: index == selectedOutfits.length - 1 ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBF9),
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkGreen))),
                    Text(_money(_number(outfit['rental_price']) * days),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkGreen)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _changeOutfitDate(index),
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: Text(_date(start), overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(foregroundColor: darkGreen, side: const BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11)),
                    )),
                    const SizedBox(width: 9),
                    Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(
                            'duration_${outfit['id'] ?? index}',
                          ),
                          value: days,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: durations.map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d days'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _setOutfitDuration(index, value);
                            }
                          },
                        )
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.local_shipping_outlined, size: 14, color: muted),
                    const SizedBox(width: 5),
                    Expanded(child: Text('Return pickup: ${_date(end)}',
                        style: const TextStyle(fontSize: 10, color: muted))),
                    Text('$days-day rental', style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    if (selectedOutfits.isEmpty) {
      _message('Please add outfits to your cart.');
      return;
    }
    if (selectedAddress == null) {
      _message('Please select a delivery address.');
      return;
    }

    final bookingCompleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSecurityPage(
          outfits: selectedOutfits
              .map((outfit) => Map<String, dynamic>.from(outfit))
              .toList(),
          deliveryAddress: Map<String, dynamic>.from(selectedAddress!),
          rentalFee: rentalTotal,
          securityDeposit: securityDeposit,
          coutureCareFee: careTotal,
          coutureCareEnabled: coutureCare,
          backupSizeIncluded: backupSize,
        ),
      ),
    );

    if (bookingCompleted == true && mounted) {
      Navigator.pop(context, true);
    }
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
            'Rental Fee (${selectedOutfits.length} Outfits, individual durations)',
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
            'Attirely Platform Fee (${selectedOutfits.length} outfits)',
            _money(platformFee),
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
  void dispose() {
    logic.dispose();
    super.dispose();
  }

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
              image: AssetImage('assets/background/app_bg.png'),
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

  // ---------------------------------------------------------
  // COMMON UI HELPERS
  // ---------------------------------------------------------

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(15),}) {
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
                icon: const Icon(Icons.arrow_back, color: darkGreen),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent Outfits',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        color: Color(0xFF202522),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Select dates & delivery details',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                    style: TextStyle(color: muted, fontSize: 10),
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
              valueColor: AlwaysStoppedAnimation<Color>(green),
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
            const Icon(Icons.checkroom_outlined, color: green, size: 17),
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
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Text(
                '${selectedOutfits.length} Outfits Selected',
                style: const TextStyle(fontSize: 10, color: darkGreen),
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
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
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
                    outfit['brand_name']?.toString() ?? '';
                final size = outfit['selected_size']?.toString() ??
                    outfit['size']?.toString() ?? '';
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    padding: EdgeInsets.only(left: 5, bottom: 4),
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
                                    style: TextStyle(fontSize: 9, color: muted),
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
                                    style: TextStyle(fontSize: 9, color: muted),
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

// import 'package:attirely/User/U_Ui/payment_security.dart';
// import 'package:flutter/material.dart';
//
// import '../U_Ui_Logic/trial_address_logic.dart';
// import 'add_trial_address.dart';
//
// class RentOutPage extends StatefulWidget {
//   final List<Map<String, dynamic>> outfits;
//
//   const RentOutPage({
//     super.key,
//     required this.outfits,
//   });
//
//   @override
//   State<RentOutPage> createState() => _RentOutPageState();
// }
//
// class _RentOutPageState extends State<RentOutPage> {
//   // Theme
//   static const Color green = Color(0xFF064C32);
//   static const Color darkGreen = Color(0xFF073F2B);
//   static const Color lightGreen = Color(0xFFEAF3E9);
//   static const Color background = Color(0xFFF7F8F5);
//   static const Color border = Color(0xFFE5E9E4);
//   static const Color muted = Color(0xFF777E79);
//
//   final TrialAddressLogic addressLogic = TrialAddressLogic.instance;
//
//   Map<String, dynamic>? selectedAddress;
//
//   // A page-local copy lets the user remove outfits from this rental
//   // without mutating the cart's original list.
//   late final List<Map<String, dynamic>> selectedOutfits;
//
//
//   bool backupSize = true;
//   bool coutureCare = true;
//
//   static const double careFee = 299;
//   static const double defaultSecurityDeposit = 1000;
//
//   @override
//   void initState() {
//     super.initState();
//     final defaultStart = DateTime.now().add(const Duration(days: 1));
//     selectedOutfits = widget.outfits.map((source) {
//       final outfit = Map<String, dynamic>.from(source);
//       outfit['rental_start_date'] ??= _isoDate(defaultStart);
//       outfit['rental_days'] ??= 4;
//       return outfit;
//     }).toList();
//     _loadAddress();
//   }
//
//   Future<void> _loadAddress() async {
//     await addressLogic.loadAddresses(refresh: true);
//
//     if (!mounted) return;
//
//     setState(() {
//       selectedAddress = addressLogic.selectedAddress;
//     });
//   }
//
//   String _isoDate(DateTime date) =>
//       '${date.year.toString().padLeft(4, '0')}-'
//           '${date.month.toString().padLeft(2, '0')}-'
//           '${date.day.toString().padLeft(2, '0')}';
//
//   DateTime _startFor(Map<String, dynamic> outfit) {
//     final raw = outfit['rental_start_date']?.toString();
//     return DateTime.tryParse(raw ?? '') ??
//         DateTime.now().add(const Duration(days: 1));
//   }
//
//   int _daysFor(Map<String, dynamic> outfit) {
//     final value = outfit['rental_days'];
//     final parsed = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
//     return (parsed == null || parsed < 1) ? 4 : parsed;
//   }
//
//   DateTime _returnFor(Map<String, dynamic> outfit) =>
//       _startFor(outfit).add(Duration(days: _daysFor(outfit) - 1));
//
//
//   Future<void> _changeOutfitDate(int index) async {
//     if (index < 0 || index >= selectedOutfits.length) {
//       return;
//     }
//
//     final outfit = selectedOutfits[index];
//     final currentDate = _startFor(outfit);
//
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//
//     final selected = await showDatePicker(
//       context: context,
//       initialDate: currentDate.isBefore(today)
//           ? today
//           : currentDate,
//       firstDate: today,
//       lastDate: today.add(const Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: green,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (selected == null || !mounted) return;
//
//     setState(() {
//       selectedOutfits[index]['rental_start_date'] =
//           _isoDate(selected);
//     });
//   }
//
//
//   void _setOutfitDuration(int index, int days) {
//     if (index < 0 || index >= selectedOutfits.length) {
//       return;
//     }
//
//     setState(() {
//       selectedOutfits[index]['rental_days'] = days;
//     });
//   }
//
//   double _number(dynamic value) {
//     if (value is num) return value.toDouble();
//
//     return double.tryParse(value?.toString() ?? '') ?? 0;
//   }
//
//   String _money(dynamic value) {
//     return '₹${_number(value).toStringAsFixed(0)}';
//   }
//
//   String _image(Map<String, dynamic> outfit) {
//     final cover = outfit['cover_image_url']?.toString() ?? '';
//
//     if (cover.isNotEmpty) return cover;
//
//     final images = outfit['images'];
//
//     if (images is List) {
//       for (final image in images) {
//         if (image is Map && image['is_cover'] == true) {
//           final url = image['image_url']?.toString() ?? '';
//
//           if (url.isNotEmpty) return url;
//         }
//       }
//
//       if (images.isNotEmpty && images.first is Map) {
//         return images.first['image_url']?.toString() ?? '';
//       }
//     }
//
//     return '';
//   }
//
//   double _depositFor(Map<String, dynamic> outfit) {
//     final deposit = _number(
//       outfit['security_deposit'] ??
//           outfit['security_price'] ??
//           outfit['deposit_amount'] ??
//           outfit['security'],
//     );
//
//     return deposit > 0 ? deposit : defaultSecurityDeposit;
//   }
//
//   // Rental price is charged per day for each outfit.
//   double get rentalTotal {
//     return selectedOutfits.fold<double>(
//       0,
//           (sum, outfit) =>
//       sum + (_number(outfit['rental_price']) * _daysFor(outfit)),
//     );
//   }
//
//   double get securityDeposit {
//     return selectedOutfits.fold<double>(
//       0,
//           (sum, outfit) => sum + _depositFor(outfit),
//     );
//   }
//
//   void _removeOutfit(int index) {
//     if (index < 0 || index >= selectedOutfits.length) return;
//
//     final removedName =
//         selectedOutfits[index]['name']?.toString() ?? 'Outfit';
//
//     setState(() {
//       selectedOutfits.removeAt(index);
//     });
//
//     _message('$removedName removed from this rental.');
//   }
//
//   double get careTotal => coutureCare ? careFee : 0;
//
//   double get totalPayable =>
//       rentalTotal + securityDeposit + careTotal;
//
//   String _date(DateTime date) {
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
//     ];
//
//     const weekdays = [
//       'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
//     ];
//
//     return '${weekdays[date.weekday - 1]}, '
//         '${months[date.month - 1]} ${date.day}';
//   }
//
//   String _fullDate(DateTime date) {
//     const months = [
//       'January', 'February', 'March', 'April',
//       'May', 'June', 'July', 'August',
//       'September', 'October', 'November', 'December',
//     ];
//
//     return '${months[date.month - 1]} ${date.year}';
//   }
//
//   String _addressText(Map<String, dynamic> address) {
//     final parts = [
//       address['house'],
//       address['street'],
//       address['landmark'],
//       address['city'],
//       address['state'],
//       address['pincode'],
//     ];
//
//     return parts
//         .where((part) =>
//     part != null && part.toString().trim().isNotEmpty)
//         .join(', ');
//   }
//
//   void _message(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }
//
//   Future<void> _addAddress({Map<String, dynamic>? address,}) async {
//     final result = await Navigator.push<Map<String, dynamic>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AddTrialAddressPage(
//           address: address,
//         ),
//       ),
//     );
//
//     if (!mounted || result == null) return;
//
//     setState(() {
//       selectedAddress = result;
//     });
//   }
//
//   void _chooseAddress() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(22),
//         ),
//       ),
//       builder: (sheetContext) {
//         return AnimatedBuilder(
//           animation: addressLogic,
//           builder: (context, _) {
//             return SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(18),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Select Delivery Address',
//                       style: TextStyle(
//                         fontSize: 19,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//
//                     if (addressLogic.isLoading)
//                       const Center(
//                         child: CircularProgressIndicator(
//                           color: green,
//                         ),
//                       )
//                     else if (addressLogic.addresses.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.all(15),
//                         child: Text('No saved addresses found.'),
//                       )
//                     else
//                       ...addressLogic.addresses.map((address) {
//                         final id = address['id']?.toString() ?? '';
//
//                         final selected =
//                             selectedAddress?['id']?.toString() == id;
//
//                         final isDefault =
//                             address['is_default'] == true;
//
//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             color: selected ? lightGreen : Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: selected ? green : border,
//                             ),
//                           ),
//                           child: ListTile(
//                             onTap: () {
//                               addressLogic.selectAddress(address);
//
//                               setState(() {
//                                 selectedAddress = address;
//                               });
//
//                               Navigator.pop(sheetContext);
//                             },
//                             leading: const Icon(
//                               Icons.location_on_outlined,
//                               color: green,
//                             ),
//                             title: Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     address['full_name']?.toString() ??
//                                         'Address',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                                 if (isDefault)
//                                   const Text(
//                                     'DEFAULT',
//                                     style: TextStyle(
//                                       fontSize: 9,
//                                       color: green,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             subtitle: Text(
//                               _addressText(address),
//                               maxLines: 3,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             trailing: selected
//                                 ? const Icon(
//                               Icons.check_circle,
//                               color: green,
//                             )
//                                 : const Icon(
//                               Icons.chevron_right,
//                               color: muted,
//                             ),
//                           ),
//                         );
//                       }),
//
//                     const SizedBox(height: 10),
//
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: () {
//                           Navigator.pop(sheetContext);
//                           _addAddress();
//                         },
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add New Address'),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: green,
//                           side: const BorderSide(color: green),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _durationSection() {
//     const durations = [3, 4, 7, 10];
//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _sectionHeading('Dates & Duration for Each Outfit',
//               icon: Icons.calendar_month_outlined,
//               trailing: _smallLabel('SET INDIVIDUALLY')),
//           const SizedBox(height: 8),
//           const Text(
//             'Choose a delivery date and rental period separately for every outfit.',
//             style: TextStyle(fontSize: 11, color: muted, height: 1.4),
//           ),
//           const SizedBox(height: 14),
//           ...List.generate(selectedOutfits.length, (index) {
//             final outfit = selectedOutfits[index];
//             final start = _startFor(outfit);
//             final end = _returnFor(outfit);
//             final days = _daysFor(outfit);
//             final name = outfit['name']?.toString() ?? 'Outfit ${index + 1}';
//             return Container(
//               margin: EdgeInsets.only(bottom: index == selectedOutfits.length - 1 ? 0 : 12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFAFBF9),
//                 border: Border.all(color: border),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(children: [
//                     Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkGreen))),
//                     Text(_money(_number(outfit['rental_price']) * days),
//                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkGreen)),
//                   ]),
//                   const SizedBox(height: 10),
//                   Row(children: [
//                     Expanded(child: OutlinedButton.icon(
//                       onPressed: () => _changeOutfitDate(index),
//                       icon: const Icon(Icons.calendar_today_outlined, size: 14),
//                       label: Text(_date(start), overflow: TextOverflow.ellipsis),
//                       style: OutlinedButton.styleFrom(foregroundColor: darkGreen, side: const BorderSide(color: border),
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11)),
//                     )),
//                     const SizedBox(width: 9),
//                     Expanded(
//                         child: DropdownButtonFormField<int>(
//                           key: ValueKey(
//                             'duration_${outfit['id'] ?? index}',
//                           ),
//                           value: days,
//                           isExpanded: true,
//                           decoration: const InputDecoration(
//                             labelText: 'Duration',
//                             isDense: true,
//                             contentPadding: EdgeInsets.symmetric(
//                               horizontal: 9,
//                               vertical: 10,
//                             ),
//                             border: OutlineInputBorder(),
//                           ),
//                           items: durations.map((d) {
//                             return DropdownMenuItem<int>(
//                               value: d,
//                               child: Text('$d days'),
//                             );
//                           }).toList(),
//                           onChanged: (value) {
//                             if (value != null) {
//                               _setOutfitDuration(index, value);
//                             }
//                           },
//                         )
//                     ),
//                   ]),
//                   const SizedBox(height: 8),
//                   Row(children: [
//                     const Icon(Icons.local_shipping_outlined, size: 14, color: muted),
//                     const SizedBox(width: 5),
//                     Expanded(child: Text('Return pickup: ${_date(end)}',
//                         style: const TextStyle(fontSize: 10, color: muted))),
//                     Text('$days-day rental', style: const TextStyle(fontSize: 10, color: darkGreen, fontWeight: FontWeight.w600)),
//                   ]),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _proceedToPayment() async {
//     if (selectedOutfits.isEmpty) {
//       _message('Please add outfits to your cart.');
//       return;
//     }
//     if (selectedAddress == null) {
//       _message('Please select a delivery address.');
//       return;
//     }
//
//     final bookingCompleted = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PaymentSecurityPage(
//           outfits: selectedOutfits
//               .map((outfit) => Map<String, dynamic>.from(outfit))
//               .toList(),
//           deliveryAddress: Map<String, dynamic>.from(selectedAddress!),
//           rentalFee: rentalTotal,
//           securityDeposit: securityDeposit,
//           coutureCareFee: careTotal,
//           coutureCareEnabled: coutureCare,
//           backupSizeIncluded: backupSize,
//         ),
//       ),
//     );
//
//     if (bookingCompleted == true && mounted) {
//       Navigator.pop(context, true);
//     }
//   }
//
//   Widget _dateInfoCard({
//     required String title,
//     required IconData icon,
//     required String date,
//     required String subtitle,
//   }) {
//     return Container(
//       constraints: const BoxConstraints(minHeight: 118),
//       padding: const EdgeInsets.all(11),
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius: BorderRadius.circular(7),
//         border: Border.all(color: border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: darkGreen,
//                     fontSize: 9,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//               Icon(icon, color: darkGreen, size: 17),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             date,
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             subtitle,
//             style: const TextStyle(
//               fontSize: 9,
//               height: 1.3,
//               color: muted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // DELIVERY ADDRESS
//   // ---------------------------------------------------------
//
//   Widget _addressSection() {
//     final address = selectedAddress;
//
//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _sectionHeading(
//             'Delivery Address',
//             icon: Icons.location_on_outlined,
//             trailing: TextButton(
//               onPressed: address == null
//                   ? () => _addAddress()
//                   : _chooseAddress,
//               child: Text(
//                 address == null ? 'ADD' : 'CHANGE',
//                 style: const TextStyle(
//                   color: darkGreen,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 7),
//
//           if (address == null)
//             Container(
//               padding: const EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: background,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: border),
//               ),
//               child: Row(
//                 children: [
//                   const Expanded(
//                     child: Text(
//                       'Add a delivery address for your rental.',
//                       style: TextStyle(
//                         color: muted,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () => _addAddress(),
//                     child: const Text(
//                       'ADD ADDRESS',
//                       style: TextStyle(color: green),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: background,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: border),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 37,
//                     width: 37,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFB6EBD0),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.home_outlined,
//                       color: green,
//                       size: 19,
//                     ),
//                   ),
//                   const SizedBox(width: 11),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Wrap(
//                           spacing: 7,
//                           crossAxisAlignment: WrapCrossAlignment.center,
//                           children: [
//                             Text(
//                               address['full_name']?.toString() ??
//                                   'Customer',
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             if (address['is_default'] == true)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 6,
//                                   vertical: 3,
//                                 ),
//                                 color: const Color(0xFFE8EAE7),
//                                 child: const Text(
//                                   'Default',
//                                   style: TextStyle(fontSize: 9),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         const SizedBox(height: 5),
//                         Text(
//                           _addressText(address),
//                           style: const TextStyle(
//                             color: muted,
//                             fontSize: 11,
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 5),
//                         Text(
//                           '+91 ${address['mobile'] ?? ''}',
//                           style: const TextStyle(
//                             color: muted,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           const SizedBox(height: 13),
//
//           // Express delivery
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF2F3F0),
//               borderRadius: BorderRadius.circular(7),
//               border: Border.all(color: border),
//             ),
//             child: const Row(
//               children: [
//                 Icon(
//                   Icons.bolt,
//                   color: Color(0xFF70541B),
//                   size: 19,
//                 ),
//                 SizedBox(width: 9),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Express White-Glove Hand Delivery',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         '(Complimentary)',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: darkGreen,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 13),
//
//           // Backup size
//           Container(
//             padding: const EdgeInsets.all(11),
//             decoration: BoxDecoration(
//               color: background,
//               borderRadius: BorderRadius.circular(7),
//               border: Border.all(color: border),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: Checkbox(
//                     value: backupSize,
//                     activeColor: green,
//                     onChanged: (value) {
//                       setState(() {
//                         backupSize = value ?? false;
//                       });
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 7),
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             'Include Free Backup Size',
//                             style: TextStyle(fontSize: 11),
//                           ),
//                           SizedBox(width: 7),
//                           _FreeTag(),
//                         ],
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "Complimentary Fit Guarantee! We'll include "
//                             "an alternate size for eligible pieces at no added fee.",
//                         style: TextStyle(
//                           color: muted,
//                           fontSize: 10,
//                           height: 1.4,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // COUTURE CARE
//   // ---------------------------------------------------------
//
//   Widget _coutureCareSection() {
//     return _card(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: 33,
//                 width: 33,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFDCEBDD),
//                   borderRadius: BorderRadius.circular(11),
//                 ),
//                 child: const Icon(
//                   Icons.shield_outlined,
//                   color: darkGreen,
//                   size: 19,
//                 ),
//               ),
//               const SizedBox(width: 10),
//
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Wrap(
//                       spacing: 7,
//                       crossAxisAlignment: WrapCrossAlignment.center,
//                       children: [
//                         const Text(
//                           'ATTIRELY Couture Care™',
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 4,
//                           ),
//                           color: const Color(0xFFB8EBCF),
//                           child: const Text(
//                             'RECOMMENDED',
//                             style: TextStyle(
//                               fontSize: 8,
//                               color: darkGreen,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 7),
//                     const Text(
//                       'Cover accidental stains, minor seam tears, '
//                           'beadwork looseness, and zipper mishaps up to ₹5,000.',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: muted,
//                         height: 1.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               Switch(
//                 value: coutureCare,
//                 activeColor: Colors.white,
//                 activeTrackColor: green,
//                 inactiveTrackColor: Colors.grey.shade300,
//                 onChanged: (value) {
//                   setState(() {
//                     coutureCare = value;
//                   });
//                 },
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 13),
//           const Divider(height: 1, color: border),
//           const SizedBox(height: 10),
//
//           Row(
//             children: [
//               const Expanded(
//                 child: Text(
//                   'Peace of Mind Fee',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: muted,
//                   ),
//                 ),
//               ),
//               Text(
//                 coutureCare ? '₹299' : '₹0',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: darkGreen,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // ORDER SUMMARY
//   // ---------------------------------------------------------
//
//   Widget _priceRow(
//       String label,
//       String value, {
//         bool bold = false,
//         String? subtitle,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: bold ? 14 : 11,
//                     fontWeight:
//                     bold ? FontWeight.w700 : FontWeight.normal,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 if (subtitle != null) ...[
//                   const SizedBox(height: 3),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(
//                       fontSize: 9,
//                       color: muted,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: bold ? 19 : 12,
//               fontWeight: FontWeight.w600,
//               color: bold ? darkGreen : Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _orderSummary() {
//     return _card(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _sectionHeading(
//             'Order Summary',
//             icon: Icons.receipt_long_outlined,
//           ),
//           const SizedBox(height: 12),
//
//           _priceRow(
//             'Rental Fee (${selectedOutfits.length} Outfits, individual durations)',
//             _money(rentalTotal),
//           ),
//
//           _priceRow(
//             'Refundable Security Deposit',
//             _money(securityDeposit),
//             subtitle: '100% Refundable on return pickup',
//           ),
//
//           if (coutureCare)
//             _priceRow(
//               'Couture Care™ Damage Protection',
//               _money(careTotal),
//             ),
//
//           _priceRow(
//             'White-Glove Delivery & Pickup',
//             'FREE',
//           ),
//
//           const Divider(height: 22, color: border),
//
//           _priceRow(
//             'Total Payable',
//             _money(totalPayable),
//             bold: true,
//           ),
//
//           const Text(
//             'Includes refundable security deposit.',
//             style: TextStyle(
//               fontSize: 10,
//               color: muted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // CONCIERGE
//   // ---------------------------------------------------------
//
//   Widget _conciergeSection() {
//     return Container(
//       padding: const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEDEEEB),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: border),
//       ),
//       child: const Row(
//         children: [
//           Icon(
//             Icons.auto_awesome,
//             color: darkGreen,
//             size: 23,
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Dedicated Atelier Concierge',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 SizedBox(height: 3),
//                 Text(
//                   'Your garments arrive professionally steamed '
//                       'in reusable couture garment bags.',
//                   style: TextStyle(
//                     color: muted,
//                     fontSize: 10,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // BOTTOM PAYMENT BAR
//   // ---------------------------------------------------------
//
//   Widget _bottomBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.07),
//               blurRadius: 13,
//               offset: const Offset(0, -3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Row(
//               children: [
//                 Icon(
//                   Icons.lock_outline,
//                   color: darkGreen,
//                   size: 13,
//                 ),
//                 SizedBox(width: 7),
//                 Expanded(
//                   child: Text(
//                     '100% Refundable Deposit · Free Doorstep Pickup & Cleaning Included',
//                     style: TextStyle(
//                       fontSize: 9,
//                       color: muted,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'TOTAL DUE',
//                         style: TextStyle(
//                           fontSize: 10,
//                           letterSpacing: 1,
//                           color: muted,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         _money(totalPayable),
//                         style: const TextStyle(
//                           fontSize: 22,
//                           color: darkGreen,
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                       Text(
//                         '${_money(securityDeposit)} refundable',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           color: muted,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 Expanded(
//                   child: SizedBox(
//                     height: 49,
//                     child: ElevatedButton(
//                       onPressed: _proceedToPayment,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: green,
//                         foregroundColor: Colors.white,
//                         elevation: 3,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Flexible(
//                             child: Text(
//                               'Proceed to Payment',
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 7),
//                           Icon(
//                             Icons.arrow_forward,
//                             size: 17,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // MAIN BUILD
//   // ---------------------------------------------------------
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: background,
//       appBar: null,
//       body: SafeArea(
//         top: true,
//         bottom: false,
//         child: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/background/app_bg.png'),
//               fit: BoxFit.cover,
//               opacity: 0.35,
//             ),
//           ),
//           child: Column(
//             children: [
//               _header(),
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.fromLTRB(
//                     19, 17, 19, 25,
//                   ),
//                   children: [
//                     _wardrobeBag(),
//
//                     // Show rental configuration only when the bag has outfits.
//                     if (selectedOutfits.isNotEmpty) ...[
//                       const SizedBox(height: 27),
//                       _durationSection(),
//                       const SizedBox(height: 24),
//                       _addressSection(),
//                       const SizedBox(height: 24),
//                       _coutureCareSection(),
//                       const SizedBox(height: 24),
//                       _orderSummary(),
//                       const SizedBox(height: 23),
//                       _conciergeSection(),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar:
//       selectedOutfits.isNotEmpty ? _bottomBar() : null,
//     );
//   }
//
//   // ---------------------------------------------------------
//   // COMMON UI HELPERS
//   // ---------------------------------------------------------
//
//   Widget _card({
//     required Widget child,
//     EdgeInsets padding = const EdgeInsets.all(15),
//   }) {
//     return Container(
//       padding: padding,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(color: border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.025),
//             blurRadius: 9,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
//
//   Widget _sectionHeading(
//       String title, {
//         IconData? icon,
//         Widget? trailing,
//       }) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 19, color: green),
//           const SizedBox(width: 9),
//         ],
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF202522),
//             ),
//           ),
//         ),
//         if (trailing != null) trailing,
//       ],
//     );
//   }
//
//   Widget _smallLabel(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         color: muted,
//         fontSize: 10,
//         letterSpacing: 0.6,
//       ),
//     );
//   }
//
//   Widget _outfitImage(String url) {
//     if (url.isEmpty) {
//       return Container(
//         color: lightGreen,
//         alignment: Alignment.center,
//         child: const Icon(
//           Icons.checkroom_outlined,
//           color: green,
//           size: 28,
//         ),
//       );
//     }
//
//     return Image.network(
//       url,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Container(
//         color: lightGreen,
//         alignment: Alignment.center,
//         child: const Icon(
//           Icons.broken_image_outlined,
//           color: green,
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // HEADER
//   // ---------------------------------------------------------
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
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Rent Outfits',
//                       style: TextStyle(
//                         fontFamily: 'serif',
//                         fontSize: 22,
//                         color: Color(0xFF202522),
//                       ),
//                     ),
//                     SizedBox(height: 3),
//                     Text(
//                       'Select dates & delivery details',
//                       style: TextStyle(color: muted, fontSize: 11),
//                     ),
//                   ],
//                 ),
//               ),
//               const Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     'STEP 1 OF 2',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 3),
//                   Text(
//                     'Dates & Delivery',
//                     style: TextStyle(color: muted, fontSize: 10),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 9),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(5),
//             child: const LinearProgressIndicator(
//               value: 0.5,
//               minHeight: 3,
//               backgroundColor: Color(0xFFE1E6E0),
//               valueColor: AlwaysStoppedAnimation<Color>(green),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------
//   // WARDROBE BAG
//   // ---------------------------------------------------------
//
//   Widget _wardrobeBag() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(Icons.checkroom_outlined, color: green, size: 17),
//             const SizedBox(width: 9),
//             const Expanded(
//               child: Text(
//                 'WARDROBE BAG',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 1,
//                 ),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
//               decoration: BoxDecoration(
//                 color: lightGreen,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: border),
//               ),
//               child: Text(
//                 '${selectedOutfits.length} Outfits Selected',
//                 style: const TextStyle(fontSize: 10, color: darkGreen),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         if (selectedOutfits.isEmpty)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(color: border),
//               borderRadius: BorderRadius.circular(11),
//             ),
//             child: const Text(
//               'Your wardrobe bag is empty. Go back to your cart and add an outfit.',
//               style: TextStyle(color: muted, fontSize: 12, height: 1.4),
//             ),
//           )
//         else
//           SizedBox(
//             height: 142,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: selectedOutfits.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 10),
//               itemBuilder: (context, index) {
//                 final outfit = selectedOutfits[index];
//                 final name = outfit['name']?.toString() ?? 'Outfit';
//                 final brand = outfit['brand']?.toString() ??
//                     outfit['brand_name']?.toString() ?? '';
//                 final size = outfit['selected_size']?.toString() ??
//                     outfit['size']?.toString() ?? '';
//                 final dailyRental = _number(outfit['rental_price']);
//                 final deposit = _depositFor(outfit);
//
//                 return Container(
//                   width: 290,
//                   padding: const EdgeInsets.all(9),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: border),
//                     borderRadius: BorderRadius.circular(11),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(6),
//                         child: SizedBox(
//                           width: 72,
//                           height: 122,
//                           child: _outfitImage(_image(outfit)),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       if (brand.isNotEmpty)
//                                         Text(
//                                           brand.toUpperCase(),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                           style: const TextStyle(
//                                             color: darkGreen,
//                                             fontSize: 9,
//                                             letterSpacing: 0.7,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       const SizedBox(height: 3),
//                                       Text(
//                                         name,
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(
//                                           fontSize: 13,
//                                           height: 1.15,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 InkWell(
//                                   onTap: () => _removeOutfit(index),
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: const Padding(
//                                     padding: EdgeInsets.only(left: 5, bottom: 4),
//                                     child: Icon(
//                                       Icons.close,
//                                       size: 18,
//                                       color: Color(0xFF8A7779),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (size.isNotEmpty) ...[
//                               const SizedBox(height: 1),
//                               Text(
//                                 'Size: $size',
//                                 style: const TextStyle(
//                                   fontSize: 10,
//                                   color: muted,
//                                 ),
//                               ),
//                             ],
//                             const Spacer(),
//                             Row(
//                               children: [
//                                 const Expanded(
//                                   child: Text(
//                                     'Rental / day',
//                                     style: TextStyle(fontSize: 9, color: muted),
//                                   ),
//                                 ),
//                                 Text(
//                                   _money(dailyRental),
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     color: darkGreen,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 3),
//                             Row(
//                               children: [
//                                 const Expanded(
//                                   child: Text(
//                                     'Security deposit',
//                                     style: TextStyle(fontSize: 9, color: muted),
//                                   ),
//                                 ),
//                                 Text(
//                                   _money(deposit),
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }
//
// }
//
// class _FreeTag extends StatelessWidget {
//   const _FreeTag();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 7,
//         vertical: 3,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFE3B8),
//         borderRadius: BorderRadius.circular(3),
//       ),
//       child: const Text(
//         'FREE',
//         style: TextStyle(
//           fontSize: 8,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF65481B),
//         ),
//       ),
//     );
//   }
// }