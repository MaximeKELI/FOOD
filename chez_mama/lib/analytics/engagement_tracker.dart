import 'package:flutter/widgets.dart';

import '../api/analytics_api.dart';
import 'device_context.dart';

/// Tracks time spent viewing meals, videos and shorts.
class EngagementTracker {
  EngagementTracker._();

  static final EngagementTracker instance = EngagementTracker._();

  final List<Map<String, dynamic>> _pending = [];
  bool _syncing = false;

  Future<void> track({
    required String contentType,
    required int contentId,
    required String contentTitle,
    required int durationSeconds,
  }) async {
    if (durationSeconds < 1) return;
    _pending.add({
      'content_type': contentType,
      'content_id': contentId,
      'content_title': contentTitle,
      'duration_seconds': durationSeconds.clamp(1, 86400),
    });
    if (_pending.length >= 3) {
      await flush();
    } else {
      Future.delayed(const Duration(seconds: 2), flush);
    }
  }

  Future<void> flush() async {
    if (_syncing || _pending.isEmpty) return;
    _syncing = true;
    final batch = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();
    try {
      final context = await DeviceContext.instance.collect();
      final sid = context['session_id'] as String?;
      final ctx = Map<String, dynamic>.from(context)..remove('session_id');
      await AnalyticsApi.instance.trackEngagementBatch(
        engagements: batch,
        context: ctx,
        sessionId: sid,
      );
    } catch (_) {
      _pending.insertAll(0, batch);
    } finally {
      _syncing = false;
    }
  }
}

/// Mixin for StatefulWidgets that tracks screen time on dispose.
mixin ContentEngagementMixin<T extends StatefulWidget> on State<T> {
  DateTime? _engagementStarted;

  void startEngagement() {
    _engagementStarted = DateTime.now();
  }

  Future<void> endEngagement({
    required String contentType,
    required int contentId,
    required String contentTitle,
  }) async {
    final started = _engagementStarted;
    if (started == null) return;
    final seconds = DateTime.now().difference(started).inSeconds;
    _engagementStarted = null;
    await EngagementTracker.instance.track(
      contentType: contentType,
      contentId: contentId,
      contentTitle: contentTitle,
      durationSeconds: seconds,
    );
  }
}
