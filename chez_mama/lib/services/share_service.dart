import 'package:share_plus/share_plus.dart';

import '../models/meal.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  Future<void> shareMeal(Meal meal) {
    final price = meal.effectivePrice.round();
    return Share.share(
      '${meal.name} — $price FCFA\n${meal.subtitle}',
      subject: meal.name,
    );
  }

  Future<void> shareSeller({required String name, required int sellerId}) {
    return Share.share(
      '$name sur Food\nfood://seller/$sellerId',
      subject: name,
    );
  }
}
