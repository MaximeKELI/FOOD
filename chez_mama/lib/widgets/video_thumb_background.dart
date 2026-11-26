import 'dart:io';

import 'package:flutter/material.dart';

import '../services/video_thumbnail_cache.dart';

/// Shows a cached frame from [videoUrl] as cover (before play / while loading).
class VideoThumbBackground extends StatefulWidget {
  const VideoThumbBackground({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
  });

  final String videoUrl;
  final BoxFit fit;

  @override
  State<VideoThumbBackground> createState() => _VideoThumbBackgroundState();
}

class _VideoThumbBackgroundState extends State<VideoThumbBackground> {
  Future<String?>? _future;
  int _retries = 0;

  void _load() {
    _future = VideoThumbnailCache.instance.thumbnailPath(widget.videoUrl);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoThumbBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _retries = 0;
      _load();
    }
  }

  void _retryIfNeeded() {
    if (_retries >= 2 || !mounted) return;
    _retries++;
    Future<void>.delayed(Duration(milliseconds: 800 * _retries), () {
      if (!mounted) return;
      setState(_load);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        final path = snap.data;
        if (path != null && File(path).existsSync()) {
          return Image.file(
            File(path),
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
        }

        if (snap.connectionState == ConnectionState.done && path == null) {
          if (_retries < 2) {
            _retryIfNeeded();
            return const _ThumbLoading();
          }
          // Thumbnail unavailable (common on Linux) — still show a playable look.
          return const _ThumbFallback();
        }

        return const _ThumbLoading();
      },
    );
  }
}

class _ThumbLoading extends StatelessWidget {
  const _ThumbLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF1A1A1E),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A12), Color(0xFF1A1A1E), Color(0xFF3D2415)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 42,
          color: Colors.white38,
        ),
      ),
    );
  }
}
