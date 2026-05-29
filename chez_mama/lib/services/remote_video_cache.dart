import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Downloads remote videos to a temp cache so desktop players can open them.
class RemoteVideoCache {
  RemoteVideoCache._();
  static final RemoteVideoCache instance = RemoteVideoCache._();

  static const _minBytes = 1024;

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  Directory get _dir {
    final d = Directory('${Directory.systemTemp.path}/food_videos');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// Returns a local file path ready for playback. Reuses cached copies.
  Future<String> ensureLocal(String url) async {
    final uri = Uri.parse(url);
    final name = p.basename(uri.path);
    if (name.isEmpty) {
      throw StateError('URL vidéo invalide.');
    }
    final file = File('${_dir.path}/$name');
    if (file.existsSync()) {
      final len = await file.length();
      if (len >= _minBytes) return file.path;
      await file.delete();
    }
    await _dio.download(url, file.path);
    final len = await file.length();
    if (len < _minBytes) {
      await file.delete();
      throw StateError(
        'Fichier vidéo invalide sur le serveur (${len} octets). '
        'Republie la vidéo.',
      );
    }
    return file.path;
  }
}
