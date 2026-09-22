import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Common_Screens/UI/splash_screen.dart';
import 'app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const AttirelyApp());
}

class AttirelyApp extends StatelessWidget {
  const AttirelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attirely',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),

      home: const SplashScreen(),

      routes: AppRoutes.routes,
    );
  }
}