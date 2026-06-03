import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../l10n/app_strings.dart';
import '../services/platform_utils.dart';
import '../services/remote_video_cache.dart';
import '../ui/chezmama_theme.dart';
import 'scroll_friendly_tap.dart';
import 'video_thumb_background.dart';

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
    this.isRemote = false,
    this.active = true,
    this.fillScreen = false,
    this.immersive = false,
    this.scrollFriendly = false,
  });

  final String path;
  final bool autoPlay;
  final bool isRemote;
  /// When false, playback is paused (e.g. off-screen page in a vertical feed).
  final bool active;
  /// Fills the area with cover fit (fullscreen reels).
  final bool fillScreen;
  /// Smaller overlays: spinner while loading, subtle pause icon.
  final bool immersive;
  /// Allows vertical PageView swipe (tap-only, no full-screen InkWell).
  final bool scrollFriendly;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = false;
  bool _preparing = false;
  bool _hasPlayedOnce = false;

  @override
  void initState() {
    super.initState();
    if (!supportsInlineVideo) {
      if (widget.isRemote) {
        _prepareRemoteForDesktop();
      }
      return;
    }
    if (widget.autoPlay && widget.active) {
      _prepareAndPlay();
    }
  }

  @override
  void didUpdateWidget(PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _hasPlayedOnce = false;
      _controller?.dispose();
      _controller = null;
    }
    if (!supportsInlineVideo) return;
    if (oldWidget.active == widget.active) return;
    if (!widget.active) {
      _controller?.pause();
      if (mounted) setState(() {});
      return;
    }
    if (widget.autoPlay) {
      final c = _controller;
      if (c != null && c.value.isInitialized) {
        c.play();
        if (mounted) setState(() {});
      } else {
        _prepareAndPlay();
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _prepareRemoteForDesktop() async {
    setState(() => _preparing = true);
    try {
      final local = await RemoteVideoCache.instance.ensureLocal(widget.path);
      if (!mounted) return;
      setState(() => _preparing = false);
      if (widget.autoPlay && widget.active) {
        await openVideoExternally(local);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _preparing = false;
      });
    }
  }

  Future<void> _prepareAndPlay() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    VideoPlayerController? controller;
    try {
      String playPath = widget.path;
      if (widget.isRemote) {
        playPath = await RemoteVideoCache.instance.ensureLocal(widget.path);
      } else if (!await File(widget.path).exists()) {
        throw StateError('Fichier vidéo introuvable');
      }

      controller = VideoPlayerController.file(File(playPath));
      await controller.initialize();
      controller.setLooping(true);
      controller.addListener(_onControllerUpdate);
      if (widget.active) {
        await controller.play();
        _hasPlayedOnce = true;
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _controller?.dispose();
      _controller = controller;
      setState(() => _loading = false);
    } catch (e) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _error = trf('social.videoPlayFailed', {'error': '$e'});
        _loading = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_error != null) {
      await _prepareAndPlay();
      return;
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      await _prepareAndPlay();
      return;
    }
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
      _hasPlayedOnce = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildVideoFrame(VideoPlayerController c) {
    final video = VideoPlayer(c);
    if (!widget.fillScreen) {
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
          child: video,
        ),
      );
    }
    final w = c.value.size.width;
    final h = c.value.size.height;
    if (w <= 0 || h <= 0) {
      return Center(child: video);
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: w, height: h, child: video),
      ),
    );
  }

  double get _overlayIconSize => widget.immersive ? 40 : 56;

  bool get _showVideoFrame {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return false;
    return c.value.isPlaying || _hasPlayedOnce;
  }

  bool get _showThumbUnderlay {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return true;
    return !c.value.isPlaying && !_hasPlayedOnce;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _VideoError(message: _error!, onRetry: _prepareAndPlay);
    }

    if (!supportsInlineVideo) {
      return _DesktopVideoPreview(
        path: widget.path,
        preparing: _preparing,
        onPlay: () async {
          try {
            final local = await RemoteVideoCache.instance.ensureLocal(widget.path);
            await openVideoExternally(local);
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = '$e');
          }
        },
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      final showSpinner = widget.immersive && (widget.autoPlay || _loading);
      final body = Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          VideoThumbBackground(videoUrl: widget.path),
          if (!showSpinner)
            _PlayBadge(size: _overlayIconSize, minimal: widget.immersive),
          if (showSpinner)
            const CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2.5,
            ),
        ],
      );
      return Material(
        color: Colors.transparent,
        child: widget.scrollFriendly
            ? ScrollFriendlyTap(onTap: _prepareAndPlay, child: body)
            : InkWell(onTap: _loading ? null : _prepareAndPlay, child: body),
      );
    }

    final frame = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (_showThumbUnderlay)
          VideoThumbBackground(videoUrl: widget.path),
        if (_showVideoFrame) _buildVideoFrame(c),
        if (!c.value.isPlaying)
          _PlayBadge(size: _overlayIconSize, minimal: widget.immersive),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: widget.scrollFriendly
          ? ScrollFriendlyTap(onTap: _togglePlay, child: frame)
          : InkWell(onTap: _togglePlay, child: frame),
    );
  }
}

class _DesktopVideoPreview extends StatelessWidget {
  const _DesktopVideoPreview({
    required this.path,
    required this.onPlay,
    this.preparing = false,
  });

  final String path;
  final bool preparing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1B1F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoThumbBackground(videoUrl: path),
          InkWell(
            onTap: preparing ? null : onPlay,
            child: Center(
              child: preparing
                  ? const CircularProgressIndicator(color: Colors.white70)
                  : const _PlayBadge(size: 48, minimal: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({this.size = 52, this.minimal = false});
  final double size;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    if (minimal) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white.withValues(alpha: 0.95),
          size: size * 0.55,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: ChezMamaTheme.brandOrange,
        size: size * 0.62,
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, size: 36, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr('action.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
