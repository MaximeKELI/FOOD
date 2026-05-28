import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../ui/chezmama_theme.dart';

class DemoData {
  static const categories = <String>[
    'Popular',
    'Plats',
    'Soupes',
    'Grillades',
    'Snacks',
    'Boissons',
  ];

  static final meals = <Meal>[
    Meal(
      id: 'mafe',
      name: 'Mafé Poulet',
      subtitle: 'Sauce arachide, riz parfumé',
      price: 3500,
      rating: 4.8,
      image: 'assets/images/food_hero_mafe.png',
      accent: ChezMamaTheme.brandOrange,
      category: 'Plats',
    ),
    Meal(
      id: 'yassa',
      name: 'Yassa Poulet',
      subtitle: 'Oignons citronnés, épices douces',
      price: 3200,
      rating: 4.7,
      image: 'assets/images/food_hero_yassa.png',
      accent: ChezMamaTheme.brandAmber,
      category: 'Plats',
    ),
    Meal(
      id: 'ndole',
      name: 'Ndolé',
      subtitle: 'Feuilles amères, crevettes, arachide',
      price: 4000,
      rating: 4.6,
      image: 'assets/images/food_hero_ndole.png',
      accent: const Color(0xFF5BBF72),
      category: 'Plats',
    ),
    Meal(
      id: 'thieboudienne',
      name: 'Thiéboudienne',
      subtitle: 'Poisson, riz rouge et légumes',
      price: 4300,
      rating: 4.7,
      image: 'assets/images/food_hero_thieboudienne.png',
      accent: const Color(0xFFB85C38),
      category: 'Plats',
    ),
    Meal(
      id: 'egusi',
      name: 'Soupe Egusi',
      subtitle: 'Egusi riche, viande et pâte',
      price: 3800,
      rating: 4.5,
      image: 'assets/images/food_hero_egusi.png',
      accent: const Color(0xFF7A5A3A),
      category: 'Soupes',
    ),
    Meal(
      id: 'suya',
      name: 'Suya',
      subtitle: 'Bœuf grillé, poudre d’arachide',
      price: 2800,
      rating: 4.5,
      image: 'assets/images/food_hero_suya.png',
      accent: const Color(0xFFB85C38),
      category: 'Grillades',
    ),
    Meal(
      id: 'brochettes',
      name: 'Brochettes mixtes',
      subtitle: 'Viande grillée, sauce piment',
      price: 3000,
      rating: 4.6,
      image: 'assets/images/food_hero_brochettes.png',
      accent: const Color(0xFFA14E2F),
      category: 'Grillades',
    ),
    Meal(
      id: 'plantain',
      name: 'Plantains épicés',
      subtitle: 'Bananes plantain et sauce tomate',
      price: 1800,
      rating: 4.4,
      image: 'assets/images/food_hero_plantain.png',
      accent: const Color(0xFFE2A83B),
      category: 'Snacks',
    ),
    Meal(
      id: 'ginger',
      name: 'Jus de Gingembre',
      subtitle: 'Frais, citron, légèrement épicé',
      price: 1500,
      rating: 4.4,
      image: 'assets/images/food_hero_drinks.png',
      accent: const Color(0xFFE2A83B),
      category: 'Boissons',
    ),
  ];
}

