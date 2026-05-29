import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// Compact +/- quantity control for cart rows.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ChezMamaTheme.subtleSurface(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rField),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onPressed: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ChezMamaTheme.rField),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: ChezMamaTheme.brandBrown),
        ),
      ),
    );
  }
}
