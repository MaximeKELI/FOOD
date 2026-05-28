import 'package:flutter/material.dart';
import 'social_feed_screen.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialFeedScreen(initialTab: SocialTab.shorts);
  }
}

