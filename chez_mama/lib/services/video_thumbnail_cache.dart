import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../api/api_config.dart';
import 'remote_video_cache.dart';

/// Caches JPEG thumbnails (frame from the video) for feed / preview backgrounds.
class VideoThumbnailCache {
  VideoThumbnailCache._();
  static final VideoThumbnailCache instance = VideoThumbnailCache._();

  final _inFlight = <String, Future<String?>>{};

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getTemporaryDirectory();
    _dir = Directory('${base.path}/food_video_thumbs');
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
    return '${resolved.hashCode.abs().toRadixString(16)}_frame.jpg';
  }

  /// Warms thumbnails for a list of video URLs (non-blocking).
  void preloadAll(Iterable<String> urls) {
    for (final url in urls) {
      thumbnailPath(url);
    }
  }

  /// Returns a local JPEG path for a frame inside the video, or null on failure.
  Future<String?> thumbnailPath(String url) {
    return _inFlight.putIfAbsent(url, () async {
      try {
        return await _thumbnailPathImpl(url);
      } finally {
        _inFlight.remove(url);
      }
    });
  }

  Future<String?> _thumbnailPathImpl(String url) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_cacheFileName(url)}');
    if (file.existsSync() && await file.length() > 512) {
      return file.path;
    }

    final sources = <String>[];
    final resolved = _resolveUrl(url);
    sources.add(resolved);

    try {
      final local = await RemoteVideoCache.instance.ensureLocal(url);
      if (!sources.contains(local)) sources.add(local);
    } catch (_) {}

    for (final source in sources) {
      final times = await _candidateTimesMs(source);
      for (final ms in times) {
        try {
          final generated = await _generate(source, dir.path, ms);
          if (generated != null) {
            await _storeGenerated(generated, file);
            return file.path;
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Prefer middle of video; fall back to early frames if duration unknown.
  Future<List<int>> _candidateTimesMs(String videoSource) async {
    final mid = await _middleTimeMs(videoSource);
    final candidates = <int>{0, 800, mid, 2000, 4000};
    return candidates.where((t) => t >= 0).toList()..sort();
  }

  Future<int> _middleTimeMs(String videoSource) async {
    VideoPlayerController? c;
    try {
      if (videoSource.startsWith('http://') || videoSource.startsWith('https://')) {
        c = VideoPlayerController.networkUrl(Uri.parse(videoSource));
      } else {
        c = VideoPlayerController.file(File(videoSource));
      }
      await c.initialize().timeout(const Duration(seconds: 20));
      final ms = c.value.duration.inMilliseconds;
      if (ms <= 800) return 0;
      return (ms * 0.5).round();
    } catch (_) {
      return 1500;
    } finally {
      await c?.dispose();
    }
  }

  Future<String?> _generate(String video, String thumbDir, int timeMs) {
    return VideoThumbnail.thumbnailFile(
      video: video,
      thumbnailPath: thumbDir,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 800,
      quality: 88,
      timeMs: timeMs,
    );
  }

  Future<void> _storeGenerated(String generated, File target) async {
    if (!File(generated).existsSync()) return;
    if (generated != target.path) {
      await File(generated).copy(target.path);
      try {
        await File(generated).delete();
      } catch (_) {}
    }
  }
}
