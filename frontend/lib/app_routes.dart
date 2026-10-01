import 'package:flutter/material.dart';

import 'Common_Screens/UI/login.dart';
import 'Common_Screens/UI/register.dart';
import 'User/U_Ui/home.dart';
import 'Vendor/V_Ui/vendor_add_outfit.dart';
import 'Vendor/V_Ui/vendor_dashboard.dart';
import 'Vendor/V_Ui/vendor_register.dart';
import 'User/U_Ui/profile.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String vendorRegister = '/vendor-register';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String vendorAddOutfit = '/vendor-add-outfit';
  static const String profile = '/profile';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const HomePage(),
    vendorRegister: (context) => const VendorRegisterPage(),
    vendorDashboard: (context) => const VendorDashboardPage(),
    vendorAddOutfit: (context) => const VendorAddOutfitPage(),
    profile: (context) => const ProfilePage(),

  };
}