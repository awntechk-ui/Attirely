
import 'package:flutter/material.dart';

import '../../Common_Screens/session_manager.dart';
import '../Vendor_API_Routes/trial_requests_api_routes.dart';
import '../Vendor_API_Routes/vendor_accessories_api_routes.dart';
import '../Vendor_API_Routes/vendor_outfits_api_routes.dart';


class VendorAnalytics extends StatefulWidget {
  const VendorAnalytics({super.key});

  @override
  State<VendorAnalytics> createState() => _VendorAnalyticsState();
}

class _VendorAnalyticsState extends State<VendorAnalytics> {
  static const Color burgundy = Color(0xFF8E2945);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);

  static const LinearGradient topGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C1026),
      Color(0xFF64172F),
      Color(0xFF4C1026),
    ],
  );

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _outfits = [];
  List<Map<String, dynamic>> _accessories = [];
  List<Map<String, dynamic>> _requests = [];

  int get _totalListings => _outfits.length + _accessories.length;

  int get _publishedOutfits => _outfits.where((item) {
    return (item['status'] ?? '').toString().toLowerCase() ==
        'published';
  }).length;

  int get _publishedAccessories => _accessories.where((item) {
    return (item['status'] ?? '').toString().toLowerCase() ==
        'published';
  }).length;

  int get _availableOutfits => _outfits.where(_isAvailable).length;

  int get _availableAccessories =>
      _accessories.where(_isAvailable).length;

  bool _isAvailable(Map<String, dynamic> item) {
    final value = item['is_available'];

    if (value is bool) return value;
    if (value is num) return value > 0;

    return value.toString().toLowerCase() == 'true';
  }

  int get _pendingRequests => _requests.where((request) {
    return _requestStatus(request) == 'pending';
  }).length;

  int get _acceptedRequests => _requests.where((request) {
    return _requestStatus(request) == 'accepted';
  }).length;

  int get _rejectedRequests => _requests.where((request) {
    return _requestStatus(request) == 'rejected';
  }).length;

  String _requestStatus(Map<String, dynamic> request) {
    return (request['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = SessionManager.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final results = await Future.wait([
        VendorOutfitApiRoutes.getMyOutfits(accessToken: token),
        VendorAccessoryApiRoutes.getMyAccessories(accessToken: token),
        TrialRequestsApiRoutes.getRequests(accessToken: token),
      ]);

      if (!mounted) return;

      setState(() {
        _outfits = List<Map<String, dynamic>>.from(results[0]);
        _accessories = List<Map<String, dynamic>>.from(results[1]);
        _requests = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _mostRequestedOutfits {
    final Map<String, int> counts = {};

    for (final request in _requests) {
      final outfitId = request['outfit_id']?.toString();

      if (outfitId == null || outfitId.isEmpty) continue;

      counts[outfitId] = (counts[outfitId] ?? 0) + 1;
    }

    final outfitMap = <String, Map<String, dynamic>>{};

    for (final outfit in _outfits) {
      final id = outfit['id']?.toString();
      if (id != null) outfitMap[id] = outfit;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).map((entry) {
      final outfit = outfitMap[entry.key];

      return {
        'name': outfit?['name'] ?? 'Outfit',
        'count': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: burgundy),
        )
            : _error != null
            ? _buildError()
            : RefreshIndicator(
          color: burgundy,
          onRefresh: _loadAnalytics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 22),
                _buildOverview(),
                _buildListingSection(),
                _buildTryOnSection(),
                _buildMostRequestedSection(),
                _buildFutureAnalytics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      decoration: const BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: gold,
                size: 27,
              ),
              const SizedBox(width: 10),
              const Text(
                'Vendor Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Understand your store performance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your listings and customer activity at a glance.',
            style: TextStyle(
              color: gold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('STORE OVERVIEW'),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Listings',
                  value: _totalListings.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: 'Try-On Requests',
                  value: _requests.length.toString(),
                  icon: Icons.assignment_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('LISTING PERFORMANCE'),
          const SizedBox(height: 13),
          _whiteCard(
            child: Column(
              children: [
                _listingRow(
                  icon: Icons.checkroom_outlined,
                  title: 'Outfits',
                  total: _outfits.length,
                  published: _publishedOutfits,
                  available: _availableOutfits,
                ),
                const Divider(height: 28),
                _listingRow(
                  icon: Icons.watch_outlined,
                  title: 'Accessories',
                  total: _accessories.length,
                  published: _publishedAccessories,
                  available: _availableAccessories,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listing distribution',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: darkBurgundy,
                  ),
                ),
                const SizedBox(height: 18),
                _distributionBar(
                  label: 'Outfits',
                  count: _outfits.length,
                  total: _totalListings,
                  color: burgundy,
                ),
                const SizedBox(height: 16),
                _distributionBar(
                  label: 'Accessories',
                  count: _accessories.length,
                  total: _totalListings,
                  color: const Color(0xFFC9A66B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTryOnSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TRY-ON ACTIVITY'),
          const SizedBox(height: 5),
          const Text(
            'Customer try-on requests only. These are not rental bookings.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _smallStatCard(
                  'Total',
                  _requests.length,
                  Icons.inbox_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _smallStatCard(
                  'Pending',
                  _pendingRequests,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _smallStatCard(
                  'Accepted',
                  _acceptedRequests,
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _whiteCard(
            child: Column(
              children: [
                _statusRow(
                  'Pending requests',
                  _pendingRequests,
                  burgundy,
                ),
                const SizedBox(height: 13),
                _statusRow(
                  'Accepted requests',
                  _acceptedRequests,
                  const Color(0xFF56866A),
                ),
                const SizedBox(height: 13),
                _statusRow(
                  'Rejected requests',
                  _rejectedRequests,
                  const Color(0xFFB66B65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostRequestedSection() {
    final items = _mostRequestedOutfits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MOST REQUESTED OUTFITS'),
          const SizedBox(height: 5),
          const Text(
            'Based on try-on requests received.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 13),
          _whiteCard(
            child: items.isEmpty
                ? _emptyMessage(
              'No outfit requests yet',
              'Outfits with try-on requests will appear here.',
            )
                : Column(
              children: List.generate(items.length, (index) {
                final item = items[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: darkBurgundy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['name'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkBurgundy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${item['count']} requests',
                        style: const TextStyle(
                          color: burgundy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureAnalytics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('RENTAL PERFORMANCE'),
          const SizedBox(height: 13),
          _whiteCard(
            child: Column(
              children: [
                _futureItem(
                  Icons.event_available_outlined,
                  'Confirmed Bookings',
                ),
                _futureItem(
                  Icons.done_all,
                  'Completed Rentals',
                ),
                _futureItem(
                  Icons.account_balance_wallet_outlined,
                  'Total Earnings',
                ),
                _futureItem(
                  Icons.calendar_month_outlined,
                  'Monthly Earnings',
                ),
                _futureItem(
                  Icons.trending_up,
                  'Rental Performance Charts',
                ),
                const SizedBox(height: 8),
                const Text(
                  'These insights will be available after booking and payment integration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkBurgundy,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: darkBurgundy.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold, size: 23),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatCard(
      String title,
      int value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.65)),
      ),
      child: Column(
        children: [
          Icon(icon, color: burgundy, size: 21),
          const SizedBox(height: 9),
          Text(
            value.toString(),
            style: const TextStyle(
              color: darkBurgundy,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: gold.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: darkBurgundy.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _listingRow({
    required IconData icon,
    required String title,
    required int total,
    required int published,
    required int available,
  }) {
    return Row(
      children: [
        Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: burgundy),
        ),
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$published published  •  $available available',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          total.toString(),
          style: const TextStyle(
            color: burgundy,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _distributionBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: darkBurgundy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: darkBurgundy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: gold.withOpacity(0.35),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: darkBurgundy,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _futureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Icon(icon, color: burgundy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkBurgundy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            'Coming soon',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMessage(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(
            Icons.insert_chart_outlined,
            color: burgundy,
            size: 30,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              color: darkBurgundy,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: burgundy,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load analytics',
              style: TextStyle(
                color: darkBurgundy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadAnalytics,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
