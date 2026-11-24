import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';

/// Page with 220ms fade + 6px rise. Instant when reduced motion.
CustomTransitionPage<void> fadeRisePage({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.screenEnter,
    reverseTransitionDuration: Motion.screenEnter,
    transitionsBuilder: (context, animation, secondary, child) {
      if (reduceMotion(context)) return child;
      final a = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: a,
        child: AnimatedBuilder(
          animation: a,
          builder: (context, c) => Transform.translate(offset: Offset(0, 6 * (1 - a.value)), child: c),
          child: child,
        ),
      );
    },
  );
}
