import 'package:flutter/material.dart';

import 'Common_Screens/UI/add_outfit.dart';
import 'Common_Screens/UI/login.dart';
import 'Common_Screens/UI/register.dart';
import 'User/U_Ui/user_cart.dart';
import 'User/U_Ui/home.dart';
import 'User/U_Ui/user_main.dart';
import 'User/U_Ui/u_myoutfits.dart';
import 'User/U_Ui/user_rentals.dart';
import 'Vendor/V_Ui/vendor_dashboard.dart';
import 'Vendor/V_Ui/vendor_main.dart';
import 'Vendor/V_Ui/vendor_profile.dart';
import 'Vendor/V_Ui/vendor_register.dart';
import 'User/U_Ui/profile.dart';



class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String userMain = '/user-main';
  static const String home = '/home';
  static const String userOutfits = "/user-outifts";
  static const String vendorRegister = '/vendor-register';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String addOutfit = '/add-outfit';
  static const String profile = '/profile';
  static const String vendorProfile = '/vendor-profile';
  static const String vendorMain = '/vendor-main';

  static const String userRentals = '/user-rentals';
  static const String userCart = '/user-cart';


  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    userMain: (context) => const UserMain(),
    home: (context) => const HomePage(),

    userOutfits: (context) => const UserOutfits(),
    vendorMain: (context) => VendorMain(),
    vendorRegister: (context) => const VendorRegisterPage(),
    vendorDashboard: (context) => const VendorDashboard(),
    addOutfit: (context) => const AddOutfit(),
    profile: (context) => const ProfilePage(),
    vendorProfile: (context) => const VendorProfile(),

    userRentals: (context) => const UserRentals(),
    userCart: (context) => const UserCartPage(),

  };
}