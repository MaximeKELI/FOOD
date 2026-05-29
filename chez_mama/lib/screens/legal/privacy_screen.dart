import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('legal.privacyTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr('legal.privacyTitle'), style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(tr('legal.privacyBody'), style: t.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
