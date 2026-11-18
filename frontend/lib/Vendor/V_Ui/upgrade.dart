
import 'package:flutter/material.dart';
import '../V_Ui_Logic/upgrade_logic.dart';

class Upgrade extends StatefulWidget {
  const Upgrade({super.key});

  @override
  State<Upgrade> createState() => _UpgradeState();
}

class _UpgradeState extends State<Upgrade> {
  late final UpgradeLogic logic;

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

  bool currentExpanded = true;
  final Set<String> expandedPlans = {};

  @override
  void initState() {
    super.initState();

    logic = UpgradeLogic();
    logic.loadData();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  String _planId(Map<String, dynamic> plan) {
    return (plan['id'] ?? plan['plan_code']).toString();
  }

  bool _isCurrent(Map<String, dynamic> plan) {
    return logic.currentPlanCode != null &&
        logic.currentPlanCode == plan['plan_code'];
  }

  String _price(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;

    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  String _limit(dynamic value, bool unlimited) {
    if (unlimited || value == null) return 'Unlimited';
    return value.toString();
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'ACTIVE';
      case 'expired':
        return 'EXPIRED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending_payment':
        return 'PENDING PAYMENT';
      default:
        return 'NO SUBSCRIPTION';
    }
  }

  List<String> _features(Map<String, dynamic> plan) {
    final data = plan['features'];

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    return [];
  }

  // =====================================================
  // MAIN SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logic,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: cream,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: burgundy,
              backgroundColor: Colors.white,
              onRefresh: logic.loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHero(),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        19, 23, 19, 10,
                      ),
                      child: _buildCurrentPlan(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _buildSectionHeading(),
                  ),

