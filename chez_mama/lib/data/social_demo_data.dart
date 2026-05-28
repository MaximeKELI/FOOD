import '../models/social_post.dart';

class SocialDemoData {
  static const posts = [
    SocialPost(
      id: 'mafe-video',
      sellerName: 'Mama Aïcha',
      caption: 'Mafé chaud prêt maintenant, livraison rapide à Douala.',
      imageAsset: 'assets/images/food_hero_mafe.png',
      distanceKm: 1.2,
      likes: 1280,
      comments: 84,
      isShort: false,
    ),
    SocialPost(
      id: 'suya-short',
      sellerName: 'Chez Bello Grill',
      caption: 'Suya fumé, piment maison, brochettes sorties du feu.',
      imageAsset: 'assets/images/food_hero_suya.png',
      distanceKm: 2.4,
      likes: 920,
      comments: 51,
      isShort: true,
    ),
    SocialPost(
      id: 'yassa-video',
      sellerName: 'Dakar Food Corner',
      caption: 'Yassa du jour avec oignons fondants et citron frais.',
      imageAsset: 'assets/images/food_hero_yassa.png',
      distanceKm: 3.1,
      likes: 740,
      comments: 42,
      isShort: false,
    ),
    SocialPost(
      id: 'drinks-short',
      sellerName: 'Fresh Bissap Bar',
      caption: 'Bissap glacé et jus de gingembre, parfait pour midi.',
      imageAsset: 'assets/images/food_hero_drinks.png',
      distanceKm: 0.9,
      likes: 530,
      comments: 23,
      isShort: true,
    ),
  ];
}

