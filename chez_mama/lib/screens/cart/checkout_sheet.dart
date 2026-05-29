import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../api/payments_api.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_location_service.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/accessible_icon_button.dart';
import '../auth/login_screen.dart';

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
  int _promoDiscount = 0;
  String? _quoteError;
  bool _quoting = false;
  bool _validatingPromo = false;

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
      setState(() {
        _deliveryFee = 0;
        _quoteError = null;
      });
      return;
    }
    if (_loc == null) {
      setState(() {
        _deliveryFee = 0;
        _quoteError = tr('checkout.needLocationQuote');
      });
      return;
    }
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final fee = await OrdersApi.instance.deliveryQuote(
        mealIds: _cart.mealIds,
        latitude: _loc?.latitude,
        longitude: _loc?.longitude,
      );
      if (!mounted) return;
      setState(() => _deliveryFee = fee);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteError = apiErrorMessage(e);
        _deliveryFee = 0;
      });
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _validatePromo() async {
    final code = _promo.text.trim();
    if (code.isEmpty) {
      setState(() => _promoDiscount = 0);
      return;
    }
    setState(() => _validatingPromo = true);
    try {
      final res = await OrdersApi.instance.validatePromo(
        promoCode: code,
        items: _cart.toOrderItems(),
      );
      if (!mounted) return;
      setState(() => _promoDiscount = res.discount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trf('checkout.promoApplied', {
              'amount': formatFcfa(res.discount),
            }),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _promoDiscount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _validatingPromo = false);
    }
  }

  int get _grandTotal =>
      (_cart.total + _deliveryFee - _promoDiscount).clamp(0, 1 << 30);

  bool _isDigitalPayment(String method) =>
      method == 'wave' ||
      method == 'orange_money' ||
      method == 'free_money';

  Future<bool> _waitForPayment(int paymentId) async {
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final intent = await PaymentsApi.instance.status(paymentId);
      if (intent.status == 'paid') return true;
      if (intent.status == 'failed' || intent.status == 'cancelled') {
        return false;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (!AuthScope.of(context).isAuthed) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    if (_fulfillment == 'delivery' && _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('checkout.needAddress'))),
      );
      return;
    }
    if (_fulfillment == 'delivery' && _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('checkout.needPhone'))),
      );
      return;
    }
    if (_fulfillment == 'delivery' && _loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('checkout.needGps'))),
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
      var paid = !_isDigitalPayment(_payment);
      if (_isDigitalPayment(_payment)) {
        final intent = await PaymentsApi.instance.initiate(order.id);
        if (intent.checkoutUrl.isNotEmpty) {
          final uri = Uri.parse(intent.checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            paid = await _waitForPayment(intent.id);
          }
        }
      }
      if (paid || _payment == 'cash') {
        _cart.clear();
      }
      ReceivedOrdersNotifier.instance.refresh();
      if (!mounted) return;
      AuthScope.of(context).refreshMe();
      Navigator.of(context).pop();
      final extra = order.discount > 0
          ? trf('checkout.discountExtra', {
              'amount': formatFcfa(order.discount),
            })
          : '';
      final message = paid
          ? trf('checkout.orderConfirmed', {
              'id': order.id,
              'total': formatFcfa(order.total),
              'extra': extra,
            })
          : trf('checkout.orderPendingPay', {
              'id': order.id,
              'total': formatFcfa(order.total),
              'extra': extra,
            });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trf('checkout.failed', {'error': apiErrorMessage(e)}),
          ),
        ),
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
              tr('checkout.title'),
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              trf('cart.summary', {
                'total': formatFcfa(_cart.total),
                'count': _cart.count,
              }),
              style: t.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ChezMamaTheme.brandBrown,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'delivery',
                  label: Text(tr('checkout.delivery')),
                  icon: const Icon(Icons.delivery_dining_rounded),
                ),
                ButtonSegment(
                  value: 'pickup',
                  label: Text(tr('checkout.pickup')),
                  icon: const Icon(Icons.storefront_rounded),
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
                decoration: InputDecoration(
                  labelText: tr('checkout.address'),
                  prefixIcon: const Icon(Icons.place_rounded),
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
                        ? tr('checkout.locationOkQuoted')
                        : tr('checkout.useLocation'),
                  ),
                ),
              ),
              if (_quoteError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _quoteError!,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: ChezMamaTheme.brandBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('checkout.phone'),
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: tr('checkout.note'),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('checkout.paymentMode'),
              style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kPaymentMethodKeys.map((key) {
                final selected = _payment == key;
                return ChoiceChip(
                  label: Text(paymentMethodLabel(key)),
                  selected: selected,
                  labelStyle: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? ChezMamaTheme.brandBrown
                        : ChezMamaTheme.mutedInk(context),
                  ),
                  onSelected: (_) => setState(() => _payment = key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promo,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: tr('checkout.promo'),
                prefixIcon: const Icon(Icons.local_offer_rounded),
                suffixIcon: _validatingPromo
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : AccessibleIconButton(
                        icon: Icons.check_rounded,
                        label: tr('checkout.verifyPromo'),
                        onPressed: _validatePromo,
                      ),
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
                  _line(t, tr('checkout.subtotal'), formatFcfa(_cart.total)),
                  if (_fulfillment == 'delivery') ...[
                    const SizedBox(height: 6),
                    _line(
                      t,
                      tr('checkout.deliveryFee'),
                      _quoting
                          ? '…'
                          : (_deliveryFee == 0
                              ? tr('checkout.toEstimate')
                              : formatFcfa(_deliveryFee)),
                    ),
                  ],
                  if (_promoDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _line(
                      t,
                      tr('checkout.promoLine'),
                      '−${formatFcfa(_promoDiscount)}',
                    ),
                  ],
                  const Divider(height: 18),
                  _line(t, tr('cart.total'), formatFcfa(_grandTotal), bold: true),
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
                label: Text(
                  _submitting ? tr('checkout.submitting') : tr('checkout.confirm'),
                ),
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
