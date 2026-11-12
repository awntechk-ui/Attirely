
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../U_Ui_Logic/profile_logic.dart';
import '../../app_routes.dart';
import 'my_rentals.dart';
import 'my_trials.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileLogic logic;
  final ImagePicker _picker = ImagePicker();

  static const Color burgundy = Color(0xFF6B1E2E);
  static const Color burgundyLight = Color(0xFFA65C69);
  static const Color gold = Color(0xFFC9A227);
  static const Color ivory = Color(0xFFFBF8F2);
  static const Color textColor = Color(0xFF321D25);
  static const Color muted = Color(0xFF8C747B);

  @override
  void initState() {
    super.initState();
    logic = ProfileLogic();
    logic.addListener(_refresh);
    logic.fetchProfile();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    logic.removeListener(_refresh);
    logic.dispose();
    super.dispose();
  }

  // =========================================================
  // PICK PROFILE IMAGE
  // =========================================================

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage == null) return;

      final success = await logic.uploadProfileImage(
        File(pickedImage.path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated successfully'
                : logic.errorMessage ?? 'Photo upload failed',
          ),
          backgroundColor: success ? burgundy : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select image: $e'),
        ),
      );
    }
  }

  void _openMyTrials() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTrialsPage(),
      ),
    );
  }

  void _openMyRentals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyRentalsPage(),
      ),
    );
  }

  // =========================================================
  // PLACEHOLDER FOR PAGES NOT CONNECTED YET
  // =========================================================

  void _showComingSoon(String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$pageName will be available soon'),
        backgroundColor: burgundy,
      ),
    );
  }

  // =========================================================
  // LOGOUT CONFIRMATION
  // =========================================================

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              color: burgundy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of Attirely?',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: muted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await logic.logout(context);
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _openMyOutfits() {
    Navigator.pushNamed(context, AppRoutes.userOutfits);
  }

  void _openAddOutfit() {
    Navigator.pushNamed(context, AppRoutes.addOutfit);
  }

  void _openRentals() {
    Navigator.pushNamed(context, AppRoutes.userRentals);
  }

  void _openOrders() {
    _showComingSoon('My Orders');
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = logic.profile;

    return Scaffold(
      backgroundColor: ivory,
      body: Stack(
        children: [
      Positioned.fill(
      child: Image.asset(
        'assets/background/login_bg.png',
        fit: BoxFit.cover,
      ),
    ),

    Positioned.fill(
    child: Container(
    color: const Color(0xEFFFFFFF),
    ),
    ),

    SafeArea(
        child: logic.isLoading && user == null
            ? const Center(
          child: CircularProgressIndicator(
            color: burgundy,
          ),
        )
            : RefreshIndicator(
          color: burgundy,
          onRefresh: logic.fetchProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14, 18, 14, 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeading(
                        'MY ACTIVITY',
                        'Customer Portal',
                      ),
                      const SizedBox(height: 10),

                      _buildActivityCards(),

                      const SizedBox(height: 10),

                      _buildActivityList(),

                      const SizedBox(height: 20),

                      _sectionHeading(
                        'MY OUTFITS',
                        'Your Wardrobe',
                      ),
                      const SizedBox(height: 10),

                      _buildMyOutfitsSection(),

                      const SizedBox(height: 22),

                      _sectionHeading(
                        'ACCOUNT & SETTINGS',
                        'Preferences',
                      ),
                      const SizedBox(height: 10),

                      _buildSettingsSection(),

                      const SizedBox(height: 24),

                      _buildLogoutButton(),

                      const SizedBox(height: 12),

                      const Center(
                        child: Text(
                          'Attirely Luxury Rental v2.4.0',
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),],
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    final name = user?['full_name']?.toString() ?? 'Your Name';
    final email = user?['email']?.toString() ?? '';
    final imageUrl = user?['profile_image_url']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            burgundyLight,
            burgundy,
            Color(0xFF642638),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerCircleButton(
                Icons.arrow_back,
                    () => Navigator.maybePop(context),
              ),
              const Spacer(),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _headerCircleButton(
                Icons.settings_outlined,
                    () => _showComingSoon('Profile settings'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Stack(
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE8D5A7),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _defaultAvatar(),
                  )
                      : _defaultAvatar(),
                ),
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: burgundy,
                        width: 1.5,
                      ),
                    ),
                    child: logic.isUploadingImage
                        ? const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: burgundy,
                      ),
                    )
                        : const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: burgundy,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            email,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFEADDE0),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _showComingSoon('Edit Profile'),
            icon: const Icon(
              Icons.edit,
              size: 12,
              color: Color(0xFFFFDFA0),
            ),
            label: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Color(0xFFFFDFA0),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFC9A27A),
              ),
              backgroundColor: Colors.white.withOpacity(0.10),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 5,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFFF2E9E7),
      child: const Icon(
        Icons.person,
        size: 45,
        color: burgundy,
      ),
    );
  }

  Widget _headerCircleButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  // =========================================================
  // SECTION HEADING
  // =========================================================

  Widget _sectionHeading(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
            color: burgundy,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 9,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MY ACTIVITY CARDS
  // =========================================================

  Widget _buildActivityCards() {
    return Row(
      children: [
        Expanded(
          child: _activityCard(
            icon: Icons.inventory_2_outlined,
            title: 'My Orders',
            subtitle: 'Track your orders',
            badge: '2 Active',
            badgeColor: const Color(0xFFFFDDE3),
            onTap: _openOrders,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _activityCard(
            icon: Icons.checkroom_outlined,
            title: 'Buy Rentals',
            subtitle: 'Current & past rentals',
            badge: '1 Ongoing',
            badgeColor: const Color(0xFFFFE0AC),
            onTap: _openRentals,
          ),
        ),
      ],
    );
  }

  Widget _activityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 119,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFEFE8E5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(icon),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xFFD5A6AC),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ACTIVITY LIST
  // =========================================================

  Widget _buildActivityList() {
    return _whiteListCard([
      _listTile(
        Icons.event_note_outlined,
        'My Trails',
        'Track your outfit trial bookings and history',
        _openMyTrials,
      ),
      _listTile(
        Icons.shopping_bag_outlined,
        'My Rentals',
        'Track your rental requests and active rentals',
        _openMyRentals,
      ),
      _listTile(
        Icons.star_border,
        'My Reviews',
        'Manage submitted ratings & reviews',
            () => _showComingSoon('My Reviews'),
      ),
      _listTile(
        Icons.assignment_return_outlined,
        'Returns & Refunds',
        'Track return requests & refund status',
            () => _showComingSoon('Returns & Refunds'),
      ),
      _listTile(
        Icons.history,
        'Recently Viewed',
        'Explore previously viewed styles',
            () => _showComingSoon('Recently Viewed'),
      ),
    ]);
  }

  // =========================================================
  // MY OUTFITS SECTION
  // =========================================================

  Widget _buildMyOutfitsSection() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEDE4E0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E8EA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.checkroom_outlined,
                  color: burgundy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Outfits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your personal outfit collection',
                      style: TextStyle(
                        fontSize: 9,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD5A6AC),
                size: 19,
              ),
            ],
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMyOutfits,
              icon: const Icon(Icons.checkroom_outlined, size: 18),
              label: const Text('View or Add My Outfits'),
              style: OutlinedButton.styleFrom(
                foregroundColor: burgundy,
                side: const BorderSide(color: gold),
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACCOUNT & SETTINGS
  // =========================================================

  Widget _buildSettingsSection() {
    return _whiteListCard([
      _listTile(
        Icons.person_outline,
        'Personal Information',
        null,
            () => _showComingSoon('Personal Information'),
      ),
      _listTile(
        Icons.location_on_outlined,
        'Manage Addresses',
        null,
            () => _showComingSoon('Manage Addresses'),
      ),
      _listTile(
        Icons.credit_card_outlined,
        'Payment Methods',
        null,
            () => _showComingSoon('Payment Methods'),
      ),
      _listTile(
        Icons.notifications_none,
        'Notifications Settings',
        null,
            () => _showComingSoon('Notifications Settings'),
      ),
      _listTile(
        Icons.support_agent,
        'Help & Support',
        null,
            () => _showComingSoon('Help & Support'),
      ),
      _listTile(
        Icons.info_outline,
        'About Attirely',
        null,
            () => _showComingSoon('About Attirely'),
      ),
      _listTile(
        Icons.verified_user_outlined,
        'Privacy Policy & Terms',
        null,
            () => _showComingSoon('Privacy Policy & Terms'),
      ),
    ]);
  }

  // =========================================================
  // WHITE LIST CARD
  // =========================================================

  Widget _whiteListCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEFE8E5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _listTile(
      IconData icon,
      String title,
      String? subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF5F0ED),
              width: 0.7,
            ),
          ),
        ),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 8,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 17,
              color: Color(0xFFD5A6AC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 15,
        color: burgundy,
      ),
    );
  }

  // =========================================================
  // LOGOUT BUTTON
  // =========================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(
          Icons.logout,
          size: 15,
          color: Colors.redAccent,
        ),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Color(0xFFF0E8E5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
