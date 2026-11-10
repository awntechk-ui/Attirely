
import 'package:flutter/material.dart';
import '../U_Ui_Logic/book_trial_logic.dart';
import '../U_Ui_Logic/trial_address_logic.dart';
import 'add_trial_address.dart';

class BookTrialPage extends StatefulWidget {
  final List<Map<String, dynamic>> outfits;

  const BookTrialPage({
    super.key,
    required this.outfits,
  });

  @override
  State<BookTrialPage> createState() => _BookTrialPageState();
}

class _BookTrialPageState extends State<BookTrialPage> {
  // Green theme
  static const Color burgundy = Color(0xFF087443);
  static const Color lightBurgundy = Color(0xFFEAF6EF);
  static const Color pageBackground = Color(0xFFF5F8F5);
  static const Color darkGreen = Color(0xFF075C36);
  static const Color borderGreen = Color(0xFFDCEBE1);

  bool _isSubmitting = false;


  late final BookTrialLogic logic;

  @override
  void initState() {
    super.initState();

    logic = BookTrialLogic(outfits: widget.outfits);

    logic.loadSavedAddresses();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
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

  Future<void> _addAddress({Map<String, dynamic>? address}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTrialAddressPage(
          address: address,
        ),
      ),
    );

    if (!mounted || result == null) return;

