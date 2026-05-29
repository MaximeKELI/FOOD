import 'api_client.dart';

class Conversation {
  Conversation({
    required this.id,
    required this.otherId,
    required this.otherName,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
  });

  final int id;
  final int otherId;
  final String otherName;
  final String lastMessage;
  final int unread;
  final String updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        otherId: json['other_id'] as int? ?? 0,
        otherName: json['other_name'] as String? ?? '',
        lastMessage: json['last_message'] as String? ?? '',
        unread: json['unread'] as int? ?? 0,
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final int sender;
  final String text;
  final String createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        sender: json['sender'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class ChatApi {
  ChatApi._();
  static final ChatApi instance = ChatApi._();

  final _dio = ApiClient.instance.dio;

  Future<List<Conversation>> fetchConversations() async {
    final res = await _dio.get('/chat/conversations/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> startWith(int userId) async {
    final res = await _dio.post(
      '/chat/conversations/start/',
      data: {'user': userId},
    );
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> fetchMessages(int conversationId) async {
    final res = await _dio.get('/chat/conversations/$conversationId/messages/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(int conversationId, String text) async {
    final res = await _dio.post(
      '/chat/conversations/$conversationId/messages/',
      data: {'text': text},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> unreadCount() async {
    final res = await _dio.get('/chat/unread/');
    return res.data['unread'] as int? ?? 0;
  }
}
