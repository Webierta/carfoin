import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/data_api.dart';

// TODO: CHECK INTERNET
class ApiService {
  static String version = dotenv.get('VERSION', fallback: 'Default');

  Future<DataApi?> getDataApi(String isin) async {
    const String urlFondo = 'https://funds.p.rapidapi.com/v1/fund/';
    var url = urlFondo + isin;
    Map<String, String> headers = {
      "x-rapidapi-host": "funds.p.rapidapi.com",
      "x-rapidapi-key": version,
    };

    try {
      var response = await http.get(Uri.parse(url), headers: headers);
      //TODO: timeout
      //.timeout(const Duration(seconds: 10));
      print(response.statusCode);
      if (response.body.contains('Access denied')) {
        // status = Status.accessDenied;
        //TODO: status Code == 200 pero sin resultados
        // else if (response.statusCode != 200)
      } else if (response.statusCode == 200) {
        return dataApiFromJson(response.body);
      }
    } catch (e) {
      print(e.toString());
    }
    /*on TimeoutException {
      //status = Status.tiempoExcedido;
      //return null;
    } on SocketException {
      //status = Status.noInternet;
      // SocketException == sin internet
    } on Error {
      //status = Status.error;
    }*/
    return null;
  }

  Future<List<DataApiRange>?>? getDataApiRange(String isin, String to, String from) async {
    String urlRange = 'https://funds.p.rapidapi.com/v1/historicalPrices/';
    var url = '$urlRange$isin?to=$to&from=$from';
    Map<String, String> headers = {
      "x-rapidapi-host": "funds.p.rapidapi.com",
      "x-rapidapi-key": version,
    };

    try {
      var response = await http.get(Uri.parse(url), headers: headers);
      // TODO: timeout
      //.timeout(const Duration(seconds: 10));
      print(response.statusCode);
      if (response.body.contains('Access denied')) {
        // status = Status.accessDenied;
      } else if (response.statusCode == 200) {
        return dataApiRangeFromJson(response.body);
      }
    } catch (e) {
      print(e.toString());
    }
    /*on TimeoutException {
      //status = Status.tiempoExcedido;
      //return null;
    } on SocketException {
      //status = Status.noInternet;
    } on Error {
      //status = Status.error;
    }*/
    return null;
  }
}
