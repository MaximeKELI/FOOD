import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../analytics/device_context.dart';
import '../../analytics/event_tracker.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../api/payments_api.dart';
import '../../api/support_api.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../payments/payment_pending_service.dart';
import '../../payments/stripe_payment_service.dart';
import '../../services/app_location_service.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/accessible_icon_button.dart';
import '../../widgets/section_header.dart';
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
  final _points = TextEditingController();
  String _fulfillment = 'delivery';
  String _payment = 'cash';
  bool _submitting = false;

  LatLng? _loc;
  bool _locating = false;
  int _deliveryFee = 0;
  int _promoDiscount = 0;
  int _pointsDiscount = 0;
  String? _quoteError;
  bool _quoting = false;
  bool _validatingPromo = false;
  DateTime? _scheduledFor;
  List<SavedAddress> _savedAddresses = [];
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQuote();
      _loadAddresses();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    _promo.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    if (!AuthScope.of(context).isAuthed) return;
    try {
      final list = await SupportApi.instance.fetchAddresses();
      if (!mounted) return;
      setState(() {
        _savedAddresses = list;
        final def = list.where((a) => a.isDefault).toList();
        if (def.isNotEmpty) _applyAddress(def.first);
      });
    } catch (_) {}
  }

  void _applyAddress(SavedAddress a) {
    _selectedAddressId = a.id;
    _address.text = a.address;
    if (a.phone.isNotEmpty) _phone.text = a.phone;
    if (a.latitude != null && a.longitude != null) {
      _loc = LatLng(a.latitude!, a.longitude!);
      _refreshQuote();
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _previewPoints() async {
    final pts = int.tryParse(_points.text.trim()) ?? 0;
    if (pts <= 0) {
      setState(() => _pointsDiscount = 0);
      return;
    }
    try {
      final preview = await OrdersApi.instance.loyaltyRedeemPreview(
        points: pts,
        subtotal: _cart.total,
      );
      if (!mounted) return;
      setState(() => _pointsDiscount = preview.discountFcfa);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pointsDiscount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
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
      (_cart.total + _deliveryFee - _promoDiscount - _pointsDiscount)
          .clamp(0, 1 << 30);

  bool _isDigitalPayment(String method) =>
      method == 'stripe' ||
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
      final deviceContext = Map<String, dynamic>.from(
        await DeviceContext.instance.collect(
          context: context,
          location: _loc,
        ),
      )..remove('session_id');
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
        scheduledFor: _scheduledFor?.toUtc().toIso8601String(),
        pointsToRedeem: int.tryParse(_points.text.trim()),
        deviceContext: deviceContext,
      );
      await EventTracker.instance.track(
        'order',
        screen: 'checkout',
        meta: 'order_id=${order.id}',
      );
      var paid = !_isDigitalPayment(_payment);
      if (_payment == 'stripe') {
        try {
          final intentId = await StripePaymentService.instance.payOrder(order.id);
          paid = await _waitForPayment(intentId);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiErrorMessage(e))),
          );
          return;
        }
      } else if (_isDigitalPayment(_payment)) {
        final intent = await PaymentsApi.instance.initiate(order.id);
        PaymentPendingService.instance.track(
          intentId: intent.id,
          orderId: order.id,
        );
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
        PaymentPendingService.instance.clear();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('checkout.title'),
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
                        fontWeight: FontWeight.w700,
                        color: ChezMamaTheme.brandBrown,
                      ),
                    ),
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    SectionHeader(
                      title: tr('checkout.fulfillmentSection'),
                      icon: Icons.local_shipping_rounded,
                    ),
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
                      if (_savedAddresses.isNotEmpty) ...[
                        Text(
                          tr('checkout.savedAddresses'),
                          style: t.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _savedAddresses.map((a) {
                            final selected = _selectedAddressId == a.id;
                            return ChoiceChip(
                              label: Text(
                                a.label.isEmpty ? a.address : a.label,
                              ),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _applyAddress(a));
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text(tr('checkout.schedule')),
                      subtitle: Text(
                        _scheduledFor == null
                            ? tr('checkout.scheduleNow')
                            : _scheduledFor!.toLocal().toString().substring(0, 16),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_scheduledFor != null)
                            IconButton(
                              onPressed: () =>
                                  setState(() => _scheduledFor = null),
                              icon: const Icon(Icons.clear_rounded),
                            ),
                          IconButton(
                            onPressed: _pickSchedule,
                            icon: const Icon(Icons.edit_calendar_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _points,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('checkout.pointsRedeem'),
                        prefixIcon:
                            const Icon(Icons.workspace_premium_rounded),
                        suffixIcon: AccessibleIconButton(
                          icon: Icons.check_rounded,
                          label: tr('checkout.verifyPoints'),
                          onPressed: _previewPoints,
                        ),
                      ),
                    ),
                    if (_pointsDiscount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        trf('checkout.pointsDiscount', {
                          'amount': formatFcfa(_pointsDiscount),
                        }),
                        style: t.textTheme.bodySmall?.copyWith(
                          color: ChezMamaTheme.brandBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      tr('checkout.multiSellerNote'),
                      style: t.textTheme.bodySmall?.copyWith(
                        color: ChezMamaTheme.mutedInk(context),
                      ),
                    ),
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    SectionHeader(
                      title: tr('checkout.paymentMode'),
                      icon: Icons.payments_rounded,
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    SectionHeader(
                      title: tr('checkout.promo'),
                      icon: Icons.local_offer_rounded,
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _promo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: tr('checkout.promoHint'),
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
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    SectionHeader(
                      title: tr('checkout.summarySection'),
                      icon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(ChezMamaTheme.spaceMd),
                      decoration: ChezMamaTheme.subtleDecoration(context),
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
                          _line(
                            t,
                            tr('cart.total'),
                            formatFcfa(_grandTotal),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: ChezMamaTheme.cardColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
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
                      _submitting
                          ? tr('checkout.submitting')
                          : tr('checkout.confirm'),
                    ),
                  ),
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
