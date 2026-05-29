import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../services/app_location_service.dart';
import '../../ui/chezmama_theme.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _cart = CartService.instance;
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _promo = TextEditingController();
  String _fulfillment = 'delivery';
  String _payment = 'cash';
  bool _submitting = false;

  LatLng? _loc;
  bool _locating = false;
  int _deliveryFee = 0;
  bool _quoting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    _promo.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final res = await AppLocationService.instance.acquireLocation();
    if (!mounted) return;
    setState(() {
      _loc = res.location;
      _locating = false;
    });
    if (res.location == null && res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error!)),
      );
    } else {
      _refreshQuote();
    }
  }

  Future<void> _refreshQuote() async {
    if (_fulfillment != 'delivery') {
      setState(() => _deliveryFee = 0);
      return;
    }
    setState(() => _quoting = true);
    try {
      final fee = await OrdersApi.instance.deliveryQuote(
        mealIds: _cart.mealIds,
        latitude: _loc?.latitude,
        longitude: _loc?.longitude,
      );
      if (!mounted) return;
      setState(() => _deliveryFee = fee);
    } catch (_) {
      // Keep previous estimate on failure.
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  int get _grandTotal => _cart.total + _deliveryFee;

  Future<void> _submit() async {
    if (_fulfillment == 'delivery' && _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique une adresse de livraison.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await OrdersApi.instance.createOrder(
        fulfillment: _fulfillment,
        paymentMethod: _payment,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        note: _note.text.trim(),
        items: _cart.toOrderItems(),
        latitude: _fulfillment == 'delivery' ? _loc?.latitude : null,
        longitude: _fulfillment == 'delivery' ? _loc?.longitude : null,
        promoCode: _promo.text.trim(),
      );
      _cart.clear();
      ReceivedOrdersNotifier.instance.refresh();
      if (!mounted) return;
      AuthScope.of(context).refreshMe();
      Navigator.of(context).pop();
      final extra = order.discount > 0
          ? ' (−${order.discount} FCFA promo)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande #${order.id} confirmée · ${order.total} FCFA$extra'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec: ${apiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finaliser la commande',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ${_cart.total} FCFA • ${_cart.count} article(s)',
              style: t.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ChezMamaTheme.brandBrown,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'delivery',
                  label: Text('Livraison'),
                  icon: Icon(Icons.delivery_dining_rounded),
                ),
                ButtonSegment(
                  value: 'pickup',
                  label: Text('Retrait'),
                  icon: Icon(Icons.storefront_rounded),
                ),
              ],
              selected: {_fulfillment},
              onSelectionChanged: (s) {
                setState(() => _fulfillment = s.first);
                _refreshQuote();
              },
            ),
            const SizedBox(height: 12),
            if (_fulfillment == 'delivery') ...[
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _loc != null
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                        ),
                  label: Text(
                    _loc != null
                        ? 'Position détectée (frais calculés)'
                        : 'Utiliser ma position',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mode de paiement',
              style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kPaymentMethods.entries.map((e) {
                final selected = _payment == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  labelStyle: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? ChezMamaTheme.brandBrown
                        : ChezMamaTheme.mutedInk(context),
                  ),
                  onSelected: (_) => setState(() => _payment = e.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code promo (optionnel)',
                prefixIcon: Icon(Icons.local_offer_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ChezMamaTheme.subtleSurface(context),
                borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
              ),
              child: Column(
                children: [
                  _line(t, 'Sous-total', '${_cart.total} FCFA'),
                  if (_fulfillment == 'delivery') ...[
                    const SizedBox(height: 6),
                    _line(
                      t,
                      'Livraison',
                      _quoting
                          ? '…'
                          : (_deliveryFee == 0
                              ? 'À estimer'
                              : '$_deliveryFee FCFA'),
                    ),
                  ],
                  const Divider(height: 18),
                  _line(t, 'Total', '$_grandTotal FCFA', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_submitting ? 'Envoi…' : 'Confirmer la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData t, String label, String value, {bool bold = false}) {
    final style = t.textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 16 : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
