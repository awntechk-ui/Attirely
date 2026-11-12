import 'package:attirely/Common_Screens/API_Routes/auth_api_routes.dart';
import 'package:attirely/User/U_Ui/user_bottom_navigation.dart';
import 'package:attirely/User/U_Ui/user_cart.dart';
import 'package:attirely/User/U_Ui/user_rentals.dart';
import 'package:attirely/User/U_Ui/outfits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Common_Screens/services/device_location_service.dart';
import '../../app_routes.dart';
import '../../Common_Screens/session_manager.dart';

import '../U_Ui_Logic/home_logic.dart';
import '../WIdgets/Home/categories_section.dart';
import '../WIdgets/Home/featured_accessories.dart';
import '../WIdgets/Home/featured_outfits_section.dart';
import '../WIdgets/Home/home_promo_slider.dart';
import '../WIdgets/Home/why_rent_section.dart';
import 'attirely_search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeLogic logic;
  String _currentLocation = 'Getting current location...';

  Future<void> _loadCurrentLocation() async {
    final location =
    await DeviceLocationService.getCurrentLocationLabel();

    if (!mounted) return;

    setState(() {
      _currentLocation = location;
    });
  }

  String _userName = 'Attirely Member';

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

    logic = HomeLogic();

    logic.loadCatalogue();

    _loadUserName();
    _loadCurrentLocation();

  }

  // ==================================================
  // LOAD LOGGED-IN USER NAME
  // ==================================================

  Future<void> _loadUserName() async {
    try {
      // Get saved access token.
      String? token = SessionManager.getToken();

      // If not available in memory, load from SharedPreferences.
      token ??= await SessionManager.loadToken();

      if (token == null || token.isEmpty) {
        debugPrint('HOME: Access token not found');
        return;
      }

      // Call existing backend /auth/session endpoint.
      final response = await AuthApiRoutes.validateSession(
        accessToken: token,
      );

      if (!mounted) return;

      // Only use the normal user's full_name.
      if (response['valid'] == true &&
          response['role'] == 'user') {
        final name = response['full_name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          setState(() {
            _userName = name;
          });
        }
      }
    } catch (e) {
      debugPrint('HOME USER NAME ERROR: $e');
    }
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // ==================================================
  // NAVIGATION
  // ==================================================

  // Each footer destination is opened as its own route.
  // Keep Home as the first route so the Home tab can return to it.
  void _openTab(int index) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    final Widget page;

    switch (index) {
      case 1:
        page = const Outfits();
        break;
      case 2:
        page = UserRentals(
          onBackToHome: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        );
        break;
      case 3:
        page = const UserCartPage();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
          (route) => route.isFirst,
    );
  }

  void _openRentals() => _openTab(2);

  void _openMyOutfits() => _openTab(1);

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttirelySearchPage(logic: logic),
      ),
    );
  }

  void _openAddresses() {
    Navigator.pushNamed(context, AppRoutes.addressList);
  }

  // ==================================================
  // HOME PAGE
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: burgundy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white, // Fallback if image fails
            image: DecorationImage(
              image: AssetImage('assets/background/app_bg.png'),
              fit: BoxFit.cover,
              onError: null,
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: AnimatedBuilder(
                    animation: logic,
                    builder: (context, _) {
                      return RefreshIndicator(
                        color: burgundy,
                        onRefresh: logic.loadCatalogue,
                        child: SingleChildScrollView(
                          physics:
                          const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroZone(),

                              const SizedBox(height: 25),

                              const CategoriesSection(),

                              const SizedBox(height: 28),

                              FeaturedOutfitsSection(
                                outfits: logic.featuredOutfits,
                                isLoading: logic.isLoadingCatalogue,
                                error: logic.catalogueError,
                                onRetry: logic.loadCatalogue,
                                onViewMore: _openRentals,
                              ),
                              const SizedBox(height: 28),

                              FeaturedAccessories(
                                accessories: logic.featuredAccessories,
                                isLoading: logic.isLoadingAccessories,
                                error: logic.accessoriesError,
                                onRetry: logic.loadCatalogue,
                              ),

                              const SizedBox(height: 30),

                              const WhyRentSection(),

                              const SizedBox(height: 30),

                              _buildManageOutfitsBanner(),

                              // Small breathing space at the end of the scroll content.
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: UserBottomNavigation(
          currentIndex: 0,
          onTap: _openTab,
        ),
      ),
    );
  }

  // ==================================================
  // GRADIENT HEADER
  // ==================================================

  Widget _buildHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        statusBarHeight + 10,
        12,
        10,
      ),
      decoration: const BoxDecoration(
        gradient: topGradient,
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withOpacity(0.75),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: gold,
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Text(
                //   'WELCOME BACK,',
                //   style: TextStyle(
                //     color: Colors.white70,
                //     fontSize: 10,
                //     fontWeight: FontWeight.w700,
                //     letterSpacing: 1.3,
                //   ),
                // ),
                //
                // const SizedBox(height: 3),

                // DYNAMIC USER NAME
                Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                // LIVE DEVICE LOCATION + MANAGE ADDRESSES
                GestureDetector(
                  onTap: _openAddresses,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _currentLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              // Connect notification page later.
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),

          Container(
            height: 25,
            width: 1,
            color: Colors.white.withOpacity(0.25),
          ),

          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
            icon: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // SEARCH LAUNCHER + PROMOTIONAL SLIDER
  // ==================================================

  Widget _buildHeroZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 9, 19, 24),
      decoration: const BoxDecoration(
        gradient: topGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // TAPPABLE SEARCH LAUNCHER
          Material(
            color: cream,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 49,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: gold,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkBurgundy.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: burgundy,
                      size: 23,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Search dresses, styles and more...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: burgundy.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 19),

          HomePromoSlider(
            onExploreRentals: _openRentals,
          ),
        ],
      ),
    );
  }

  // ==================================================
  // MANAGE YOUR OUTFITS
  // ==================================================

  Widget _buildManageOutfitsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: burgundy,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _openMyOutfits,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: topGradient,
              border: Border.all(
                color: gold,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have outfits to share?',
                        style: TextStyle(
                          color: gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'List your outfits, earn effortlessly, '
                            'and give them a new occasion.',
                        style: TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My Outfits',
                              style: TextStyle(
                                color: burgundy,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: burgundy,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  height: 75,
                  width: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: gold.withOpacity(0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    color: gold,
                    size: 39,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



//
// import 'package:attirely/Common_Screens/API_Routes/auth_api_routes.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../../app_routes.dart';
// import '../../Common_Screens/session_manager.dart';
//
// import '../U_Ui_Logic/home_logic.dart';
// import '../WIdgets/Home/categories_section.dart';
// import '../WIdgets/Home/featured_accessories.dart';
// import '../WIdgets/Home/featured_outfits_section.dart';
// import '../WIdgets/Home/home_promo_slider.dart';
// import '../WIdgets/Home/why_rent_section.dart';
// import 'attirely_search_page.dart';
//
// class HomePage extends StatefulWidget {
//   final ValueChanged<int>? onOpenTab;
//
//   const HomePage({
//     super.key,
//     this.onOpenTab,
//   });
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   late final HomeLogic logic;
//
//   String _userName = 'Attirely Member';
//
//   static const Color burgundy = Color(0xFF8E2945);
//   static const Color darkBurgundy = Color(0xFF4C1026);
//   static const Color gold = Color(0xFFE9D8B0);
//   static const Color cream = Color(0xFFFFFCF8);
//
//   static const LinearGradient topGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [
//       Color(0xFF4C1026),
//       Color(0xFF64172F),
//       Color(0xFF4C1026),
//     ],
//   );
//
//   @override
//   void initState() {
//     super.initState();
//
//     logic = HomeLogic();
//
//     logic.loadCatalogue();
//
//     _loadUserName();
//   }
//
//   // ==================================================
//   // LOAD LOGGED-IN USER NAME
//   // ==================================================
//
//   Future<void> _loadUserName() async {
//     try {
//       // Get saved access token.
//       String? token = SessionManager.getToken();
//
//       // If not available in memory, load from SharedPreferences.
//       token ??= await SessionManager.loadToken();
//
//       if (token == null || token.isEmpty) {
//         debugPrint('HOME: Access token not found');
//         return;
//       }
//
//       // Call existing backend /auth/session endpoint.
//       final response = await AuthApiRoutes.validateSession(
//         accessToken: token,
//       );
//
//       if (!mounted) return;
//
//       // Only use the normal user's full_name.
//       if (response['valid'] == true &&
//           response['role'] == 'user') {
//         final name = response['full_name']?.toString().trim();
//
//         if (name != null && name.isNotEmpty) {
//           setState(() {
//             _userName = name;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('HOME USER NAME ERROR: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     logic.dispose();
//     super.dispose();
//   }
//
//   // ==================================================
//   // NAVIGATION
//   // ==================================================
//
//   void _openRentals() {
//     Navigator.pushNamed(context, AppRoutes.userRentals);
//   }
//
//   void _openMyOutfits() {
//     Navigator.pushNamed(context, AppRoutes.userOutfits);
//   }
//
//   void _openSearch() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => AttirelySearchPage(logic: logic),
//       ),
//     );
//   }
//
//   void _showLocationMessage() {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         const SnackBar(
//           content: Text('Location feature coming soon.'),
//           backgroundColor: burgundy,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }
//
//   // ==================================================
//   // HOME PAGE
//   // ==================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: burgundy,
//         statusBarIconBrightness: Brightness.light,
//         statusBarBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: const BoxDecoration(
//             color: Colors.white, // Fallback if image fails
//             image: DecorationImage(
//               image: AssetImage('assets/background/login_bg.png'),
//               fit: BoxFit.cover,
//               onError: null,
//             ),
//           ),
//           child: SafeArea(
//           top: false,
//           bottom: false,
//           child: Column(
//             children: [
//               _buildHeader(),
//
//               Expanded(
//                 child: AnimatedBuilder(
//                   animation: logic,
//                   builder: (context, _) {
//                     return RefreshIndicator(
//                       color: burgundy,
//                       onRefresh: logic.loadCatalogue,
//                       child: SingleChildScrollView(
//                         physics:
//                         const AlwaysScrollableScrollPhysics(),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildHeroZone(),
//
//                             const SizedBox(height: 25),
//
//                             const CategoriesSection(),
//
//                             const SizedBox(height: 28),
//
//                             FeaturedOutfitsSection(
//                               outfits: logic.featuredOutfits,
//                               isLoading: logic.isLoadingCatalogue,
//                               error: logic.catalogueError,
//                               onRetry: logic.loadCatalogue,
//                               onViewMore: _openRentals,
//                             ),
//                             const SizedBox(height: 28),
//
//                             FeaturedAccessories(
//                               accessories: logic.featuredAccessories,
//                               isLoading: logic.isLoadingAccessories,
//                               error: logic.accessoriesError,
//                               onRetry: logic.loadCatalogue,
//                             ),
//
//                             const SizedBox(height: 30),
//
//                             const WhyRentSection(),
//
//                             const SizedBox(height: 30),
//
//                             _buildManageOutfitsBanner(),
//
//                             // Space for floating bottom navigation.
//                             const SizedBox(height: 125),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//         ),
//
//       ),
//     );
//   }
//
//   // ==================================================
//   // GRADIENT HEADER
//   // ==================================================
//
//   Widget _buildHeader() {
//     final statusBarHeight = MediaQuery.of(context).padding.top;
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.fromLTRB(
//         20,
//         statusBarHeight + 10,
//         12,
//         10,
//       ),
//       decoration: const BoxDecoration(
//         gradient: topGradient,
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 42,
//             width: 42,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.12),
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: gold.withOpacity(0.75),
//               ),
//             ),
//             child: const Icon(
//               Icons.auto_awesome_rounded,
//               color: gold,
//               size: 22,
//             ),
//           ),
//
//           const SizedBox(width: 11),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // const Text(
//                 //   'WELCOME BACK,',
//                 //   style: TextStyle(
//                 //     color: Colors.white70,
//                 //     fontSize: 10,
//                 //     fontWeight: FontWeight.w700,
//                 //     letterSpacing: 1.3,
//                 //   ),
//                 // ),
//                 //
//                 // const SizedBox(height: 3),
//
//                 // DYNAMIC USER NAME
//                 Text(
//                   _userName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 // LOCATION - TEMPORARY CLICK ACTION
//                 GestureDetector(
//                   onTap: _showLocationMessage,
//                   behavior: HitTestBehavior.opaque,
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.location_on_outlined,
//                         color: Colors.white70,
//                         size: 13,
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         'Kurnool, AP',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Icon(
//                         Icons.keyboard_arrow_down_rounded,
//                         color: Colors.white70,
//                         size: 16,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           IconButton(
//             tooltip: 'Notifications',
//             onPressed: () {
//               // Connect notification page later.
//             },
//             icon: const Icon(
//               Icons.notifications_none_rounded,
//               color: Colors.white,
//               size: 26,
//             ),
//           ),
//
//           Container(
//             height: 25,
//             width: 1,
//             color: Colors.white.withOpacity(0.25),
//           ),
//
//           IconButton(
//             tooltip: 'Profile',
//             onPressed: () {
//               Navigator.pushNamed(context, AppRoutes.profile);
//             },
//             icon: const Icon(
//               Icons.person_outline_rounded,
//               color: Colors.white,
//               size: 26,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================================================
//   // SEARCH LAUNCHER + PROMOTIONAL SLIDER
//   // ==================================================
//
//   Widget _buildHeroZone() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(19, 9, 19, 24),
//       decoration: const BoxDecoration(
//         gradient: topGradient,
//         borderRadius: BorderRadius.vertical(
//           bottom: Radius.circular(28),
//         ),
//       ),
//       child: Column(
//         children: [
//           // TAPPABLE SEARCH LAUNCHER
//           Material(
//             color: cream,
//             borderRadius: BorderRadius.circular(30),
//             child: InkWell(
//               onTap: _openSearch,
//               borderRadius: BorderRadius.circular(30),
//               child: Container(
//                 height: 49,
//                 padding: const EdgeInsets.symmetric(horizontal: 17),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   border: Border.all(
//                     color: gold,
//                     width: 1,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: darkBurgundy.withOpacity(0.10),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.search_rounded,
//                       color: burgundy,
//                       size: 23,
//                     ),
//                     const SizedBox(width: 13),
//                     Expanded(
//                       child: Text(
//                         'Search dresses, styles and more...',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: burgundy.withOpacity(0.55),
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 19),
//
//           HomePromoSlider(
//             onExploreRentals: _openRentals,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================================================
//   // MANAGE YOUR OUTFITS
//   // ==================================================
//
//   Widget _buildManageOutfitsBanner() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Material(
//         color: burgundy,
//         borderRadius: BorderRadius.circular(22),
//         child: InkWell(
//           onTap: _openMyOutfits,
//           borderRadius: BorderRadius.circular(22),
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(19),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(22),
//               gradient: topGradient,
//               border: Border.all(
//                 color: gold,
//                 width: 1.2,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Have outfits to share?',
//                         style: TextStyle(
//                           color: gold,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       const Text(
//                         'List your outfits, earn effortlessly, '
//                             'and give them a new occasion.',
//                         style: TextStyle(
//                           color: Color(0xE6FFFFFF),
//                           fontSize: 11,
//                           height: 1.4,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 15,
//                           vertical: 9,
//                         ),
//                         decoration: BoxDecoration(
//                           color: gold,
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                         child: const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               'My Outfits',
//                               style: TextStyle(
//                                 color: burgundy,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                             SizedBox(width: 7),
//                             Icon(
//                               Icons.arrow_forward_rounded,
//                               color: burgundy,
//                               size: 15,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(width: 10),
//
//                 Container(
//                   height: 75,
//                   width: 65,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(17),
//                     border: Border.all(
//                       color: gold.withOpacity(0.6),
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.checkroom_rounded,
//                     color: gold,
//                     size: 39,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
