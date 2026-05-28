import 'package:flutter/material.dart';
import '../../analytics/event_tracker.dart';
import '../../data/social_demo_data.dart';
import '../../models/social_post.dart';
import '../../ui/chezmama_theme.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final liked = <String>{};
  final followed = <String>{};
  final favorites = <String>{};
  final downloaded = <String>{};

  void _track(String action, SocialPost post) {
    EventTracker.instance.track(
      action,
      screen: 'SocialFeedScreen',
      element: post.id,
      meta: post.sellerName,
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _openComments(SocialPost post) {
    _track('comments_open', post);
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
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
                    'Découvre les vendeurs proches, abonne-toi, like et commande.',
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: ChezMamaTheme.ink.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
            sliver: SliverList.separated(
              itemCount: SocialDemoData.posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final post = SocialDemoData.posts[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 360 + (i * 90)),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) {
                    return Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - v)),
                        child: child,
                      ),
                    );
                  },
                  child: _SocialPostCard(
                    post: post,
                    liked: liked.contains(post.id),
                    followed: followed.contains(post.sellerName),
                    favorite: favorites.contains(post.id),
                    downloaded: downloaded.contains(post.id),
                    onLike: () {
                      setState(() {
                        liked.contains(post.id)
                            ? liked.remove(post.id)
                            : liked.add(post.id);
                      });
                      _track('video_like_toggle', post);
                    },
                    onFollow: () {
                      setState(() {
                        followed.contains(post.sellerName)
                            ? followed.remove(post.sellerName)
                            : followed.add(post.sellerName);
                      });
                      _track('seller_subscribe_toggle', post);
                    },
                    onFavorite: () {
                      setState(() {
                        favorites.contains(post.id)
                            ? favorites.remove(post.id)
                            : favorites.add(post.id);
                      });
                      _track('favorite_toggle', post);
                    },
                    onDownload: () {
                      setState(() => downloaded.add(post.id));
                      _track('download_media', post);
                      _snack('Téléchargement simulé');
                    },
                    onShare: () {
                      _track('share_media', post);
                      _snack('Lien de partage copié (simulation)');
                    },
                    onComments: () => _openComments(post),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.liked,
    required this.followed,
    required this.favorite,
    required this.downloaded,
    required this.onLike,
    required this.onFollow,
    required this.onFavorite,
    required this.onDownload,
    required this.onShare,
    required this.onComments,
  });

  final SocialPost post;
  final bool liked;
  final bool followed;
  final bool favorite;
  final bool downloaded;
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
                  Image.asset(post.imageAsset, fit: BoxFit.cover),
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
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        post.isShort
                            ? 'Short • ${post.distanceKm} km'
                            : 'Vidéo • ${post.distanceKm} km',
                        style: t.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                    icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: '${post.likes + (liked ? 1 : 0)}',
                    active: liked,
                    onTap: onLike,
                  ),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.comments}',
                    active: false,
                    onTap: onComments,
                  ),
                  _ActionButton(
                    icon: favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    label: 'Favori',
                    active: favorite,
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
                      downloaded ? Icons.download_done_rounded : Icons.download_rounded,
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

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});
  final SocialPost post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final controller = TextEditingController();
  final comments = <String>[
    'Ça a l’air trop bon, tu livres à Bonamoussadi ?',
    'Je recommande, portion généreuse.',
  ];
  final replies = <String, List<String>>{
    'Ça a l’air trop bon, tu livres à Bonamoussadi ?': ['Oui, livraison dispo.'],
  };

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      comments.insert(0, text);
      controller.clear();
    });
    EventTracker.instance.track(
      'comment_add',
      screen: 'CommentsSheet',
      element: widget.post.id,
      meta: text,
    );
  }

  void _addReply(String comment) {
    setState(() {
      replies.putIfAbsent(comment, () => []).add('Merci pour ton retour !');
    });
    EventTracker.instance.track(
      'reply_add',
      screen: 'CommentsSheet',
      element: widget.post.id,
      meta: comment,
    );
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
              child: ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 22),
                itemBuilder: (context, i) {
                  final comment = comments[i];
                  final commentReplies = replies[comment] ?? const <String>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment, style: t.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => _addReply(comment),
                        child: const Text('Répondre'),
                      ),
                      for (final reply in commentReplies)
                        Padding(
                          padding: const EdgeInsets.only(left: 18, top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.subdirectory_arrow_right_rounded, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text(reply)),
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

