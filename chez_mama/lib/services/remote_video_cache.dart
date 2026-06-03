import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/api_config.dart';

/// Downloads remote videos to a local cache for reliable playback on mobile.
class RemoteVideoCache {
  RemoteVideoCache._();
  static final RemoteVideoCache instance = RemoteVideoCache._();

  static const _minBytes = 2048;

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(minutes: 8),
      headers: {'Accept': '*/*'},
    ),
  );

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getTemporaryDirectory();
    _dir = Directory('${base.path}/food_videos');
    if (!_dir!.existsSync()) _dir!.createSync(recursive: true);
    return _dir!;
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
    return url;
  }

  String _cacheFileName(String url) {
    final resolved = _resolveUrl(url);
    final uri = Uri.parse(resolved);
    final ext = p.extension(uri.path);
    final safeExt = ext.isNotEmpty ? ext : '.mp4';
    final digest = resolved.hashCode.abs().toRadixString(16);
    return '$digest$safeExt';
  }

  /// Returns a local file path ready for playback. Reuses cached copies.
  Future<String> ensureLocal(String url) async {
    final resolved = _resolveUrl(url);
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_cacheFileName(url)}');
    if (file.existsSync()) {
      final len = await file.length();
      if (len >= _minBytes) return file.path;
      await file.delete();
    }
    await _dio.download(resolved, file.path);
    final len = await file.length();
    if (len < _minBytes) {
      await file.delete();
      throw StateError(
        'Vidéo inaccessible ou fichier invalide ($len octets). '
        'Vérifie la connexion au serveur.',
      );
    }
    return file.path;
  }
}
