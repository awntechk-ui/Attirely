
import 'package:flutter/material.dart';

Route<T> createZoomFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },

    transitionDuration: const Duration(milliseconds: 1800),
    reverseTransitionDuration: const Duration(milliseconds: 1400),

    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );

      final scale = Tween<double>(
        begin: 0.70,
        end: 1.0,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
      );
    },
  );
}
