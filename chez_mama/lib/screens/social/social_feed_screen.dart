import 'package:flutter/material.dart';
import '../../analytics/event_tracker.dart';
import '../../auth/auth_scope.dart';
import '../../ui/chezmama_theme.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<_UserPost> _videos = [];
  final List<_UserPost> _shorts = [];
  final Set<String> _followingSellers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _publishPost(bool isShort) async {
    final post = await showModalBottomSheet<_UserPost>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreatePostSheet(
        isShort: isShort,
        sellerName: AuthScope.of(context).userName ?? 'Utilisateur',
      ),
    );
    if (post == null) return;
    setState(() {
      if (isShort) {
        _shorts.insert(0, post);
      } else {
        _videos.insert(0, post);
      }
    });
    EventTracker.instance.track(
      'post_publish',
      screen: 'SocialFeedScreen',
      element: post.id,
      meta: post.caption,
    );
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
                  'Vidéos & Shorts',
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Publie ton contenu et laisse la communauté réagir.',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: ChezMamaTheme.ink.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  indicatorColor: ChezMamaTheme.brandOrange,
                  labelColor: ChezMamaTheme.brandOrange,
                  unselectedLabelColor: ChezMamaTheme.ink.withValues(alpha: 0.6),
                  tabs: const [
                    Tab(text: 'Vidéos'),
                    Tab(text: 'Shorts'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FeedList(
                  posts: _videos,
                  emptyTitle: 'Aucune vidéo publiée',
                  emptySubtitle: 'Publie la première vidéo de ton plat.',
                  followingSellers: _followingSellers,
                ),
                _FeedList(
                  posts: _shorts,
                  emptyTitle: 'Aucun short publié',
                  emptySubtitle: 'Publie un short pour attirer les clients.',
                  followingSellers: _followingSellers,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isShort = _tabController.index == 1;
          return FloatingActionButton.extended(
            onPressed: () => _publishPost(isShort),
            backgroundColor: ChezMamaTheme.brandOrange,
            foregroundColor: Colors.white,
            icon: Icon(isShort ? Icons.bolt_rounded : Icons.videocam_rounded),
            label: Text(isShort ? 'Publier short' : 'Publier vidéo'),
          );
        },
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  const _FeedList({
    required this.posts,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.followingSellers,
  });

  final List<_UserPost> posts;
  final String emptyTitle;
  final String emptySubtitle;
  final Set<String> followingSellers;

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  void _openComments(_UserPost post) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return _EmptyState(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      itemCount: widget.posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final post = widget.posts[i];
        final followed = widget.followingSellers.contains(post.sellerName);
        return _SocialPostCard(
          post: post,
          followed: followed,
          onFollow: () {
            setState(() {
              if (followed) {
                widget.followingSellers.remove(post.sellerName);
              } else {
                widget.followingSellers.add(post.sellerName);
              }
            });
            EventTracker.instance.track(
              'seller_subscribe_toggle',
              screen: 'SocialFeedScreen',
              element: post.id,
              meta: post.sellerName,
            );
          },
          onLike: () {
            setState(() => post.likeCount += post.likedByMe ? -1 : 1);
            post.likedByMe = !post.likedByMe;
            EventTracker.instance.track(
              'video_like_toggle',
              screen: 'SocialFeedScreen',
              element: post.id,
            );
          },
          onFavorite: () => setState(() => post.favorite = !post.favorite),
          onDownload: () => setState(() => post.downloaded = true),
          onShare: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partage ouvert')),
          ),
          onComments: () => _openComments(post),
        );
      },
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.followed,
    required this.onLike,
    required this.onFollow,
    required this.onFavorite,
    required this.onDownload,
    required this.onShare,
    required this.onComments,
  });

  final _UserPost post;
  final bool followed;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onFavorite;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                  if (post.mediaPath.isNotEmpty)
                    Image.asset(
                      post.mediaPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PostPlaceholder(post: post),
                    )
                  else
                    _PostPlaceholder(post: post),
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
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: ChezMamaTheme.brandOrange,
                        size: 38,
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
                                post.sellerName,
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
                            backgroundColor:
                                followed ? Colors.white : ChezMamaTheme.brandOrange,
                            foregroundColor:
                                followed ? ChezMamaTheme.brandBrown : Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(followed ? 'Abonné' : 'S’abonner'),
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
                    label: '${post.comments.length}',
                    active: false,
                    onTap: onComments,
                  ),
                  _ActionButton(
                    icon: post.favorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: 'Favori',
                    active: post.favorite,
                    onTap: onFavorite,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Partager',
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                  IconButton(
                    tooltip: 'Télécharger',
                    onPressed: onDownload,
                    icon: Icon(
                      post.downloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                    ),
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

class _PostPlaceholder extends StatelessWidget {
  const _PostPlaceholder({required this.post});
  final _UserPost post;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE3C3),
            Color(0xFFFFFBF6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          post.isShort ? Icons.bolt_rounded : Icons.videocam_rounded,
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

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.isShort,
    required this.sellerName,
  });

  final bool isShort;
  final String sellerName;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final captionController = TextEditingController();
  final mediaController = TextEditingController();

  @override
  void dispose() {
    captionController.dispose();
    mediaController.dispose();
    super.dispose();
  }

  void _submit() {
    final caption = captionController.text.trim();
    if (caption.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final post = _UserPost(
      id: 'p_$now',
      sellerName: widget.sellerName,
      caption: caption,
      mediaPath: mediaController.text.trim(),
      isShort: widget.isShort,
    );
    Navigator.of(context).pop(post);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: captionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.isShort ? 'Texte du short' : 'Description de la vidéo',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mediaController,
            decoration: const InputDecoration(
              labelText: 'Chemin image locale (optionnel)',
              hintText: 'Ex: assets/images/food_hero_mafe.png',
              border: OutlineInputBorder(),
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
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});
  final _UserPost post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.post.comments.insert(0, _CommentNode(text: text));
      controller.clear();
    });
  }

  Future<void> _addReply(_CommentNode target) async {
    final replyController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Répondre'),
        content: TextField(
          controller: replyController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ta réponse…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(replyController.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    replyController.dispose();
    if (text == null || text.isEmpty) return;
    setState(() {
      target.replies.add(_CommentNode(text: text));
    });
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
              'Commentaires',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.post.comments.isEmpty
                  ? const Center(child: Text('Aucun commentaire pour le moment.'))
                  : ListView.separated(
                      itemCount: widget.post.comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 22),
                      itemBuilder: (context, i) {
                        final comment = widget.post.comments[i];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.text, style: t.textTheme.bodyMedium),
                            TextButton(
                              onPressed: () => _addReply(comment),
                              child: const Text('Répondre'),
                            ),
                            for (final reply in comment.replies)
                              Padding(
                                padding: const EdgeInsets.only(left: 18, top: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(reply.text)),
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
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _addComment,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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

class _UserPost {
  _UserPost({
    required this.id,
    required this.sellerName,
    required this.caption,
    required this.mediaPath,
    required this.isShort,
  });

  final String id;
  final String sellerName;
  final String caption;
  final String mediaPath;
  final bool isShort;

  bool likedByMe = false;
  int likeCount = 0;
  bool favorite = false;
  bool downloaded = false;
  final List<_CommentNode> comments = [];
}

class _CommentNode {
  _CommentNode({required this.text});
  final String text;
  final List<_CommentNode> replies = [];
}

