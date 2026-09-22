import 'package:flutter/material.dart';

import 'Common_Screens/UI/login.dart';
import 'Common_Screens/UI/register.dart';
import 'User/U_Ui/home.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const HomePage(),
  };
}