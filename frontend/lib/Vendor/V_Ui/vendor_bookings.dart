
import 'package:flutter/material.dart';

import '../V_Ui_Logic/vendor_booking_logic.dart';

class VendorBookings extends StatefulWidget {
  const VendorBookings({super.key});

  @override
  State<VendorBookings> createState() => _VendorBookingsState();
}

class _VendorBookingsState extends State<VendorBookings>
    with SingleTickerProviderStateMixin {
  late VendorBookingLogic logic;
  late TabController tabController;

  static const burgundy = Color(0xFF800020);
  static const darkBurgundy = Color(0xFF4C1026);
  static const gold = Color(0xFFE9D8B0);
  static const cream = Color(0xFFFFFCF8);

  final List<String> categories = [
    'pending',
    'accepted',
    'handed_over',
    'rejected',
    'customer_cancelled',
    'cancelled_by_you',
  ];

  final List<String> tabLabels = [
    'Pending',
    'Accepted',
    'Handed Over',
    'Rejected',
    'Customer\nCancelled',
    'Cancelled\nby You',
  ];

  @override
  void initState() {
    super.initState();
    logic = VendorBookingLogic();
    tabController = TabController(length: 6, vsync: this);
    logic.loadBookings();
  }

  @override
  void dispose() {
    logic.dispose();
    tabController.dispose();
    super.dispose();
  }
  Future<void> showCancellationRestrictionDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: burgundy),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Cancellation unavailable',
                style: TextStyle(
                  color: darkBurgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'This booking can no longer be cancelled because it is within '
              '24 hours of the rental start date.\n\n'
              'If you have a genuine issue with this booking, please raise '
              'a support ticket for assistance.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: burgundy),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support ticket feature coming soon.'),
                  backgroundColor: burgundy,
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Raise a Ticket'),
          ),
        ],
      ),
    );
  }
  Future<String?> selectRentMethod() async {
    String selectedMethod = 'delivery';

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Confirm availability',
                style: TextStyle(
                  color: darkBurgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can you hand over this outfit to the customer?',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  _rentMethodOption(
                    title: 'Delivery available',
                    subtitle: 'You can deliver the outfit.',
                    icon: Icons.local_shipping_outlined,
                    value: 'delivery',
                    selected: selectedMethod,
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'delivery';
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _rentMethodOption(
                    title: 'Customer pickup',
                    subtitle: 'Customer can collect the outfit.',
                    icon: Icons.storefront_outlined,
                    value: 'pickup',
                    selected: selectedMethod,
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'pickup';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: burgundy),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      selectedMethod,
                    );
                  },
                  child: const Text('Confirm & Accept'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _rentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String selected,
    required VoidCallback onTap,
  }) {
    final isSelected = selected == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isSelected
              ? burgundy.withOpacity(0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? burgundy : gold,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: burgundy, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkBurgundy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? burgundy : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String money(dynamic value) {
    final amount =
        double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(0)}';
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString());
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }
  bool canCompleteBooking(dynamic returnDate) {
    if (returnDate == null) return false;

    try {
      final date = DateTime.parse(returnDate.toString());

      final today = DateTime.now();

      final returnDay = DateTime(date.year, date.month, date.day);
      final todayDate = DateTime(today.year, today.month, today.day);

      return !todayDate.isBefore(returnDay);
    } catch (_) {
      return false;
    }
  }

  Future<String?> askReason(String title) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: darkBurgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your reason...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;

              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    // Do not dispose the controller here while the dialog
    // may still be completing its closing transition.
    return result;
  }


  Future<bool> confirmAction(
      String title,
      String message,
      ) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: Text(
          title,
          style: const TextStyle(
            color: darkBurgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Go back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> handleAction(
      Map<String, dynamic> booking,
      String action,
      ) async {
    final id = booking['id']?.toString() ?? '';
    if (id.isEmpty) return;

    bool success = false;

    switch (action) {
      case 'accept':
        final rentMethod = await selectRentMethod();

        if (rentMethod == null) return;

        success = await logic.acceptBooking(
          id,
          rentMethod,
        );
        break;

      case 'reject':
        final reason = await askReason('Reject booking');
        if (reason == null) return;

        success = await logic.rejectBooking(id, reason);
        break;

      case 'cancel':
        final reason = await askReason('Cancel booking');
        if (reason == null) return;

        success = await logic.cancelBooking(id, reason);
        break;

      case 'handover':
        if (!await confirmAction(
          'Confirm handover?',
          'Have you handed over the outfit to the customer?',
        )) {
          return;
        }

        success = await logic.handoverBooking(id);
        break;

      case 'complete':
        if (!await confirmAction(
          'Complete booking?',
          'Did you receive your outfit back from the customer?',
        )) {
          return;
        }

        success = await logic.completeBooking(id);
        break;
    }

    if (!mounted) return;

    if (!success &&
        action == 'cancel' &&
        (logic.errorMessage ?? '').toLowerCase().contains('24')) {
      await showCancellationRestrictionDialog();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking updated successfully'
              : logic.errorMessage ?? 'Action failed',
        ),
        backgroundColor: success ? Colors.green : burgundy,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade800;
      case 'accepted':
        return Colors.blue.shade700;
      case 'handed_over':
        return Colors.green.shade700;
      case 'completed':
        return Colors.teal.shade700;
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: burgundy),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkBurgundy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget amountRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: bold ? darkBurgundy : Colors.black54,
              fontWeight:
              bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            money(value),
            style: TextStyle(
              fontSize: 13,
              color: darkBurgundy,
              fontWeight:
              bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton(
      String label,
      VoidCallback onPressed, {
        bool outlined = false,
      }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: outlined ? Colors.white : burgundy,
        foregroundColor: outlined ? burgundy : Colors.white,
        side: const BorderSide(color: burgundy),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget bookingImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Image.network(
        imageUrl,
        width: 76,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const SizedBox.shrink(),
      ),
    );
  }

  Widget bookingCard(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? '';
    final name = booking['outfit_name']?.toString() ?? 'Outfit';
    final customer =
        booking['customer_name']?.toString() ?? 'Customer';
    final phone =
        booking['customer_phone']?.toString() ?? '';
    final imageUrl =
    booking['outfit_image_url']?.toString();

    final rejectedByMe = status == 'rejected';
    final customerCancelled =
        status == 'cancelled' &&
            booking['cancelled_by_role'] == 'customer';
    final cancelledByYou =
        status == 'cancelled' &&
            ['owner', 'vendor'].contains(booking['cancelled_by_role']);

    final outcomeReason = rejectedByMe
        ? booking['rejection_reason']
        : (customerCancelled || cancelledByYou)
        ? booking['cancellation_reason']
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: darkBurgundy.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            14, 0, 14, 15,
          ),
          leading: imageUrl != null && imageUrl.trim().isNotEmpty
              ? bookingImage(imageUrl)
              : const Icon(
            Icons.checkroom_outlined,
            color: burgundy,
            size: 30,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkBurgundy,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          rejectedByMe
                              ? 'REJECTED BY YOU'
                              : customerCancelled
                              ? 'CANCELLED BY CUSTOMER'
                              : cancelledByYou
                              ? 'CANCELLED BY YOU'
                              : status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor(status),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(color: Color(0xFFF0E7E2)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: burgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            infoRow(Icons.person_outline, 'Customer', customer),
            infoRow(
              Icons.phone_outlined,
              'Phone',
              phone.isEmpty ? '-' : phone,
            ),
            const Divider(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RENTAL DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: burgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            infoRow(
              Icons.checkroom_outlined,
              'Selected size',
              booking['selected_size']?.toString() ?? '-',
            ),
            if (booking['rent_method'] != null)
              infoRow(
                Icons.local_shipping_outlined,
                'Handover method',
                booking['rent_method'] == 'delivery'
                    ? 'Delivery'
                    : 'Customer Pickup',
              ),
            infoRow(
              Icons.calendar_today_outlined,
              'Rental starts',
              formatDate(booking['rental_start_date']),
            ),
            infoRow(
              Icons.event_available_outlined,
              'Return date',
              formatDate(booking['rental_return_date']),
            ),
            infoRow(
              Icons.timelapse,
              'Duration',
              '${booking['rental_days'] ?? '-'} days',
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  amountRow('Rental amount', booking['rental_amount']),
                  amountRow(
                    'Security deposit',
                    booking['security_deposit_amount'],
                  ),
                  amountRow(
                    'Total paid',
                    booking['total_amount'],
                    bold: true,
                  ),
                ],
              ),
            ),
            if (outcomeReason != null &&
                outcomeReason.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rejectedByMe
                          ? 'YOUR REJECTION REASON'
                          : customerCancelled
                          ? 'CUSTOMER CANCELLATION REASON'
                          : cancelledByYou
                          ? 'YOUR CANCELLATION REASON'
                          : 'CANCELLATION REASON',
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      outcomeReason.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: darkBurgundy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  actionButton(
                    'Accept',
                        () => handleAction(booking, 'accept'),
                  ),
                  actionButton(
                    'Reject',
                        () => handleAction(booking, 'reject'),
                    outlined: true,
                  ),
                ],
              ),
            ],
            if (status == 'accepted') ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  actionButton(
                    'Confirm Handover',
                        () => handleAction(booking, 'handover'),
                  ),
                  actionButton(
                    'Cancel Booking',
                        () => handleAction(booking, 'cancel'),
                    outlined: true,
                  ),
                ],
              ),
            ],
            if (status == 'handed_over') ...[
              const SizedBox(height: 14),

              if (canCompleteBooking(booking['rental_return_date']))
                SizedBox(
                  width: double.infinity,
                  child: actionButton(
                    'Complete Booking',
                        () => handleAction(booking, 'complete'),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold),
                  ),
                  child: const Text(
                    'The booking can be completed on or after the rental return date.',
                    style: TextStyle(
                      color: darkBurgundy,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget bookingList(String category) {
    final items = logic.bookingsFor(category);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 45,
              color: burgundy.withOpacity(0.35),
            ),
            const SizedBox(height: 10),
            Text(
              category == 'customer_cancelled'
                  ? 'No customer cancellations'
                  : category == 'cancelled_by_you'
                  ? 'No bookings cancelled by you'
                  : category == 'handed_over'
                  ? 'No handed-over bookings'
                  : category == 'rejected'
                  ? 'No rejected bookings'
                  : category == 'pending'
                  ? 'No pending requests'
                  : 'No accepted bookings',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: burgundy,
      onRefresh: logic.loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 15, 14, 25),
        itemCount: items.length,
        itemBuilder: (_, index) => bookingCard(items[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: cream,
        child: Container(
          decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background/login_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(
                    'Booking Management',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: burgundy,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: gold),
                    ),
                    child: TabBar(
                      controller: tabController,
                      isScrollable: true,

                      labelPadding: const EdgeInsets.symmetric(horizontal: 10),

                      labelColor: Colors.white,
                      unselectedLabelColor: burgundy,

                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: burgundy,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: gold,
                          width: 0.8,
                        ),
                      ),

                      dividerColor: Colors.transparent,

                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),

                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),

                      tabs: tabLabels.map((label) {
                        return Tab(
                          height: 46,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: logic.isLoading && logic.bookings.isEmpty
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: burgundy,
                    ),
                  )
                      : logic.errorMessage != null &&
                      logic.bookings.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          logic.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: logic.loadBookings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                      : TabBarView(
                    controller: tabController,
                    children: categories
                        .map(bookingList)
                        .toList(),
                  ),
                ),
                if (logic.isActionLoading)
                  const LinearProgressIndicator(
                    color: burgundy,
                    minHeight: 2,
                  ),
              ],
            );
          },
        ),
      ),
        ),
    );
  }
}
