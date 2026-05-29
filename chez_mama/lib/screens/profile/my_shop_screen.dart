import 'package:flutter/material.dart';
import '../../api/accounts_api.dart';
import '../../api/api_client.dart';
import '../../auth/auth_scope.dart';
import '../../services/app_location_service.dart';
import '../../ui/chezmama_theme.dart';

class MyShopScreen extends StatefulWidget {
  const MyShopScreen({super.key});

  @override
  State<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends State<MyShopScreen> {
  final _displayName = TextEditingController();
  final _phone = TextEditingController();
  final _shopName = TextEditingController();
  final _shopCategory = TextEditingController();
  final _cuisine = TextEditingController();
  final _city = TextEditingController();
  final _neighborhood = TextEditingController();
  final _opensAt = TextEditingController();
  final _closesAt = TextEditingController();
  final _radius = TextEditingController();

  bool _acceptsDelivery = true;
  bool _acceptsPickup = true;
  double? _lat;
  double? _lng;

  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _displayName,
      _phone,
      _shopName,
      _shopCategory,
      _cuisine,
      _city,
      _neighborhood,
      _opensAt,
      _closesAt,
      _radius,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AccountsApi.instance.fetchMyProfile();
      if (!mounted) return;
      _shopName.text = profile['shop_name'] as String? ?? '';
      _shopCategory.text = profile['shop_category'] as String? ?? '';
      _cuisine.text = profile['cuisine'] as String? ?? '';
      _city.text = profile['city'] as String? ?? '';
      _neighborhood.text = profile['neighborhood'] as String? ?? '';
      _opensAt.text = profile['opens_at'] as String? ?? '';
      _closesAt.text = profile['closes_at'] as String? ?? '';
      _radius.text = (profile['delivery_radius_km'] ?? 5).toString();
      _acceptsDelivery = profile['accepts_delivery'] as bool? ?? true;
      _acceptsPickup = profile['accepts_pickup'] as bool? ?? true;
      _lat = (profile['latitude'] as num?)?.toDouble();
      _lng = (profile['longitude'] as num?)?.toDouble();

      final auth = AuthScope.of(context);
      _displayName.text = auth.userName ?? '';

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final result = await AppLocationService.instance.acquireLocation();
      if (!mounted) return;
      if (result.location != null) {
        setState(() {
          _lat = result.location!.latitude;
          _lng = result.location!.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position enregistrée.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Localisation indisponible.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountsApi.instance.updateMyProfile({
        'shop_name': _shopName.text.trim(),
        'shop_category': _shopCategory.text.trim(),
        'cuisine': _cuisine.text.trim(),
        'city': _city.text.trim(),
        'neighborhood': _neighborhood.text.trim(),
        'opens_at': _opensAt.text.trim(),
        'closes_at': _closesAt.text.trim(),
        'delivery_radius_km': int.tryParse(_radius.text.trim()) ?? 5,
        'accepts_delivery': _acceptsDelivery,
        'accepts_pickup': _acceptsPickup,
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
      });
      await AccountsApi.instance.updateMe(
        displayName: _displayName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boutique mise à jour.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma boutique')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    final hasLocation = _lat != null && _lng != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        _section('Identité'),
        _field(_displayName, 'Nom affiché', Icons.person_rounded),
        _field(_phone, 'Téléphone', Icons.phone_rounded,
            keyboard: TextInputType.phone),
        _section('Boutique'),
        _field(_shopName, 'Nom de la boutique', Icons.storefront_rounded),
        _field(_shopCategory, 'Catégorie', Icons.category_rounded),
        _field(_cuisine, 'Cuisine', Icons.restaurant_menu_rounded),
        _section('Localisation'),
        _field(_city, 'Ville', Icons.location_city_rounded),
        _field(_neighborhood, 'Quartier', Icons.map_rounded),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ChezMamaTheme.subtleSurface(context),
            borderRadius: BorderRadius.circular(ChezMamaTheme.rField),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.place_rounded : Icons.location_off_rounded,
                color: hasLocation
                    ? ChezMamaTheme.brandOrange
                    : ChezMamaTheme.brandBrown,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? 'Position: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                      : 'Aucune position définie',
                ),
              ),
              TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Utiliser ma position'),
              ),
            ],
          ),
        ),
        _section('Horaires & service'),
        Row(
          children: [
            Expanded(
              child: _field(_opensAt, 'Ouvre à', Icons.schedule_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_closesAt, 'Ferme à', Icons.schedule_rounded),
            ),
          ],
        ),
        _field(_radius, 'Rayon de livraison (km)', Icons.delivery_dining_rounded,
            keyboard: TextInputType.number),
        SwitchListTile(
          value: _acceptsDelivery,
          onChanged: (v) => setState(() => _acceptsDelivery = v),
          title: const Text('Livraison'),
          activeColor: ChezMamaTheme.brandOrange,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _acceptsPickup,
          onChanged: (v) => setState(() => _acceptsPickup = v),
          title: const Text('Retrait sur place'),
          activeColor: ChezMamaTheme.brandOrange,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
