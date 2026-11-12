
import 'package:flutter/material.dart';

import '../U_Ui_Logic/my_trials_logic.dart';


class MyTrialsPage extends StatefulWidget {
  const MyTrialsPage({super.key});

  @override
  State<MyTrialsPage> createState() => _MyTrialsPageState();
}

class _MyTrialsPageState extends State<MyTrialsPage> {
  late final MyTrialsLogic logic;

  static const Color burgundy = Color(0xFF6B1E2E);
  static const Color ivory = Color(0xFFFCF8F5);
  static const Color muted = Color(0xFF927F7D);
  static const Color border = Color(0xFFECE3DF);
  static const Color green = Color(0xFF176B43);

  @override
  void initState() {
    super.initState();
    logic = MyTrialsLogic();
    logic.loadTrials();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF167447);
      case 'pending':
        return const Color(0xFFC17A16);
      case 'rejected':
        return const Color(0xFFB3262D);
      case 'completed':
        return const Color(0xFF285D9B);
      default:
        return muted;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFFEAF5EE);
      case 'pending':
        return const Color(0xFFFFF4E2);
      case 'rejected':
        return const Color(0xFFFCEBEC);
      case 'completed':
        return const Color(0xFFEAF1FA);
      default:
        return const Color(0xFFF1EFED);
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  String _bookingLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'TR-UNKNOWN';

    // Display a short readable reference without changing the DB value.
    final compact = text.replaceAll('-', '').toUpperCase();
    return 'TR-${compact.length > 8 ? compact.substring(0, 8) : compact}';
  }

  void _showDetails(Map<String, dynamic> trial) {
    final outfit = logic.outfitOf(trial);
    final vendor = logic.vendorOf(trial);
    final status = (trial['status'] ?? 'pending').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                    'Trial Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    outfit['name']?.toString() ??
                        trial['outfit_name']?.toString() ??
                        'Outfit',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailLine('Brand',
                      outfit['brand']?.toString() ?? '—'),
                  _detailLine('Vendor',
                      vendor['store_name']?.toString() ?? '—'),
                  _detailLine('Status', _titleCase(status)),
                  _detailLine('Size',
                      trial['selected_size']?.toString() ?? '—'),
                  _detailLine('Trial date',
                      logic.dateLabel(trial['preferred_trial_date'])),
                  _detailLine('Time slot',
                      trial['preferred_time_slot']?.toString() ?? '—'),
                  _detailLine('Trial method',
                      trial['trial_method']?.toString() ?? 'Not confirmed'),
                  _detailLine('Address', logic.addressOf(trial)),
                  _detailLine('Trial charge',
                      logic.money(trial['trial_fee'])),
                  _detailLine('Platform fee',
                      logic.money(trial['platform_fee'])),
                  _detailLine('Total paid',
                      logic.money(trial['trial_amount'])),
                  if ((trial['rejection_reason'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty)
                    _detailLine(
                      'Reason',
                      trial['rejection_reason'].toString(),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: burgundy,
                        foregroundColor: Colors.white,
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
            width: 112,
            child: Text(label,
                style: const TextStyle(color: muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
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
                  'My Trails',
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
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: _TrailSearchDelegate(
                      onSearch: logic.setSearch,
                    ),
                  );
                },
                icon: const Icon(Icons.search, color: burgundy),
              ),
              IconButton(
                onPressed: () => _showFilterInfo(),
                icon: const Icon(Icons.tune, color: burgundy),
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
                        'Track and manage your scheduled doorstep outfit trials.',
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
                        'ACTIVE SALON',
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
                          horizontal: 14,
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
                                    : _statusColor(filter),
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
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (logic.isLoading && logic.trials.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: burgundy),
      );
    }

    if (logic.errorMessage != null && logic.trials.isEmpty) {
      return _emptyState(
        icon: Icons.wifi_off_outlined,
        title: 'Unable to load your trails',
        subtitle: logic.errorMessage!,
        buttonText: 'Try Again',
        onPressed: logic.loadTrials,
      );
    }

    if (logic.groupedTrials.isEmpty) {
      return RefreshIndicator(
        color: burgundy,
        onRefresh: logic.loadTrials,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(Icons.event_note_outlined,
                size: 48, color: Color(0xFFC9AEB2)),
            SizedBox(height: 14),
            Center(
              child: Text(
                'No trails found',
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
                'Your outfit trial bookings will appear here.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: burgundy,
      onRefresh: logic.loadTrials,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: logic.groupedTrials.length + 1,
        itemBuilder: (context, index) {
          if (index == logic.groupedTrials.length) {
            return _guaranteeCard();
          }

          return _bookingGroup(logic.groupedTrials[index]);
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
                  'TRAIL BOOKING #${_bookingLabel(group['booking_reference'])}',
                  style: const TextStyle(
                    color: burgundy,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
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

  Widget _outfitCard(Map<String, dynamic> trial) {
    final outfit = logic.outfitOf(trial);
    final vendor = logic.vendorOf(trial);

    final status = (trial['status'] ?? 'pending')
        .toString()
        .toLowerCase();

    final statusColor = _statusColor(status);
    final statusBg = _statusBackground(status);

    final name = outfit['name']?.toString() ??
        trial['outfit_name']?.toString() ??
        'Outfit';

    final brand = outfit['brand']?.toString() ??
        vendor['store_name']?.toString() ??
        'Attirely';

    final image = logic.imageOf(trial);
    final price = logic.money(outfit['rental_price']);
    final mrp = outfit['mrp'] == null
        ? ''
        : logic.money(outfit['mrp']);

    final fee = logic.money(trial['trial_fee']);
    final platform = logic.money(trial['platform_fee']);
    final total = logic.money(trial['trial_amount']);

    final refund = trial['refund_amount'] ??
        (status == 'pending' || status == 'accepted' ? 150 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(.25)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: .4,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                status == 'accepted'
                    ? Icons.check_circle_outline
                    : status == 'pending'
                    ? Icons.hourglass_empty
                    : status == 'rejected'
                    ? Icons.info_outline
                    : Icons.done_all,
                size: 11,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status == 'accepted'
                      ? 'Trial confirmed'
                      : status == 'pending'
                      ? 'Waiting atelier confirmation'
                      : status == 'rejected'
                      ? 'Vendor unavailable'
                      : 'Trial completed',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: statusColor),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF3ECE9)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      width: 72,
                      height: 108,
                      child: image.isEmpty
                          ? Container(
                        color: const Color(0xFFF5ECEA),
                        child: const Icon(
                          Icons.checkroom,
                          color: burgundy,
                        ),
                      )
                          : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5ECEA),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: burgundy,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      color: Colors.white.withOpacity(.92),
                      child: Text(
                        'Size ${trial['selected_size'] ?? '—'}',
                        style: const TextStyle(fontSize: 7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 7,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        height: 1.2,
                        color: Color(0xFF241B1B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          '$price / day',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mrp.isNotEmpty)
                          Text(
                            'MRP $mrp',
                            style: const TextStyle(
                              fontSize: 9,
                              color: muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _smallInfo(
                      Icons.calendar_month_outlined,
                      '${logic.dateLabel(trial['preferred_trial_date'])}  •  '
                          '${trial['preferred_time_slot'] ?? 'Time not set'}',
                    ),
                    const SizedBox(height: 5),
                    _smallInfo(
                      Icons.location_on_outlined,
                      logic.addressOf(trial).isEmpty
                          ? 'Address not available'
                          : logic.addressOf(trial),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (status == 'rejected')
            _rejectionBox(trial)
          else if (status == 'completed')
            _completedBox(trial),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7F4),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Wrap(
              spacing: 7,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Trail: $fee',
                    style: const TextStyle(fontSize: 9, color: muted)),
                const Text('|', style: TextStyle(color: muted)),
                Text('Platform: $platform',
                    style: const TextStyle(fontSize: 9, color: muted)),
                const Text('|', style: TextStyle(color: muted)),
                Text('Paid: $total',
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold)),
                if (status == 'rejected' ||
                    status == 'pending' ||
                    status == 'accepted')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${logic.money(refund)} Refundable',
                      style: const TextStyle(
                        color: green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showDetails(trial),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: Color(0xFFD8BFC3)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View Details  →',
                style: TextStyle(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 11, color: burgundy),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _rejectionBox(Map<String, dynamic> trial) {
    final reason =
        trial['rejection_reason']?.toString().trim() ?? '';

    final refundStatus =
        trial['refund_status']?.toString() ?? 'pending';

    final refundAmount = trial['refund_amount'] ?? 150;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        border: Border.all(color: const Color(0xFFF1D8D4)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason: ${reason.isEmpty ? 'Vendor rejected this request.' : reason}',
            style: const TextStyle(fontSize: 9, height: 1.4),
          ),
          const SizedBox(height: 7),
          Text(
            'Refund ${_titleCase(refundStatus)}: ${logic.money(refundAmount)}',
            style: const TextStyle(
              color: green,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'The platform fee is non-refundable. Refund processing depends on the payment provider.',
            style: TextStyle(fontSize: 8, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _completedBox(Map<String, dynamic> trial) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'Trial completed ${trial['trial_completed_at'] == null ? '' : 'on ${logic.dateLabel(trial['trial_completed_at'])}'}',
        style: const TextStyle(fontSize: 9, color: muted),
      ),
    );
  }

  Widget _guaranteeCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 15),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 16, color: burgundy),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Attirely Guarantee: The ₹150 refundable amount is subject to our trial cancellation and rejection policy. The ₹50 platform fee is non-refundable once scheduled.',
              style: TextStyle(
                fontSize: 9,
                height: 1.5,
                color: muted,
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: burgundy),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: burgundy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 15),
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

  void _showFilterInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter trails',
                style: TextStyle(
                  color: burgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),
              ...logic.filters.map(
                    (filter) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(filter),
                  trailing: logic.selectedFilter == filter
                      ? const Icon(Icons.check, color: burgundy)
                      : null,
                  onTap: () {
                    logic.setFilter(filter);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailSearchDelegate extends SearchDelegate<String> {
  final ValueChanged<String> onSearch;

  _TrailSearchDelegate({required this.onSearch});

  @override
  String get searchFieldLabel => 'Search outfits or booking reference';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      onPressed: () {
        query = '';
        onSearch('');
      },
      icon: const Icon(Icons.clear),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ''),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    onSearch(query);
    return const Center(
      child: Text(
        'Search by outfit name, brand, or booking reference.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
