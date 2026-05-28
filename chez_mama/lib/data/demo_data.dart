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
      image: 'https://images.unsplash.com/photo-1604908554027-3c4a25b4c7b5?auto=format&fit=crop&w=1200&q=60',
      accent: ChezMamaTheme.brandOrange,
      category: 'Popular',
    ),
    Meal(
      id: 'yassa',
      name: 'Yassa Poulet',
      subtitle: 'Oignons citronnés, épices douces',
      price: 3200,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1604909054103-3f8b80b9dcd3?auto=format&fit=crop&w=1200&q=60',
      accent: ChezMamaTheme.brandAmber,
      category: 'Plats',
    ),
    Meal(
      id: 'ndole',
      name: 'Ndolé',
      subtitle: 'Feuilles amères, crevettes, arachide',
      price: 4000,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1604908177078-6db8b27c1208?auto=format&fit=crop&w=1200&q=60',
      accent: const Color(0xFF5BBF72),
      category: 'Plats',
    ),
    Meal(
      id: 'suya',
      name: 'Suya',
      subtitle: 'Bœuf grillé, poudre d’arachide',
      price: 2800,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=60',
      accent: const Color(0xFFB85C38),
      category: 'Grillades',
    ),
    Meal(
      id: 'ginger',
      name: 'Jus de Gingembre',
      subtitle: 'Frais, citron, légèrement épicé',
      price: 1500,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1510626176961-4b57d4fbad03?auto=format&fit=crop&w=1200&q=60',
      accent: const Color(0xFFE2A83B),
      category: 'Boissons',
    ),
  ];
}

