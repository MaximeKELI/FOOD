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
      image: 'https://picsum.photos/seed/chezmama_mafe/1200/800',
      accent: ChezMamaTheme.brandOrange,
      category: 'Popular',
    ),
    Meal(
      id: 'yassa',
      name: 'Yassa Poulet',
      subtitle: 'Oignons citronnés, épices douces',
      price: 3200,
      rating: 4.7,
      image: 'https://picsum.photos/seed/chezmama_yassa/1200/800',
      accent: ChezMamaTheme.brandAmber,
      category: 'Plats',
    ),
    Meal(
      id: 'ndole',
      name: 'Ndolé',
      subtitle: 'Feuilles amères, crevettes, arachide',
      price: 4000,
      rating: 4.6,
      image: 'https://picsum.photos/seed/chezmama_ndole/1200/800',
      accent: const Color(0xFF5BBF72),
      category: 'Plats',
    ),
    Meal(
      id: 'suya',
      name: 'Suya',
      subtitle: 'Bœuf grillé, poudre d’arachide',
      price: 2800,
      rating: 4.5,
      image: 'https://picsum.photos/seed/chezmama_suya/1200/800',
      accent: const Color(0xFFB85C38),
      category: 'Grillades',
    ),
    Meal(
      id: 'ginger',
      name: 'Jus de Gingembre',
      subtitle: 'Frais, citron, légèrement épicé',
      price: 1500,
      rating: 4.4,
      image: 'https://picsum.photos/seed/chezmama_ginger/1200/800',
      accent: const Color(0xFFE2A83B),
      category: 'Boissons',
    ),
  ];
}

