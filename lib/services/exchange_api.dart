import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/fecha_util.dart';

class Rate {
  final int date;
  final double rate;

  const Rate({required this.date, required this.rate});
}

class ExchangeApi {
  Future<Rate?> latestRate() async {
    Rate? lastRate;
    const String url = 'https://api.frankfurter.app/latest?from=USD&to=EUR';
    const Map<String, String> headers = {
      "Host": "api.frankfurter.app",
      "Content-Type": "application/json; charset=utf-8",
    };
    try {
      var response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dateDecoded = decoded['date'];
        final ratesMap = (decoded['rates'] as Map).cast<String, double>();
        //lastRate = ratesMap.values.first.toDouble();
        var lastRateEUR = ratesMap['EUR'] as double;
        var dateTime = DateTime.parse(dateDecoded);
        //dateTime = FechaUtil.dateToDateHms(dateTime);
        var date = FechaUtil.dateToEpoch(dateTime);
        lastRate = Rate(date: date, rate: lastRateEUR);
      }
    } catch (e) {
      print(e.toString());
    }
    return lastRate;
  }
}
