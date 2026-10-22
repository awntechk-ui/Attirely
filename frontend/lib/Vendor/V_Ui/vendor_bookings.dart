import 'package:flutter/material.dart';

class VendorBookings extends StatelessWidget {
  const VendorBookings({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                10,
              ),
              child: Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF800020),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
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