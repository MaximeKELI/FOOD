import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';

/// Seller UI to list / create / delete option groups on a meal.
Future<void> showMealOptionsEditor(
  BuildContext context,
  Meal meal,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MealOptionsEditor(meal: meal),
  );
}

class _MealOptionsEditor extends StatefulWidget {
  const _MealOptionsEditor({required this.meal});
  final Meal meal;

  @override
  State<_MealOptionsEditor> createState() => _MealOptionsEditorState();
}

class _MealOptionsEditorState extends State<_MealOptionsEditor> {
  List<MealOptionGroup> _groups = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _groups = List.of(widget.meal.optionGroups);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups =
          await CatalogApi.instance.fetchMealOptions(widget.meal.id);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _addGroup() async {
    final nameCtrl = TextEditingController();
    final choiceCtrl = TextEditingController();
    final extraCtrl = TextEditingController(text: '0');
    var required = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(tr('meal.optionsAddGroup')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr('meal.optionsGroupName'),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: choiceCtrl,
                  decoration: InputDecoration(
                    labelText: tr('meal.optionsChoiceName'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: extraCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: tr('meal.optionsChoiceExtra'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: required,
                  onChanged: (v) => setLocal(() => required = v),
                  title: Text(tr('meal.optionsRequiredToggle')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('action.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('action.save')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    final choice = choiceCtrl.text.trim();
    if (name.isEmpty || choice.isEmpty) return;
    final extra = int.tryParse(extraCtrl.text.trim()) ?? 0;
    setState(() => _busy = true);
    try {
      await CatalogApi.instance.createMealOptionGroup(
        widget.meal.id,
        name: name,
        required: required,
        minSelect: required ? 1 : 0,
        maxSelect: 1,
        choices: [
          {'name': choice, 'price_extra': extra},
        ],
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteGroup(MealOptionGroup g) async {
    setState(() => _busy = true);
    try {
      await CatalogApi.instance.deleteMealOptionGroup(widget.meal.id, g.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            trf('meal.optionsManageTitle', {'name': widget.meal.name}),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red))
          else if (_groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                tr('meal.optionsEmpty'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _groups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final g = _groups[i];
                  final choices = g.choices
                      .map((c) => c.priceExtra > 0
                          ? '${c.name} (+${c.priceExtra})'
                          : c.name)
                      .join(', ');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      g.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      choices.isEmpty ? tr('meal.optionsNoChoices') : choices,
                    ),
                    trailing: IconButton(
                      tooltip: tr('action.delete'),
                      onPressed: _busy ? null : () => _deleteGroup(g),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _addGroup,
            style: FilledButton.styleFrom(
              backgroundColor: ChezMamaTheme.brandOrange,
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('meal.optionsAddGroup')),
          ),
        ],
      ),
    );
  }
}
