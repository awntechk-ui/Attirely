
import 'package:flutter/material.dart';

Route<T> createSlideFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },

    transitionDuration: const Duration(milliseconds: 2000),
    reverseTransitionDuration: const Duration(milliseconds: 1600),

    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.35),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}
