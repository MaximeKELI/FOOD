import 'package:flutter/material.dart';
import '../../ui/chezmama_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final items = <String>[
    'Mafé Poulet',
    'Jus de Gingembre',
  ];

  void _remove(int index) {
    final removed = items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: FadeTransition(
          opacity: animation,
          child: _CartRow(
            title: removed,
            price: 1500,
            onRemove: () {},
          ),
        ),
      ),
      duration: const Duration(milliseconds: 240),
    );
    setState(() {});
  }

  void _add() {
    final index = items.length;
    items.add('Suya');
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 260),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Ajouter (demo)',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ChezMamaTheme.surface2,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: 5000 FCFA',
                      style: t.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: ChezMamaTheme.brandOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Commander'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: items.length,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartRow(
                          title: items[index],
                          price: 1500 + (index * 700),
                          onRemove: () => _remove(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.title,
    required this.price,
    required this.onRemove,
  });

  final String title;
  final double price;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: ChezMamaTheme.brandOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${price.toStringAsFixed(0)} FCFA',
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.ink.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

