import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../auth/auth_scope.dart';
import '../../analytics/event_tracker.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const countries = [
    'Cameroun',
    'Sénégal',
    'Côte d’Ivoire',
    'Nigeria',
    'Ghana',
    'Mali',
    'Bénin',
    'Togo',
    'France',
    'Autre',
  ];
  static const citiesByCountry = {
    'Cameroun': ['Douala', 'Yaoundé', 'Bafoussam', 'Garoua', 'Bamenda'],
    'Sénégal': ['Dakar', 'Thiès', 'Saint-Louis', 'Mbour'],
    'Côte d’Ivoire': ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San Pedro'],
    'Nigeria': ['Lagos', 'Abuja', 'Kano', 'Port Harcourt'],
    'Ghana': ['Accra', 'Kumasi', 'Tamale'],
    'Mali': ['Bamako', 'Sikasso', 'Mopti'],
    'Bénin': ['Cotonou', 'Porto-Novo', 'Parakou'],
    'Togo': ['Lomé', 'Sokodé', 'Kara'],
    'France': ['Paris', 'Lyon', 'Marseille', 'Toulouse'],
    'Autre': ['Autre'],
  };
  static const genders = ['Non précisé', 'Femme', 'Homme', 'Autre'];
  static const shopCategories = [
    'Restaurant',
    'Traiteur',
    'Street food',
    'Pâtisserie',
    'Boissons',
    'Épicerie locale',
    'Chef à domicile',
  ];
  static const cuisines = [
    'Africaine',
    'Camerounaise',
    'Sénégalaise',
    'Ivoirienne',
    'Nigériane',
    'Ghanéenne',
    'Fusion',
    'Végétarienne',
  ];
  static const hours = [
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '18:00',
    '20:00',
    '22:00',
    '00:00',
  ];
  static const deliveryRadii = ['1', '2', '3', '5', '8', '10', '15', '20'];

  final name = TextEditingController();
  final phone = TextEditingController();
  final country = TextEditingController(text: 'Cameroun');
  final city = TextEditingController(text: 'Douala');
  final neighborhood = TextEditingController();
  final birthYear = TextEditingController();
  final gender = TextEditingController(text: 'Non précisé');

  final shopName = TextEditingController();
  final shopCategory = TextEditingController(text: 'Restaurant');
  final cuisine = TextEditingController(text: 'Africaine');
  final opensAt = TextEditingController(text: '08:00');
  final closesAt = TextEditingController(text: '22:00');
  final deliveryRadiusKm = TextEditingController(text: '5');
  final acceptsDelivery = ValueNotifier<bool>(true);
  final acceptsPickup = ValueNotifier<bool>(true);

  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  List<String> get _cityOptions {
    return citiesByCountry[country.text] ?? const ['Autre'];
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    country.dispose();
    city.dispose();
    neighborhood.dispose();
    birthYear.dispose();
    gender.dispose();
    shopName.dispose();
    shopCategory.dispose();
    cuisine.dispose();
    opensAt.dispose();
    closesAt.dispose();
    deliveryRadiusKm.dispose();
    acceptsDelivery.dispose();
    acceptsPickup.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email requis et mot de passe d’au moins 6 caractères.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final auth = AuthScope.of(context);
      final profile = _buildProfile();
      await EventTracker.instance.track(
        'register_submit',
        screen: 'RegisterScreen',
        meta: profile.toString(),
      );
      await auth.register(
        name: name.text,
        email: email.text,
        password: password.text,
        profile: profile,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Map<String, dynamic> _buildProfile() {
    String s(String v) => v.trim();
    return <String, dynamic>{
      'phone': s(phone.text),
      'country': s(country.text),
      'city': s(city.text),
      'neighborhood': s(neighborhood.text),
      'birth_year': s(birthYear.text),
      'gender': s(gender.text),
      'shop_name': s(shopName.text),
      'shop_category': s(shopCategory.text),
      'cuisine': s(cuisine.text),
      'opens_at': s(opensAt.text),
      'closes_at': s(closesAt.text),
      'delivery_radius_km': int.tryParse(s(deliveryRadiusKm.text)) ?? 5,
      'accepts_delivery': acceptsDelivery.value,
      'accepts_pickup': acceptsPickup.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ChezMamaTheme.cardColor(context),
                borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil vendeur',
                    style: t.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crée ton compte pour mettre tes produits en ligne.',
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: ChezMamaTheme.mutedInk(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Infos personnelles',
                    style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nom boutique / vendeur',
                      prefixIcon: Icon(Icons.badge_rounded),                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (WhatsApp)',
                      prefixIcon: Icon(Icons.phone_rounded),                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Pays',
                          icon: Icons.public_rounded,
                          value: country.text,
                          items: countries,
                          onChanged: (value) {
                            setState(() {
                              country.text = value;
                              city.text = citiesByCountry[value]?.first ?? 'Autre';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Ville',
                          icon: Icons.location_city_rounded,
                          value: city.text,
                          items: _cityOptions,
                          onChanged: (value) => setState(() => city.text = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: neighborhood,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Quartier',
                      prefixIcon: Icon(Icons.place_rounded),                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: birthYear,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Année de naissance',
                            prefixIcon: Icon(Icons.cake_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Genre',
                          icon: Icons.person_rounded,
                          value: gender.text,
                          items: genders,
                          onChanged: (value) => setState(() => gender.text = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Infos business',
                    style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: shopName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nom du restaurant / boutique',
                      prefixIcon: Icon(Icons.storefront_rounded),                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Type',
                          icon: Icons.category_rounded,
                          value: shopCategory.text,
                          items: shopCategories,
                          onChanged: (value) =>
                              setState(() => shopCategory.text = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Cuisine',
                          icon: Icons.restaurant_menu_rounded,
                          value: cuisine.text,
                          items: cuisines,
                          onChanged: (value) => setState(() => cuisine.text = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Ouverture',
                          icon: Icons.schedule_rounded,
                          value: opensAt.text,
                          items: hours,
                          onChanged: (value) => setState(() => opensAt.text = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Fermeture',
                          icon: Icons.schedule_rounded,
                          value: closesAt.text,
                          items: hours,
                          onChanged: (value) => setState(() => closesAt.text = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Rayon de livraison (km)',
                    icon: Icons.route_rounded,
                    value: deliveryRadiusKm.text,
                    items: deliveryRadii,
                    onChanged: (value) =>
                        setState(() => deliveryRadiusKm.text = value),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: acceptsDelivery,
                    builder: (context, v, _) {
                      return SwitchListTile(
                        value: v,
                        onChanged: (x) => acceptsDelivery.value = x,
                        title: const Text('Livraison disponible'),
                        activeColor: ChezMamaTheme.brandOrange,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: acceptsPickup,
                    builder: (context, v, _) {
                      return SwitchListTile(
                        value: v,
                        onChanged: (x) => acceptsPickup.value = x,
                        title: const Text('Retrait sur place'),
                        activeColor: ChezMamaTheme.brandOrange,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Accès au compte',
                    style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_rounded),                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AbsorbPointer(
                      absorbing: busy,
                      child: PrimaryButton(
                        label: busy ? 'Création…' : 'Créer le compte',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: resolvedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      borderRadius: BorderRadius.circular(ChezMamaTheme.rField),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

