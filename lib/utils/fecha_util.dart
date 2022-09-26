import 'package:intl/intl.dart' show DateFormat;

class FechaUtil {
  static String dateToString(
      {required DateTime date, String formato = 'd/MM/yy'}) {
    return DateFormat(formato, 'es').format(date);
  }

  static DateTime epochToDate(int epoch) {
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  }

  static String epochToString(int epoch, {String formato = 'd/MM/yy'}) {
    final DateTime date = epochToDate(epoch);
    return dateToString(date: date, formato: formato);
  }

  static int dateToEpoch(DateTime date) {
    return date.millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime dateToDateHms(DateTime date) {
    return DateTime(date.year, date.month, date.day, 2, 0, 0, 0, 0);
  }

  static int epochToEpochHms(int epoch) {
    DateTime date = epochToDate(epoch);
    date = dateToDateHms(date);
    return dateToEpoch(date);
  }
}
