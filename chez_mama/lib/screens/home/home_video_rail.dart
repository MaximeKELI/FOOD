import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/social_api.dart';
import '../../auth/auth_gate.dart';
import '../../l10n/app_strings.dart';
import '../../services/video_thumbnail_cache.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/video_post_badge.dart';
import '../../widgets/video_thumb_background.dart';
import '../social/fullscreen_video_page.dart';

/// Horizontal TikTok-style rail of ranked seller videos for the home screen.
class HomeVideoRail extends StatefulWidget {
  const HomeVideoRail({super.key});

  @override
  State<HomeVideoRail> createState() => HomeVideoRailState();
}

class HomeVideoRailState extends State<HomeVideoRail> {
  final _api = SocialApi.instance;
  List<ApiPost> _posts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _api.fetchHomeDiscoverFeed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
      VideoThumbnailCache.instance.preloadAll(
        posts
            .where((p) => p.isVideo || isVideoUrl(p.mediaUrl))
            .map((p) => p.mediaUrl),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(ApiPost post) async {
    if (!await requireAuth(context)) return;
    try {
      final result = await _api.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        post.likedByMe = result.liked;
        post.likeCount = result.likeCount;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _openComments(ApiPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HomeCommentsSheet(post: post),
    );
    if (mounted) setState(() {});
  }

  void _openFeed(int index) {
    final videoPosts = _posts
        .where((p) => p.isVideo || isVideoUrl(p.mediaUrl))
        .toList();
    final target = _posts[index];
    var initial = videoPosts.indexWhere((p) => p.id == target.id);
    if (initial < 0) initial = 0;
    final feed = videoPosts.isNotEmpty ? videoPosts : _posts;
    FullscreenVideoFeed.open(
      context,
      posts: feed,
      initialIndex: initial.clamp(0, feed.length - 1),
      onLike: _toggleLike,
      onComments: _openComments,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _posts.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null && _posts.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('home.forYou'),
          style: ChezMamaTheme.sectionTitle(t, context),
        ),
        const SizedBox(height: 4),
        Text(
          tr('home.forYouHint'),
          style: t.textTheme.bodySmall?.copyWith(
            color: ChezMamaTheme.mutedInk(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final post = _posts[i];
              return _SellerVideoCard(
                post: post,
                onTap: () => _openFeed(i),
                onLike: () => _toggleLike(post),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SellerVideoCard extends StatelessWidget {
  const _SellerVideoCard({
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  final ApiPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final isVideo = post.isVideo || isVideoUrl(post.mediaUrl);
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                VideoThumbBackground(videoUrl: post.mediaUrl)
              else
                FoodNetworkImage(url: post.mediaUrl, memCacheWidth: 420),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              if (isVideo)
                const Positioned(
                  left: 10,
                  top: 10,
                  child: VideoPostBadge(),
                ),
              if (isVideo)
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${post.authorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (post.caption.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        post.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        InkWell(
                          onTap: onLike,
                          child: Row(
                            children: [
                              Icon(
                                post.likedByMe
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: post.likedByMe
                                    ? ChezMamaTheme.brandOrange
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCommentsSheet extends StatefulWidget {
  const _HomeCommentsSheet({required this.post});

  final ApiPost post;

  @override
  State<_HomeCommentsSheet> createState() => _HomeCommentsSheetState();
}

class _HomeCommentsSheetState extends State<_HomeCommentsSheet> {
  final _api = SocialApi.instance;
  final _ctrl = TextEditingController();
  List<ApiComment> _comments = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _api.fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (!await requireAuth(context)) return;
    try {
      final c = await _api.addComment(widget.post.id, text);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, c];
        widget.post.commentCount += 1;
        _ctrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                tr('social.comments'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            c.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(c.text),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: tr('social.addComment'),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      color: ChezMamaTheme.brandOrange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
