import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../api/social_api.dart';
import '../../auth/auth_scope.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';

class MyPublicationsScreen extends StatefulWidget {
  const MyPublicationsScreen({super.key});

  @override
  State<MyPublicationsScreen> createState() => _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends State<MyPublicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int? _userId;

  List<Meal> _meals = [];
  List<ApiPost> _videos = [];
  List<ApiPost> _shorts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = AuthScope.of(context).userId;
      _load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CatalogApi.instance.fetchMeals(sellerId: _userId),
        SocialApi.instance.fetchPosts(isShort: false, authorId: _userId),
        SocialApi.instance.fetchPosts(isShort: true, authorId: _userId),
      ]);
      if (!mounted) return;
      setState(() {
        _meals = results[0] as List<Meal>;
        _videos = results[1] as List<ApiPost>;
        _shorts = results[2] as List<ApiPost>;
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

  Future<bool> _confirm(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer $label ? Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteMeal(Meal meal) async {
    if (!await _confirm('le plat "${meal.name}"')) return;
    try {
      await CatalogApi.instance.deleteMeal(meal.id);
      if (!mounted) return;
      setState(() => _meals.removeWhere((m) => m.id == meal.id));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deletePost(ApiPost post, bool isShort) async {
    if (!await _confirm(isShort ? 'ce short' : 'cette vidéo')) return;
    try {
      await SocialApi.instance.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        (isShort ? _shorts : _videos).removeWhere((p) => p.id == post.id);
      });
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(apiErrorMessage(e))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes publications'),
        bottom: TabBar(
          controller: _tab,
          labelColor: ChezMamaTheme.brandOrange,
          indicatorColor: ChezMamaTheme.brandOrange,
          tabs: const [
            Tab(text: 'Plats'),
            Tab(text: 'Vidéos'),
            Tab(text: 'Shorts'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tab,
                  children: [
                    _MealsTab(meals: _meals, onDelete: _deleteMeal),
                    _PostsTab(
                      posts: _videos,
                      emptyText: 'Aucune vidéo publiée.',
                      onDelete: (p) => _deletePost(p, false),
                    ),
                    _PostsTab(
                      posts: _shorts,
                      emptyText: 'Aucun short publié.',
                      onDelete: (p) => _deletePost(p, true),
                    ),
                  ],
                ),
    );
  }
}

class _MealsTab extends StatelessWidget {
  const _MealsTab({required this.meals, required this.onDelete});
  final List<Meal> meals;
  final ValueChanged<Meal> onDelete;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return const Center(child: Text('Aucun plat publié.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final meal = meals[i];
        return _Row(
          title: meal.name,
          subtitle: meal.category,
          imageUrl: meal.image,
          onDelete: () => onDelete(meal),
        );
      },
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.posts,
    required this.emptyText,
    required this.onDelete,
  });
  final List<ApiPost> posts;
  final String emptyText;
  final ValueChanged<ApiPost> onDelete;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final post = posts[i];
        return _Row(
          title: post.caption.isEmpty ? '(sans texte)' : post.caption,
          subtitle:
              '${post.likeCount} j’aime • ${post.commentCount} commentaire(s)',
          imageUrl: post.isVideo ? '' : post.mediaUrl,
          leadingIcon: post.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
          onDelete: () => onDelete(post),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onDelete,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData? leadingIcon;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.08),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _icon(leadingIcon),
                    )
                  : _icon(leadingIcon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _icon(IconData? icon) {
    return Container(
      color: ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
      child: Icon(
        icon ?? Icons.restaurant_rounded,
        color: ChezMamaTheme.brandOrange,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
              label: const Text('Réessayer'),
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
