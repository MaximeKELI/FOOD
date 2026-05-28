import 'package:flutter/material.dart';
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
  final name = TextEditingController();
  final phone = TextEditingController();
  final country = TextEditingController(text: 'Cameroun');
  final city = TextEditingController();
  final neighborhood = TextEditingController();
  final birthYear = TextEditingController();
  final gender = TextEditingController();

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
    setState(() => busy = true);
    try {
      final auth = AuthScope.of(context);
      final profileJson = _buildProfileJson();
      await EventTracker.instance.track(
        'register_submit',
        screen: 'RegisterScreen',
        meta: profileJson,
      );
      await auth.register(
        name: name.text,
        email: email.text,
        password: password.text,
        profileJson: profileJson,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _buildProfileJson() {
    String s(String v) => v.trim();
    return <String, Object?>{
      'name': s(name.text),
      'phone': s(phone.text),
      'country': s(country.text),
      'city': s(city.text),
      'neighborhood': s(neighborhood.text),
      'birthYear': s(birthYear.text),
      'gender': s(gender.text),
      'shopName': s(shopName.text),
      'shopCategory': s(shopCategory.text),
      'cuisine': s(cuisine.text),
      'opensAt': s(opensAt.text),
      'closesAt': s(closesAt.text),
      'deliveryRadiusKm': s(deliveryRadiusKm.text),
      'acceptsDelivery': acceptsDelivery.value,
      'acceptsPickup': acceptsPickup.value,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    }.toString();
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      color: ChezMamaTheme.ink.withValues(alpha: 0.7),
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
                      prefixIcon: Icon(Icons.badge_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (WhatsApp)',
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: country,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Pays',
                            prefixIcon: Icon(Icons.public_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: city,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Ville',
                            prefixIcon: Icon(Icons.location_city_rounded),
                            border: OutlineInputBorder(),
                          ),
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
                      prefixIcon: Icon(Icons.place_rounded),
                      border: OutlineInputBorder(),
                    ),
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
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: gender,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Genre (optionnel)',
                            prefixIcon: Icon(Icons.person_rounded),
                            border: OutlineInputBorder(),
                          ),
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
                      prefixIcon: Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: shopCategory,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Type (Restaurant, Traiteur, …)',
                            prefixIcon: Icon(Icons.category_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cuisine,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Cuisine (Africaine, …)',
                            prefixIcon: Icon(Icons.restaurant_menu_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: opensAt,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Ouverture',
                            prefixIcon: Icon(Icons.schedule_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: closesAt,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Fermeture',
                            prefixIcon: Icon(Icons.schedule_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deliveryRadiusKm,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Rayon de livraison (km)',
                      prefixIcon: Icon(Icons.route_rounded),
                      border: OutlineInputBorder(),
                    ),
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
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_rounded),
                      border: OutlineInputBorder(),
                    ),
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

