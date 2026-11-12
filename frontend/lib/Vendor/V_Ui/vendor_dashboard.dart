
import 'package:flutter/material.dart';

import '../../Common_Screens/services/device_location_service.dart';
import '../../app_routes.dart';
import '../V_Ui_Logic/dashboard_logic.dart';
import '../widgets/vendor_dashboard_stats.dart';
import 'vendor_outfit.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  late final DashboardLogic logic;
  String _currentLocation = 'Getting current location...';

  Future<void> _loadCurrentLocation() async {
    final location =
    await DeviceLocationService.getCurrentLocationLabel();

    if (!mounted) return;

    setState(() {
      _currentLocation = location;
    });
  }

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

  @override
  void initState() {
    super.initState();
    logic = DashboardLogic();
    logic.loadDashboard();
    _loadCurrentLocation();


  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Uncomment if you want to display date/time later.
    // final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: cream.withOpacity(0.16),
            ),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: logic,
              builder: (context, _) {
                return RefreshIndicator(
                  color: burgundy,
                  onRefresh: logic.loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      9,
                      16,
                      125,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),

                        const SizedBox(height: 13),

                        _heading(
                          'Store Overview',
                          'Your listings at a glance',
                        ),

                        const SizedBox(height: 7),

                        VendorDashboardStats(
                          activeOutfits: logic.activeOutfits,
                          totalOutfits: logic.totalOutfits,
                          activeAccessories: logic.activeAccessories,
                          totalAccessories: logic.totalAccessories,
                          totalListings: logic.totalListings,
                        ),

                        const SizedBox(height: 14),

                        _subscriptionCard(),

                        const SizedBox(height: 15),

                        _quickActions(),

                        const SizedBox(height: 15),

                        _performanceSummary(),

                        const SizedBox(height: 15),

                        _recentActivity(),

                        const SizedBox(height: 15),

                        _thankYou(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attirely',
                style: TextStyle(
                  color: darkBurgundy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                ),
              ),
            ),

            _headerButton(
              Icons.notifications_none_rounded,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications coming soon.'),
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            _headerButton(
              Icons.person_outline_rounded,
                  () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.vendorProfile,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            Flexible(
              flex: 1,
              child: Text(
                '${_greeting()},',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: darkBurgundy.withOpacity(0.78),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Flexible(
              flex: 3,
              child: Text(
                logic.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkBurgundy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(width: 4),

            const Text(
              '👋',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: burgundy,
              size: 15,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                _currentLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: darkBurgundy.withOpacity(0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh location',
              onPressed: _loadCurrentLocation,
              icon: const Icon(
                Icons.refresh_rounded,
                color: burgundy,
                size: 17,
              ),
              constraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),

        // Date/time intentionally omitted.
        // Uncomment if needed:
        // Text(_formatDate(DateTime.now())),
      ],
    );
  }

  Widget _headerButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold),
        ),
        child: Icon(
          icon,
          color: darkBurgundy,
          size: 19,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION HEADING
  // --------------------------------------------------

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkBurgundy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,
          style: TextStyle(
            color: darkBurgundy.withOpacity(0.65),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SUBSCRIPTION
  // --------------------------------------------------

  Widget _subscriptionCard() {
    if (!logic.hasActiveSubscription ||
        logic.subscription == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: _lightCard(),
        child: const Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: burgundy,
              size: 24,
            ),

            SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active subscription',
                    style: TextStyle(
                      color: darkBurgundy,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    'Choose a vendor plan to manage your listing capacity.',
                    style: TextStyle(
                      color: burgundy,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: gold.withOpacity(0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: darkBurgundy.withOpacity(0.15),
            blurRadius: 11,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: gold,
                size: 21,
              ),

              const SizedBox(width: 7),

              const Expanded(
                child: Text(
                  'YOUR SUBSCRIPTION',
                  style: TextStyle(
                    color: cream,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),

              Text(
                logic.subscriptionStatus.isEmpty
                    ? 'ACTIVE'
                    : logic.subscriptionStatus.toUpperCase(),
                style: const TextStyle(
                  color: gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            logic.planName,
            style: const TextStyle(
              color: cream,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '₹${logic.subscriptionPrice}'
                '${logic.billingInterval.isNotEmpty ? ' / ${logic.billingInterval}' : ''}',
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _usageBar(
            'Outfit listings',
            logic.totalOutfits,
            logic.outfitLimit,
            logic.outfitsUnlimited,
            logic.outfitUsage,
          ),

          const SizedBox(height: 10),

          _usageBar(
            'Accessory listings',
            logic.totalAccessories,
            logic.accessoryLimit,
            logic.accessoriesUnlimited,
            logic.accessoryUsage,
          ),

          const SizedBox(height: 11),

          Divider(
            color: cream.withOpacity(0.22),
            height: 1,
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _remaining(
                  'Outfit slots left',
                  logic.outfitsUnlimited
                      ? 'Unlimited'
                      : '${logic.remainingOutfitSlots}',
                ),
              ),

              Expanded(
                child: _remaining(
                  'Accessory slots left',
                  logic.accessoriesUnlimited
                      ? 'Unlimited'
                      : '${logic.remainingAccessorySlots}',
                ),
              ),
            ],
          ),

          if (logic.subscriptionEndDate.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              'Valid until: ${_formatDateValue(logic.subscriptionEndDate)}',
              style: const TextStyle(
                color: cream,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _usageBar(
      String title,
      int used,
      int limit,
      bool unlimited,
      double progress,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: cream,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              unlimited ? '$used / Unlimited' : '$used / $limit',
              style: const TextStyle(
                color: gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: unlimited ? 0 : progress,
            minHeight: 6,
            backgroundColor: cream.withOpacity(0.18),
            valueColor:
            const AlwaysStoppedAnimation<Color>(gold),
          ),
        ),
      ],
    );
  }

  Widget _remaining(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: cream,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(
            color: cream,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // QUICK ACTIONS
  // --------------------------------------------------

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Quick Actions',
          'Manage your rental business',
        ),

        const SizedBox(height: 7),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionButton(
              title: 'Add New Outfit',
              icon: Icons.add_rounded,
              filled: true,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorOutfit(),
                  ),
                );

                if (result == true) {
                  await logic.loadDashboard();
                }
              },
            ),

            _ActionButton(
              title: 'View Requests',
              icon: Icons.receipt_long_outlined,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.vendorRequests,
                );
              },
            ),

            _ActionButton(
              title: 'View Bookings',
              icon: Icons.calendar_month_outlined,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.vendorBookings,
                );
              },
            ),

            _ActionButton(
              title: 'Check Analytics',
              icon: Icons.insights_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Analytics will be available soon.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // PERFORMANCE SUMMARY
  // --------------------------------------------------

  Widget _performanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Performance Summary',
          'A quick look at your store',
        ),

        const SizedBox(height: 7),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: _lightCard(),
          child: Column(
            children: [
              _performanceRow(
                Icons.checkroom_outlined,
                'Active outfits',
                '${logic.activeOutfits}',
              ),

              const Divider(
                height: 15,
                color: gold,
              ),

              _performanceRow(
                Icons.shopping_bag_outlined,
                'Active accessories',
                '${logic.activeAccessories}',
              ),

              const Divider(
                height: 15,
                color: gold,
              ),

              _performanceRow(
                Icons.inventory_2_outlined,
                'Total store listings',
                '${logic.totalListings}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _performanceRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: burgundy,
          size: 17,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: darkBurgundy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            color: burgundy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // RECENT ACTIVITY
  // --------------------------------------------------

  Widget _recentActivity() {
    final activities = [
      (
      'Store dashboard refreshed',
      'Your latest listing and plan information',
      Icons.refresh_rounded,
      ),
      (
      'Manage your listings',
      'Keep your outfit and accessory catalogue updated',
      Icons.inventory_2_outlined,
      ),
      (
      'Subscription overview',
      'Check your plan usage and remaining slots',
      Icons.workspace_premium_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Recent Activity',
          'Stay on top of your store',
        ),

        const SizedBox(height: 7),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 3,
          ),
          decoration: _lightCard(),
          child: Column(
            children: List.generate(
              activities.length,
                  (index) {
                final item = activities[index];

                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      minVerticalPadding: 4,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.48),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          item.$3,
                          color: burgundy,
                          size: 17,
                        ),
                      ),
                      title: Text(
                        item.$1,
                        style: const TextStyle(
                          color: darkBurgundy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        item.$2,
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 9,
                        ),
                      ),
                    ),

                    if (index != activities.length - 1)
                      Divider(
                        height: 1,
                        color: gold.withOpacity(0.8),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // THANK YOU MESSAGE
  // --------------------------------------------------

  Widget _thankYou() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cream.withOpacity(0.94),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: gold,
          width: 1.4,
        ),
      ),
      child: const Column(
        children: [
          Text(
            'Thank you for choosing Attirely',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkBurgundy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 3),

          Text(
            'We are happy to be part of your fashion journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: burgundy,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // COMMON DECORATION
  // --------------------------------------------------

  BoxDecoration _lightCard() {
    return BoxDecoration(
      color: cream.withOpacity(0.95),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: gold.withOpacity(0.9),
      ),
      boxShadow: [
        BoxShadow(
          color: darkBurgundy.withOpacity(0.07),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // GREETING
  // --------------------------------------------------

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }

    return 'Good night';
  }

  String _formatDateValue(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ==================================================
// QUICK ACTION BUTTON
// ==================================================

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
          ),
          decoration: BoxDecoration(
            color: filled
                ? const Color(0xFF8E2945)
                : const Color(0xFFFFFCF8).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE9D8B0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled
                    ? const Color(0xFFFFFCF8)
                    : const Color(0xFF4C1026),
                size: 16,
              ),

              const SizedBox(width: 5),

              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled
                        ? const Color(0xFFFFFCF8)
                        : const Color(0xFF4C1026),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
