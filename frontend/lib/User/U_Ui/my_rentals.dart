
import 'package:flutter/material.dart';

import '../U_Ui_Logic/my_rentals_logic.dart';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  late final MyRentalsLogic logic;

  static const Color burgundy = Color(0xFF6B1E2E);
  static const Color ivory = Color(0xFFFCF8F5);
  static const Color muted = Color(0xFF927F7D);
  static const Color border = Color(0xFFECE3DF);

  @override
  void initState() {
    super.initState();
    logic = MyRentalsLogic();
    logic.loadRentals();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFC17A16);
      case 'accepted':
        return const Color(0xFF167447);
      case 'active':
        return const Color(0xFF176B9B);
      case 'rejected':
        return const Color(0xFFB3262D);
      case 'completed':
        return const Color(0xFF285D9B);
      case 'cancelled':
        return const Color(0xFF777777);
      default:
        return muted;
    }
  }

  Color statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF4E2);
      case 'accepted':
        return const Color(0xFFEAF5EE);
      case 'active':
        return const Color(0xFFE7F2FA);
      case 'rejected':
        return const Color(0xFFFCEBEC);
      case 'completed':
        return const Color(0xFFEAF1FA);
      case 'cancelled':
        return const Color(0xFFF1EFED);
      default:
        return const Color(0xFFF1EFED);
    }
  }

  void showSearchBox() {
    showSearch(
      context: context,
      delegate: _RentalSearchDelegate(
        onSearch: logic.setSearch,
      ),
    );
  }

  void showDetails(Map<String, dynamic> rental) {
    final status = logic.statusOf(rental);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Rental Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _detailLine(
                    'Outfit',
                    logic.outfitName(rental),
                  ),
                  _detailLine(
                    'Booking reference',
                    logic.bookingLabel(rental['booking_reference']),
                  ),
                  _detailLine(
                    'Status',
                    logic.titleCase(status),
                  ),
                  _detailLine(
                    'Selected size',
                    rental['selected_size']?.toString() ?? '—',
                  ),
                  _detailLine(
                    'Rental start',
                    logic.dateLabel(rental['rental_start_date']),
                  ),
                  _detailLine(
                    'Rental return',
                    logic.dateLabel(rental['rental_return_date']),
                  ),
                  _detailLine(
                    'Rental duration',
                    '${rental['rental_days'] ?? 0} days',
                  ),

                  const Divider(height: 25),

                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _detailLine(
                    'Rental price per day',
                    logic.money(rental['rental_price_per_day']),
                  ),
                  _detailLine(
                    'Rental amount',
                    logic.money(rental['rental_amount']),
                  ),
                  _detailLine(
                    'Security deposit',
                    logic.money(rental['security_deposit_amount']),
                  ),
                  _detailLine(
                    'Platform fee',
                    logic.money(rental['platform_fee']),
                  ),
                  _detailLine(
                    'Total paid',
                    logic.money(rental['total_amount']),
                  ),
                  _detailLine(
                    'Payment status',
                    logic.titleCase(
                      rental['payment_status']?.toString() ?? 'unknown',
                    ),
                  ),

                  if (rental['refund_amount'] != null)
                    _detailLine(
                      'Refund amount',
                      logic.money(rental['refund_amount']),
                    ),

                  if (rental['refund_status'] != null)
                    _detailLine(
                      'Refund status',
                      logic.titleCase(
                        rental['refund_status'].toString(),
                      ),
                    ),

                  if ((rental['rejection_reason'] ?? '')
                      .toString().trim().isNotEmpty)
                    _detailLine(
                      'Rejection reason',
                      rental['rejection_reason'].toString(),
                    ),

                  if ((rental['cancellation_reason'] ?? '')
                      .toString().trim().isNotEmpty)
                    _detailLine(
                      'Cancellation reason',
                      rental['cancellation_reason'].toString(),
                    ),

                  const Divider(height: 25),

                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    logic.addressLabel(rental).isEmpty
                        ? 'Address unavailable'
                        : logic.addressLabel(rental),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: muted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF321D25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logic,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: ivory,
          appBar: AppBar(
            backgroundColor: ivory,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: burgundy),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATTIRELY',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: burgundy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'My Rentals',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF321D25),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: showSearchBox,
                icon: const Icon(Icons.search, color: burgundy),
              ),
              IconButton(
                onPressed: logic.loadRentals,
                icon: const Icon(Icons.refresh, color: burgundy),
              ),
            ],
          ),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Track your rental requests, upcoming rentals and rental history.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E9E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                      ),
                      child: const Text(
                        'MY WARDROBE',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.5,
                          color: burgundy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: logic.filters.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    final filter = logic.filters[index];
                    final selected = logic.selectedFilter == filter;

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => logic.setFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? burgundy : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? burgundy : border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              filter,
                              style: TextStyle(
                                fontSize: 10,
                                color: selected ? Colors.white : burgundy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${logic.countFor(filter)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? Colors.white
                                    : statusColor(filter),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 7),

              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (logic.isLoading && logic.rentals.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: burgundy),
      );
    }

    if (logic.errorMessage != null && logic.rentals.isEmpty) {
      return _emptyState(
        icon: Icons.wifi_off_outlined,
        title: 'Unable to load your rentals',
        subtitle: logic.errorMessage!,
        buttonText: 'Try Again',
        onPressed: logic.loadRentals,
      );
    }

    if (logic.groupedRentals.isEmpty) {
      return RefreshIndicator(
        color: burgundy,
        onRefresh: logic.loadRentals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Color(0xFFC9AEB2),
            ),
            SizedBox(height: 14),
            Center(
              child: Text(
                'No rentals found',
                style: TextStyle(
                  color: burgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                'Your rental bookings will appear here.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: burgundy,
      onRefresh: logic.loadRentals,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: logic.groupedRentals.length,
        itemBuilder: (context, index) {
          return _bookingGroup(logic.groupedRentals[index]);
        },
      ),
    );
  }

  Widget _bookingGroup(Map<String, dynamic> group) {
    final outfits = group['outfits'] as List<Map<String, dynamic>>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RENTAL BOOKING #${logic.bookingLabel(group['booking_reference'])}',
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${group['total_outfits']} Outfits',
                  style: const TextStyle(fontSize: 9, color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Booked on: ${logic.dateLabel(group['booked_on'])}',
            style: const TextStyle(fontSize: 9, color: muted),
          ),
          const Divider(height: 17, color: border),
          ...outfits.map(_outfitCard),
        ],
      ),
    );
  }

  Widget _outfitCard(Map<String, dynamic> rental) {
    final status = logic.statusOf(rental);
    final imageUrl = logic.imageOf(rental);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  width: 91,
                  height: 112,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            logic.outfitName(rental),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF321D25),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _statusBadge(status),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Size: ${rental['selected_size'] ?? '—'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${rental['rental_days'] ?? 0} days rental',
                      style: const TextStyle(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      logic.money(rental['rental_amount']),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: burgundy,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'Rental amount',
                      style: TextStyle(
                        fontSize: 9,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20, color: border),

          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: burgundy,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${logic.dateLabel(rental['rental_start_date'])} – ${logic.dateLabel(rental['rental_return_date'])}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
              ),
              Text(
                'Total ${logic.money(rental['total_amount'])}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: burgundy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () => showDetails(rental),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: burgundy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'View Rental Details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 9),

            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: logic.cancellingRentalIds.contains(
                  rental['id']?.toString(),
                )
                    ? null
                    : () => _showCancelDialog(rental),

                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                ),

                label: Text(
                  logic.cancellingRentalIds.contains(
                    rental['id']?.toString(),
                  )
                      ? 'Cancelling...'
                      : 'Cancel Rental',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB3262D),
                  side: const BorderSide(
                    color: Color(0xFFB3262D),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }


  Future<void> _showCancelDialog(Map<String, dynamic> rental) async {
    final rentalId = rental['id']?.toString() ?? '';

    if (rentalId.isEmpty ||
        logic.statusOf(rental) != 'pending') {
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Cancel Rental?',
            style: TextStyle(
              color: Color(0xFF6B1E2E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this rental request? '
                    'This action cannot be undone.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancellation reason',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 250,
                decoration: InputDecoration(
                  hintText: 'Tell us why you are cancelling...',
                  filled: true,
                  fillColor: const Color(0xFFFCF8F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF6B1E2E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Keep Rental',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B1E2E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a cancellation reason.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (reason == null || reason.trim().isEmpty) return;
    if (!mounted) return;

    try {
      await logic.cancelRental(
        rentalId: rentalId,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental cancelled successfully.'),
          backgroundColor: Color(0xFF6B1E2E),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        logic.titleCase(status),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: statusColor(status),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 91,
      height: 112,
      color: const Color(0xFFF5EEEE),
      child: const Icon(
        Icons.checkroom_outlined,
        color: burgundy,
        size: 30,
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 45, color: const Color(0xFFC9AEB2)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: burgundy,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalSearchDelegate extends SearchDelegate {
  final ValueChanged<String> onSearch;

  _RentalSearchDelegate({required this.onSearch});

  @override
  String get searchFieldLabel => 'Search rentals or booking reference';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
          onSearch('');
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, null);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    onSearch(query);
    return const Center(
      child: Text('Search by outfit name or booking reference'),
    );
  }
}


//
// import 'package:flutter/material.dart';
//
// import '../U_Ui_Logic/my_rentals_logic.dart';
//
// class MyRentalsPage extends StatefulWidget {
//   const MyRentalsPage({super.key});
//
//   @override
//   State<MyRentalsPage> createState() => _MyRentalsPageState();
// }
//
// class _MyRentalsPageState extends State<MyRentalsPage> {
//   late final MyRentalsLogic logic;
//
//   static const Color burgundy = Color(0xFF6B1E2E);
//   static const Color ivory = Color(0xFFFCF8F5);
//   static const Color muted = Color(0xFF927F7D);
//   static const Color border = Color(0xFFECE3DF);
//
//   @override
//   void initState() {
//     super.initState();
//     logic = MyRentalsLogic();
//     logic.loadRentals();
//   }
//
//   @override
//   void dispose() {
//     logic.dispose();
//     super.dispose();
//   }
//
//   Color statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return const Color(0xFFC17A16);
//       case 'accepted':
//         return const Color(0xFF167447);
//       case 'active':
//         return const Color(0xFF176B9B);
//       case 'rejected':
//         return const Color(0xFFB3262D);
//       case 'completed':
//         return const Color(0xFF285D9B);
//       case 'cancelled':
//         return const Color(0xFF777777);
//       default:
//         return muted;
//     }
//   }
//
//   Color statusBackground(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return const Color(0xFFFFF4E2);
//       case 'accepted':
//         return const Color(0xFFEAF5EE);
//       case 'active':
//         return const Color(0xFFE7F2FA);
//       case 'rejected':
//         return const Color(0xFFFCEBEC);
//       case 'completed':
//         return const Color(0xFFEAF1FA);
//       case 'cancelled':
//         return const Color(0xFFF1EFED);
//       default:
//         return const Color(0xFFF1EFED);
//     }
//   }
//
//   void showSearchBox() {
//     showSearch(
//       context: context,
//       delegate: _RentalSearchDelegate(
//         onSearch: logic.setSearch,
//       ),
//     );
//   }
//
//   void showDetails(Map<String, dynamic> rental) {
//     final status = logic.statusOf(rental);
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(22),
//         ),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 42,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: border,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//
//                   const Text(
//                     'Rental Details',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: burgundy,
//                     ),
//                   ),
//
//                   const SizedBox(height: 15),
//
//                   _detailLine(
//                     'Outfit',
//                     logic.outfitName(rental),
//                   ),
//                   _detailLine(
//                     'Booking reference',
//                     logic.bookingLabel(rental['booking_reference']),
//                   ),
//                   _detailLine(
//                     'Status',
//                     logic.titleCase(status),
//                   ),
//                   _detailLine(
//                     'Selected size',
//                     rental['selected_size']?.toString() ?? '—',
//                   ),
//                   _detailLine(
//                     'Rental start',
//                     logic.dateLabel(rental['rental_start_date']),
//                   ),
//                   _detailLine(
//                     'Rental return',
//                     logic.dateLabel(rental['rental_return_date']),
//                   ),
//                   _detailLine(
//                     'Rental duration',
//                     '${rental['rental_days'] ?? 0} days',
//                   ),
//
//                   const Divider(height: 25),
//
//                   const Text(
//                     'Payment Breakdown',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: burgundy,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   _detailLine(
//                     'Rental price per day',
//                     logic.money(rental['rental_price_per_day']),
//                   ),
//                   _detailLine(
//                     'Rental amount',
//                     logic.money(rental['rental_amount']),
//                   ),
//                   _detailLine(
//                     'Security deposit',
//                     logic.money(rental['security_deposit_amount']),
//                   ),
//                   _detailLine(
//                     'Platform fee',
//                     logic.money(rental['platform_fee']),
//                   ),
//                   _detailLine(
//                     'Total paid',
//                     logic.money(rental['total_amount']),
//                   ),
//                   _detailLine(
//                     'Payment status',
//                     logic.titleCase(
//                       rental['payment_status']?.toString() ?? 'unknown',
//                     ),
//                   ),
//
//                   if (rental['refund_amount'] != null)
//                     _detailLine(
//                       'Refund amount',
//                       logic.money(rental['refund_amount']),
//                     ),
//
//                   if ((rental['rejection_reason'] ?? '')
//                       .toString().trim().isNotEmpty)
//                     _detailLine(
//                       'Rejection reason',
//                       rental['rejection_reason'].toString(),
//                     ),
//
//                   if ((rental['cancellation_reason'] ?? '')
//                       .toString().trim().isNotEmpty)
//                     _detailLine(
//                       'Cancellation reason',
//                       rental['cancellation_reason'].toString(),
//                     ),
//
//                   const Divider(height: 25),
//
//                   const Text(
//                     'Delivery Address',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: burgundy,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   Text(
//                     logic.addressLabel(rental).isEmpty
//                         ? 'Address unavailable'
//                         : logic.addressLabel(rental),
//                     style: const TextStyle(
//                       fontSize: 12,
//                       height: 1.5,
//                       color: muted,
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: burgundy,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 13),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text('Close'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _detailLine(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 125,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 color: muted,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF321D25),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: logic,
//       builder: (context, _) {
//         return Scaffold(
//           backgroundColor: ivory,
//           appBar: AppBar(
//             backgroundColor: ivory,
//             elevation: 0,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: burgundy),
//               onPressed: () => Navigator.pop(context),
//             ),
//             titleSpacing: 0,
//             title: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'ATTIRELY',
//                   style: TextStyle(
//                     fontSize: 9,
//                     letterSpacing: 2,
//                     color: burgundy,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'My Rentals',
//                   style: TextStyle(
//                     fontSize: 17,
//                     color: Color(0xFF321D25),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               IconButton(
//                 onPressed: showSearchBox,
//                 icon: const Icon(Icons.search, color: burgundy),
//               ),
//               IconButton(
//                 onPressed: logic.loadRentals,
//                 icon: const Icon(Icons.refresh, color: burgundy),
//               ),
//             ],
//           ),
//
//           body: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//                 child: Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         'Track your rental requests, upcoming rentals and rental history.',
//                         style: TextStyle(
//                           fontSize: 11,
//                           height: 1.5,
//                           color: muted,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 9,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF4E9E9),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: border),
//                       ),
//                       child: const Text(
//                         'MY WARDROBE',
//                         style: TextStyle(
//                           fontSize: 8,
//                           letterSpacing: 0.5,
//                           color: burgundy,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(
//                 height: 42,
//                 child: ListView.separated(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   scrollDirection: Axis.horizontal,
//                   itemCount: logic.filters.length,
//                   separatorBuilder: (_, __) =>
//                   const SizedBox(width: 7),
//                   itemBuilder: (context, index) {
//                     final filter = logic.filters[index];
//                     final selected = logic.selectedFilter == filter;
//
//                     return InkWell(
//                       borderRadius: BorderRadius.circular(20),
//                       onTap: () => logic.setFilter(filter),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 13,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: selected ? burgundy : Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: selected ? burgundy : border,
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               filter,
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: selected ? Colors.white : burgundy,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               '${logic.countFor(filter)}',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 color: selected
//                                     ? Colors.white
//                                     : statusColor(filter),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 7),
//
//               Expanded(child: _buildBody()),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildBody() {
//     if (logic.isLoading && logic.rentals.isEmpty) {
//       return const Center(
//         child: CircularProgressIndicator(color: burgundy),
//       );
//     }
//
//     if (logic.errorMessage != null && logic.rentals.isEmpty) {
//       return _emptyState(
//         icon: Icons.wifi_off_outlined,
//         title: 'Unable to load your rentals',
//         subtitle: logic.errorMessage!,
//         buttonText: 'Try Again',
//         onPressed: logic.loadRentals,
//       );
//     }
//
//     if (logic.groupedRentals.isEmpty) {
//       return RefreshIndicator(
//         color: burgundy,
//         onRefresh: logic.loadRentals,
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           children: const [
//             SizedBox(height: 110),
//             Icon(
//               Icons.shopping_bag_outlined,
//               size: 48,
//               color: Color(0xFFC9AEB2),
//             ),
//             SizedBox(height: 14),
//             Center(
//               child: Text(
//                 'No rentals found',
//                 style: TextStyle(
//                   color: burgundy,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             SizedBox(height: 6),
//             Center(
//               child: Text(
//                 'Your rental bookings will appear here.',
//                 style: TextStyle(color: muted, fontSize: 11),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       color: burgundy,
//       onRefresh: logic.loadRentals,
//       child: ListView.builder(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
//         physics: const AlwaysScrollableScrollPhysics(),
//         itemCount: logic.groupedRentals.length,
//         itemBuilder: (context, index) {
//           return _bookingGroup(logic.groupedRentals[index]);
//         },
//       ),
//     );
//   }
//
//   Widget _bookingGroup(Map<String, dynamic> group) {
//     final outfits = group['outfits'] as List<Map<String, dynamic>>;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'RENTAL BOOKING #${logic.bookingLabel(group['booking_reference'])}',
//                   style: const TextStyle(
//                     color: burgundy,
//                     fontSize: 9,
//                     letterSpacing: 0.6,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 9,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF1ECE9),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Text(
//                   '${group['total_outfits']} Outfits',
//                   style: const TextStyle(fontSize: 9, color: muted),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Booked on: ${logic.dateLabel(group['booked_on'])}',
//             style: const TextStyle(fontSize: 9, color: muted),
//           ),
//           const Divider(height: 17, color: border),
//           ...outfits.map(_outfitCard),
//         ],
//       ),
//     );
//   }
//
//   Widget _outfitCard(Map<String, dynamic> rental) {
//     final status = logic.statusOf(rental);
//     final imageUrl = logic.imageOf(rental);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(11),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: border),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x08000000),
//             blurRadius: 8,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(11),
//                 child: imageUrl.isNotEmpty
//                     ? Image.network(
//                   imageUrl,
//                   width: 91,
//                   height: 112,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => _imagePlaceholder(),
//                 )
//                     : _imagePlaceholder(),
//               ),
//               const SizedBox(width: 11),
//
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             logic.outfitName(rental),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF321D25),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 5),
//                         _statusBadge(status),
//                       ],
//                     ),
//
//                     const SizedBox(height: 7),
//
//                     Text(
//                       'Size: ${rental['selected_size'] ?? '—'}',
//                       style: const TextStyle(
//                         fontSize: 10,
//                         color: muted,
//                       ),
//                     ),
//
//                     const SizedBox(height: 5),
//
//                     Text(
//                       '${rental['rental_days'] ?? 0} days rental',
//                       style: const TextStyle(
//                         fontSize: 10,
//                         color: muted,
//                       ),
//                     ),
//
//                     const SizedBox(height: 7),
//
//                     Text(
//                       logic.money(rental['rental_amount']),
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                         color: burgundy,
//                       ),
//                     ),
//
//                     const SizedBox(height: 2),
//
//                     const Text(
//                       'Rental amount',
//                       style: TextStyle(
//                         fontSize: 9,
//                         color: muted,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           const Divider(height: 20, color: border),
//
//           Row(
//             children: [
//               const Icon(
//                 Icons.calendar_month_outlined,
//                 size: 15,
//                 color: burgundy,
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   '${logic.dateLabel(rental['rental_start_date'])} – ${logic.dateLabel(rental['rental_return_date'])}',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: muted,
//                   ),
//                 ),
//               ),
//               Text(
//                 'Total ${logic.money(rental['total_amount'])}',
//                 style: const TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                   color: burgundy,
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 10),
//
//           SizedBox(
//             width: double.infinity,
//             height: 36,
//             child: OutlinedButton(
//               onPressed: () => showDetails(rental),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: burgundy,
//                 side: const BorderSide(color: burgundy),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//               ),
//               child: const Text(
//                 'View Rental Details',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _statusBadge(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 5,
//       ),
//       decoration: BoxDecoration(
//         color: statusBackground(status),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         logic.titleCase(status),
//         style: TextStyle(
//           fontSize: 8,
//           fontWeight: FontWeight.bold,
//           color: statusColor(status),
//         ),
//       ),
//     );
//   }
//
//   Widget _imagePlaceholder() {
//     return Container(
//       width: 91,
//       height: 112,
//       color: const Color(0xFFF5EEEE),
//       child: const Icon(
//         Icons.checkroom_outlined,
//         color: burgundy,
//         size: 30,
//       ),
//     );
//   }
//
//   Widget _emptyState({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String buttonText,
//     required VoidCallback onPressed,
//   }) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 45, color: const Color(0xFFC9AEB2)),
//             const SizedBox(height: 14),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: burgundy,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 7),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: muted,
//                 fontSize: 11,
//               ),
//             ),
//             const SizedBox(height: 18),
//             ElevatedButton(
//               onPressed: onPressed,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: burgundy,
//                 foregroundColor: Colors.white,
//               ),
//               child: Text(buttonText),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _RentalSearchDelegate extends SearchDelegate {
//   final ValueChanged<String> onSearch;
//
//   _RentalSearchDelegate({required this.onSearch});
//
//   @override
//   String get searchFieldLabel => 'Search rentals or booking reference';
//
//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       IconButton(
//         onPressed: () {
//           query = '';
//           onSearch('');
//         },
//         icon: const Icon(Icons.clear),
//       ),
//     ];
//   }
//
//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       onPressed: () => close(context, null),
//       icon: const Icon(Icons.arrow_back),
//     );
//   }
//
//   @override
//   Widget buildResults(BuildContext context) {
//     onSearch(query);
//     close(context, null);
//     return const SizedBox.shrink();
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) {
//     onSearch(query);
//     return const Center(
//       child: Text('Search by outfit name or booking reference'),
//     );
//   }
// }
