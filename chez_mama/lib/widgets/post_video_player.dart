import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/platform_utils.dart';
import '../ui/chezmama_theme.dart';

Future<void> openVideoExternally(String path) async {
  if (Platform.isLinux) {
    await Process.run('xdg-open', [path]);
    return;
  }
  if (Platform.isMacOS) {
    await Process.run('open', [path]);
    return;
  }
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', path]);
  }
}

class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({
    super.key,
    required this.path,
    this.autoPlay = false,
  });

  final String path;
  final bool autoPlay;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (isDesktopPlatform) {
      _checkFile();
    } else {
      _initInlinePlayer();
    }
  }

  Future<void> _checkFile() async {
    if (!await File(widget.path).exists()) {
      if (!mounted) return;
      setState(() => _error = 'Fichier vidéo introuvable');
    }
  }

  Future<void> _initInlinePlayer() async {
    final file = File(widget.path);
    if (!await file.exists()) {
      if (!mounted) return;
      setState(() => _error = 'Fichier vidéo introuvable');
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (widget.autoPlay) {
        await controller.play();
        controller.setLooping(true);
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _error = 'Lecture impossible: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _VideoError(message: _error!);
    }

    if (isDesktopPlatform) {
      return _DesktopVideoPreview(path: widget.path);
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (c.value.isPlaying) {
            c.pause();
          } else {
            c.play();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          if (!c.value.isPlaying)
            const Center(
              child: _PlayBadge(),
            ),
        ],
      ),
    );
  }
}

class _DesktopVideoPreview extends StatelessWidget {
  const _DesktopVideoPreview({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final name = path.split(Platform.pathSeparator).last;
    return Material(
      color: const Color(0xFF1B1B1F),
      child: InkWell(
        onTap: () => openVideoExternally(path),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PlayBadge(size: 64),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appuie pour lire avec le lecteur système',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: ChezMamaTheme.brandOrange,
        size: size * 0.65,
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ChezMamaTheme.brandBrown,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
