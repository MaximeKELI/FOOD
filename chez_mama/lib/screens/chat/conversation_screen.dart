import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/chat_api.dart';
import '../../auth/auth_scope.dart';
import '../../ui/chezmama_theme.dart';

/// A 1:1 chat thread. Either [conversationId] or [otherUserId] must be given.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    this.conversationId,
    this.otherUserId,
    this.otherName = '',
  });

  final int? conversationId;
  final int? otherUserId;
  final String otherName;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  int? _conversationId;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _bootstrap();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      if (_conversationId == null && widget.otherUserId != null) {
        final convo = await ChatApi.instance.startWith(widget.otherUserId!);
        _conversationId = convo.id;
      }
      await _load();
      _poll = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _load(silent: true),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (_conversationId == null) return;
    try {
      final msgs = await ChatApi.instance.fetchMessages(_conversationId!);
      if (!mounted) return;
      final wasAtBottom = !_scroll.hasClients ||
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40;
      setState(() {
        _messages = msgs;
        _loading = false;
        _error = null;
      });
      if (wasAtBottom) _jumpToBottom();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _conversationId == null || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final msg = await ChatApi.instance.sendMessage(_conversationId!, text);
      if (!mounted) return;
      setState(() => _messages = [..._messages, msg]);
      _jumpToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthScope.of(context).userId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName.isEmpty ? 'Discussion' : widget.otherName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Démarre la conversation 👋',
                              style: TextStyle(
                                color: ChezMamaTheme.mutedInk(context),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(14),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              return _Bubble(text: m.text, mine: m.sender == me);
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _send,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine
              ? ChezMamaTheme.brandOrange
              : ChezMamaTheme.cardColor(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? Colors.white : ChezMamaTheme.inkColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
