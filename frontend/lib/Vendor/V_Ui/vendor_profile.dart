
import 'package:flutter/material.dart';

import 'package:attirely/Common_Screens/session_manager.dart';
import 'package:attirely/Common_Screens/UI/add_outfit.dart';
import 'package:attirely/app_routes.dart';

class VendorProfile extends StatefulWidget {
  final ValueChanged<int>? onTabSelected;

  const VendorProfile({
    super.key,
    this.onTabSelected,
  });

  @override
  State<VendorProfile> createState() => _VendorProfileState();
}

class _VendorProfileState extends State<VendorProfile> {
  static const Color burgundy = Color(0xFF800020);
  static const Color burgundyLight = Color(0xFFA65C69);
  static const Color gold = Color(0xFFC9A227);
  static const Color ivory = Color(0xFFFBF8F2);
  static const Color textColor = Color(0xFF321D25);
  static const Color muted = Color(0xFF8C747B);

  // ---------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------

  void _openTab(int index) {
    widget.onTabSelected?.call(index);
  }

  void _openAddOutfit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddOutfit(),
      ),
    );
  }

  void _showComingSoon(String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$page will be connected soon'),
        backgroundColor: burgundy,
      ),
    );
  }

  // ---------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(
              color: burgundy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout of your vendor account?',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: muted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Restore the previous working logout flow.
    await SessionManager.clearToken();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  // ---------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/background/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: ivory,
              );
            },
          ),
        ),

        // Light overlay for readability
        Positioned.fill(
          child: Container(
            color: const Color(0xEFFFFFFF),
          ),
        ),

        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: burgundy,
            onRefresh: () async {
              // Vendor profile refresh can be connected to API logic later.
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 135),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      22,
                      16,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStoreCard(),

                        const SizedBox(height: 25),

                        _sectionHeading(
                          'BUSINESS OVERVIEW',
                          'Your store at a glance',
                        ),

                        const SizedBox(height: 12),

                        _buildPerformanceCards(),

                        const SizedBox(height: 25),

                        _sectionHeading(
                          'MANAGE YOUR STORE',
                          'Your business operations',
                        ),

                        const SizedBox(height: 12),

                        _buildStoreManagement(),

                        const SizedBox(height: 25),

                        _sectionHeading(
                          'CUSTOMER ACTIVITY',
                          'Manage your customer interactions',
                        ),

                        const SizedBox(height: 12),

                        _buildCustomerActivity(),

                        const SizedBox(height: 25),

                        _sectionHeading(
                          'STORE SETTINGS',
                          'Manage your business details',
                        ),

                        const SizedBox(height: 12),

                        _buildStoreSettings(),

                        const SizedBox(height: 25),

                        _sectionHeading(
                          'ACCOUNT & SUPPORT',
                          'Your account preferences',
                        ),

                        const SizedBox(height: 12),

                        _buildAccountSettings(),

                        const SizedBox(height: 25),

                        _buildLogoutButton(),

                        const SizedBox(height: 18),

                        const Center(
                          child: Text(
                            'Attirely • Vendor Portal',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }


  // ---------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            burgundyLight,
            burgundy,
            Color(0xFF511526),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 13,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(
                Icons.arrow_back,
                    () => Navigator.maybePop(context),
              ),

              const Spacer(),

              const Text(
                'Vendor Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              _headerButton(
                Icons.settings_outlined,
                    () => _showComingSoon('Settings'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: gold,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFFF4E9E9),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: burgundy,
                  size: 43,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Vendor Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Manage your store and grow your business',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFEADDE0),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0x66E8D5A7),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: gold,
                  size: 16,
                ),
                SizedBox(width: 7),
                Text(
                  'ATTIRELY VENDOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: () => _showComingSoon('Edit Vendor Profile'),
            icon: const Icon(
              Icons.edit_outlined,
              size: 17,
            ),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: gold,
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 23,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x44FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // STORE CARD
  // ---------------------------------------------------------

  Widget _buildStoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.storefront_outlined),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY STORE',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your Store Name',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => _showComingSoon('My Store'),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: burgundy,
                  size: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Manage your store information, business description and location.',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showComingSoon('Store Information'),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: gold),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Manage Store Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // BUSINESS OVERVIEW - FOUR SQUARE CARDS
  // ---------------------------------------------------------

  Widget _buildPerformanceCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      // Near-square cards instead of wide rectangles.
      childAspectRatio: 1.08,

      children: [
        _performanceCard(
          Icons.checkroom_outlined,
          'Total Listings',
          '—',
        ),
        _performanceCard(
          Icons.shopping_bag_outlined,
          'Total Rentals',
          '—',
        ),
        _performanceCard(
          Icons.currency_rupee,
          'Total Earnings',
          '—',
        ),
        _performanceCard(
          Icons.star_outline_rounded,
          'Store Rating',
          '—',
        ),
      ],
    );
  }

  Widget _performanceCard(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EDEF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: burgundy,
              size: 21,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: burgundy,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // MANAGE YOUR STORE
  // ---------------------------------------------------------

  Widget _buildStoreManagement() {
    return _menuCard([
      _menuTile(
        Icons.inventory_2_outlined,
        'My Listings',
        'Manage your outfits and accessories',
            () => _openTab(1),
      ),

      _menuTile(
        Icons.add_box_outlined,
        'Add New Listing',
        'Upload a new outfit or accessory',
        _openAddOutfit,
      ),

      _menuTile(
        Icons.calendar_month_outlined,
        'Manage Availability',
        'Update available and unavailable dates',
            () => _showComingSoon('Manage Availability'),
      ),

      _menuTile(
        Icons.store_mall_directory_outlined,
        'Store Information',
        'Edit your business details',
            () => _showComingSoon('Store Information'),
      ),
    ]);
  }

  // ---------------------------------------------------------
  // CUSTOMER ACTIVITY
  // ---------------------------------------------------------

  Widget _buildCustomerActivity() {
    return _menuCard([
      _menuTile(
        Icons.receipt_long_outlined,
        'Rental Requests',
        'View and respond to incoming requests',
            () => _openTab(2),
      ),

      _menuTile(
        Icons.shopping_bag_outlined,
        'Bookings',
        'View confirmed and ongoing bookings',
            () => _openTab(3),
      ),

      _menuTile(
        Icons.account_balance_wallet_outlined,
        'My Earnings',
        'Track revenue and payouts',
            () => _showComingSoon('My Earnings'),
      ),

      _menuTile(
        Icons.rate_review_outlined,
        'Vendor Reviews',
        'Read customer ratings and feedback',
            () => _showComingSoon('Vendor Reviews'),
      ),

      _menuTile(
        Icons.analytics_outlined,
        'Vendor Analytics',
        'Explore views, rentals and performance',
            () => _showComingSoon('Vendor Analytics'),
      ),
    ]);
  }

  // ---------------------------------------------------------
  // STORE SETTINGS
  // ---------------------------------------------------------

  Widget _buildStoreSettings() {
    return _menuCard([
      _menuTile(
        Icons.person_outline,
        'Personal Information',
        'Your name and contact details',
            () => _showComingSoon('Personal Information'),
      ),

      _menuTile(
        Icons.location_on_outlined,
        'Business Address',
        'Manage your store location',
            () => _showComingSoon('Business Address'),
      ),

      _menuTile(
        Icons.badge_outlined,
        'Business Verification',
        'Manage your business documents',
            () => _showComingSoon('Business Verification'),
      ),

      _menuTile(
        Icons.account_balance_outlined,
        'Bank & Payout Details',
        'Manage payment and payout information',
            () => _showComingSoon('Bank & Payout Details'),
      ),

      _menuTile(
        Icons.notifications_none_outlined,
        'Notifications',
        'Manage your alerts and updates',
            () => _showComingSoon('Notifications'),
      ),
    ]);
  }

  // ---------------------------------------------------------
  // ACCOUNT & SUPPORT
  // ---------------------------------------------------------

  Widget _buildAccountSettings() {
    return _menuCard([
      _menuTile(
        Icons.lock_outline,
        'Privacy & Security',
        'Password and account security',
            () => _showComingSoon('Privacy & Security'),
      ),

      _menuTile(
        Icons.support_agent_outlined,
        'Help & Support',
        'Get assistance with your vendor account',
            () => _showComingSoon('Help & Support'),
      ),

      _menuTile(
        Icons.info_outline,
        'About Attirely',
        'Learn more about Attirely',
            () => _showComingSoon('About Attirely'),
      ),

      _menuTile(
        Icons.policy_outlined,
        'Terms & Policies',
        'Vendor terms and platform policies',
            () => _showComingSoon('Terms & Policies'),
      ),
    ]);
  }

  // ---------------------------------------------------------
  // REUSABLE WIDGETS
  // ---------------------------------------------------------

  Widget _sectionHeading(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: burgundy,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: const Color(0xFFEFE8E5),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: burgundy,
        size: 22,
      ),
    );
  }

  Widget _menuTile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 70,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        child: Row(
          children: [
            _iconBox(icon),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right,
              color: Color(0xFFD0A5AA),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // LOGOUT BUTTON
  // ---------------------------------------------------------

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(
          Icons.logout,
          color: burgundy,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: burgundy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: gold,
            width: 1.5,
          ),
          backgroundColor: Colors.white.withOpacity(0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
