import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class EventTracker {
  EventTracker._();

  static final EventTracker instance = EventTracker._();

  Database? _db;
  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    if (_ready) return;
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
      final db = _db;
      if (db == null) return;
      await db.insert('events', {
        'ts': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'screen': screen,
        'element': element,
        'meta': meta,
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('EventTracker.track failed: $e');
      }
    }
  }

  Future<Map<String, int>> countsByName({int lastHours = 24}) async {
    if (!_ready) await init();
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
    final db = _db;
    _db = null;
    _ready = false;
    await db?.close();
  }
}

