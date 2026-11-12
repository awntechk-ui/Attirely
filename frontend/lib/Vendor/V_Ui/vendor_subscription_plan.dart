

import 'package:flutter/material.dart';
import '../../Common_Screens/session_manager.dart';
import '../../app_routes.dart';
import '../Vendor_API_Routes/vendor_subscription_api_routes.dart';
import 'vendor_dashboard.dart';

const Color burgundy = Color(0xFF800020);
const Color burgundyDark = Color(0xFF6B1E2E);
const Color gold = Color(0xFFC9A227);
const Color ivory = Color(0xFFFFF8F5);
const Color textColor = Color(0xFF30202A);

class VendorUpgrade extends StatefulWidget {
  const VendorUpgrade({super.key});

  @override
  State<VendorUpgrade> createState() => _VendorUpgradeState();
}

class _VendorUpgradeState extends State<VendorUpgrade> {
  bool showComparison = false;
  bool isActivating = false;

  Future<void> continueFreePlan() async {
    if (isActivating) return;

    final accessToken = SessionManager.getToken();

    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
        ),
      );
      return;
    }

    setState(() {
      isActivating = true;
    });

    try {
      await VendorSubscriptionApiRoutes.selectPlan(
        accessToken: accessToken,
        planCode: 'starter',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starter Atelier plan activated successfully!'),
        ),
      );

      // CASE 4: ACTIVE SUBSCRIPTION EXISTS

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.vendorMain,
      );
      return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isActivating = false;
        });
      }
    }
  }

  Widget progressStep(String title, bool active, bool completed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.circle,
          size: 16,
          color: active || completed ? gold : Colors.grey.shade400,
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? burgundy : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: gold,
            size: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget planButton({
    required String title,
    required bool isFree,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: ElevatedButton(
        onPressed: isFree
            ? (isActivating ? null : continueFreePlan)
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This subscription plan is coming soon!'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFree ? burgundy : const Color(0xFF7D354B),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isFree && isActivating
            ? const Center(
          child: SizedBox(
            height: 19,
            width: 19,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              isFree ? Icons.arrow_forward : Icons.lock_outline,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget planCard({
    required String label,
    required String name,
    required String description,
    required String price,
    required String priceSuffix,
    required List<String> features,
    required String buttonText,
    required bool isFree,
    String? badge,
    String? priceNote,
    bool highlighted = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: highlighted
                  ? gold.withOpacity(0.75)
                  : const Color(0xFFECE2DF),
              width: highlighted ? 1.7 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (priceNote != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2DF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priceNote,
                        style: const TextStyle(
                          fontSize: 9,
                          color: burgundy,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 9),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 21,
                  color: burgundy,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                ),
              ),

              const SizedBox(height: 5),

              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.brown.shade400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 25,
                      color: burgundy,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      priceSuffix,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 13),

              const Text(
                'KEY INCLUSIONS:',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: burgundy,
                ),
              ),

              const SizedBox(height: 12),

              ...features.map((item) => feature(item)),

              const SizedBox(height: 10),

              planButton(
                title: buttonText,
                isFree: isFree,
              ),

              if (isFree)
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Center(
                    child: Text(
                      'No credit card required. Upgrade anytime.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF986F79),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (badge != null)
          Positioned(
            top: -10,
            right: 13,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget comparisonSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE2DF)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                showComparison = !showComparison;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    color: burgundy,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare All Plans',
                          style: TextStyle(
                            color: burgundy,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Feature breakdown across tiers',
                          style: TextStyle(
                            color: Colors.brown,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    showComparison
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: gold,
                  ),
                ],
              ),
            ),
          ),
          if (showComparison)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  comparisonRow('Active Catalogues', '7', '50', 'Unlimited'),
                  comparisonRow('Store Management', '✓', '✓', '✓'),
                  comparisonRow('Rental Requests', '✓', '✓', '✓'),
                  comparisonRow('Order Management', '✓', '✓', '✓'),
                  comparisonRow('Analytics', 'Basic', 'Advanced', 'Advanced'),
                  comparisonRow('Promotions', '—', '✓', '✓'),
                  comparisonRow('Featured Listings', '—', '✓', '✓'),
                  comparisonRow('Priority Support', '—', '✓', '✓'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget comparisonRow(
      String title,
      String starter,
      String growth,
      String elite,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: const TextStyle(fontSize: 10)),
          ),
          Expanded(
            child: Text(
              starter,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              growth,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              elite,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 25),
                children: [
                  // HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: burgundy,
                        ),
                      ),
                      const Spacer(),
                      const Column(
                        children: [
                          Text(
                            'ATTIRELY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: burgundy,
                              letterSpacing: 2,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          Text(
                            'VENDOR ONBOARDING',
                            style: TextStyle(
                              fontSize: 8,
                              color: gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.help_outline,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // PROGRESS INDICATOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EFED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        progressStep('1. Profile', false, true),
                        Container(
                          height: 1,
                          width: 15,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: burgundy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '●  2. Plans',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          width: 15,
                          color: Colors.grey.shade300,
                        ),
                        progressStep('3. Launch', false, false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Icon(
                    Icons.checkroom_outlined,
                    color: gold,
                    size: 28,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose Your Vendor Plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                      fontFamily: 'Georgia',
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Curate your atelier presence and scale your high-fashion rental enterprise effortlessly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // STARTER PLAN
                  planCard(
                    label: 'Free Forever',
                    name: 'Starter Atelier',
                    description:
                    'Ideal for boutique designers & independent curators entering fashion rental.',
                    price: '₹0',
                    priceSuffix: '/ month forever',
                    features: [
                      'Upload up to 7 active catalogues',
                      'Women\'s wear, men\'s wear and accessories',
                      'Manage your store profile',
                      'Receive instant rental requests',
                      'Manage orders & calendar bookings',
                      'Basic earnings & payout overview',
                    ],
                    buttonText: 'Continue with Free Plan',
                    isFree: true,
                  ),

                  const SizedBox(height: 32),

                  // GROWTH PLAN
                  planCard(
                    label: 'Grow Your Business',
                    name: 'Growth Boutique',
                    description:
                    'For expanding rental labels aiming for higher velocity & elevated platform discovery.',
                    price: '₹1,499',
                    priceSuffix: '/ month',
                    priceNote: 'Billed Monthly',
                    badge: '★ POPULAR CHOICE',
                    highlighted: true,
                    features: [
                      'Upload up to 50 active catalogues',
                      'All clothing categories & archival accessories',
                      'Advanced store customization & branding',
                      'Advanced rental analytics & peak event trends',
                      'Featured listing opportunities on Homepage',
                      'Seasonal promotional discount tools',
                      'Priority dedicated vendor support',
                    ],
                    buttonText: 'Choose Growth Plan (Coming Soon)',
                    isFree: false,
                  ),

                  const SizedBox(height: 25),

                  // ELITE PLAN
                  planCard(
                    label: 'For Established Stores',
                    name: 'Elite Fashion House',
                    description:
                    'Full-scale enterprise solution for premier rental houses & celebrity stylists.',
                    price: '₹3,999',
                    priceSuffix: '/ month',
                    priceNote: 'Coming Soon',
                    features: [
                      'Unlimited active catalogues',
                      'All luxury categories & fine jewelry',
                      'Premium top-tier store visibility across city searches',
                      'Advanced multi-store business intelligence',
                      'Curated marketing & editorial campaign features',
                      'Dedicated promotional campaign suite & push alerts',
                      '24/7 Priority concierge & stylist support',
                    ],
                    buttonText: 'Choose Elite Plan (Coming Soon)',
                    isFree: false,
                  ),

                  const SizedBox(height: 23),

                  // COMPARE PLANS
                  comparisonSection(),

                  const SizedBox(height: 15),

                  // INFORMATION BOX
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFECE2DF),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: gold,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You can upgrade or adjust your plan anytime directly from your Vendor Dashboard.\nYour active catalogue limit applies across all categories, including apparel & accessories.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF795B60),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // FOOTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: gold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Partner Desk',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Center(
                    child: Text(
                      'ATTIRELY © Luxury Rental Atelier Network. All Rights Reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAD8B94),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
