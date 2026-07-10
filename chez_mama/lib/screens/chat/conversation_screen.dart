import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/chat_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../services/socket_service.dart';
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
  Timer? _typingDebounce;
  bool _sending = false;
  bool _otherTyping = false;
  bool _socketBound = false;

  void Function(dynamic)? _onMessage;
  void Function(dynamic)? _onTyping;
  void Function(dynamic)? _onRead;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _typingDebounce?.cancel();
    _unbindSocket();
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_conversationId == null) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 400), () {
      SocketService.instance.emit('chat:typing', {
        'conversation_id': _conversationId,
        'is_typing': _input.text.trim().isNotEmpty,
      });
    });
  }

  void _bindSocket() {
    if (_conversationId == null || _socketBound) return;
    final sock = SocketService.instance;
    sock.join(['conversation:$_conversationId']);

    _onMessage = (data) {
      if (!mounted || data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final convoId = map['conversation_id'] as int? ??
          map['conversation'] as int?;
      if (convoId != null && convoId != _conversationId) return;
      final msg = ChatMessage.fromJson(map);
      if (_messages.any((m) => m.id == msg.id && msg.id != 0)) return;
      setState(() => _messages = [..._messages, msg]);
      _jumpToBottom();
    };
    _onTyping = (data) {
      if (!mounted || data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final convoId = map['conversation_id'] as int?;
      if (convoId != null && convoId != _conversationId) return;
      final me = AuthScope.of(context).userId;
      final uid = map['user_id'] as int?;
      if (uid != null && uid == me) return;
      setState(() => _otherTyping = map['is_typing'] == true);
    };
    _onRead = (data) {
      if (!mounted || data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final convoId = map['conversation_id'] as int?;
      if (convoId != null && convoId != _conversationId) return;
      final messageId = map['message_id'] as int?;
      setState(() {
        for (final m in _messages) {
          if (messageId == null || m.id == messageId) {
            m.isRead = true;
          }
        }
      });
    };

    sock.on(SocketService.eventChatMessage, _onMessage!);
    sock.on(SocketService.eventChatTyping, _onTyping!);
    sock.on(SocketService.eventChatRead, _onRead!);
    _socketBound = true;

    // Fallback poll only when socket is not connected.
    _poll?.cancel();
    if (!sock.isConnected) {
      _poll = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _load(silent: true),
      );
    }
  }

  void _unbindSocket() {
    if (!_socketBound) return;
    final sock = SocketService.instance;
    if (_onMessage != null) {
      sock.off(SocketService.eventChatMessage, _onMessage);
    }
    if (_onTyping != null) {
      sock.off(SocketService.eventChatTyping, _onTyping);
    }
    if (_onRead != null) {
      sock.off(SocketService.eventChatRead, _onRead);
    }
    _socketBound = false;
  }

  Future<void> _bootstrap() async {
    try {
      if (_conversationId == null && widget.otherUserId != null) {
        final convo = await ChatApi.instance.startWith(widget.otherUserId!);
        _conversationId = convo.id;
      }
      await _load();
      _bindSocket();
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
    SocketService.instance.emit('chat:typing', {
      'conversation_id': _conversationId,
      'is_typing': false,
    });
    try {
      final msg = await ChatApi.instance.sendMessage(_conversationId!, text);
      if (!mounted) return;
      if (!_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages = [..._messages, msg]);
      }
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
        title: Text(
          widget.otherName.isEmpty ? tr('chat.threadTitle') : widget.otherName,
        ),
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
                              tr('chat.startConversation'),
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
                              return _Bubble(
                                text: m.text,
                                mine: m.sender == me,
                                isRead: m.isRead,
                              );
                            },
                          ),
          ),
          if (_otherTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('chat.typing'),
                  style: TextStyle(
                    color: ChezMamaTheme.mutedInk(context),
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
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
                      decoration: InputDecoration(
                        hintText: tr('chat.hint'),
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
  const _Bubble({
    required this.text,
    required this.mine,
    this.isRead = false,
  });
  final String text;
  final bool mine;
  final bool isRead;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : ChezMamaTheme.inkColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (mine) ...[
              const SizedBox(height: 2),
              Icon(
                isRead ? Icons.done_all_rounded : Icons.done_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
