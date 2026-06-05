import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../api/analytics_api.dart';
import 'device_context.dart';

class EventTracker {
  EventTracker._();

  static final EventTracker instance = EventTracker._();

  Database? _db;
  bool _ready = false;
  bool _disabled = false;
  bool get ready => _ready;
  bool get disabled => _disabled;

  final List<Map<String, dynamic>> _pendingSync = [];
  Timer? _syncTimer;
  Timer? _debounceTimer;
  bool _syncing = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'food_analytics.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ts INTEGER NOT NULL,
              name TEXT NOT NULL,
              screen TEXT,
              element TEXT,
              meta TEXT
            )
          ''');
        },
      );
      _ready = true;
      _syncTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => flushNow(),
      );
    } catch (e) {
      _disabled = true;
      _ready = true;
    }
  }

  Future<void> track(
    String name, {
    String? screen,
    String? element,
    String? meta,
  }) async {
    try {
      if (!_ready) {
        await init();
      }
      if (_disabled) return;

      final db = _db;
      if (db != null) {
        await db.insert('events', {
          'ts': DateTime.now().millisecondsSinceEpoch,
          'name': name,
          'screen': screen,
          'element': element,
          'meta': meta,
        });
      }

      _pendingSync.add({
        'name': name,
        if (screen != null) 'screen': screen,
        if (element != null) 'element': element,
        if (meta != null) 'meta': meta,
      });
      _scheduleFlush();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('EventTracker.track failed: $e');
      }
    }
  }

  void _scheduleFlush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      unawaited(flushNow());
    });
    if (_pendingSync.length >= 5) {
      unawaited(flushNow());
    }
  }

  /// Push pending events to the backend immediately (e.g. after login).
  Future<void> flushNow() async {
    if (_syncing || _pendingSync.isEmpty) return;
    _syncing = true;
    final batch = List<Map<String, dynamic>>.from(_pendingSync);
    _pendingSync.clear();
    try {
      final context = await DeviceContext.instance.collect();
      final sid = context['session_id'] as String?;
      final ctx = Map<String, dynamic>.from(context)..remove('session_id');
      await AnalyticsApi.instance.trackBatch(
        events: batch,
        context: ctx,
        sessionId: sid,
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('EventTracker: synced ${batch.length} event(s)');
      }
    } catch (e) {
      _pendingSync.insertAll(0, batch);
      if (kDebugMode) {
        // ignore: avoid_print
        print('EventTracker sync failed: $e');
      }
    } finally {
      _syncing = false;
    }
  }

  Future<Map<String, int>> countsByName({int lastHours = 24}) async {
    if (!_ready) await init();
    if (_disabled) return {};
    final db = _db;
    if (db == null) return {};
    final since = DateTime.now()
        .subtract(Duration(hours: lastHours))
        .millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT name, COUNT(*) as c
      FROM events
      WHERE ts >= ?
      GROUP BY name
      ORDER BY c DESC
    ''', [since]);
    return {
      for (final r in rows) (r['name'] as String): (r['c'] as int),
    };
  }

  Future<void> dispose() async {
    _syncTimer?.cancel();
    _debounceTimer?.cancel();
    await flushNow();
    final db = _db;
    _db = null;
    _ready = false;
    await db?.close();
  }
}
