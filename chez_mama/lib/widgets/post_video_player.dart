import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../ui/chezmama_theme.dart';

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
  late final Player _player;
  late final VideoController _videoController;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _open();
  }

  @override
  void didUpdateWidget(covariant PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _open();
    }
  }

  Future<void> _open() async {
    setState(() {
      _ready = false;
      _error = null;
    });

    final file = File(widget.path);
    if (!await file.exists()) {
      if (!mounted) return;
      setState(() => _error = 'Fichier vidéo introuvable');
      return;
    }

    try {
      await _player.open(Media(widget.path), play: widget.autoPlay);
      await _player.setPlaylistMode(PlaylistMode.loop);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Lecture impossible: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ChezMamaTheme.brandBrown,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => _player.playOrPause(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: _videoController,
            fit: BoxFit.cover,
            controls: NoVideoControls,
          ),
          StreamBuilder<bool>(
            stream: _player.stream.playing,
            initialData: false,
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return const SizedBox.shrink();
              }
              return Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: ChezMamaTheme.brandOrange,
                    size: 34,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
