import 'package:flutter/material.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    RouteSettings? settings,
    AppTransition transition = AppTransition.fadeUp,
  }) : super(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            switch (transition) {
              case AppTransition.slide:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(curve),
                  child: FadeTransition(opacity: curve, child: child),
                );
              case AppTransition.fadeUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(curve),
                  child: FadeTransition(opacity: curve, child: child),
                );
              case AppTransition.fade:
                return FadeTransition(opacity: curve, child: child);
            }
          },
        );
}

enum AppTransition { fadeUp, slide, fade }

