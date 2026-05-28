import 'package:flutter/material.dart';
import 'event_tracker.dart';

class TrackedTap extends StatelessWidget {
  const TrackedTap({
    super.key,
    required this.event,
    required this.child,
    this.onTap,
    this.screen,
    this.element,
    this.meta,
  });

  final String event;
  final String? screen;
  final String? element;
  final String? meta;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        EventTracker.instance.track(
          event,
          screen: screen,
          element: element,
          meta: meta,
        );
        onTap?.call();
      },
      child: child,
    );
  }
}

class TrackedNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name ?? route.runtimeType.toString();
    EventTracker.instance.track('screen_view', screen: name);
    super.didPush(route, previousRoute);
  }
}

