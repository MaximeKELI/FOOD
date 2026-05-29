import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/accessible_icon_button.dart';
import '../../widgets/entrance.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/food_card.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/quantity_stepper.dart';
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
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ChezMamaTheme.spaceMd,
                  ChezMamaTheme.spaceMd,
                  ChezMamaTheme.spaceMd,
                  ChezMamaTheme.navClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('cart.title'),
                      style: t.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trf('cart.summary', {
                        'total': formatFcfa(_cart.total),
                        'count': _cart.count,
                      }),
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: ChezMamaTheme.mutedInk(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: ChezMamaTheme.spaceMd),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _cart.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: ChezMamaTheme.spaceSm),
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
              ),
              Positioned(
                left: ChezMamaTheme.spaceMd,
                right: ChezMamaTheme.spaceMd,
                bottom: ChezMamaTheme.navClearance - 8,
                child: _CheckoutBar(
                  total: _cart.total,
                  onCheckout: _openCheckout,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onCheckout});

  final int total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ChezMamaTheme.spaceMd),
      decoration: ChezMamaTheme.cardDecoration(
        context,
        shadowOpacity: 0.16,
        border: Border.all(
          color: ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('cart.total'),
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.mutedInk(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatFcfa(total),
                  style: t.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ChezMamaTheme.brandBrown,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onCheckout,
            icon: const Icon(Icons.shopping_bag_rounded, size: 20),
            label: Text(tr('cart.checkout')),
          ),
        ],
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
    return Dismissible(
      key: ValueKey(item.mealId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: ChezMamaTheme.promoRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: ChezMamaTheme.promoRed),
      ),
      child: FoodCard(
        padding: const EdgeInsets.all(12),
        shadowOpacity: 0.08,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ChezMamaTheme.rField),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FoodNetworkImage(url: item.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatFcfa(item.unitPrice),
                    style: t.textTheme.bodySmall?.copyWith(
                      color: ChezMamaTheme.mutedInk(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatFcfa(item.lineTotal),
                    style: ChezMamaTheme.priceStyle(context, t),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                AccessibleIconButton(
                  icon: Icons.delete_outline_rounded,
                  label: tr('action.delete'),
                  onPressed: onDelete,
                ),
                const SizedBox(height: 4),
                QuantityStepper(
                  quantity: item.quantity,
                  onDecrement: onRemove,
                  onIncrement: onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onSeeOrders});
  final VoidCallback onSeeOrders;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.shopping_bag_outlined,
      lottieAsset: LottieAssets.empty,
      title: tr('cart.empty'),
      subtitle: tr('cart.emptyHint'),
      secondaryActionLabel: tr('cart.orders'),
      onSecondaryAction: onSeeOrders,
    );
  }
}
