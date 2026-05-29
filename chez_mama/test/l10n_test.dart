import 'package:flutter_test/flutter_test.dart';

import 'package:chez_mama/l10n/app_strings.dart';
import 'package:chez_mama/utils/currency_format.dart';

void main() {
  group('formatFcfa', () {
    test('formats French locale with FCFA suffix', () {
      expect(formatFcfa(1500, lang: AppLang.fr), '1\u202f500 FCFA');
    });

    test('formats English locale', () {
      expect(formatFcfa(1500, lang: AppLang.en), '1,500 FCFA');
    });

    test('formats zero', () {
      expect(formatFcfa(0, lang: AppLang.fr), '0 FCFA');
    });
  });

  group('tr / trf', () {
    setUp(() async {
      await LocaleController.instance.setLang(AppLang.fr);
    });

    test('returns French string for known key', () {
      expect(tr('auth.login'), 'Connexion');
    });

    test('interpolates placeholders', () {
      expect(
        trf('checkout.orderConfirmed', {'id': 7, 'total': '2 500 FCFA'}),
        contains('#7'),
      );
    });

    test('payment resume keys exist in all languages', () {
      for (final lang in AppLang.values) {
        LocaleController.instance.setLang(lang);
        expect(tr('checkout.paymentConfirmedResume'), isNotEmpty);
        expect(tr('checkout.paymentFailedResume'), isNotEmpty);
      }
    });
  });
}
