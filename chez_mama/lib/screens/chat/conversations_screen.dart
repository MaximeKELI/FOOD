import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/chat_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';
import 'conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _items = [];
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
      final items = await ChatApi.instance.fetchConversations();
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
      appBar: AppBar(title: Text(tr('chat.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListLoadingSkeleton(itemCount: 6, imageHeight: 64);
    }
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
        icon: Icons.forum_outlined,
        lottieAsset: LottieAssets.empty,
        title: tr('chat.empty'),
        subtitle: tr('chat.emptyHint'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = _items[i];
          return FadeInUp(
            index: i,
            child: Container(
              decoration: BoxDecoration(
                color: ChezMamaTheme.cardColor(context),
                borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      ChezMamaTheme.brandOrange.withValues(alpha: 0.15),
                  child: Text(
                    c.otherName.isEmpty ? '?' : c.otherName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ChezMamaTheme.brandBrown,
                    ),
                  ),
                ),
                title: Text(
                  c.otherName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: c.unread > 0
                    ? Badge.count(count: c.unread)
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        conversationId: c.id,
                        otherName: c.otherName,
                      ),
                    ),
                  );
                  _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
