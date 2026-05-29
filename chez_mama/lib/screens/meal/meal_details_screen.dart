import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/primary_button.dart';
import '../chat/conversation_screen.dart';
import '../profile/seller_profile_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({super.key, required this.meal});

  final Meal meal;

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  List<MealReview> _reviews = [];
  bool _loadingReviews = true;
  double _avg = 0;
  late bool _favorited;
  bool _favBusy = false;

  @override
  void initState() {
    super.initState();
    _avg = widget.meal.rating;
    _favorited = widget.meal.favoritedByMe;
    _loadReviews();
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy) return;
    setState(() => _favBusy = true);
    try {
      final fav = await CatalogApi.instance.toggleFavorite(widget.meal.id);
      if (!mounted) return;
      setState(() => _favorited = fav);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await CatalogApi.instance.fetchReviews(widget.meal.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
        if (reviews.isNotEmpty) {
          _avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _addReview() async {
    final result = await showModalBottomSheet<({int rating, String comment})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddReviewSheet(),
    );
    if (result == null) return;
    try {
      await CatalogApi.instance.addReview(
        widget.meal.id,
        rating: result.rating,
        comment: result.comment,
      );
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour ton avis !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Widget _buildHeroImage() {
    final meal = widget.meal;
    if (meal.image.startsWith('assets/')) {
      return Image.asset(
        meal.image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    }
    return Image.network(
      meal.image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, error, stackTrace) {
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
              Icons.restaurant_rounded,
              size: 54,
              color: ChezMamaTheme.brandOrange,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final meal = widget.meal;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 290,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: ChezMamaTheme.inkColor(context),
            actions: [
              IconButton(
                tooltip: _favorited ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed: _favBusy ? null : _toggleFavorite,
                icon: Icon(
                  _favorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _favorited ? Colors.red : null,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'meal_${meal.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildHeroImage(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: t.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.subtitle,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: ChezMamaTheme.mutedInk(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RatingSummary(avg: _avg, count: _reviews.length),
                  if (meal.sellerId != null && meal.sellerName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                            sellerId: meal.sellerId!,
                            sellerName: meal.sellerName,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded,
                                size: 18, color: ChezMamaTheme.brandOrange),
                            const SizedBox(width: 6),
                            Text(
                              meal.sellerName,
                              style: t.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: ChezMamaTheme.brandBrown,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (meal.isSpecial || !meal.isAvailable) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (meal.isSpecial)
                          _Badge(
                            label: 'Plat du jour',
                            color: ChezMamaTheme.brandBrown,
                            icon: Icons.local_fire_department_rounded,
                          ),
                        if (meal.isSpecial && !meal.isAvailable)
                          const SizedBox(width: 8),
                        if (!meal.isAvailable)
                          const _Badge(
                            label: 'Épuisé',
                            color: Color(0xFF8A8A8A),
                            icon: Icons.block_rounded,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ChezMamaTheme.subtleSurface(context),
                      borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (meal.hasPromo)
                                Text(
                                  '${meal.price.toStringAsFixed(0)} FCFA',
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    color: ChezMamaTheme.mutedInk(context),
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                '${meal.effectivePrice.toStringAsFixed(0)} FCFA',
                                style: t.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: meal.hasPromo
                                      ? const Color(0xFFD7263D)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PrimaryButton(
                          label: meal.isAvailable
                              ? tr('action.addToCart')
                              : tr('action.unavailable'),
                          onPressed: meal.isAvailable
                              ? () {
                                  final added =
                                      CartService.instance.addMeal(meal);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        added
                                            ? '${meal.name} ajouté au panier'
                                            : 'Ce plat ne peut pas être ajouté au panier.',
                                      ),
                                      duration:
                                          const Duration(milliseconds: 900),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (meal.sellerId != null &&
                      meal.sellerId != AuthScope.of(context).userId) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConversationScreen(
                              otherUserId: meal.sellerId!,
                              otherName: meal.sellerName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(tr('action.contactSeller')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Avis (${_reviews.length})',
                          style: t.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addReview,
                        icon: const Icon(Icons.rate_review_rounded),
                        label: const Text('Donner mon avis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Text(
                      'Aucun avis pour le moment. Sois le premier !',
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: ChezMamaTheme.mutedInk(context),
                      ),
                    )
                  else
                    ..._reviews.map((r) => _ReviewTile(review: r)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.avg, required this.count});
  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (count == 0) {
      return Text(
        'Pas encore noté',
        style: t.textTheme.bodySmall?.copyWith(
          color: ChezMamaTheme.mutedInk(context),
        ),
      );
    }
    return Row(
      children: [
        _Stars(value: avg),
        const SizedBox(width: 8),
        Text(
          '${avg.toStringAsFixed(1)} ($count)',
          style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 18});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: ChezMamaTheme.brandAmber,
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final MealReview review;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName.isEmpty ? 'Client' : review.userName,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Stars(value: review.rating.toDouble(), size: 15),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment, style: t.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  const _AddReviewSheet();

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donner mon avis',
            style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 36,
                  color: ChezMamaTheme.brandAmber,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(
                (rating: _rating, comment: _comment.text.trim()),
              ),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Publier mon avis'),
            ),
          ),
        ],
      ),
    );
  }
}
