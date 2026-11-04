//
// import 'package:flutter/material.dart';
//
// Route<T> createFadeRoute<T>(Widget page) {
//   return PageRouteBuilder<T>(
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return page;
//     },
//
//     transitionDuration: const Duration(milliseconds: 1800),
//     reverseTransitionDuration: const Duration(milliseconds: 1400),
//
//     transitionsBuilder:
//         (context, animation, secondaryAnimation, child) {
//
//       final fade = CurvedAnimation(
//         parent: animation,
//         curve: Curves.easeInOutCubic,
//       );
//
//       return FadeTransition(
//         opacity: fade,
//         child: child,
//       );
//     },
//   );
// }

import 'package:flutter/material.dart';

Route<T> createFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,

    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },

    transitionDuration: const Duration(milliseconds: 1800),
    reverseTransitionDuration: const Duration(milliseconds: 1400),

    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
        child: child,
      );
    },
  );
}