    logic.setAddress(result);
  }

  void _chooseSavedAddress() {
    final addressLogic = TrialAddressLogic.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
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
                      'Select an Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (addressLogic.isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: burgundy,
                        ),
                      )
                    else if (addressLogic.addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No saved addresses yet.'),
                      )
                    else
                      ...addressLogic.addresses.map((address) {
                        final id = address['id']?.toString() ?? '';
                        final isDefault =
                            address['is_default'] == true;
                        final isSelected =
                            logic.selectedAddress?['id']?.toString() ==
                                id;

                        return Card(
                          color: isSelected
                              ? lightBurgundy
                              : Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? burgundy
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              addressLogic.selectAddress(address);
                              logic.setAddress(address);
                              Navigator.pop(sheetContext);
                            },
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: burgundy,
                            ),
                            title: Text(
                              '${address['address_type'] ?? 'Address'}'
                                  ' - ${address['full_name'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(logic.addressText(address)),
                                if (isDefault)
                                  const Text(
                                    'Default address',
                                    style: TextStyle(
                                      color: burgundy,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                try {
                                  if (value == 'edit') {
                                    Navigator.pop(sheetContext);
                                    await _addAddress(address: address);
                                  } else if (value == 'default') {
                                    await addressLogic
                                        .setDefaultAddress(id);

                                    if (!mounted) return;

                                    logic.setAddress(
                                      addressLogic.selectedAddress!,
                                    );

                                    _message('Default address updated.');
                                  } else if (value == 'delete') {
                                    final confirmed =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Delete Address?',
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete this address?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                    dialogContext,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                    dialogContext,
                                                    true,
                                                  ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: burgundy,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmed == true) {
                                      await addressLogic.deleteAddress(id);

                                      if (!mounted) return;

                                      logic.setAddress(
                                        addressLogic.selectedAddress ??
                                            {},
                                      );

                                      if (logic.selectedAddress!.isEmpty) {
                                        logic.clearAddress();
                                      }

                                      _message('Address deleted.');
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _message(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (!isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Set as default'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
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
                          foregroundColor: burgundy,
                          side: const BorderSide(color: burgundy),
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


  Future<void> _continuePayment() async {
    if (logic.isSubmitting) return;

    try {
      final response = await logic.submitBooking();

      if (!mounted) return;

      final bookingReference =
          response['booking_reference']?.toString() ?? '';

      final totalOutfits =
          response['total_outfits'] ?? logic.outfitCount;

      final amount =
          response['total_amount'] ?? logic.totalPayable;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 55,
            ),
            title: const Text(
              'Trial Booked Successfully!',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your trial requests have been sent to the respective vendors.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text('Outfits: $totalOutfits'),
                Text(
                  'Payment: ${response['payment_status'] ?? 'successful'}',
                ),
                Text('Amount: ₹$amount'),
                const SizedBox(height: 12),
                const Text(
                  'Booking Reference',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  bookingReference,
                  style: const TextStyle(
                    fontSize: 11,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }


  String _displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }


  Widget _outfitImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: lightBurgundy,
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_outlined,
          size: 38,
          color: burgundy,
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: lightBurgundy,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: burgundy,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _trialScheduleSection(Map<String, dynamic> outfit) {
    final outfitId = outfit['id']?.toString() ?? '';
    final selectedDate = logic.trialDateFor(outfitId);
    final selectedTime = logic.timeSlotFor(outfitId);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: lightBurgundy,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferred Trial Schedule',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: burgundy,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      logic.setTrialDate(outfitId, picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 17),
                  label: Text(
                    selectedDate == null
                        ? 'Select Date'
                        : _displayDate(selectedDate),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkGreen,
                    side: const BorderSide(color: borderGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedTime,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.access_time,
                      size: 17,
                    ),
                    hintText: 'Select Time',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: BookTrialLogic.trialTimeSlots.map((slot) {
                    return DropdownMenuItem<String>(
                      value: slot,
                      child: Text(
                        slot,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      logic.setTrialTimeSlot(outfitId, value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _priceRow(
      String label,
      String value, {
        bool bold = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: FontWeight.bold,
              color: valueColor ??
                  (bold ? burgundy : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressSection() {
    final address = logic.selectedAddress;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: burgundy,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Trial Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: address == null
                    ? _addAddress
                    : _chooseSavedAddress,
                child: Text(
                  address == null ? 'Add' : 'Change',
                  style: const TextStyle(
                    color: burgundy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (address == null) ...[
            const Text(
              'Add your address to continue with the trial booking.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: burgundy),
              ),
            ),
            TextButton.icon(
              onPressed: () => _message(
                'Current location feature is coming soon.',
              ),
              icon: const Icon(Icons.my_location, size: 17),
              label: const Text('Use Current Location'),
              style: TextButton.styleFrom(
                foregroundColor: burgundy,
              ),
            ),
          ] else ...[
            Text(
              '${address['address_type'] ?? 'Address'} · '
                  '${address['full_name'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              logic.addressText(address),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Mobile: ${address['mobile'] ?? ''}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Method'),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: lightBurgundy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: burgundy),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: burgundy,
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: burgundy,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Razorpay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'UPI, Cards, Net Banking and more',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: burgundy,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (logic.selectedOutfits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.checkroom_outlined,
                size: 65,
                color: burgundy,
              ),
              const SizedBox(height: 15),
              const Text(
                'No outfits selected',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go back to your cart and select available outfits '
                    'for your trial.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Cart'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 125),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: lightBurgundy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                color: burgundy,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Try before you decide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${logic.outfitCount} '
                          '${logic.outfitCount == 1 ? 'outfit' : 'outfits'} '
                          'selected for trial',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle('Selected Outfits'),

        ...logic.selectedOutfits.map((outfit) {
          final id = outfit['id']?.toString() ?? '';
          final name = outfit['name']?.toString() ?? 'Outfit';
          final image = logic.imageUrl(outfit);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 82,
                    height: 105,
                    child: _outfitImage(image),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total trial amount: ${logic.money(
                          BookTrialLogic.trialChargePerOutfit + BookTrialLogic.platformFeePerOutfit,
                        )}',
                        style: const TextStyle(
                          color: burgundy,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _trialScheduleSection(outfit),
                      TextButton.icon(
                        onPressed: () => logic.removeOutfit(id),
                        style: TextButton.styleFrom(
                          foregroundColor: burgundy,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 17,
                        ),
                        label: const Text('Remove from trial'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        _sectionTitle('Trial Address'),
        _addressSection(),

        const SizedBox(height: 22),

        _sectionTitle('Payment Summary'),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderGreen),
          ),
          child: Column(
            children: [
              _priceRow(
                'Trial charge (${logic.outfitCount} × ₹150)',
                logic.money(logic.totalTrialCharge),
              ),
              _priceRow(
                'Platform fee (${logic.outfitCount} × ₹50)',
                logic.money(logic.totalPlatformFee),
              ),
              const Divider(height: 22),
              _priceRow(
                'Total payable (${logic.outfitCount} × ₹200)',
                logic.money(logic.totalPayable),
                bold: true,
                valueColor: darkGreen,
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBurgundy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _priceRow(
                      'Refundable amount',
                      logic.money(logic.refundableAmount),
                      bold: true,
                      valueColor: darkGreen,
                    ),
                    const Text(
                      'Refundable amount = total payable − total platform fee. '
                          '₹150 is refundable for each outfit.',
                      style: TextStyle(
                        color: Colors.black54,
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

        const SizedBox(height: 22),

        _paymentSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logic,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: pageBackground,
          appBar: AppBar(
            backgroundColor: pageBackground,
            foregroundColor: burgundy,
            elevation: 0,
            title: const Text(
              'Book a Trial',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/app_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: _buildContent(),
          ),
          bottomNavigationBar: logic.selectedOutfits.isEmpty
              ? null
              : SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                15, 12, 15, 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _continuePayment,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirm Trial Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        logic.money(logic.totalPayable),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}