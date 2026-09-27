import 'package:flutter/material.dart';

class VendorDashboardPage extends StatelessWidget {
  const VendorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Vendor Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}