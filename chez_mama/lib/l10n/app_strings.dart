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
  'home.voiceSearch': {AppLang.fr: 'Recherche vocale', AppLang.en: 'Voice search', AppLang.wo: 'Seet ak baat'},

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

  // Tracking
  'tracking.title': {AppLang.fr: 'Suivi de commande', AppLang.en: 'Order tracking', AppLang.wo: 'Topp commande'},
  'tracking.none': {AppLang.fr: 'Aucune commande en cours', AppLang.en: 'No active order', AppLang.wo: 'Amul commande ci yoon'},
  'tracking.loginRequired': {AppLang.fr: 'Connecte-toi pour suivre tes commandes.', AppLang.en: 'Sign in to track orders.', AppLang.wo: 'Dugg ngir topp sa commande.'},
  'tracking.orderLabel': {AppLang.fr: 'Commande #{id}', AppLang.en: 'Order #{id}', AppLang.wo: 'Commande #{id}'},
  'tracking.seeAll': {AppLang.fr: 'Voir toutes mes commandes', AppLang.en: 'See all orders', AppLang.wo: 'Gis commande yépp'},

  // Notifications
  'notif.title': {AppLang.fr: 'Notifications', AppLang.en: 'Notifications', AppLang.wo: 'Xibaar yi'},
  'notif.empty': {AppLang.fr: 'Aucune notification.', AppLang.en: 'No notifications.', AppLang.wo: 'Amul xibaar.'},

  // Chat
  'chat.title': {AppLang.fr: 'Messages', AppLang.en: 'Messages', AppLang.wo: 'Bataaxal'},
  'chat.empty': {AppLang.fr: 'Aucune conversation.', AppLang.en: 'No conversations.', AppLang.wo: 'Amul waxtaan.'},
  'chat.hint': {AppLang.fr: 'Écris un message…', AppLang.en: 'Write a message…', AppLang.wo: 'Bindal bataaxal…'},

  // Favorites / loyalty / profile
  'favorites.title': {AppLang.fr: 'Mes favoris', AppLang.en: 'My favorites', AppLang.wo: 'Sama soobé'},
  'favorites.empty': {AppLang.fr: 'Aucun favori.', AppLang.en: 'No favorites.', AppLang.wo: 'Amul soobé.'},
  'loyalty.title': {AppLang.fr: 'Mes points fidélité', AppLang.en: 'Loyalty points', AppLang.wo: 'Sama poñ'},
  'loyalty.points': {AppLang.fr: '{points} points', AppLang.en: '{points} points', AppLang.wo: '{points} poñ'},
  'shop.title': {AppLang.fr: 'Ma boutique', AppLang.en: 'My shop', AppLang.wo: 'Sama bitik'},
  'dashboard.title': {AppLang.fr: 'Tableau de bord', AppLang.en: 'Dashboard', AppLang.wo: 'Tablo'},
  'publications.title': {AppLang.fr: 'Mes publications', AppLang.en: 'My publications', AppLang.wo: 'Sama yéene'},

  // Meal details
  'meal.reviews': {AppLang.fr: 'Avis', AppLang.en: 'Reviews', AppLang.wo: 'Xalaat'},
  'meal.addReview': {AppLang.fr: 'Laisser un avis', AppLang.en: 'Leave a review', AppLang.wo: 'Bind xalaat'},
  'meal.yourRating': {AppLang.fr: 'Ta note', AppLang.en: 'Your rating', AppLang.wo: 'Sa not'},

  // Social
  'social.feed': {AppLang.fr: 'Fil social', AppLang.en: 'Social feed', AppLang.wo: 'Fil social'},
  'social.like': {AppLang.fr: 'J\'aime', AppLang.en: 'Like', AppLang.wo: 'Bëgg'},
  'social.comment': {AppLang.fr: 'Commenter', AppLang.en: 'Comment', AppLang.wo: 'Commente'},
  'social.share': {AppLang.fr: 'Partager', AppLang.en: 'Share', AppLang.wo: 'Seddoo'},

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
};
