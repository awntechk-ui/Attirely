
import 'package:flutter/material.dart';

import 'package:attirely/Common_Screens/session_manager.dart';
import 'package:attirely/app_routes.dart';

import '../Vendor_API_Routes/vendor_auth_api_routes.dart';

class DeleteVendorAccountPage extends StatefulWidget {
  const DeleteVendorAccountPage({super.key});

  @override
  State<DeleteVendorAccountPage> createState() =>
      _DeleteVendorAccountPageState();
}

class _DeleteVendorAccountPageState
    extends State<DeleteVendorAccountPage> {
  static const Color burgundy = Color(0xFF800020);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);
  static const Color textColor = Color(0xFF321D25);
  static const Color muted = Color(0xFF8C747B);
  static const Color danger = Color(0xFFB3261E);

  final TextEditingController _confirmationController =
  TextEditingController();

  bool _isDeleting = false;

  bool get _canDelete =>
      _confirmationController.text.trim() == 'DELETE';

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  // =========================================================
  // FINAL CONFIRMATION
  // =========================================================

  Future<void> _showFinalConfirmation() async {
    if (!_canDelete || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: danger,
            size: 42,
          ),
          title: const Text(
            'Delete your account permanently?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkBurgundy,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          content: const Text(
            'This action cannot be undone. Your vendor account '
                'and catalogues will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete Permanently',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  // =========================================================
  // DELETE ACCOUNT API
  // =========================================================

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      String? token = SessionManager.getToken();
      token ??= await SessionManager.loadToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Your session has expired. Please login again.',
        );
      }

      final result =
      await VendorAuthApiRoutes.deleteMyVendorAccount(
        accessToken: token,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message'] ??
              'Account deletion could not be completed.',
        );
      }

      if (!mounted) return;

      await SessionManager.clearToken();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      final message = e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // WARNING ITEM
  // =========================================================

  Widget _warningItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8EDEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: burgundy,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MAIN UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: darkBurgundy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: darkBurgundy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Center(
                      child: Container(
                        height: 82,
                        width: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8EDEF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gold,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_forever_outlined,
                          size: 43,
                          color: burgundy,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Leaving Attirely?',
                        style: TextStyle(
                          color: darkBurgundy,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'We are sorry to see you go. Please review '
                          'what happens when you permanently delete '
                          'your vendor account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // DELETION DETAILS
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEEDFE2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The following will be permanently removed',
                            style: TextStyle(
                              color: darkBurgundy,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _warningItem(
                            icon: Icons.storefront_outlined,
                            title: 'Vendor profile',
                            description:
                            'Your vendor account and store information.',
                          ),

                          _warningItem(
                            icon: Icons.checkroom_outlined,
                            title: 'Outfits and accessories',
                            description:
                            'All your published catalogues and listing details.',
                          ),

                          _warningItem(
                            icon: Icons.image_outlined,
                            title: 'Catalogue images',
                            description:
                            'Images stored in your vendor catalogue.',
                          ),

                          _warningItem(
                            icon: Icons.receipt_long_outlined,
                            title: 'Trial requests',
                            description:
                            'Your active and historical live trial requests '
                                'will be removed.',
                          ),

                          _warningItem(
                            icon: Icons.card_membership_outlined,
                            title: 'Subscription',
                            description:
                            'Your vendor subscription records will be removed.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PAYMENT RECORD NOTICE
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: gold,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF92702D),
                            size: 23,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment records are preserved',
                                  style: TextStyle(
                                    color: darkBurgundy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Trial payment and audit details will be '
                                      'retained in a restricted archive. They '
                                      'will not be available as live requests.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // TYPE DELETE
                    const Text(
                      'Confirm account deletion',
                      style: TextStyle(
                        color: darkBurgundy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Type DELETE below to continue.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _confirmationController,
                      enabled: !_isDeleting,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Type DELETE',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB7A8AC),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7DADD),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7DADD),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: burgundy,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: _canDelete
                            ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // DELETE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: !_canDelete || _isDeleting
                            ? null
                            : _showFinalConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: danger,
                          disabledBackgroundColor:
                          const Color(0xFFD9C7CA),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                            : const Text(
                          'Permanently Delete My Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: TextButton(
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Keep My Account',
                          style: TextStyle(
                            color: burgundy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            if (_isDeleting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(
                    child: Card(
                      color: cream,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: burgundy,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Deleting your account...',
                              style: TextStyle(
                                color: darkBurgundy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Please do not close the app.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
