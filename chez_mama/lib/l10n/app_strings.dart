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

/// Holds the selected language and persists it. The app rebuilds when it
/// changes (MaterialApp listens to this controller).
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

/// Translation lookup. Falls back to French, then to the key itself.
String tr(String key) {
  final lang = LocaleController.instance.lang;
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[lang] ?? entry[AppLang.fr] ?? key;
}

const Map<String, Map<AppLang, String>> _strings = {
  // Navigation / shell
  'nav.home': {AppLang.fr: 'Accueil', AppLang.en: 'Home', AppLang.wo: 'Kër'},
  'nav.shorts': {AppLang.fr: 'Shorts', AppLang.en: 'Shorts', AppLang.wo: 'Shorts'},
  'nav.videos': {AppLang.fr: 'Vidéos', AppLang.en: 'Videos', AppLang.wo: 'Wideo'},
  'nav.tracking': {AppLang.fr: 'Suivi', AppLang.en: 'Tracking', AppLang.wo: 'Topp'},
  'nav.cart': {AppLang.fr: 'Panier', AppLang.en: 'Cart', AppLang.wo: 'Pañe'},
  'menu.dashboard': {
    AppLang.fr: 'Tableau de bord',
    AppLang.en: 'Dashboard',
    AppLang.wo: 'Tablo'
  },
  'menu.shop': {
    AppLang.fr: 'Ma boutique',
    AppLang.en: 'My shop',
    AppLang.wo: 'Sama bitik'
  },
  'menu.publications': {
    AppLang.fr: 'Mes publications',
    AppLang.en: 'My publications',
    AppLang.wo: 'Sama yéene'
  },
  'menu.favorites': {
    AppLang.fr: 'Mes favoris',
    AppLang.en: 'My favorites',
    AppLang.wo: 'Sama soobé'
  },
  'menu.messages': {
    AppLang.fr: 'Messages',
    AppLang.en: 'Messages',
    AppLang.wo: 'Bataaxal'
  },
  'menu.loyalty': {
    AppLang.fr: 'Mes points',
    AppLang.en: 'My points',
    AppLang.wo: 'Sama poñ'
  },
  'menu.language': {
    AppLang.fr: 'Langue',
    AppLang.en: 'Language',
    AppLang.wo: 'Làkk'
  },
  'menu.darkMode': {
    AppLang.fr: 'Mode sombre',
    AppLang.en: 'Dark mode',
    AppLang.wo: 'Mode lëndëm'
  },
  'menu.lightMode': {
    AppLang.fr: 'Mode clair',
    AppLang.en: 'Light mode',
    AppLang.wo: 'Mode leer'
  },
  'menu.logout': {
    AppLang.fr: 'Déconnexion',
    AppLang.en: 'Log out',
    AppLang.wo: 'Génn'
  },
  // Common actions
  'action.retry': {
    AppLang.fr: 'Réessayer',
    AppLang.en: 'Retry',
    AppLang.wo: 'Jéemataat'
  },
  'action.addToCart': {
    AppLang.fr: 'Ajouter au panier',
    AppLang.en: 'Add to cart',
    AppLang.wo: 'Yokk ci pañe'
  },
  'action.unavailable': {
    AppLang.fr: 'Indisponible',
    AppLang.en: 'Unavailable',
    AppLang.wo: 'Amul'
  },
  'action.contactSeller': {
    AppLang.fr: 'Contacter le vendeur',
    AppLang.en: 'Contact the seller',
    AppLang.wo: 'Jokkoo ak jaaykat bi'
  },
  // Home
  'home.publishMeal': {
    AppLang.fr: 'Publier un plat',
    AppLang.en: 'Publish a dish',
    AppLang.wo: 'Yéene ñam'
  },
  'home.search': {
    AppLang.fr: 'Rechercher un plat, un vendeur…',
    AppLang.en: 'Search a dish, a seller…',
    AppLang.wo: 'Seet ñam, jaaykat…'
  },
  'home.filter.available': {
    AppLang.fr: 'Dispo',
    AppLang.en: 'Available',
    AppLang.wo: 'Am na'
  },
  'home.filter.promo': {AppLang.fr: 'Promo', AppLang.en: 'Deal', AppLang.wo: 'Promo'},
  'home.filter.special': {
    AppLang.fr: 'Plat du jour',
    AppLang.en: 'Today\'s special',
    AppLang.wo: 'Ñamu bés bi'
  },
  'home.sort': {AppLang.fr: 'Trier', AppLang.en: 'Sort', AppLang.wo: 'Tëral'},
  // Language dialog
  'lang.choose': {
    AppLang.fr: 'Choisir la langue',
    AppLang.en: 'Choose language',
    AppLang.wo: 'Tann làkk'
  },
};
