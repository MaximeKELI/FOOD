import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<FaqEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await SupportApi.instance.fetchFaq();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('faq.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton();
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        icon: Icons.help_outline_rounded,
        title: tr('faq.empty'),
        subtitle: tr('faq.emptyHint'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final f = _items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text(
                f.question,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: f.category.isEmpty
                  ? null
                  : Text(
                      f.category,
                      style: TextStyle(
                        color: ChezMamaTheme.mutedInk(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(f.answer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
