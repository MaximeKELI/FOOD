class SocialPost {
  const SocialPost({
    required this.id,
    required this.sellerName,
    required this.caption,
    required this.imageAsset,
    required this.distanceKm,
    required this.likes,
    required this.comments,
    required this.isShort,
  });

  final String id;
  final String sellerName;
  final String caption;
  final String imageAsset;
  final double distanceKm;
  final int likes;
  final int comments;
  final bool isShort;
}

