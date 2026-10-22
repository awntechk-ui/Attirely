import 'package:flutter/material.dart';

class VendorRequests extends StatelessWidget {
  const VendorRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                'Requests',
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
                  'No requests yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}