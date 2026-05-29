import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../api/api_client.dart';
import '../../api/social_api.dart';
import '../../analytics/event_tracker.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_media_picker.dart';
import '../../services/platform_utils.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/post_video_player.dart';

enum SocialTab { videos, shorts }

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key, required this.initialTab});

  final SocialTab initialTab;

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final _api = SocialApi.instance;
  List<ApiPost> _posts = [];
  bool _loading = true;
  String? _error;

  bool get _isShort => widget.initialTab == SocialTab.shorts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _api.fetchPosts(isShort: _isShort);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _publishPost() async {
    final draft = await showModalBottomSheet<_PostDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreatePostSheet(isShort: _isShort),
    );
    if (draft == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('social.publishing'))),
    );
    try {
      await _api.createPost(
        caption: draft.caption,
        isShort: _isShort,
        isVideo: draft.isVideo,
        mediaPath: draft.mediaPath,
      );
      EventTracker.instance.track(
        'post_publish',
        screen: 'SocialFeedScreen',
        meta: draft.caption,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isShort ? tr('social.shortPublished') : tr('social.videoPublished'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trf('social.publishFailed', {'error': apiErrorMessage(e)})),
        ),
      );
    }
  }

  Future<void> _toggleLike(ApiPost post) async {
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

  Future<void> _toggleFavorite(ApiPost post) async {
    try {
      final fav = await _api.toggleFavorite(post.id);
      if (!mounted) return;
      setState(() => post.favoritedByMe = fav);
    } catch (_) {}
  }

  Future<void> _toggleFollow(ApiPost post) async {
    try {
      await _api.toggleFollow(post.authorId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _openComments(ApiPost post) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CommentsSheet(post: post),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isShort ? tr('nav.shorts') : tr('nav.videos'),
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('social.subtitle'),
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: ChezMamaTheme.ink.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publishPost,
        backgroundColor: ChezMamaTheme.brandOrange,
        foregroundColor: Colors.white,
        icon: Icon(_isShort ? Icons.bolt_rounded : Icons.videocam_rounded),
        label: Text(_isShort ? tr('social.publishShort') : tr('social.publishVideo')),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            _EmptyState(
              title: _isShort ? tr('social.emptyShort') : tr('social.emptyVideo'),
              subtitle: _isShort
                  ? tr('social.emptyShortHint')
                  : tr('social.emptyVideoHint'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final post = _posts[i];
          return _SocialPostCard(
            post: post,
            onLike: () => _toggleLike(post),
            onFollow: () => _toggleFollow(post),
            onFavorite: () => _toggleFavorite(post),
            onShare: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('social.shareOpened'))),
            ),
            onComments: () => _openComments(post),
          );
        },
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.onLike,
    required this.onFollow,
    required this.onFavorite,
    required this.onShare,
    required this.onComments,
  });

  final ApiPost post;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.11),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: post.isShort ? 9 / 11 : 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.mediaUrl.isNotEmpty)
                    _PostMedia(post: post)
                  else
                    const _PostPlaceholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.62),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post.authorName,
                                style: t.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: onFollow,
                          style: FilledButton.styleFrom(
                            backgroundColor: ChezMamaTheme.brandOrange,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(tr('social.subscribe')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likeCount}',
                    active: post.likedByMe,
                    onTap: onLike,
                  ),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount}',
                    active: false,
                    onTap: onComments,
                  ),
                  _ActionButton(
                    icon: post.favoritedByMe
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: tr('social.favorite'),
                    active: post.favoritedByMe,
                    onTap: onFavorite,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: tr('social.share'),
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.post});
  final ApiPost post;

  @override
  Widget build(BuildContext context) {
    if (!post.isVideo) {
      return FoodNetworkImage(
        url: post.mediaUrl,
        fit: BoxFit.cover,
        placeholder: const _PostPlaceholder(),
      );
    }
    return PostVideoPlayer(path: post.mediaUrl, isRemote: true);
  }
}

class _PostPlaceholder extends StatelessWidget {
  const _PostPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3C3), Color(0xFFFFFBF6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 54,
          color: ChezMamaTheme.brandOrange,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: active ? ChezMamaTheme.brandOrange : ChezMamaTheme.ink,
      ),
      label: Text(
        label,
        style: t.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: active ? ChezMamaTheme.brandOrange : ChezMamaTheme.ink,
        ),
      ),
    );
  }
}

/// Draft returned by the create sheet; the parent uploads it to the backend.
class _PostDraft {
  _PostDraft({
    required this.caption,
    required this.mediaPath,
    required this.isVideo,
  });