                  if (logic.isLoading && logic.plans.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: burgundy,
                        ),
                      ),
                    )
                  else if (logic.errorMessage != null &&
                      logic.plans.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildError(),
                    )
                  else if (logic.plans.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No plans available currently.'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          18, 12, 18, 25,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final plan = logic.plans[index];

                              return _animatedPlanCard(
                                plan,
                                index,
                              );
                            },
                            childCount: logic.plans.length,
                          ),
                        ),
                      ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 35),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildSelectionBar(),
        );
      },
    );
  }

  // =====================================================
  // HERO SECTION
  // =====================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -55,
            top: -70,
            child: Container(
              height: 210,
              width: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gold.withOpacity(0.13),
                  width: 1.5,
                ),
              ),
            ),
          ),

          Positioned(
            right: 15,
            bottom: 20,
            child: Icon(
              Icons.auto_awesome,
              color: gold.withOpacity(0.17),
              size: 90,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              19, 12, 19, 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: cream,
                        size: 19,
                      ),
                    ),

                    const Spacer(),

                    const Text(
                      'ATTIRELY',
                      style: TextStyle(
                        color: gold,
                        fontSize: 13,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: logic.loadData,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: cream,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Text(
                  'YOUR NEXT CHAPTER',
                  style: TextStyle(
                    color: gold,
                    fontSize: 9,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 11),

                const Text(
                  'Grow beyond\nthe ordinary.',
                  style: TextStyle(
                    color: cream,
                    fontSize: 34,
                    height: 1.12,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Discover membership plans designed '
                      'to elevate your fashion rental business.',
                  style: TextStyle(
                    color: cream.withOpacity(0.83),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 23),

                Row(
                  children: [
                    _heroTag(
                      Icons.diamond_outlined,
                      'Premium plans',
                    ),
                    const SizedBox(width: 9),
                    _heroTag(
                      Icons.trending_up,
                      'Business growth',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: gold.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: cream,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CURRENT PLAN
  // =====================================================

  Widget _buildCurrentPlan() {
    final subscription = logic.currentSubscription;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: gold.withOpacity(0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: darkBurgundy.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(21),
            onTap: () {
              setState(() {
                currentExpanded = !currentExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: burgundy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: burgundy,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR CURRENT PLAN',
                          style: TextStyle(
                            color: burgundy,
                            fontSize: 9,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subscription?['plan_name'] ??
                              'No active plan',
                          style: const TextStyle(
                            color: darkBurgundy,
                            fontSize: 17,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _statusBadge(
                    _statusLabel(logic.currentPlanStatus),
                  ),

                  const SizedBox(width: 5),

                  AnimatedRotation(
                    turns: currentExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: burgundy,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            crossFadeState: currentExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(
              width: double.infinity,
            ),
            secondChild: _buildCurrentDetails(subscription),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDetails(
      Map<String, dynamic>? subscription,
      ) {
    if (subscription == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(17, 0, 17, 18),
        child: Text(
          'No subscription history found. Choose a plan below.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
      );
    }

    final price = _price(subscription['price'] ?? 0);
    final outfits = _limit(
      subscription['outfits_limit'],
      subscription['outfits_unlimited'] == true,
    );
    final accessories = _limit(
      subscription['accessories_limit'],
      subscription['accessories_unlimited'] == true,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: gold.withOpacity(0.55)),

          Text(
            subscription['plan_label']?.toString() ?? '',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _currentStat(
                  'Outfits',
                  outfits,
                  Icons.checkroom_outlined,
                ),
              ),
              Expanded(
                child: _currentStat(
                  'Accessories',
                  accessories,
                  Icons.diamond_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: burgundy,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                '₹$price',
                style: const TextStyle(
                  color: darkBurgundy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                subscription['billing_interval'] == 'monthly'
                    ? '/ month'
                    : '/ lifetime',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          if (logic.currentPlanStatus == 'expired')
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Your subscription has expired. '
                    'Your existing listings remain visible, '
                    'but plan-dependent uploads are restricted.',
                style: TextStyle(
                  color: burgundy,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _currentStat(
      String label,
      String value,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(icon, color: burgundy, size: 16),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: darkBurgundy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final active = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE9F5EC)
            : const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active
              ? const Color(0xFF287746)
              : burgundy,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =====================================================
  // SECTION HEADING
  // =====================================================

  Widget _buildSectionHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIND YOUR PERFECT PLAN',
            style: TextStyle(
              color: burgundy,
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose your next level.',
            style: TextStyle(
              color: darkBurgundy,
              fontFamily: 'Georgia',
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Explore the possibilities available for your store.',
            style: TextStyle(
              color: Colors.brown.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ANIMATED PLAN ENTRANCE
  // =====================================================

  Widget _animatedPlanCard(
      Map<String, dynamic> plan,
      int index,
      ) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_planId(plan)),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 550 + (index * 120),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 25 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 19),
        child: _buildPlanCard(plan),
      ),
    );
  }

  // =====================================================
  // PLAN CARD
  // =====================================================

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final id = _planId(plan);

    final selected =
        logic.selectedPlan?['plan_code'] == plan['plan_code'];

    final current = _isCurrent(plan);
    final comingSoon = logic.isComingSoon(plan);

    final features = _features(plan);
    final expanded = expandedPlans.contains(id);

    final restrictions =
    Map<String, dynamic>.from(
      plan['restrictions'] ?? {},
    );

    final images = restrictions['max_images_per_listing'] ?? 0;
    final videos = restrictions['max_videos_per_listing'] ?? 0;

    final outfitLimit = _limit(
      plan['outfits_limit'],
      plan['outfits_unlimited'] == true,
    );

    final accessoryLimit = _limit(
      plan['accessories_limit'],
      plan['accessories_unlimited'] == true,
    );

    final badge = plan['badge_text']?.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: selected || current
              ? gold
              : const Color(0xFFECE2DF),
          width: selected || current ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? burgundy.withOpacity(0.13)
                : Colors.black.withOpacity(0.045),
            blurRadius: selected ? 22 : 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          if (badge != null && badge.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                gradient: topGradient,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(21),
                ),
              ),
              child: Text(
                badge.replaceAll('★', '').trim().toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: gold,
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan['plan_label']?.toString() ?? '',
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    if (current)
                      _smallTag('CURRENT PLAN', burgundy),

                    if (comingSoon)
                      _smallTag('COMING SOON', darkBurgundy),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  plan['plan_name']?.toString() ?? '',
                  style: const TextStyle(
                    color: darkBurgundy,
                    fontSize: 23,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  plan['description']?.toString() ?? '',
                  style: TextStyle(
                    color: Colors.brown.shade400,
                    fontSize: 11,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 17),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_price(plan['price'] ?? 0)}',
                      style: const TextStyle(
                        color: burgundy,
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        plan['billing_interval'] == 'monthly'
                            ? '/ month'
                            : '/ lifetime',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const Spacer(),

                    if (plan['price_note'] != null)
                      Text(
                        plan['price_note'].toString(),
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _planMetric(
                        Icons.checkroom_outlined,
                        outfitLimit,
                        'Outfits',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _planMetric(
                        Icons.diamond_outlined,
                        accessoryLimit,
                        'Accessories',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: _planMetric(
                        Icons.photo_library_outlined,
                        '$images',
                        'Images / listing',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _planMetric(
                        Icons.videocam_outlined,
                        '$videos',
                        'Videos / listing',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Divider(
                  color: gold.withOpacity(0.7),
                  height: 1,
                ),

                InkWell(
                  onTap: () {
                    setState(() {
                      if (expanded) {
                        expandedPlans.remove(id);
                      } else {
                        expandedPlans.add(id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          color: burgundy,
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'Explore plan benefits',
                            style: TextStyle(
                              color: darkBurgundy,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: burgundy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: expanded
                      ? Column(
                    children: [
                      ...features.map(
                            (feature) => _featureRow(feature),
                      ),
                    ],
                  )
                      : const SizedBox(width: double.infinity),
                ),

                const SizedBox(height: 9),

                _planActionButton(
                  plan: plan,
                  current: current,
                  comingSoon: comingSoon,
                  selected: selected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PLAN METRICS
  // =====================================================

  Widget _planMetric(
      IconData icon,
      String value,
      String label,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFF0E8E5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: burgundy, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkBurgundy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FEATURE ROW
  // =====================================================

  Widget _featureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: burgundy,
            size: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                color: Color(0xFF51434A),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =====================================================
  // PLAN ACTION BUTTON
  // =====================================================

  Widget _planActionButton({
    required Map<String, dynamic> plan,
    required bool current,
    required bool comingSoon,
    required bool selected,
  }) {
    final disabled = current || comingSoon;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 49,
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : selected
            ? topGradient
            : const LinearGradient(
          colors: [burgundy, Color(0xFF64172F)],
        ),
        color: disabled
            ? const Color(0xFFF3EFED)
            : null,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: disabled
              ? null
              : () => logic.setSelectedPlan(plan),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current)
                  const Icon(
                    Icons.check_circle,
                    color: burgundy,
                    size: 16,
                  )
                else if (comingSoon)
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.black45,
                    size: 15,
                  )
                else
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.arrow_forward_rounded,
                    color: cream,
                    size: 16,
                  ),

                const SizedBox(width: 8),

                Text(
                  current
                      ? 'YOUR CURRENT PLAN'
                      : comingSoon
                      ? 'COMING SOON'
                      : selected
                      ? 'PLAN SELECTED'
                      : 'EXPLORE THIS PLAN',
                  style: TextStyle(
                    color: disabled
                        ? Colors.black45
                        : cream,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // STICKY SELECTION BAR
  // =====================================================

  Widget? _buildSelectionBar() {
    final selected = logic.selectedPlan;

    if (selected == null) return null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: darkBurgundy.withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'YOUR SELECTION',
                    style: TextStyle(
                      color: burgundy,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected['plan_name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkBurgundy,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            ElevatedButton(
              onPressed: _showConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: cream,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(
                    color: gold,
                    width: 1,
                  ),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CONFIRMATION
  // =====================================================

  Future<void> _showConfirmation() async {
    final selected = logic.selectedPlan;

    if (selected == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(23, 25, 23, 30),
          decoration: const BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 22),

              Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  gradient: topGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: gold,
                  size: 34,
                ),
              ),

              const SizedBox(height: 17),

              const Text(
                'A choice for your next chapter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkBurgundy,
                  fontFamily: 'Georgia',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                'You selected ${selected['plan_name']}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: burgundy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Confirming here only records your selection '
                    'on this screen. It will not activate the plan, '
                    'create a subscription or process a payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burgundy,
                    foregroundColor: cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'CONFIRM SELECTION',
                    style: TextStyle(
                      letterSpacing: 1,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 7),

              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext, false);
                },
                child: const Text(
                  'Go back',
                  style: TextStyle(
                    color: burgundy,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      logic.confirmPlanSelection();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: darkBurgundy,
          content: Text(
            'Your plan selection has been acknowledged. '
                'Your current subscription remains unchanged.',
          ),
        ),
      );
    }
  }

  // =====================================================
  // ERROR
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: burgundy,
              size: 43,
            ),
            const SizedBox(height: 13),
            const Text(
              'Unable to load membership plans',
              style: TextStyle(
                color: darkBurgundy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              logic.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 17),
            ElevatedButton(
              onPressed: logic.loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: burgundy,
                foregroundColor: cream,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
