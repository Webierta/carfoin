import 'package:intl/intl.dart';

class FechaUtil {
  static String dateToString({required DateTime date, String formato = 'd/MM/yy'}) {
    return DateFormat(formato, 'es').format(date);
  }

  static DateTime epochToDate(int epoch) {
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  }

  static String epochToString(int epoch, {String formato = 'd/MM/yy'}) {
    final DateTime date = epochToDate(epoch);
    return dateToString(date: date, formato: formato);
  }
}
