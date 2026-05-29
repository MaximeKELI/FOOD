import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';

/// Formats amounts in West African CFA francs.
String formatFcfa(num amount, {AppLang? lang}) {
  final locale = switch (lang ?? LocaleController.instance.lang) {
    AppLang.en => 'en_US',
    AppLang.wo => 'fr_SN',
    AppLang.fr => 'fr_FR',
  };
  final formatted = NumberFormat.decimalPattern(locale).format(amount);
  return '$formatted FCFA';
}
