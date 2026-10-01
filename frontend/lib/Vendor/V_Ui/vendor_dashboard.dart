import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../V_Ui_Logic/dashboard_logic.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  State<VendorDashboardPage> createState() =>
      _VendorDashboardPageState();
}

class _VendorDashboardPageState
    extends State<VendorDashboardPage> {
  late final DashboardLogic logic;

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);
  static const Color pageWhite = Color(0xFFFDF9F5);

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    logic = DashboardLogic();
    logic.loadDashboard();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/app_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: pageWhite.withOpacity(0.10),
            ),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: logic,
              builder: (context, _) {
                return SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(now),
                      const SizedBox(height: 28),
                      _buildStatsGrid(),
                      const SizedBox(height: 28),
                      _buildQuickActions(),
                    ],
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ============================================================
        // TOP ROW
        // Attirely + Notification + Profile
        // ============================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // Attirely logo/name
            Expanded(
              child: Text(
                'Attirely',
                style: const TextStyle(
                  color: burgundy,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Notification
            Stack(
              clipBehavior: Clip.none,
              children: [
                _circleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    // Notifications will be connected later.
                  },
                ),

                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: burgundy,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Profile
            GestureDetector(
              onTap: () {
                // Vendor profile will be connected later.
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.88),
                  border: Border.all(
                    color: burgundy.withOpacity(0.15),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: burgundy,
                  size: 23,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ============================================================
        // GREETING
        // ============================================================

        Text(
          _getGreeting(now.hour),
          style: TextStyle(
            color: burgundy.withOpacity(0.82),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 3),

        // ============================================================
        // STORE NAME
        // ============================================================

        Row(
          children: [
            Flexible(
              child: Text(
                logic.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: burgundy,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),

            const SizedBox(width: 6),

            const Text(
              '👋',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // ============================================================
        // DATE
        // ============================================================

        Text(
          _formatDate(now),
          style: TextStyle(
            color: burgundy.withOpacity(0.62),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          value: logic.activeOutfits,
          label: 'Active Outfits',
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF9B2948),
          iconBackground: const Color(0xFFFFE9EE),
        ),
        _StatCard(
          value: logic.trialRequests,
          label: 'Trial Requests',
          icon: Icons.event_available_rounded,
          iconColor: const Color(0xFFE08A24),
          iconBackground: const Color(0xFFFFF1D9),
        ),
        _StatCard(
          value: logic.upcomingTrials,
          label: 'Upcoming Trials',
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFF31966D),
          iconBackground: const Color(0xFFE2F7EC),
        ),
        _StatCard(
          value: logic.completedRentals,
          label: 'Completed Rentals',
          icon: Icons.card_giftcard_outlined,
          iconColor: const Color(0xFF7951D4),
          iconBackground: const Color(0xFFEDE5FF),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: burgundy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                title: 'Add New Outfit',
                icon: Icons.add_rounded,
                filled: true,
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.vendorAddOutfit,
                  );

                  if (result == true) {
                    await logic.loadDashboard();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                title: 'View Requests',
                icon: Icons.receipt_long_outlined,
                filled: false,
                onTap: () {
                  // Requests page will be added later.
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      (
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      ),
      (
      icon: Icons.checkroom_outlined,
      selectedIcon: Icons.checkroom_rounded,
      label: 'Outfits',
      ),
      (
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Requests',
      ),
      (
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Bookings',
      ),
      (
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      ),
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: burgundy.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: burgundy.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
              (index) {
            final item = items[index];

            return _BottomNavItem(
              icon: selectedIndex == index
                  ? item.selectedIcon
                  : item.icon,
              label: item.label,
              selected: selectedIndex == index,
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: burgundy.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          color: burgundy,
          size: 23,
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon,';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening,';
    }
    return 'Good night,';
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFF800020);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: burgundy.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: burgundy.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: burgundy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              color: burgundy.withOpacity(0.68),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFF800020);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          decoration: BoxDecoration(
            color: filled
                ? burgundy
                : Colors.white.withOpacity(0.76),
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color: filled
                  ? burgundy
                  : burgundy.withOpacity(0.10),
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled
                    ? Colors.white
                    : burgundy,
                size: 20,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled
                        ? Colors.white
                        : burgundy,
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w700,
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFF800020);

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(18),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? burgundy
                  : burgundy.withOpacity(0.52),
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? burgundy
                    : burgundy.withOpacity(0.52),
                fontSize: 9.5,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}