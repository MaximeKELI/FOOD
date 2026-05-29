import 'api_client.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NotificationsApi {
  NotificationsApi._();
  static final NotificationsApi instance = NotificationsApi._();

  final _dio = ApiClient.instance.dio;

  Future<({int unread, List<AppNotification> items})> fetch() async {
    final res = await _dio.get('/notifications/');
    final data = res.data as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    return (
      unread: data['unread'] as int? ?? 0,
      items: results
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read/');
  }
}
