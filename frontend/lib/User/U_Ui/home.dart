import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../U_Ui_Logic/home_logic.dart';
import '../WIdgets/Home/categories_section.dart';
import '../WIdgets/Home/featured_outfits_section.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onOpenTab;

  const HomePage({
    super.key,
    this.onOpenTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeLogic logic;
  final TextEditingController _searchController =
  TextEditingController();

  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    logic = HomeLogic();
    logic.loadCatalogue();
  }

  @override
  void dispose() {
    _searchController.dispose();
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/app_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFFFF8F7)),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: logic,
              builder: (context, _) {
                return RefreshIndicator(
                  color: burgundy,
                  onRefresh: logic.loadCatalogue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP BAR
                        Row(
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: burgundy,
                                    size: 22,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Your Location',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: burgundy,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: burgundy,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: burgundy,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.profile,
                                );
                              },
                              icon: const Icon(
                                Icons.person_outline,
                                color: burgundy,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // SEARCH
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.82),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: burgundy.withOpacity(0.15),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: burgundy,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search dresses, styles and more...',
                              hintStyle: TextStyle(
                                color: burgundy.withOpacity(0.55),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: burgundy,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Search filters will be added next.',
                                        ),
                                      ),
                                    );
                                },
                                icon: const Icon(
                                  Icons.tune,
                                  color: burgundy,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // OWNER BANNER
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.userOutfits,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 180),
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: gold,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: burgundy.withOpacity(0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Manage Your Outfits',
                                  style: TextStyle(
                                    color: burgundy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'View and manage your listed outfits '
                                      'in one place on Attirely.',
                                  style: TextStyle(
                                    color: burgundy.withOpacity(0.75),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: burgundy,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'My Outfits',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 7),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          ),
                        ),

                        const SizedBox(height: 28),

                        // CATEGORIES
                        const CategoriesSection(),

                        const SizedBox(height: 28),

                        // FEATURED OUTFITS FROM BACKEND
                        FeaturedOutfitsSection(
                          outfits: logic.featuredOutfits,
                          isLoading: logic.isLoadingCatalogue,
                          error: logic.catalogueError,
                          onRetry: logic.loadCatalogue,
                          // Switch to Rentals through the main navigation.
                          // This callback will be connected in Step 3.
                          onViewMore: () {
                            widget.onOpenTab?.call(1);
                          },                        ),

                        const SizedBox(height: 28),
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
}