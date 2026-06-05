import 'api_client.dart';

class AnalyticsApi {
  AnalyticsApi._();
  static final AnalyticsApi instance = AnalyticsApi._();

  final _dio = ApiClient.instance.dio;

  Future<void> trackEvent({
    required String name,
    String? screen,
    String? element,
    String? meta,
    Map<String, dynamic>? context,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (screen != null) 'screen': screen,
      if (element != null) 'element': element,
      if (meta != null) 'meta': meta,
      ...?context,
    };
    await _dio.post('/analytics/events/', data: data);
  }

  Future<void> trackBatch({
    required List<Map<String, dynamic>> events,
    Map<String, dynamic>? context,
    String? sessionId,
  }) async {
    await _dio.post('/analytics/events/batch/', data: {
      if (sessionId != null) 'session_id': sessionId,
      if (context != null) 'context': context,
      'events': events,
    });
  }

  Future<void> trackEngagement({
    required String contentType,
    required int contentId,
    required String contentTitle,
    required int durationSeconds,
    Map<String, dynamic>? context,
  }) async {
    await _dio.post('/analytics/engagement/', data: {
      'content_type': contentType,
      'content_id': contentId,
      'content_title': contentTitle,
      'duration_seconds': durationSeconds,
      ...?context,
    });
  }

  Future<void> trackEngagementBatch({
    required List<Map<String, dynamic>> engagements,
    Map<String, dynamic>? context,
    String? sessionId,
  }) async {
    await _dio.post('/analytics/engagement/batch/', data: {
      if (sessionId != null) 'session_id': sessionId,
      if (context != null) 'context': context,
      'engagements': engagements,
    });
  }
}
