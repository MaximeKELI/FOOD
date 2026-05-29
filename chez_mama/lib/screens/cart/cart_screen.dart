import 'package:flutter/material.dart';
import '../../cart/cart_service.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/entrance.dart';
import 'checkout_sheet.dart';
import 'orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService.instance;

  void _openCheckout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ton panier est vide.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          IconButton(
            tooltip: 'Mes commandes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          if (_cart.isEmpty) {
            return _EmptyCart(
              onSeeOrders: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ChezMamaTheme.subtleSurface(context),
                    borderRadius:
                        BorderRadius.circular(ChezMamaTheme.rCard),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: ${_cart.total} FCFA',
                          style: t.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _openCheckout,
                        child: const Text('Commander'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _cart.items[index];
                      return FadeInUp(
                        index: index,
                        child: _CartRow(
                          item: item,
                          onAdd: () => _cart.increment(item.mealId),
                          onRemove: () => _cart.decrement(item.mealId),
                          onDelete: () => _cart.removeItem(item.mealId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: item.image.startsWith('http')
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _Thumb(),
                    )
                  : const _Thumb(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.unitPrice} FCFA',
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.mutedInk(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _QtyButton(icon: Icons.remove_rounded, onTap: onRemove),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QtyButton(icon: Icons.add_rounded, onTap: onAdd),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
      child: const Icon(Icons.restaurant_rounded, color: ChezMamaTheme.brandOrange),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ChezMamaTheme.subtleSurface(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: ChezMamaTheme.brandBrown),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onSeeOrders});
  final VoidCallback onSeeOrders;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              'Ton panier est vide',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoute des plats depuis l’accueil pour passer commande.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSeeOrders,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Voir mes commandes'),
            ),
          ],
        ),
      ),
    );
  }
}
