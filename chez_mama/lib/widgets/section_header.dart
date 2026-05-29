import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// Section title with optional trailing action, used in sheets and forms.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ChezMamaTheme.spaceSm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: ChezMamaTheme.brandOrange),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: ChezMamaTheme.sectionTitle(t, context)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
