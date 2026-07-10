import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';

/// Bottom sheet to pick meal option choices before adding to cart.
/// Returns `null` if cancelled, otherwise `{ids: List<int>, extra: int}`.
Future<Map<String, dynamic>?> showMealOptionsSheet(
  BuildContext context,
  Meal meal,
) async {
  if (meal.optionGroups.isEmpty) {
    return {'ids': <int>[], 'extra': 0};
  }

  final selected = <int>{};
  for (final g in meal.optionGroups) {
    if (g.required && g.choices.isNotEmpty) {
      selected.add(g.choices.first.id);
    }
  }

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          int extra = 0;
          for (final g in meal.optionGroups) {
            for (final c in g.choices) {
              if (selected.contains(c.id)) extra += c.priceExtra;
            }
          }

          String? validation;
          for (final g in meal.optionGroups) {
            final count =
                g.choices.where((c) => selected.contains(c.id)).length;
            if (g.required && count < (g.minSelect == 0 ? 1 : g.minSelect)) {
              validation = trf('meal.optionsRequired', {'name': g.name});
              break;
            }
            if (count > g.maxSelect) {
              validation = trf('meal.optionsMax', {'name': g.name});
              break;
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    meal.name,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final g in meal.optionGroups) ...[
                          Text(
                            '${g.name}${g.required ? ' *' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          for (final c in g.choices.where((c) => c.isAvailable))
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.name),
                              subtitle: c.priceExtra > 0
                                  ? Text('+ ${c.priceExtra} F')
                                  : null,
                              value: selected.contains(c.id),
                              activeColor: ChezMamaTheme.brandBrown,
                              onChanged: (v) {
                                setLocal(() {
                                  if (v == true) {
                                    if (g.maxSelect <= 1) {
                                      for (final other in g.choices) {
                                        selected.remove(other.id);
                                      }
                                    }
                                    selected.add(c.id);
                                  } else {
                                    selected.remove(c.id);
                                  }
                                });
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  if (validation != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        validation,
                        style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                      ),
                    ),
                  FilledButton(
                    onPressed: validation != null
                        ? null
                        : () => Navigator.pop(ctx, {
                              'ids': selected.toList(),
                              'extra': extra,
                            }),
                    child: Text(
                      '${tr('action.addToCart')}${extra > 0 ? ' (+$extra F)' : ''}',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
