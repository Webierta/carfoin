import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/data_api.dart';
import '../models/logger.dart';
import '../utils/konstantes.dart';
import '../utils/status_api_service.dart';

class ApiService {
  StatusApiService status = StatusApiService.inactive;

  Future<DataApi?> getDataApi(String isin) async {
    Map<String, String> headers = {
      "x-rapidapi-host": "funds.p.rapidapi.com",
      "x-rapidapi-key": apiTest(),
    };
    const String urlFondo = 'https://funds.p.rapidapi.com/v1/fund/';
    var url = urlFondo + isin;

    try {
      var response =
          await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        status = StatusApiService.okHttp;
        return dataApiFromJson(response.body);
      } else {
        status = StatusApiService.errorHttp;
        Logger.log(
            dataLog: DataLog(
                msg: 'Status Code: ${response.statusCode} $isin',
                file: 'api_service.dart',
                clase: 'ApiService',
                funcion: 'getDataApi'));
      }
    } on TimeoutException {
      status = StatusApiService.tiempoOut;
    } on SocketException {
      status = StatusApiService.noInternet;
    } on Error {
      status = StatusApiService.error;
    } catch (e, s) {
      status = StatusApiService.error;
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Response Funds API',
              file: 'api_service.dart',
              clase: 'ApiService',
              funcion: 'getDataApi',
              error: e,
              stackTrace: s));
    }
    return null;
  }

  Future<List<DataApiRange>?>? getDataApiRange(String isin, String to, String from) async {
    Map<String, String> headers = {
      "x-rapidapi-host": "funds.p.rapidapi.com",
      "x-rapidapi-key": apiTest(),
    };
    const String urlRange = 'https://funds.p.rapidapi.com/v1/historicalPrices/';
    var url = '$urlRange$isin?to=$to&from=$from';

    try {
      var response =
          await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        status = StatusApiService.okHttp;
        return dataApiRangeFromJson(response.body);
      } else {
        status = StatusApiService.errorHttp;
        Logger.log(
            dataLog: DataLog(
                msg: 'Status Code: ${response.statusCode}',
                file: 'api_service.dart',
                clase: 'ApiService',
                funcion: 'getDataApiRange'));
      }
    } on TimeoutException {
      status = StatusApiService.tiempoOut;
    } on SocketException {
      status = StatusApiService.noInternet;
    } on Error {
      status = StatusApiService.error;
    } catch (e, s) {
      status = StatusApiService.error;
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Response Funds API',
              file: 'api_service.dart',
              clase: 'ApiService',
              funcion: 'getDataApiRange',
              error: e,
              stackTrace: s));
    }
    return null;
  }

  static apiTest() {
    final test = isinTest.split(' ').map((i) => int.parse(i.toString(), radix: 2)).toList();
    return utf8.decode(base64.decode(utf8.decode(test)));
  }
}
