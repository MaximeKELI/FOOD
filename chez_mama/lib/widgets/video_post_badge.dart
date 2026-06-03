import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Small pill indicating the post is a video (feed preview).
class VideoPostBadge extends StatelessWidget {
  const VideoPostBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: 14,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.play_arrow_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: 16,
          ),
          const SizedBox(width: 2),
          Text(
            tr('social.videoBadge'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
