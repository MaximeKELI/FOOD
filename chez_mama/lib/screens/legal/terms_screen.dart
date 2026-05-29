import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('legal.termsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr('legal.termsTitle'), style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(tr('legal.termsBody'), style: t.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
