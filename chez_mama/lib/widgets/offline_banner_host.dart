import 'package:flutter/material.dart';

import '../services/api_reachability_service.dart';
import '../services/connectivity_service.dart';
import '../ui/chezmama_theme.dart';
import '../l10n/app_strings.dart';

/// Overlays a persistent strip when offline or when the API is unreachable.
class OfflineBannerHost extends StatelessWidget {
  const OfflineBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ConnectivityService.instance,
        ApiReachabilityService.instance,
      ]),
      builder: (context, _) {
        final offline = !ConnectivityService.instance.isOnline;
        final apiDown = !ApiReachabilityService.instance.reachable;
        final show = offline || apiDown;
        final message = offline
            ? tr('app.offlineBanner')
            : tr('error.apiUnreachableBanner');
        final icon = offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded;

        return Stack(
          children: [
            child,
            AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset: show ? Offset.zero : const Offset(0, -1),
              child: Material(
                color: offline
                    ? ChezMamaTheme.brandBrown
                    : ChezMamaTheme.brandOrange,
                elevation: 2,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ChezMamaTheme.spaceMd,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (apiDown && !offline)
                          TextButton(
                            onPressed: ApiReachabilityService.instance.check,
                            child: Text(
                              tr('action.retry'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
