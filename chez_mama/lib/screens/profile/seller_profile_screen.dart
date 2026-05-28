import 'package:flutter/material.dart';
import '../../api/accounts_api.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../home/meal_card.dart';
import '../meal/meal_details_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.sellerName = '',
  });

  final int sellerId;
  final String sellerName;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  SellerProfileView? _seller;
  List<Meal> _meals = [];
  bool _loading = true;
  String? _error;
  bool _followBusy = false;

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
      final results = await Future.wait([
        AccountsApi.instance.fetchSeller(widget.sellerId),
        CatalogApi.instance.fetchMeals(sellerId: widget.sellerId),
      ]);
      if (!mounted) return;
      setState(() {
        _seller = results[0] as SellerProfileView;
        _meals = results[1] as List<Meal>;
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

  Future<void> _toggleFollow() async {
    final seller = _seller;
    if (seller == null || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final following = await AccountsApi.instance.toggleFollow(seller.id);
      if (!mounted) return;
      setState(() {
        _seller = SellerProfileView(
          id: seller.id,
          name: seller.name,
          phone: seller.phone,
          shopName: seller.shopName,
          shopCategory: seller.shopCategory,
          cuisine: seller.cuisine,
          city: seller.city,
          neighborhood: seller.neighborhood,
          opensAt: seller.opensAt,
          closesAt: seller.closesAt,
          acceptsDelivery: seller.acceptsDelivery,
          acceptsPickup: seller.acceptsPickup,
          followersCount:
              seller.followersCount + (following ? 1 : -1),
          mealsCount: seller.mealsCount,
          followedByMe: following,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _seller?.shopName.isNotEmpty == true
              ? _seller!.shopName
              : (widget.sellerName.isEmpty ? 'Vendeur' : widget.sellerName),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _seller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46),
              const SizedBox(height: 10),
              Text(_error ?? 'Vendeur introuvable', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
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
    final seller = _seller!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          _Header(
            seller: seller,
            followBusy: _followBusy,
            onToggleFollow: _toggleFollow,
          ),
          const SizedBox(height: 18),
          Text(
            'Ses plats (${_meals.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          if (_meals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucun plat publié.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemCount: _meals.length,
              itemBuilder: (context, i) {
                final meal = _meals[i];
                return MealCard(
                  meal: meal,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MealDetailsScreen(meal: meal),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.seller,
    required this.followBusy,
    required this.onToggleFollow,
  });

  final SellerProfileView seller;
  final bool followBusy;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final location = [seller.neighborhood, seller.city]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    ChezMamaTheme.brandOrange.withValues(alpha: 0.15),
                child: const Icon(Icons.storefront_rounded,
                    color: ChezMamaTheme.brandOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.shopName.isEmpty ? seller.name : seller.shopName,
                      style: t.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (seller.cuisine.isNotEmpty)
                      Text(seller.cuisine,
                          style: t.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(value: '${seller.mealsCount}', label: 'Plats'),
              const SizedBox(width: 18),
              _Stat(value: '${seller.followersCount}', label: 'Abonnés'),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 16),
                const SizedBox(width: 4),
                Text(location, style: t.textTheme.bodySmall),
              ],
            ),
          ],
          if (seller.opensAt.isNotEmpty && seller.closesAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16),
                const SizedBox(width: 4),
                Text('${seller.opensAt} - ${seller.closesAt}',
                    style: t.textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: followBusy ? null : onToggleFollow,
              icon: Icon(
                seller.followedByMe
                    ? Icons.check_rounded
                    : Icons.person_add_alt_1_rounded,
              ),
              label: Text(seller.followedByMe ? 'Abonné' : 'S’abonner'),
              style: FilledButton.styleFrom(
                backgroundColor: seller.followedByMe
                    ? ChezMamaTheme.brandBrown
                    : ChezMamaTheme.brandOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: t.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            )),
        Text(label, style: t.textTheme.bodySmall),
      ],
    );
  }
}
