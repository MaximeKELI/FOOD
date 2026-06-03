import 'package:flutter/material.dart';

import '../../api/social_api.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/post_video_player.dart';
import '../../widgets/video_post_badge.dart';
import '../../widgets/video_thumb_background.dart';

typedef PostLikeHandler = Future<void> Function(ApiPost post);
typedef PostCommentsHandler = Future<void> Function(ApiPost post);

/// Vertical reel viewer with like / comment while scrolling.
class FullscreenVideoFeed extends StatefulWidget {
  const FullscreenVideoFeed({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.onLike,
    required this.onComments,
  });

  final List<ApiPost> posts;
  final int initialIndex;
  final PostLikeHandler onLike;
  final PostCommentsHandler onComments;

  static Future<void> open(
    BuildContext context, {
    required List<ApiPost> posts,
    required int initialIndex,
    required PostLikeHandler onLike,
    required PostCommentsHandler onComments,
  }) {
    if (posts.isEmpty) return Future.value();
    final index = initialIndex.clamp(0, posts.length - 1);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenVideoFeed(
          posts: posts,
          initialIndex: index,
          onLike: onLike,
          onComments: onComments,
        ),
      ),
    );
  }

  @override
  State<FullscreenVideoFeed> createState() => _FullscreenVideoFeedState();
}

class _FullscreenVideoFeedState extends State<FullscreenVideoFeed> {
  late final PageController _pageController;
  late int _currentIndex;

  ApiPost get _post => widget.posts[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _like() async {
    await widget.onLike(_post);
    if (mounted) setState(() {});
  }

  Future<void> _comments() async {
    await widget.onComments(_post);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final t = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            itemCount: widget.posts.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbBackground(videoUrl: post.mediaUrl),
                  PostVideoPlayer(
                    key: ValueKey(post.mediaUrl),
                    path: post.mediaUrl,
                    isRemote: true,
                    autoPlay: true,
                    active: index == _currentIndex,
                    fillScreen: true,
                    immersive: true,
                    scrollFriendly: true,
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(top: topPad + 6, left: 6, right: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                  if (widget.posts.length > 1) ...[
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.posts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 72,
            bottom: bottomPad + 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _post.authorName,
                  style: t.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0xCC000000), blurRadius: 6),
                    ],
                  ),
                ),
                if (_post.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _post.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Color(0xAA000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: bottomPad + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FullscreenAction(
                  icon: _post.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${_post.likeCount}',
                  active: _post.likedByMe,
                  onTap: _like,
                ),
                const SizedBox(height: 12),
                _FullscreenAction(
                  icon: Icons.mode_comment_rounded,
                  label: '${_post.commentCount}',
                  onTap: _comments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenAction extends StatelessWidget {
  const _FullscreenAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? ChezMamaTheme.brandOrange : Colors.white,
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feed preview: mid-frame thumbnail + video badge.
class VideoFeedTile extends StatefulWidget {
  const VideoFeedTile({
    super.key,
    required this.post,
    required this.videoPosts,
    required this.onLike,
    required this.onComments,
  });

  final ApiPost post;
  final List<ApiPost> videoPosts;
  final PostLikeHandler onLike;
  final PostCommentsHandler onComments;

  @override
  State<VideoFeedTile> createState() => _VideoFeedTileState();
}

class _VideoFeedTileState extends State<VideoFeedTile> {
  @override
  Widget build(BuildContext context) {
    final index = widget.videoPosts.indexWhere((p) => p.id == widget.post.id);
    final initialIndex = index >= 0 ? index : 0;

    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: () => FullscreenVideoFeed.open(
          context,
          posts: widget.videoPosts,
          initialIndex: initialIndex,
          onLike: widget.onLike,
          onComments: widget.onComments,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoThumbBackground(videoUrl: widget.post.mediaUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 10,
              top: 10,
              child: VideoPostBadge(),
            ),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
