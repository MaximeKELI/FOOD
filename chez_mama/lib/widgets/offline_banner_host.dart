import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/connectivity_service.dart';
import '../ui/chezmama_theme.dart';

/// Wraps the app and shows a persistent offline strip when disconnected.
class OfflineBannerHost extends StatelessWidget {
  const OfflineBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityService.instance,
      builder: (context, _) {
        final offline = !ConnectivityService.instance.isOnline;
        return Column(
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              crossFadeState:
                  offline ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Material(
                color: ChezMamaTheme.brandBrown,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ChezMamaTheme.spaceMd,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('app.offlineBanner'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