  final String caption;
  final String mediaPath;
  final bool isVideo;
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.isShort});

  final bool isShort;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final captionController = TextEditingController();
  final _mediaPicker = AppMediaPicker.instance;
  String? mediaPath;
  bool? isVideo;

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  void _showPickError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(trf('social.pickFileFailed', {'error': e}))),
    );
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final media = await _mediaPicker.pickVideoFromGallery();
      if (!mounted || media == null) return;
      setState(() {
        mediaPath = media.path;
        isVideo = true;
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      _showPickError(e);
    }
  }

  Future<void> _captureVideo() async {
    final hint = _mediaPicker.desktopCaptureHint();
    if (hint != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hint)));
      return;
    }
    try {
      final media = await _mediaPicker.captureVideo();
      if (!mounted || media == null) return;
      setState(() {
        mediaPath = media.path;
        isVideo = true;
      });
    } catch (e) {
      _showPickError(e);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final media = await _mediaPicker.pickPhotoFromGallery();
      if (!mounted || media == null) return;
      setState(() {
        mediaPath = media.path;
        isVideo = false;
      });
    } catch (e) {
      _showPickError(e);
    }
  }

  void _submit() {
    if (mediaPath == null || isVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis d’abord une photo ou une vidéo.')),
      );
      return;
    }
    var caption = captionController.text.trim();
    if (caption.isEmpty) {
      caption = isVideo!
          ? (widget.isShort ? 'Mon short' : 'Ma vidéo')
          : 'Ma photo';
    }
    Navigator.of(context).pop(
      _PostDraft(caption: caption, mediaPath: mediaPath!, isVideo: isVideo!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: captionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    widget.isShort ? 'Texte du short' : 'Description de la vidéo',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Photo (galerie)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideoFromGallery,
                    icon: const Icon(Icons.video_library_rounded),
                    label: const Text('Vidéo (galerie)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isMobilePlatform)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _captureVideo,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Filmer maintenant (caméra)'),
                ),
              ),
            const SizedBox(height: 12),
            if (mediaPath != null && isVideo == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: widget.isShort ? 9 / 16 : 16 / 9,
                  child: PostVideoPlayer(path: mediaPath!, autoPlay: true),
                ),
              ),
            if (mediaPath != null && isVideo == false)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(mediaPath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChezMamaTheme.surface2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                mediaPath == null
                    ? 'Aucun média sélectionné — obligatoire pour publier'
                    : 'Média sélectionné: ${p.basename(mediaPath!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: ChezMamaTheme.brandOrange,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.isShort ? 'Publier short' : 'Publier vidéo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});
  final ApiPost post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final controller = TextEditingController();
  final _api = SocialApi.instance;
  List<ApiComment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await _api.fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
        widget.post.commentCount = comments.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<ApiComment> get _topLevel =>
      _comments.where((c) => c.parentId == null).toList();

  List<ApiComment> _repliesOf(int id) =>
      _comments.where((c) => c.parentId == id).toList();

  Future<void> _addComment({int? parentId, TextEditingController? source}) async {
    final ctrl = source ?? controller;
    final text = ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment =
          await _api.addComment(widget.post.id, text, parentId: parentId);
      if (!mounted) return;
      setState(() {
        _comments.add(comment);
        widget.post.commentCount = _comments.length;
        ctrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _replyTo(ApiComment target) async {
    final replyController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('social.replyTitle')),
        content: TextField(
          controller: replyController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: tr('social.replyHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('action.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(replyController.text.trim()),
            child: Text(tr('action.send')),
          ),
        ],
      ),
    );
    final value = text;
    replyController.text = value ?? '';
    if (value == null || value.isEmpty) {
      replyController.dispose();
      return;
    }
    await _addComment(parentId: target.id, source: replyController);
    replyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('social.comments'),
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _topLevel.isEmpty
                      ? Center(child: Text(tr('social.noComments')))
                      : ListView.separated(
                          itemCount: _topLevel.length,
                          separatorBuilder: (_, __) => const Divider(height: 22),
                          itemBuilder: (context, i) {
                            final comment = _topLevel[i];
                            final replies = _repliesOf(comment.id);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.authorName,
                                  style: t.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(comment.text, style: t.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: () => _replyTo(comment),
                                  child: Text(tr('social.reply')),
                                ),
                                for (final reply in replies)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 18, top: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.subdirectory_arrow_right_rounded,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${reply.authorName}: ${reply.text}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: tr('social.addComment'),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _sending ? null : () => _addComment(),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChezMamaTheme.brandOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ChezMamaTheme.cardColor(context),
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
            boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_collection_outlined, size: 46),
              const SizedBox(height: 10),
              Text(
                title,
                style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: t.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 46),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('action.retry')),
              style: FilledButton.styleFrom(
                backgroundColor: ChezMamaTheme.brandOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
