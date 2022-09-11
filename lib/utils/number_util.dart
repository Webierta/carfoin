import 'package:intl/intl.dart';

const String locEs = 'es';
const double limitDown = 10000;
const double limitUp = 500000;

class NumberUtil {
  static bool inLimit(double number, double limit) {
    if (number < limit && number > -limit) return true;
    return false;
  }

  static String decimal(double number, {bool long = true}) {
    if (!inLimit(number, limitUp)) {
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

  static String decimalFixed(double number,
      {int decimals = 2, bool long = true, double limit = limitUp}) {
    if (!inLimit(number, limit)) {
      return long ? compactLongFixed(number) : compactFixed(number);
    }
    return NumberFormat.decimalPattern(locEs)
        .format(double.parse(number.toStringAsFixed(decimals)));
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

  static String percentCompact(double number) {
    var numberx100 = number * 100;
    if (inLimit(numberx100, limitDown)) return percent(number);
    if (inLimit(numberx100, limitUp)) return '${compactFixed(numberx100)} %';
    return '${NumberFormat.scientificPattern().format(numberx100)} %';
  }

  static String currency(double number) {
    if (!inLimit(number, limitUp)) return compactCurrency(number);
    return NumberFormat.currency(locale: locEs, symbol: '').format(number);
  }

  static String compactCurrency(double number) {
    return NumberFormat.compactCurrency(locale: locEs, symbol: '')
        .format(number);
  }
}
