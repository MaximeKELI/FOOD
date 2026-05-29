import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { fr, en, wo }

extension AppLangX on AppLang {
  String get code => switch (this) {
        AppLang.fr => 'fr',
        AppLang.en => 'en',
        AppLang.wo => 'wo',
      };

  String get label => switch (this) {
        AppLang.fr => 'Français',
        AppLang.en => 'English',
        AppLang.wo => 'Wolof',
      };

  String get flag => switch (this) {
        AppLang.fr => '🇫🇷',
        AppLang.en => '🇬🇧',
        AppLang.wo => '🇸🇳',
      };
}

class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _key = 'app_lang';
  AppLang _lang = AppLang.fr;
  AppLang get lang => _lang;
  Locale get locale => Locale(_lang.code);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _lang = AppLang.values.firstWhere(
      (l) => l.code == saved,
      orElse: () => AppLang.fr,
    );
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.code);
  }
}

String tr(String key) {
  final lang = LocaleController.instance.lang;
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[lang] ?? entry[AppLang.fr] ?? key;
}

/// Interpolates `{name}` placeholders in translated strings.
String trf(String key, Map<String, Object> params) {
  var s = tr(key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', v.toString()));
  return s;
}

String paymentMethodLabel(String key) {
  return tr('payment.$key');
}

String orderStatusLabel(String key) {
  return tr('status.$key');
}

const Map<String, Map<AppLang, String>> _strings = {
  // App
  'app.name': {AppLang.fr: 'Food', AppLang.en: 'Food', AppLang.wo: 'Food'},
  'app.tagline': {
    AppLang.fr: 'Du chaud. Du local. Du bon.',
    AppLang.en: 'Hot. Local. Good.',
    AppLang.wo: 'Tàng. Local. Baax.',
  },

  // Navigation
  'nav.home': {AppLang.fr: 'Accueil', AppLang.en: 'Home', AppLang.wo: 'Kër'},
  'nav.shorts': {AppLang.fr: 'Shorts', AppLang.en: 'Shorts', AppLang.wo: 'Shorts'},
  'nav.videos': {AppLang.fr: 'Vidéos', AppLang.en: 'Videos', AppLang.wo: 'Wideo'},
  'nav.tracking': {AppLang.fr: 'Suivi', AppLang.en: 'Tracking', AppLang.wo: 'Topp'},
  'nav.cart': {AppLang.fr: 'Panier', AppLang.en: 'Cart', AppLang.wo: 'Pañe'},

  // Menu
  'menu.dashboard': {AppLang.fr: 'Tableau de bord', AppLang.en: 'Dashboard', AppLang.wo: 'Tablo'},
  'menu.shop': {AppLang.fr: 'Ma boutique', AppLang.en: 'My shop', AppLang.wo: 'Sama bitik'},
  'menu.publications': {AppLang.fr: 'Mes publications', AppLang.en: 'My publications', AppLang.wo: 'Sama yéene'},
  'menu.favorites': {AppLang.fr: 'Mes favoris', AppLang.en: 'My favorites', AppLang.wo: 'Sama soobé'},
  'menu.messages': {AppLang.fr: 'Messages', AppLang.en: 'Messages', AppLang.wo: 'Bataaxal'},
  'menu.loyalty': {AppLang.fr: 'Mes points', AppLang.en: 'My points', AppLang.wo: 'Sama poñ'},
  'menu.language': {AppLang.fr: 'Langue', AppLang.en: 'Language', AppLang.wo: 'Làkk'},
  'menu.darkMode': {AppLang.fr: 'Mode sombre', AppLang.en: 'Dark mode', AppLang.wo: 'Mode lëndëm'},
  'menu.lightMode': {AppLang.fr: 'Mode clair', AppLang.en: 'Light mode', AppLang.wo: 'Mode leer'},
  'menu.logout': {AppLang.fr: 'Déconnexion', AppLang.en: 'Log out', AppLang.wo: 'Génn'},
  'menu.receivedOrders': {AppLang.fr: 'Commandes reçues', AppLang.en: 'Received orders', AppLang.wo: 'Commande yi ñu jox ma'},

  // Auth
  'auth.login': {AppLang.fr: 'Se connecter', AppLang.en: 'Sign in', AppLang.wo: 'Dugg'},
  'auth.loginTitle': {AppLang.fr: 'Connexion', AppLang.en: 'Sign in', AppLang.wo: 'Dugg'},
  'auth.loginSubtitle': {
    AppLang.fr: 'Commande tes plats préférés ou gère ta boutique.',
    AppLang.en: 'Order your favorite dishes or manage your shop.',
    AppLang.wo: 'Commande sa ñam walla saytu sa bitik.',
  },
  'auth.email': {AppLang.fr: 'Email', AppLang.en: 'Email', AppLang.wo: 'Email'},
  'auth.password': {AppLang.fr: 'Mot de passe', AppLang.en: 'Password', AppLang.wo: 'Baatu jàll'},
  'auth.signingIn': {AppLang.fr: 'Connexion…', AppLang.en: 'Signing in…', AppLang.wo: 'Mi ngi dugg…'},
  'auth.noAccount': {AppLang.fr: 'Pas de compte ?', AppLang.en: 'No account?', AppLang.wo: 'Amul compte?'},
  'auth.createAccount': {AppLang.fr: 'Créer un compte', AppLang.en: 'Create account', AppLang.wo: 'Sos compte'},
  'auth.registerTitle': {AppLang.fr: 'Créer un compte vendeur', AppLang.en: 'Create seller account', AppLang.wo: 'Sos compte jaaykat'},
  'auth.fillEmailPassword': {
    AppLang.fr: 'Renseigne ton email et ton mot de passe.',
    AppLang.en: 'Enter your email and password.',
    AppLang.wo: 'Duggal sa email ak sa baatu jàll.',
  },
  'auth.sessionExpiredTitle': {
    AppLang.fr: 'Session expirée',
    AppLang.en: 'Session expired',
    AppLang.wo: 'Session bi jeex na',
  },
  'auth.sessionExpiredBody': {
    AppLang.fr: 'Reconnecte-toi pour continuer tes commandes.',
    AppLang.en: 'Sign in again to continue your orders.',
    AppLang.wo: 'Duggaat ngir wéyal sa commande.',
  },
  'auth.sellerRegister': {
    AppLang.fr: 'Devenir vendeur',
    AppLang.en: 'Become a seller',
    AppLang.wo: 'Ne jaaykat',
  },
  'register.sellerProfile': {
    AppLang.fr: 'Profil vendeur',
    AppLang.en: 'Seller profile',
    AppLang.wo: 'Profil jaaykat',
  },
  'register.subtitle': {
    AppLang.fr: 'Crée ton compte pour mettre tes produits en ligne.',
    AppLang.en: 'Create your account to list your products online.',
    AppLang.wo: 'Sos sa compte ngir yéene sa produit yi.',
  },
  'register.personalInfo': {
    AppLang.fr: 'Infos personnelles',
    AppLang.en: 'Personal info',
    AppLang.wo: 'Xibaar yu bopp',
  },
  'register.businessInfo': {
    AppLang.fr: 'Infos business',
    AppLang.en: 'Business info',
    AppLang.wo: 'Xibaar business',
  },
  'register.accountAccess': {
    AppLang.fr: 'Accès au compte',
    AppLang.en: 'Account access',
    AppLang.wo: 'Accès compte bi',
  },
  'register.shopSellerName': {
    AppLang.fr: 'Nom boutique / vendeur',
    AppLang.en: 'Shop / seller name',
    AppLang.wo: 'Tur bitik / jaaykat',
  },
  'register.phoneWhatsapp': {
    AppLang.fr: 'Téléphone (WhatsApp)',
    AppLang.en: 'Phone (WhatsApp)',
    AppLang.wo: 'Telefon (WhatsApp)',
  },
  'register.country': {AppLang.fr: 'Pays', AppLang.en: 'Country', AppLang.wo: 'Réew'},
  'register.city': {AppLang.fr: 'Ville', AppLang.en: 'City', AppLang.wo: 'Dëkk bi'},
  'register.neighborhood': {AppLang.fr: 'Quartier', AppLang.en: 'Neighborhood', AppLang.wo: 'Quartier'},
  'register.birthYear': {
    AppLang.fr: 'Année de naissance',
    AppLang.en: 'Birth year',
    AppLang.wo: 'Atum judd',
  },
  'register.gender': {AppLang.fr: 'Genre', AppLang.en: 'Gender', AppLang.wo: 'Jigéen walla góor'},
  'register.restaurantName': {
    AppLang.fr: 'Nom du restaurant / boutique',
    AppLang.en: 'Restaurant / shop name',
    AppLang.wo: 'Tur restaurant / bitik bi',
  },
  'register.type': {AppLang.fr: 'Type', AppLang.en: 'Type', AppLang.wo: 'Xeetu'},
  'register.cuisine': {AppLang.fr: 'Cuisine', AppLang.en: 'Cuisine', AppLang.wo: 'Cuisine'},
  'register.opening': {AppLang.fr: 'Ouverture', AppLang.en: 'Opening', AppLang.wo: 'Ubbi'},
  'register.closing': {AppLang.fr: 'Fermeture', AppLang.en: 'Closing', AppLang.wo: 'Tëj'},
  'register.deliveryRadius': {
    AppLang.fr: 'Rayon de livraison (km)',
    AppLang.en: 'Delivery radius (km)',
    AppLang.wo: 'Rayon yónnee (km)',
  },
  'register.deliveryAvailable': {
    AppLang.fr: 'Livraison disponible',
    AppLang.en: 'Delivery available',
    AppLang.wo: 'Yónnee am na',
  },
  'register.pickupAvailable': {
    AppLang.fr: 'Retrait sur place',
    AppLang.en: 'Pickup on site',
    AppLang.wo: 'Jël ci bitik bi',
  },
  'register.passwordRequired': {
    AppLang.fr: 'Email requis et mot de passe d’au moins 6 caractères.',
    AppLang.en: 'Email required and password must be at least 6 characters.',
    AppLang.wo: 'Email laaj na ak baatu jàll bu tollu ci 6 araf.',
  },
  'register.creating': {AppLang.fr: 'Création…', AppLang.en: 'Creating…', AppLang.wo: 'Mi ngi sos…'},
  'register.submit': {AppLang.fr: 'Créer le compte', AppLang.en: 'Create account', AppLang.wo: 'Sos compte bi'},

  // Actions
  'action.retry': {AppLang.fr: 'Réessayer', AppLang.en: 'Retry', AppLang.wo: 'Jéemataat'},
  'action.continueGuest': {AppLang.fr: 'Continuer', AppLang.en: 'Continue', AppLang.wo: 'Kontine'},
  'action.addToCart': {AppLang.fr: 'Ajouter au panier', AppLang.en: 'Add to cart', AppLang.wo: 'Yokk ci pañe'},
  'action.unavailable': {AppLang.fr: 'Indisponible', AppLang.en: 'Unavailable', AppLang.wo: 'Amul'},
  'action.contactSeller': {AppLang.fr: 'Contacter le vendeur', AppLang.en: 'Contact seller', AppLang.wo: 'Jokkoo ak jaaykat bi'},
  'action.delete': {AppLang.fr: 'Supprimer', AppLang.en: 'Remove', AppLang.wo: 'Dindi'},
  'action.decreaseQty': {AppLang.fr: 'Diminuer la quantité', AppLang.en: 'Decrease quantity', AppLang.wo: 'Waññi lim'},
  'action.increaseQty': {AppLang.fr: 'Augmenter la quantité', AppLang.en: 'Increase quantity', AppLang.wo: 'Yokk lim'},
  'action.close': {AppLang.fr: 'Fermer', AppLang.en: 'Close', AppLang.wo: 'Tëj'},
  'action.save': {AppLang.fr: 'Enregistrer', AppLang.en: 'Save', AppLang.wo: 'Aar'},
  'action.cancel': {AppLang.fr: 'Annuler', AppLang.en: 'Cancel', AppLang.wo: 'Neenal'},
  'action.send': {AppLang.fr: 'Envoyer', AppLang.en: 'Send', AppLang.wo: 'Yónnee'},

  // Home
  'home.publishMeal': {AppLang.fr: 'Publier un plat', AppLang.en: 'Publish dish', AppLang.wo: 'Yéene ñam'},
  'home.search': {AppLang.fr: 'Rechercher un plat, un vendeur…', AppLang.en: 'Search dish, seller…', AppLang.wo: 'Seet ñam, jaaykat…'},
  'home.filter.available': {AppLang.fr: 'Dispo', AppLang.en: 'Available', AppLang.wo: 'Am na'},
  'home.filter.promo': {AppLang.fr: 'Promo', AppLang.en: 'Deal', AppLang.wo: 'Promo'},
  'home.filter.special': {AppLang.fr: 'Plat du jour', AppLang.en: 'Special', AppLang.wo: 'Ñamu bés bi'},
  'home.sort': {AppLang.fr: 'Trier', AppLang.en: 'Sort', AppLang.wo: 'Tëral'},
  'home.offlineBanner': {
    AppLang.fr: 'Mode hors ligne — données en cache',
    AppLang.en: 'Offline mode — cached data',
    AppLang.wo: 'Offline — données ci cache',
  },
  'home.loadError': {
    AppLang.fr: 'Impossible de charger les plats.',
    AppLang.en: 'Could not load dishes.',
    AppLang.wo: 'Mënuloo yeb ñam yi.',
  },
  'home.sortPriceAsc': {AppLang.fr: 'Prix ↑', AppLang.en: 'Price ↑', AppLang.wo: 'Pri ↑'},
  'home.sortPriceDesc': {AppLang.fr: 'Prix ↓', AppLang.en: 'Price ↓', AppLang.wo: 'Pri ↓'},
  'home.sortRating': {AppLang.fr: 'Note', AppLang.en: 'Rating', AppLang.wo: 'Not'},
  'home.sortRecent': {AppLang.fr: 'Récents', AppLang.en: 'Recent', AppLang.wo: 'Ci gannaaw'},
  'home.sortDistance': {AppLang.fr: 'Plus proches', AppLang.en: 'Nearest', AppLang.wo: 'Ci gëstu'},
  'home.allCategory': {AppLang.fr: 'Tous', AppLang.en: 'All', AppLang.wo: 'Yépp'},
  'home.connectionFailed': {AppLang.fr: 'Connexion impossible', AppLang.en: 'Connection failed', AppLang.wo: 'Connexion amul'},
  'home.noResults': {AppLang.fr: 'Aucun résultat', AppLang.en: 'No results', AppLang.wo: 'Amul benn'},
  'home.noResultsQuery': {
    AppLang.fr: 'Aucun plat ne correspond à « {query} ».',
    AppLang.en: 'No dish matches « {query} ».',
    AppLang.wo: 'Amul ñam bu mel « {query} ».',
  },
  'home.noMeals': {AppLang.fr: 'Aucun plat pour le moment', AppLang.en: 'No dishes yet', AppLang.wo: 'Amul ñam léegi'},
  'home.noMealsHint': {
    AppLang.fr: 'Les plats publiés par les vendeurs apparaîtront ici.',
    AppLang.en: 'Dishes from sellers will appear here.',
    AppLang.wo: 'Ñam yi jaaykat yi dinañu fee.',
  },
  'home.voiceSearch': {AppLang.fr: 'Recherche vocale', AppLang.en: 'Voice search', AppLang.wo: 'Seet ak baat'},
  'home.voiceUnavailable': {
    AppLang.fr: 'Reconnaissance vocale indisponible.',
    AppLang.en: 'Voice recognition unavailable.',
    AppLang.wo: 'Seet ak baat amul.',
  },
  'home.publishSuccess': {
    AppLang.fr: 'Plat publié avec succès',
    AppLang.en: 'Dish published successfully',
    AppLang.wo: 'Ñam bi yéene na',
  },
  'hero.mafe.title': {AppLang.fr: 'Mafé chaud près de toi', AppLang.en: 'Hot mafé near you', AppLang.wo: 'Mafé tàng ci sa gëstu'},
  'hero.mafe.subtitle': {AppLang.fr: 'Découvre les vendeurs locaux les mieux notés', AppLang.en: 'Discover top-rated local sellers', AppLang.wo: 'Gis jaaykat yu gëna baax'},
  'hero.yassa.title': {AppLang.fr: 'Yassa du jour', AppLang.en: 'Yassa of the day', AppLang.wo: 'Yassa bu bés bi'},
  'hero.yassa.subtitle': {AppLang.fr: 'Suis les créateurs, like et commande', AppLang.en: 'Follow creators, like and order', AppLang.wo: 'Topp créateurs, like ak commande'},
  'hero.suya.title': {AppLang.fr: 'Suya grillé maintenant', AppLang.en: 'Suya grilling now', AppLang.wo: 'Suya bu tàng léegi'},
  'hero.suya.subtitle': {AppLang.fr: 'Vidéos, shorts et plats à proximité', AppLang.en: 'Videos, shorts and nearby dishes', AppLang.wo: 'Wideo, shorts ak ñam ci gëstu'},
  'hero.thieb.title': {AppLang.fr: 'Thiéboudienne maison', AppLang.en: 'Homemade thiéboudienne', AppLang.wo: 'Ceebu jën ci kër'},
  'hero.thieb.subtitle': {AppLang.fr: 'Le goût local, livré rapidement', AppLang.en: 'Local taste, delivered fast', AppLang.wo: 'Goxu réew, yónnee gaaw'},
  'hero.ndole.title': {AppLang.fr: 'Ndolé gourmand', AppLang.en: 'Hearty ndolé', AppLang.wo: 'Ndolé bu baax'},
  'hero.ndole.subtitle': {AppLang.fr: 'Trouve les meilleurs vendeurs autour de toi', AppLang.en: 'Find the best sellers around you', AppLang.wo: 'Gis jaaykat yu gëna baax'},
  'hero.jollof.title': {AppLang.fr: 'Jollof & poulet braisé', AppLang.en: 'Jollof & grilled chicken', AppLang.wo: 'Jollof ak ganaar bu tàng'},
  'hero.jollof.subtitle': {AppLang.fr: 'Commande, like, partage', AppLang.en: 'Order, like, share', AppLang.wo: 'Commande, like, séddoo'},
  'hero.attieke.title': {AppLang.fr: 'Attiéké poisson', AppLang.en: 'Attiéké with fish', AppLang.wo: 'Attiéké ak jën'},
  'hero.attieke.subtitle': {AppLang.fr: 'Les saveurs côtières près de toi', AppLang.en: 'Coastal flavors near you', AppLang.wo: 'Goxu ndox ci sa gëstu'},
  'hero.plantain.title': {AppLang.fr: 'Plantains dorés', AppLang.en: 'Golden plantains', AppLang.wo: 'Plantain bu wër'},
  'hero.plantain.subtitle': {AppLang.fr: 'Sauces piquantes et vendeurs favoris', AppLang.en: 'Spicy sauces and favorite sellers', AppLang.wo: 'Sauce bu tàng ak jaaykat yu baax'},
  'hero.egusi.title': {AppLang.fr: 'Egusi & fufu', AppLang.en: 'Egusi & fufu', AppLang.wo: 'Egusi ak fufu'},
  'hero.egusi.subtitle': {AppLang.fr: 'Découvre, commente, abonne-toi', AppLang.en: 'Discover, comment, subscribe', AppLang.wo: 'Gis, bind, abonne'},
  'hero.brochettes.title': {AppLang.fr: 'Brochettes fumées', AppLang.en: 'Smoky skewers', AppLang.wo: 'Brochettes bu saaf'},
  'hero.brochettes.subtitle': {AppLang.fr: 'Des shorts appétissants à partager', AppLang.en: 'Tasty shorts to share', AppLang.wo: 'Shorts yu neex ngir séddoo'},
  'hero.drinks.title': {AppLang.fr: 'Bissap & gingembre', AppLang.en: 'Hibiscus & ginger', AppLang.wo: 'Bissap ak gingembre'},
  'hero.drinks.subtitle': {AppLang.fr: 'Boissons fraîches disponibles maintenant', AppLang.en: 'Fresh drinks available now', AppLang.wo: 'Naan yu sedd am nañu léegi'},
  'publish.nameRequired': {
    AppLang.fr: 'Donne un nom au plat.',
    AppLang.en: 'Enter a dish name.',
    AppLang.wo: 'Bind turu ñam bi.',
  },
  'publish.categoryRequired': {
    AppLang.fr: 'Choisis une catégorie.',
    AppLang.en: 'Choose a category.',
    AppLang.wo: 'Tann benn catégorie.',
  },
  'publish.photoRequired': {
    AppLang.fr: 'Ajoute une photo du plat.',
    AppLang.en: 'Add a photo of the dish.',
    AppLang.wo: 'Yokk foto bu ñam bi.',
  },
  'publish.promoMustBeLower': {
    AppLang.fr: 'Le prix promo doit être inférieur au prix.',
    AppLang.en: 'Promo price must be lower than the regular price.',
    AppLang.wo: 'Pri promo dafa wara néew ci pri bi.',
  },
  'publish.imagePickFailed': {
    AppLang.fr: 'Impossible de choisir l’image : {error}',
    AppLang.en: 'Could not pick image: {error}',
    AppLang.wo: 'Mënuloo tann foto bi : {error}',
  },
  'publish.extraPhotoFailed': {
    AppLang.fr: 'Impossible d’ajouter la photo : {error}',
    AppLang.en: 'Could not add photo: {error}',
    AppLang.wo: 'Mënuloo yokk foto bi : {error}',
  },
  'publish.mealName': {AppLang.fr: 'Nom du plat', AppLang.en: 'Dish name', AppLang.wo: 'Turu ñam bi'},
  'publish.category': {AppLang.fr: 'Catégorie', AppLang.en: 'Category', AppLang.wo: 'Catégorie'},
  'publish.description': {
    AppLang.fr: 'Description (optionnel)',
    AppLang.en: 'Description (optional)',
    AppLang.wo: 'Description (optionnel)',
  },
  'publish.price': {
    AppLang.fr: 'Prix en FCFA (optionnel)',
    AppLang.en: 'Price in FCFA (optional)',
    AppLang.wo: 'Pri ci FCFA (optionnel)',
  },
  'publish.promoPrice': {
    AppLang.fr: 'Prix promo en FCFA (optionnel)',
    AppLang.en: 'Promo price in FCFA (optional)',
    AppLang.wo: 'Pri promo ci FCFA (optionnel)',
  },
  'publish.extraPhotos': {
    AppLang.fr: 'Photos supplémentaires (optionnel)',
    AppLang.en: 'Extra photos (optional)',
    AppLang.wo: 'Yeneen foto (optionnel)',
  },
  'publish.addPhotoCount': {
    AppLang.fr: 'Ajouter une photo ({count}/4)',
    AppLang.en: 'Add photo ({count}/4)',
    AppLang.wo: 'Yokk foto ({count}/4)',
  },
  'publish.choosePhoto': {AppLang.fr: 'Choisir une photo', AppLang.en: 'Choose photo', AppLang.wo: 'Tann foto'},
  'publish.changePhoto': {AppLang.fr: 'Changer la photo', AppLang.en: 'Change photo', AppLang.wo: 'Soppi foto bi'},
  'publish.publishing': {AppLang.fr: 'Publication…', AppLang.en: 'Publishing…', AppLang.wo: 'Mi ngi yéene…'},
  'publish.submit': {AppLang.fr: 'Publier le plat', AppLang.en: 'Publish dish', AppLang.wo: 'Yéene ñam bi'},

  // Cart & checkout
  'cart.title': {AppLang.fr: 'Panier', AppLang.en: 'Cart', AppLang.wo: 'Pañe'},
  'cart.empty': {AppLang.fr: 'Ton panier est vide', AppLang.en: 'Your cart is empty', AppLang.wo: 'Sa pañe amul dara'},
  'cart.emptyHint': {
    AppLang.fr: 'Ajoute des plats depuis l’accueil pour passer commande.',
    AppLang.en: 'Add dishes from home to order.',
    AppLang.wo: 'Yokk ñam ci kër ngir commande.',
  },
  'cart.total': {AppLang.fr: 'Total', AppLang.en: 'Total', AppLang.wo: 'Total'},
  'cart.checkout': {AppLang.fr: 'Commander', AppLang.en: 'Checkout', AppLang.wo: 'Commande'},
  'cart.orders': {AppLang.fr: 'Mes commandes', AppLang.en: 'My orders', AppLang.wo: 'Sama commande'},
  'cart.summary': {AppLang.fr: '{total} • {count} article(s)', AppLang.en: '{total} • {count} item(s)', AppLang.wo: '{total} • {count} article'},

  'checkout.title': {AppLang.fr: 'Finaliser la commande', AppLang.en: 'Complete order', AppLang.wo: 'Jeexal commande bi'},
  'checkout.delivery': {AppLang.fr: 'Livraison', AppLang.en: 'Delivery', AppLang.wo: 'Yónnee'},
  'checkout.pickup': {AppLang.fr: 'Retrait', AppLang.en: 'Pickup', AppLang.wo: 'Jël'},
  'checkout.confirm': {AppLang.fr: 'Confirmer la commande', AppLang.en: 'Confirm order', AppLang.wo: 'Dëggël commande bi'},
  'checkout.submitting': {AppLang.fr: 'Envoi…', AppLang.en: 'Submitting…', AppLang.wo: 'Yónnee…'},
  'checkout.address': {AppLang.fr: 'Adresse de livraison', AppLang.en: 'Delivery address', AppLang.wo: 'Adresse yónnee'},
  'checkout.phone': {AppLang.fr: 'Téléphone', AppLang.en: 'Phone', AppLang.wo: 'Telefon'},
  'checkout.note': {AppLang.fr: 'Note (optionnel)', AppLang.en: 'Note (optional)', AppLang.wo: 'Note (optionnel)'},
  'checkout.paymentMode': {AppLang.fr: 'Mode de paiement', AppLang.en: 'Payment method', AppLang.wo: 'Fey'},
  'checkout.promo': {AppLang.fr: 'Code promo (optionnel)', AppLang.en: 'Promo code (optional)', AppLang.wo: 'Code promo'},
  'checkout.verifyPromo': {AppLang.fr: 'Vérifier le code', AppLang.en: 'Verify code', AppLang.wo: 'Seet code bi'},
  'checkout.useLocation': {AppLang.fr: 'Utiliser ma position', AppLang.en: 'Use my location', AppLang.wo: 'Jëfandikoo sama position'},
  'checkout.locationOk': {AppLang.fr: 'Position détectée', AppLang.en: 'Location detected', AppLang.wo: 'Position gis na'},
  'checkout.locationOkQuoted': {
    AppLang.fr: 'Position détectée (frais calculés)',
    AppLang.en: 'Location detected (fee calculated)',
    AppLang.wo: 'Position gis na (frais xam na)',
  },
  'checkout.discountExtra': {AppLang.fr: ' (−{amount})', AppLang.en: ' (−{amount})', AppLang.wo: ' (−{amount})'},
  'checkout.needLocationQuote': {
    AppLang.fr: 'Utilise ta position pour estimer la livraison.',
    AppLang.en: 'Use your location to estimate delivery.',
    AppLang.wo: 'Jëfandikoo sa position ngir xam yónnee bi.',
  },
  'checkout.needAddress': {AppLang.fr: 'Indique une adresse de livraison.', AppLang.en: 'Enter a delivery address.', AppLang.wo: 'Dugal adresse bi.'},
  'checkout.needPhone': {AppLang.fr: 'Indique un numéro de téléphone.', AppLang.en: 'Enter a phone number.', AppLang.wo: 'Dugal nimero telefon.'},
  'checkout.needGps': {AppLang.fr: 'Utilise ta position pour la livraison.', AppLang.en: 'Use your location for delivery.', AppLang.wo: 'Jëfandikoo sa position.'},
  'checkout.subtotal': {AppLang.fr: 'Sous-total', AppLang.en: 'Subtotal', AppLang.wo: 'Sous-total'},
  'checkout.deliveryFee': {AppLang.fr: 'Livraison', AppLang.en: 'Delivery', AppLang.wo: 'Yónnee'},
  'checkout.promoLine': {AppLang.fr: 'Promo', AppLang.en: 'Promo', AppLang.wo: 'Promo'},
  'checkout.toEstimate': {AppLang.fr: 'À estimer', AppLang.en: 'To estimate', AppLang.wo: 'Estime'},
  'checkout.promoApplied': {AppLang.fr: 'Promo appliquée : −{amount}', AppLang.en: 'Promo applied: −{amount}', AppLang.wo: 'Promo: −{amount}'},
  'checkout.orderConfirmed': {AppLang.fr: 'Commande #{id} confirmée · {total}{extra}', AppLang.en: 'Order #{id} confirmed · {total}{extra}', AppLang.wo: 'Commande #{id} dëgg na · {total}{extra}'},
  'checkout.orderPendingPay': {AppLang.fr: 'Commande #{id} — paiement en cours ({total}{extra})', AppLang.en: 'Order #{id} — payment pending ({total}{extra})', AppLang.wo: 'Commande #{id} — fey bi ci yoon ({total}{extra})'},
  'checkout.failed': {AppLang.fr: 'Échec: {error}', AppLang.en: 'Failed: {error}', AppLang.wo: 'Xanaa: {error}'},
  'checkout.paymentConfirmedResume': {
    AppLang.fr: 'Paiement confirmé pour la commande #{id}',
    AppLang.en: 'Payment confirmed for order #{id}',
    AppLang.wo: 'Fey dëgg na ci commande #{id}',
  },
  'checkout.paymentFailedResume': {
    AppLang.fr: 'Paiement échoué ou annulé.',
    AppLang.en: 'Payment failed or was cancelled.',
    AppLang.wo: 'Fey bi xanaa walla neen na.',
  },

  // Payment methods
  'payment.cash': {AppLang.fr: 'À la livraison', AppLang.en: 'Cash on delivery', AppLang.wo: 'Fey bu ñu yónnee'},
  'payment.wave': {AppLang.fr: 'Wave', AppLang.en: 'Wave', AppLang.wo: 'Wave'},
  'payment.orange_money': {AppLang.fr: 'Orange Money', AppLang.en: 'Orange Money', AppLang.wo: 'Orange Money'},
  'payment.free_money': {AppLang.fr: 'Free Money', AppLang.en: 'Free Money', AppLang.wo: 'Free Money'},

  // Order statuses
  'status.pending': {AppLang.fr: 'En attente', AppLang.en: 'Pending', AppLang.wo: 'Ci xaar'},
  'status.preparing': {AppLang.fr: 'En préparation', AppLang.en: 'Preparing', AppLang.wo: 'Mi ngi pare'},
  'status.on_the_way': {AppLang.fr: 'En route', AppLang.en: 'On the way', AppLang.wo: 'Ci yoon'},
  'status.delivered': {AppLang.fr: 'Livrée', AppLang.en: 'Delivered', AppLang.wo: 'Yónnee na'},
  'status.cancelled': {AppLang.fr: 'Annulée', AppLang.en: 'Cancelled', AppLang.wo: 'Neen na'},

  // Orders
  'orders.title': {AppLang.fr: 'Mes commandes', AppLang.en: 'My orders', AppLang.wo: 'Sama commande'},
  'orders.empty': {AppLang.fr: 'Aucune commande.', AppLang.en: 'No orders yet.', AppLang.wo: 'Amul commande.'},
  'orders.received': {AppLang.fr: 'Commandes reçues', AppLang.en: 'Received orders', AppLang.wo: 'Commande yi ñu jox ma'},
  'orders.receivedEmpty': {AppLang.fr: 'Aucune commande reçue.', AppLang.en: 'No received orders.', AppLang.wo: 'Amul commande.'},
  'orders.totalLine': {AppLang.fr: 'Total: {total}', AppLang.en: 'Total: {total}', AppLang.wo: 'Total: {total}'},
  'orders.loyaltyEarned': {
    AppLang.fr: '+{points} points de fidélité',
    AppLang.en: '+{points} loyalty points',
    AppLang.wo: '+{points} poñ fidélité',
  },
  'orders.promoWithCode': {AppLang.fr: 'Promo ({code})', AppLang.en: 'Promo ({code})', AppLang.wo: 'Promo ({code})'},
  'orders.tabActive': {AppLang.fr: 'En cours ({count})', AppLang.en: 'Active ({count})', AppLang.wo: 'Ci yoon ({count})'},
  'orders.tabDone': {AppLang.fr: 'Terminées ({count})', AppLang.en: 'Completed ({count})', AppLang.wo: 'Jeex na ({count})'},
  'orders.activeEmpty': {AppLang.fr: 'Aucune commande en cours.', AppLang.en: 'No active orders.', AppLang.wo: 'Amul commande ci yoon.'},
  'orders.doneEmpty': {AppLang.fr: 'Aucune commande terminée.', AppLang.en: 'No completed orders.', AppLang.wo: 'Amul commande bu jeex.'},
  'orders.statusUpdated': {AppLang.fr: 'Statut : {status}', AppLang.en: 'Status: {status}', AppLang.wo: 'Statut : {status}'},
  'orders.customerLine': {AppLang.fr: 'Client : {name}', AppLang.en: 'Customer: {name}', AppLang.wo: 'Client : {name}'},
  'orders.paymentLine': {AppLang.fr: 'Paiement : {method}', AppLang.en: 'Payment: {method}', AppLang.wo: 'Fey : {method}'},
  'orders.deliveryWithAddress': {AppLang.fr: 'Livraison • {address}', AppLang.en: 'Delivery • {address}', AppLang.wo: 'Yónnee • {address}'},

  // Tracking
  'tracking.title': {AppLang.fr: 'Suivi de commande', AppLang.en: 'Order tracking', AppLang.wo: 'Topp commande'},
  'tracking.none': {AppLang.fr: 'Aucune commande en cours', AppLang.en: 'No active order', AppLang.wo: 'Amul commande ci yoon'},
  'tracking.noneHint': {
    AppLang.fr: 'Passe une commande depuis le panier pour suivre sa préparation ici.',
    AppLang.en: 'Order from the cart to track preparation here.',
    AppLang.wo: 'Commande ci pañe ngir topp fii.',
  },
  'tracking.loadError': {
    AppLang.fr: 'Impossible de charger les commandes',
    AppLang.en: 'Could not load orders',
    AppLang.wo: 'Mënuloo yeb commande yi',
  },
  'tracking.loginRequired': {AppLang.fr: 'Connecte-toi pour suivre tes commandes.', AppLang.en: 'Sign in to track orders.', AppLang.wo: 'Dugg ngir topp sa commande.'},
  'tracking.orderLabel': {AppLang.fr: 'Commande #{id}', AppLang.en: 'Order #{id}', AppLang.wo: 'Commande #{id}'},
  'tracking.seeAll': {AppLang.fr: 'Voir mes commandes', AppLang.en: 'See my orders', AppLang.wo: 'Gis sama commande'},
  'tracking.mapSection': {AppLang.fr: 'Carte & position', AppLang.en: 'Map & location', AppLang.wo: 'Kàrt ak position'},
  'tracking.manualGpsHint': {
    AppLang.fr: 'GPS indisponible : appuie sur la carte pour placer ta position.',
    AppLang.en: 'GPS unavailable: tap the map to set your location.',
    AppLang.wo: 'GPS amul : bësal kàrt bi ngir def sa position.',
  },
  'tracking.settings': {AppLang.fr: 'Réglages', AppLang.en: 'Settings', AppLang.wo: 'Paramètres'},
  'tracking.appSettings': {AppLang.fr: 'Paramètres app', AppLang.en: 'App settings', AppLang.wo: 'Paramètres app'},
  'tracking.retryGps': {AppLang.fr: 'Réessayer GPS', AppLang.en: 'Retry GPS', AppLang.wo: 'Jéemataat GPS'},
  'tracking.locationUnavailable': {
    AppLang.fr: 'Position indisponible.',
    AppLang.en: 'Location unavailable.',
    AppLang.wo: 'Position amul.',
  },
  'tracking.viewShop': {AppLang.fr: 'Voir la boutique', AppLang.en: 'View shop', AppLang.wo: 'Gis bitik bi'},
  'tracking.coords': {AppLang.fr: 'Lat: {lat}  •  Lng: {lng}', AppLang.en: 'Lat: {lat}  •  Lng: {lng}', AppLang.wo: 'Lat: {lat}  •  Lng: {lng}'},
  'tracking.fulfillmentLine': {AppLang.fr: '{fulfillment} • {total}', AppLang.en: '{fulfillment} • {total}', AppLang.wo: '{fulfillment} • {total}'},

  // Notifications
  'notif.title': {AppLang.fr: 'Notifications', AppLang.en: 'Notifications', AppLang.wo: 'Xibaar yi'},
  'notif.empty': {AppLang.fr: 'Aucune notification.', AppLang.en: 'No notifications.', AppLang.wo: 'Amul xibaar.'},

  // Chat
  'chat.title': {AppLang.fr: 'Messages', AppLang.en: 'Messages', AppLang.wo: 'Bataaxal'},
  'chat.empty': {AppLang.fr: 'Aucune conversation.', AppLang.en: 'No conversations.', AppLang.wo: 'Amul waxtaan.'},
  'chat.hint': {AppLang.fr: 'Écris un message…', AppLang.en: 'Write a message…', AppLang.wo: 'Bindal bataaxal…'},
  'chat.noDiscussions': {
    AppLang.fr: 'Aucune discussion pour le moment.',
    AppLang.en: 'No conversations yet.',
    AppLang.wo: 'Amul waxtaan léegi.',
  },
  'chat.threadTitle': {AppLang.fr: 'Discussion', AppLang.en: 'Chat', AppLang.wo: 'Waxtaan'},
  'chat.startConversation': {
    AppLang.fr: 'Démarre la conversation 👋',
    AppLang.en: 'Start the conversation 👋',
    AppLang.wo: 'Tambali waxtaan bi 👋',
  },

  // Favorites / loyalty / profile
  'favorites.title': {AppLang.fr: 'Mes favoris', AppLang.en: 'My favorites', AppLang.wo: 'Sama soobé'},
  'favorites.empty': {AppLang.fr: 'Aucun favori.', AppLang.en: 'No favorites.', AppLang.wo: 'Amul soobé.'},
  'favorites.emptyHint': {
    AppLang.fr: 'Aucun plat favori.\nAppuie sur le cœur d’un plat pour l’ajouter ici.',
    AppLang.en: 'No favorite dishes yet.\nTap the heart on a dish to save it here.',
    AppLang.wo: 'Amul ñam bu soobé.\nBësal xol bi ci ñam ngir yokk fii.',
  },
  'loyalty.title': {AppLang.fr: 'Mes points fidélité', AppLang.en: 'Loyalty points', AppLang.wo: 'Sama poñ'},
  'loyalty.programTitle': {
    AppLang.fr: 'Programme de fidélité',
    AppLang.en: 'Loyalty program',
    AppLang.wo: 'Programme fidélité',
  },
  'loyalty.points': {AppLang.fr: '{points} points', AppLang.en: '{points} points', AppLang.wo: '{points} poñ'},
  'loyalty.earnHint': {
    AppLang.fr: 'Cumule des points à chaque commande livrée.',
    AppLang.en: 'Earn points with every delivered order.',
    AppLang.wo: 'Am poñ ci commande bu ñu yónnee.',
  },
  'loyalty.nextReward': {
    AppLang.fr: 'Prochaine récompense',
    AppLang.en: 'Next reward',
    AppLang.wo: 'Récompense bi ci topp',
  },
  'loyalty.pointsToUnlock': {
    AppLang.fr: 'Encore {points} points pour débloquer un plat offert 🎁',
    AppLang.en: '{points} more points to unlock a free dish 🎁',
    AppLang.wo: '{points} poñ ci des ngir am ñam 🎁',
  },
  'loyalty.howToEarn': {
    AppLang.fr: 'Comment gagner des points ?',
    AppLang.en: 'How to earn points?',
    AppLang.wo: 'Nan la am poñ?',
  },
  'loyalty.howToEarnBody': {
    AppLang.fr: '1 point pour 100 FCFA dépensés, crédité quand la commande est livrée.',
    AppLang.en: '1 point per 100 FCFA spent, credited when the order is delivered.',
    AppLang.wo: '1 poñ ci 100 FCFA, bu commande bi yónnee.',
  },
  'loyalty.rewardTitle': {AppLang.fr: 'Récompense', AppLang.en: 'Reward', AppLang.wo: 'Récompense'},
  'loyalty.rewardBody': {
    AppLang.fr: 'À 100 points, profite d\'un plat offert chez tes vendeurs.',
    AppLang.en: 'At 100 points, enjoy a free dish from your sellers.',
    AppLang.wo: 'Ci 100 poñ, am ñam bu jaaykat yi jox la.',
  },
  'shop.title': {AppLang.fr: 'Ma boutique', AppLang.en: 'My shop', AppLang.wo: 'Sama bitik'},
  'shop.sectionIdentity': {AppLang.fr: 'Identité', AppLang.en: 'Identity', AppLang.wo: 'Identité'},
  'shop.sectionShop': {AppLang.fr: 'Boutique', AppLang.en: 'Shop', AppLang.wo: 'Bitik'},
  'shop.sectionLocation': {AppLang.fr: 'Localisation', AppLang.en: 'Location', AppLang.wo: 'Position'},
  'shop.sectionHours': {AppLang.fr: 'Horaires & service', AppLang.en: 'Hours & service', AppLang.wo: 'Waxtu ak service'},
  'shop.displayName': {AppLang.fr: 'Nom affiché', AppLang.en: 'Display name', AppLang.wo: 'Tur bu feeñ'},
  'shop.shopName': {AppLang.fr: 'Nom de la boutique', AppLang.en: 'Shop name', AppLang.wo: 'Tur bitik bi'},
  'shop.category': {AppLang.fr: 'Catégorie', AppLang.en: 'Category', AppLang.wo: 'Catégorie'},
  'shop.cuisine': {AppLang.fr: 'Cuisine', AppLang.en: 'Cuisine', AppLang.wo: 'Cuisine'},
  'shop.city': {AppLang.fr: 'Ville', AppLang.en: 'City', AppLang.wo: 'Dëkk bi'},
  'shop.neighborhood': {AppLang.fr: 'Quartier', AppLang.en: 'Neighborhood', AppLang.wo: 'Quartier'},
  'shop.positionSet': {
    AppLang.fr: 'Position : {lat}, {lng}',
    AppLang.en: 'Location: {lat}, {lng}',
    AppLang.wo: 'Position : {lat}, {lng}',
  },
  'shop.noPosition': {
    AppLang.fr: 'Aucune position définie',
    AppLang.en: 'No location set',
    AppLang.wo: 'Amul position',
  },
  'shop.opensAt': {AppLang.fr: 'Ouvre à', AppLang.en: 'Opens at', AppLang.wo: 'Ubbi ci'},
  'shop.closesAt': {AppLang.fr: 'Ferme à', AppLang.en: 'Closes at', AppLang.wo: 'Tëj ci'},
  'shop.deliveryRadius': {
    AppLang.fr: 'Rayon de livraison (km)',
    AppLang.en: 'Delivery radius (km)',
    AppLang.wo: 'Rayon yónnee (km)',
  },
  'shop.feeBase': {AppLang.fr: 'Frais de base (FCFA)', AppLang.en: 'Base fee (FCFA)', AppLang.wo: 'Frais bu njëkk (FCFA)'},
  'shop.feePerKm': {AppLang.fr: 'Frais / km (FCFA)', AppLang.en: 'Fee / km (FCFA)', AppLang.wo: 'Frais / km (FCFA)'},
  'shop.freeDeliveryOver': {
    AppLang.fr: 'Livraison gratuite dès (FCFA, 0 = off)',
    AppLang.en: 'Free delivery from (FCFA, 0 = off)',
    AppLang.wo: 'Yónnee bu amul jar dale (FCFA, 0 = off)',
  },
  'shop.pickup': {AppLang.fr: 'Retrait sur place', AppLang.en: 'Pickup on site', AppLang.wo: 'Jël ci bitik bi'},
  'shop.locationSaved': {
    AppLang.fr: 'Position enregistrée.',
    AppLang.en: 'Location saved.',
    AppLang.wo: 'Position aar na.',
  },
  'shop.locationUnavailable': {
    AppLang.fr: 'Localisation indisponible.',
    AppLang.en: 'Location unavailable.',
    AppLang.wo: 'Position amul.',
  },
  'shop.updated': {
    AppLang.fr: 'Boutique mise à jour.',
    AppLang.en: 'Shop updated.',
    AppLang.wo: 'Bitik bi soppi na.',
  },
  'shop.saving': {AppLang.fr: 'Enregistrement…', AppLang.en: 'Saving…', AppLang.wo: 'Mi ngi aar…'},
  'dashboard.title': {AppLang.fr: 'Tableau de bord', AppLang.en: 'Dashboard', AppLang.wo: 'Tablo'},
  'dashboard.totalRevenue': {AppLang.fr: 'Revenu total', AppLang.en: 'Total revenue', AppLang.wo: 'Revenu total'},
  'dashboard.deliveredRevenue': {AppLang.fr: 'Revenu livré', AppLang.en: 'Delivered revenue', AppLang.wo: 'Revenu bu yónnee'},
  'dashboard.ordersCount': {AppLang.fr: 'Commandes', AppLang.en: 'Orders', AppLang.wo: 'Commande yi'},
  'dashboard.itemsSold': {AppLang.fr: 'Articles vendus', AppLang.en: 'Items sold', AppLang.wo: 'Article yi jaay'},
  'dashboard.followers': {AppLang.fr: 'Abonnés', AppLang.en: 'Followers', AppLang.wo: 'Toppkat yi'},
  'dashboard.meals': {AppLang.fr: 'Plats', AppLang.en: 'Dishes', AppLang.wo: 'Ñam yi'},
  'dashboard.salesLast7Days': {
    AppLang.fr: 'Ventes des 7 derniers jours',
    AppLang.en: 'Sales over the last 7 days',
    AppLang.wo: 'Jaay ci 7 fan yi weesu',
  },
  'dashboard.ordersByStatus': {
    AppLang.fr: 'Commandes par statut',
    AppLang.en: 'Orders by status',
    AppLang.wo: 'Commande yi ci statut',
  },
  'dashboard.topMeals': {
    AppLang.fr: 'Plats les plus vendus',
    AppLang.en: 'Top selling dishes',
    AppLang.wo: 'Ñam yi ñu jaay lool',
  },
  'dashboard.noSales': {
    AppLang.fr: 'Aucune vente pour le moment.',
    AppLang.en: 'No sales yet.',
    AppLang.wo: 'Amul jaay léegi.',
  },
  'dashboard.noData': {AppLang.fr: 'Aucune donnée.', AppLang.en: 'No data.', AppLang.wo: 'Amul données.'},
  'dashboard.weekTotal': {
    AppLang.fr: 'Total semaine : {total}',
    AppLang.en: 'Week total: {total}',
    AppLang.wo: 'Total ayubés bi : {total}',
  },
  'dashboard.mealSoldLine': {
    AppLang.fr: '{quantity} vendus  •  {revenue}',
    AppLang.en: '{quantity} sold  •  {revenue}',
    AppLang.wo: '{quantity} jaay  •  {revenue}',
  },
  'seller.defaultName': {AppLang.fr: 'Vendeur', AppLang.en: 'Seller', AppLang.wo: 'Jaaykat'},
  'seller.notFound': {
    AppLang.fr: 'Vendeur introuvable',
    AppLang.en: 'Seller not found',
    AppLang.wo: 'Amul jaaykat bi',
  },
  'seller.theirMeals': {AppLang.fr: 'Ses plats ({count})', AppLang.en: 'Their dishes ({count})', AppLang.wo: 'Ñam yi ({count})'},
  'seller.followed': {AppLang.fr: 'Abonné', AppLang.en: 'Following', AppLang.wo: 'Topp na'},
  'publications.title': {AppLang.fr: 'Mes publications', AppLang.en: 'My publications', AppLang.wo: 'Sama yéene'},
  'publications.tabMeals': {AppLang.fr: 'Plats', AppLang.en: 'Dishes', AppLang.wo: 'Ñam'},
  'publications.tabVideos': {AppLang.fr: 'Vidéos', AppLang.en: 'Videos', AppLang.wo: 'Wideo'},
  'publications.tabShorts': {AppLang.fr: 'Shorts', AppLang.en: 'Shorts', AppLang.wo: 'Shorts'},
  'publications.noMeals': {AppLang.fr: 'Aucun plat publié.', AppLang.en: 'No dishes published.', AppLang.wo: 'Amul ñam bu yéene.'},
  'publications.noVideos': {AppLang.fr: 'Aucune vidéo publiée.', AppLang.en: 'No videos published.', AppLang.wo: 'Amul wideo bu yéene.'},
  'publications.noShorts': {AppLang.fr: 'Aucun short publié.', AppLang.en: 'No shorts published.', AppLang.wo: 'Amul short bu yéene.'},
  'publications.markSoldOut': {AppLang.fr: 'Marquer épuisé', AppLang.en: 'Mark sold out', AppLang.wo: 'Wax ne jeex na'},
  'publications.markAvailable': {AppLang.fr: 'Marquer disponible', AppLang.en: 'Mark available', AppLang.wo: 'Wax ne am na'},
  'publications.removeSpecial': {AppLang.fr: 'Retirer plat du jour', AppLang.en: 'Remove special', AppLang.wo: 'Dindi ñamu bés bi'},
  'publications.markSpecial': {AppLang.fr: 'Marquer plat du jour', AppLang.en: 'Mark as special', AppLang.wo: 'Wax ne ñamu bés bi la'},
  'publications.deleteConfirm': {
    AppLang.fr: 'Supprimer {label} ? Cette action est définitive.',
    AppLang.en: 'Delete {label}? This cannot be undone.',
    AppLang.wo: 'Dindi {label}? Dëgg la.',
  },
  'publications.noCaption': {AppLang.fr: '(sans texte)', AppLang.en: '(no caption)', AppLang.wo: '(amul bind)'},
  'publications.likesComments': {
    AppLang.fr: '{likes} j’aime • {comments} commentaire(s)',
    AppLang.en: '{likes} likes • {comments} comment(s)',
    AppLang.wo: '{likes} bëgg • {comments} commentaire',
  },

  // Meal details
  'meal.reviews': {AppLang.fr: 'Avis', AppLang.en: 'Reviews', AppLang.wo: 'Xalaat'},
  'meal.addReview': {AppLang.fr: 'Laisser un avis', AppLang.en: 'Leave a review', AppLang.wo: 'Bind xalaat'},
  'meal.yourRating': {AppLang.fr: 'Ta note', AppLang.en: 'Your rating', AppLang.wo: 'Sa not'},
  'meal.addFavorite': {AppLang.fr: 'Ajouter aux favoris', AppLang.en: 'Add to favorites', AppLang.wo: 'Yokk ci soobé'},
  'meal.removeFavorite': {AppLang.fr: 'Retirer des favoris', AppLang.en: 'Remove from favorites', AppLang.wo: 'Dindi ci soobé'},
  'meal.thanksReview': {AppLang.fr: 'Merci pour ton avis !', AppLang.en: 'Thanks for your review!', AppLang.wo: 'Jëriñ ci sa xalaat!'},
  'meal.soldOut': {AppLang.fr: 'Épuisé', AppLang.en: 'Sold out', AppLang.wo: 'Jeex na'},
  'meal.addedToCart': {AppLang.fr: '{name} ajouté au panier', AppLang.en: '{name} added to cart', AppLang.wo: '{name} yokk na ci pañe'},
  'meal.cannotAddToCart': {
    AppLang.fr: 'Ce plat ne peut pas être ajouté au panier.',
    AppLang.en: 'This dish cannot be added to the cart.',
    AppLang.wo: 'Mënuloo yokk ñam bi ci pañe.',
  },
  'meal.reviewsCount': {AppLang.fr: 'Avis ({count})', AppLang.en: 'Reviews ({count})', AppLang.wo: 'Xalaat ({count})'},
  'meal.noReviews': {
    AppLang.fr: 'Aucun avis pour le moment. Sois le premier !',
    AppLang.en: 'No reviews yet. Be the first!',
    AppLang.wo: 'Amul xalaat. Bindal sa bopp!',
  },
  'meal.notRated': {AppLang.fr: 'Pas encore noté', AppLang.en: 'Not rated yet', AppLang.wo: 'Amul not'},
  'meal.customer': {AppLang.fr: 'Client', AppLang.en: 'Customer', AppLang.wo: 'Client'},
  'meal.reviewComment': {AppLang.fr: 'Commentaire (optionnel)', AppLang.en: 'Comment (optional)', AppLang.wo: 'Commentaire (optionnel)'},
  'meal.publishReview': {AppLang.fr: 'Publier mon avis', AppLang.en: 'Post review', AppLang.wo: 'Yónnee sama xalaat'},

  // Social
  'social.feed': {AppLang.fr: 'Fil social', AppLang.en: 'Social feed', AppLang.wo: 'Fil social'},
  'social.like': {AppLang.fr: 'J\'aime', AppLang.en: 'Like', AppLang.wo: 'Bëgg'},
  'social.comment': {AppLang.fr: 'Commenter', AppLang.en: 'Comment', AppLang.wo: 'Commente'},
  'social.share': {AppLang.fr: 'Partager', AppLang.en: 'Share', AppLang.wo: 'Seddoo'},
  'social.subtitle': {
    AppLang.fr: 'Publie ton contenu et laisse la communauté réagir.',
    AppLang.en: 'Publish your content and let the community react.',
    AppLang.wo: 'Yéene sa contenu te taxawal koom-koom bi.',
  },
  'social.publishShort': {AppLang.fr: 'Publier short', AppLang.en: 'Publish short', AppLang.wo: 'Yéene short'},
  'social.publishVideo': {AppLang.fr: 'Publier vidéo', AppLang.en: 'Publish video', AppLang.wo: 'Yéene wideo'},
  'social.publishing': {AppLang.fr: 'Publication en cours…', AppLang.en: 'Publishing…', AppLang.wo: 'Mi ngi yéene…'},
  'social.shortPublished': {AppLang.fr: 'Short publié avec succès', AppLang.en: 'Short published', AppLang.wo: 'Short bi yéene na'},
  'social.videoPublished': {AppLang.fr: 'Vidéo publiée avec succès', AppLang.en: 'Video published', AppLang.wo: 'Wideo bi yéene na'},
  'social.publishFailed': {AppLang.fr: 'Échec de la publication: {error}', AppLang.en: 'Publish failed: {error}', AppLang.wo: 'Xanaa: {error}'},
  'social.emptyShort': {AppLang.fr: 'Aucun short publié', AppLang.en: 'No shorts yet', AppLang.wo: 'Amul short'},
  'social.emptyVideo': {AppLang.fr: 'Aucune vidéo publiée', AppLang.en: 'No videos yet', AppLang.wo: 'Amul wideo'},
  'social.emptyShortHint': {
    AppLang.fr: 'Publie un short pour attirer les clients.',
    AppLang.en: 'Publish a short to attract customers.',
    AppLang.wo: 'Yéene short ngir jël clients yi.',
  },
  'social.emptyVideoHint': {
    AppLang.fr: 'Publie la première vidéo de ton plat.',
    AppLang.en: 'Publish your first dish video.',
    AppLang.wo: 'Yéene sa wideo bu njëkk.',
  },
  'social.subscribe': {AppLang.fr: 'S’abonner', AppLang.en: 'Follow', AppLang.wo: 'Topp'},
  'social.favorite': {AppLang.fr: 'Favori', AppLang.en: 'Save', AppLang.wo: 'Aar'},
  'social.shareOpened': {AppLang.fr: 'Partage ouvert', AppLang.en: 'Share opened', AppLang.wo: 'Seddoo ubbi na'},
  'social.comments': {AppLang.fr: 'Commentaires', AppLang.en: 'Comments', AppLang.wo: 'Commentaire yi'},
  'social.noComments': {AppLang.fr: 'Aucun commentaire pour le moment.', AppLang.en: 'No comments yet.', AppLang.wo: 'Amul commentaire.'},
  'social.addComment': {AppLang.fr: 'Ajouter un commentaire…', AppLang.en: 'Add a comment…', AppLang.wo: 'Yokk commentaire…'},
  'social.reply': {AppLang.fr: 'Répondre', AppLang.en: 'Reply', AppLang.wo: 'Tontu'},
  'social.replyTitle': {AppLang.fr: 'Répondre', AppLang.en: 'Reply', AppLang.wo: 'Tontu'},
  'social.replyHint': {AppLang.fr: 'Ta réponse…', AppLang.en: 'Your reply…', AppLang.wo: 'Sa tontu…'},
  'social.pickFileFailed': {
    AppLang.fr: 'Impossible de choisir le fichier : {error}',
    AppLang.en: 'Could not pick file: {error}',
    AppLang.wo: 'Mënuloo tann fichier bi : {error}',
  },
  'social.pickMediaFirst': {
    AppLang.fr: 'Choisis d’abord une photo ou une vidéo.',
    AppLang.en: 'Choose a photo or video first.',
    AppLang.wo: 'Tannal foto walla wideo bu njëkk.',
  },
  'social.defaultShortCaption': {AppLang.fr: 'Mon short', AppLang.en: 'My short', AppLang.wo: 'Sama short'},
  'social.defaultVideoCaption': {AppLang.fr: 'Ma vidéo', AppLang.en: 'My video', AppLang.wo: 'Sama wideo'},
  'social.defaultPhotoCaption': {AppLang.fr: 'Ma photo', AppLang.en: 'My photo', AppLang.wo: 'Sama foto'},
  'social.shortCaptionLabel': {AppLang.fr: 'Texte du short', AppLang.en: 'Short caption', AppLang.wo: 'Bind short bi'},
  'social.videoCaptionLabel': {
    AppLang.fr: 'Description de la vidéo',
    AppLang.en: 'Video description',
    AppLang.wo: 'Description wideo bi',
  },
  'social.photoGallery': {AppLang.fr: 'Photo (galerie)', AppLang.en: 'Photo (gallery)', AppLang.wo: 'Foto (galerie)'},
  'social.videoGallery': {AppLang.fr: 'Vidéo (galerie)', AppLang.en: 'Video (gallery)', AppLang.wo: 'Wideo (galerie)'},
  'social.recordVideo': {
    AppLang.fr: 'Filmer maintenant (caméra)',
    AppLang.en: 'Record now (camera)',
    AppLang.wo: 'Filme léegi (kamera)',
  },
  'social.noMediaSelected': {
    AppLang.fr: 'Aucun média sélectionné — obligatoire pour publier',
    AppLang.en: 'No media selected — required to publish',
    AppLang.wo: 'Amul média — laaj na ngir yéene',
  },
  'social.mediaSelected': {
    AppLang.fr: 'Média sélectionné : {name}',
    AppLang.en: 'Media selected: {name}',
    AppLang.wo: 'Média tann na : {name}',
  },
  'social.publishShortBtn': {AppLang.fr: 'Publier short', AppLang.en: 'Publish short', AppLang.wo: 'Yéene short'},
  'social.publishVideoBtn': {AppLang.fr: 'Publier vidéo', AppLang.en: 'Publish video', AppLang.wo: 'Yéene wideo'},

  // Legal
  'legal.privacyTitle': {AppLang.fr: 'Politique de confidentialité', AppLang.en: 'Privacy policy', AppLang.wo: 'Politique sutura'},
  'legal.termsTitle': {AppLang.fr: 'Conditions d\'utilisation', AppLang.en: 'Terms of use', AppLang.wo: 'Conditions'},
  'legal.privacyBody': {
    AppLang.fr: 'Food collecte email, téléphone, adresse et position uniquement pour traiter tes commandes et améliorer le service. Tes données ne sont pas vendues à des tiers. Contacte-nous pour demander la suppression de ton compte.',
    AppLang.en: 'Food collects email, phone, address and location only to process orders and improve the service. Your data is not sold to third parties. Contact us to request account deletion.',
    AppLang.wo: 'Food dafay jël email, telefon, adresse ak position rekk ngir saytu sa commande. Nu ngi jëfandikoo sa données rekk ci service bi.',
  },
  'legal.termsBody': {
    AppLang.fr: 'En utilisant Food, tu acceptes nos règles de commande, de paiement et de livraison. Les vendeurs sont responsables de la qualité des plats proposés.',
    AppLang.en: 'By using Food, you accept our ordering, payment and delivery rules. Sellers are responsible for the quality of dishes offered.',
    AppLang.wo: 'Bu nga jëfandikoo Food, danga nangu sunu règle yi. Jaaykat yi dañu responsable qualité ñam yi.',
  },
  'legal.privacyLink': {AppLang.fr: 'Confidentialité', AppLang.en: 'Privacy', AppLang.wo: 'Sutura'},
  'legal.termsLink': {AppLang.fr: 'Conditions', AppLang.en: 'Terms', AppLang.wo: 'Conditions'},

  // Errors
  'error.network': {
    AppLang.fr: 'Impossible de joindre le serveur. Vérifie ta connexion.',
    AppLang.en: 'Cannot reach server. Check your connection.',
    AppLang.wo: 'Mënuloo jëkkandoo ak serveur bi.',
  },
  'error.generic': {AppLang.fr: 'Erreur réseau', AppLang.en: 'Network error', AppLang.wo: 'Erreur réseau'},

  // Language
  'lang.choose': {AppLang.fr: 'Choisir la langue', AppLang.en: 'Choose language', AppLang.wo: 'Tann làkk'},

  // Date abbreviations (Mon–Sun)
  'date.weekdayMon': {AppLang.fr: 'L', AppLang.en: 'M', AppLang.wo: 'Alt'},
  'date.weekdayTue': {AppLang.fr: 'M', AppLang.en: 'T', AppLang.wo: 'Talaata'},
  'date.weekdayWed': {AppLang.fr: 'M', AppLang.en: 'W', AppLang.wo: 'Àllarba'},
  'date.weekdayThu': {AppLang.fr: 'J', AppLang.en: 'T', AppLang.wo: 'Alxames'},
  'date.weekdayFri': {AppLang.fr: 'V', AppLang.en: 'F', AppLang.wo: 'Àjjuma'},
  'date.weekdaySat': {AppLang.fr: 'S', AppLang.en: 'S', AppLang.wo: 'Gaawu'},
  'date.weekdaySun': {AppLang.fr: 'D', AppLang.en: 'S', AppLang.wo: 'Dibéer'},
};
