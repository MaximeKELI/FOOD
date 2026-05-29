import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/accessible_icon_button.dart';
import '../../widgets/entrance.dart';
import '../../widgets/food_network_image.dart';
import '../auth/login_screen.dart';
import 'checkout_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.onSeeOrders});

  final VoidCallback onSeeOrders;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService.instance;

  void _openCheckout() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('cart.empty'))),
      );
      return;
    }
    if (!AuthScope.of(context).isAuthed) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      body: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          if (_cart.isEmpty) {
            return _EmptyCart(onSeeOrders: widget.onSeeOrders);
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
                          '${tr('cart.total')}: ${formatFcfa(_cart.total)}',
                          style: t.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _openCheckout,
                        child: Text(tr('cart.checkout')),
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
              child: _buildItemImage(item.image),
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
                  formatFcfa(item.unitPrice),
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.mutedInk(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AccessibleIconButton(
            icon: Icons.remove_rounded,
            label: tr('action.decreaseQty'),
            onPressed: onRemove,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          AccessibleIconButton(
            icon: Icons.add_rounded,
            label: tr('action.increaseQty'),
            onPressed: onAdd,
          ),
          AccessibleIconButton(
            icon: Icons.delete_outline_rounded,
            label: tr('action.delete'),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String image) {
    if (image.startsWith('assets/')) {
      return Image.asset(image, fit: BoxFit.cover);
    }
    if (image.startsWith('http')) {
      return FoodNetworkImage(url: image, fit: BoxFit.cover);
    }
    return const _Thumb();
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
              tr('cart.empty'),
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              tr('cart.emptyHint'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSeeOrders,
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(tr('cart.orders')),
            ),
          ],
        ),
      ),
    );
  }
}
