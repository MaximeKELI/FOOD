import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/meal.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  Future<void> shareMeal(Meal meal) {
    final price = meal.effectivePrice.round();
    final deep = 'food://meal/${meal.id}';
    return SharePlus.instance.share(
      ShareParams(
        text: '${meal.name} — $price FCFA\n${meal.subtitle}\n$deep',
        subject: meal.name,
      ),
    );
  }

  Future<void> shareSeller({required String name, required int sellerId}) {
    return SharePlus.instance.share(
      ShareParams(
        text: '$name sur Food\nfood://seller/$sellerId',
        subject: name,
      ),
    );
  }

  Future<void> shareGroupOrder(String code) {
    final link = 'food://group-order/$code';
    return SharePlus.instance.share(
      ShareParams(
        text: '${tr('groupOrder.shareText')}\n'
            '${trf('groupOrder.codeLine', {'code': code})}\n$link',
        subject: tr('groupOrder.title'),
      ),
    );
  }
}
