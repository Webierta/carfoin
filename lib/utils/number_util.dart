import 'package:intl/intl.dart';

const String locEs = 'es';

class NumberUtil {
  static String decimal(double number, {bool long = true}) {
    if (number > 1000000) {
      return long ? compactLong(number) : compact(number);
    }
    return NumberFormat.decimalPattern(locEs).format(number);
  }

  static String compact(double number) {
    return NumberFormat.compact(locale: locEs).format(number);
  }

  static String compactLong(double number) {
    return NumberFormat.compactLong(locale: locEs).format(number);
  }

  static String decimalFixed(double number, {bool long = true}) {
    if (number > 1000000) {
      return long ? compactLongFixed(number) : compactFixed(number);
    }
    return NumberFormat.decimalPattern(locEs)
        .format(double.parse(number.toStringAsFixed(2)));
  }

  static String compactFixed(double number) {
    return NumberFormat.compact(locale: locEs)
        .format(double.parse(number.toStringAsFixed(2)));
  }

  static String compactLongFixed(double number) {
    return NumberFormat.compactLong(locale: locEs)
        .format(double.parse(number.toStringAsFixed(2)));
  }

  static String percent(double number) {
    return NumberFormat.decimalPercentPattern(locale: locEs, decimalDigits: 2)
        .format(number);
  }

  static String currency(double number) {
    if (number > 1000000) return compactCurrency(number);
    return NumberFormat.currency(locale: locEs, symbol: '').format(number);
  }

  static String compactCurrency(double number) {
    return NumberFormat.compactCurrency(locale: locEs, symbol: '')
        .format(number);
  }
}
