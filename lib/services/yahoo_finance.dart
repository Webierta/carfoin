/*
1. BUSCAR POR ISIN
   symbolYahoo = https://query1.finance.yahoo.com/v1/finance/search
    ?q=ES0152743003
    &quotesCount=1
    &newsCount=0
    &listsCount=0
    &typeDisp=Fund
    &quotesQueryId=tss_match_phrase_query

2. BUSCAR POR SYMBOL
   dataYahoo = https://query1.finance.yahoo.com/v7/finance/options/0P0000A9EK.F

3. BUSCAR POR NOMBRE
   listaFondos = YahooFinance().getFondoByName(termino)
   https://query1.finance.yahoo.com/v1/finance/search?q=naranja

   fondosSugeridos = YahooFinance().searchIsin(listaFondos)
   YahooFinance().getIsinByName(nombreFondo)
   https://markets.ft.com/data/search?query=Naranja+Renta+Fija+Corto+Plazo

   https://markets.ft.com/data/search?query=ING+Direc&country=SP&assetClass=Fund
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';

import '../models/cartera.dart';
import '../models/data_yahoo.dart';
import '../utils/fecha_util.dart';
import '../utils/status_api_service.dart';

class YahooFinance {
  StatusApiService status = StatusApiService.inactive;

  Future<Fondo?> getFondoByIsin(String isin) async {
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      'HttpHeaders.contentTypeHeader': 'application/json',
    };
    final Map<String, String> queryParameters = {
      'q': isin,
      'quotesCount': '1',
      'newsCount': '0',
      'listsCount': '0',
      'typeDisp': 'Fund',
      'quotesQueryId': 'tss_match_phrase_query',
    };
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v1/finance/search',
      queryParameters,
    );
    var client = http.Client();
    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        status = StatusApiService.okHttp;
        SymbolYahoo symbolYahoo = SymbolYahoo.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        var symbol = symbolYahoo.symbol;
        final uri2 = Uri.https(
          'query1.finance.yahoo.com',
          '/v7/finance/options/$symbol',
        );
        final response2 = await client.get(uri2, headers: headers);
        if (response2.statusCode == 200) {
          DataYahoo dataYahoo = DataYahoo.fromJson(
              jsonDecode(response2.body) as Map<String, dynamic>);
          Fondo newFondo = Fondo(
            isin: isin,
            name: dataYahoo.name,
            divisa: dataYahoo.divisa,
            ticker: dataYahoo.symbol,
          );
          newFondo.valores = [
            Valor(
              date: FechaUtil.epochToEpochHms(dataYahoo.fecha),
              precio: dataYahoo.valor,
            )
          ];
          //newFondo.ticker = dataYahoo.symbol;
          return newFondo;
        } else {
          //response2.statusCode != 200
          status = StatusApiService.errorHttp;
          return null;
        }
      } else {
        //response.statusCode != 200
        status = StatusApiService.errorHttp;
        return null;
      }
    } on TimeoutException {
      status = StatusApiService.tiempoOut;
      return null;
    } on SocketException {
      status = StatusApiService.noInternet;
      return null;
    } on Error {
      status = StatusApiService.error;
      return null;
    } catch (e) {
      status = StatusApiService.error;
      return null;
    } finally {
      client.close();
    }
  }

  Future<String?> getTickerYahoo(String isin) async {
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      'HttpHeaders.contentTypeHeader': 'application/json',
    };
    final Map<String, String> queryParameters = {
      'q': isin,
      'quotesCount': '1',
      'newsCount': '0',
      'listsCount': '0',
      'quotesQueryId': 'tss_match_phrase_query',
    };
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v1/finance/search',
      queryParameters,
    );
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        status = StatusApiService.okHttp;
        SymbolYahoo symbolYahoo = SymbolYahoo.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        return symbolYahoo.symbol;
      } else {
        status = StatusApiService.errorHttp;
        return null;
      }
    } on TimeoutException {
      status = StatusApiService.tiempoOut;
      return null;
    } on SocketException {
      status = StatusApiService.noInternet;
      return null;
    } catch (e) {
      status = StatusApiService.error;
      return null;
    }
  }

  Future<List<Valor>?> getYahooFinanceResponse(Fondo fondo,
      [DateTime? to, DateTime? from]) async {
    DateTime? date1;
    DateTime? date2;
    if (to != null && from != null) {
      date1 = FechaUtil.dateToDateHms(from);
      date2 = FechaUtil.dateToDateHms(to);
    }

    if (fondo.ticker == null || fondo.ticker!.isEmpty) {
      fondo.ticker = await getTickerYahoo(fondo.isin);
      // TODO: guardar en database
    }

    //fondo.ticker ??= await getTickerYahoo(fondo.isin);
    if (fondo.ticker == null || fondo.ticker!.isEmpty) {
      return null;
    }
    YahooFinanceResponse response;
    try {
      response = await const YahooFinanceDailyReader(
        timeout: Duration(seconds: 10),
      ).getDailyDTOs(fondo.ticker!, startDate: date1);
    } catch (e) {
      status = StatusApiService.errorHttp;
      return null;
    }
    if (response.candlesData.isEmpty) {
      status = StatusApiService.errorHttp;
      return null;
    }
    status = StatusApiService.okHttp;
    List<YahooFinanceCandleData> candlesData = response.candlesData;
    List<Valor> valores = [];

    if (to == null && from == null) {
      var candle = response.candlesData.last;
      var data = FechaUtil.dateToDateHms(candle.date);
      valores.add(
        Valor(
          date: FechaUtil.dateToEpoch(data),
          precio: candle.close,
        ),
      );
      return valores;
    }

    List<YahooFinanceCandleData> candlesPeriodo = [];
    for (var candle in candlesData) {
      var data = FechaUtil.dateToDateHms(candle.date);
      if (data.compareTo(date2!) <= 0) {
        candlesPeriodo.add(candle);
      }
    }
    for (var candle in candlesPeriodo) {
      var data = FechaUtil.dateToDateHms(candle.date);
      valores.add(
        Valor(
          date: FechaUtil.dateToEpoch(data),
          precio: candle.close,
        ),
      );
    }
    return valores;
  }

  Future<List<Fondo>> getFondosByName(String termino) async {
    List<Fondo> fondos = [];
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      'HttpHeaders.contentTypeHeader': 'application/json',
    };
    final Map<String, String> queryParameters = {
      'q': termino,
      'newsCount': '0',
      'listsCount': '0',
      'quotesQueryId': 'tss_match_phrase_query',
    };
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v1/finance/search',
      queryParameters,
    );

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        SearchNameSymbol searchNameSymbol = SearchNameSymbol.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        Map<String, String> mapSymbolName = searchNameSymbol.mapSymbolName;
        if (mapSymbolName.isEmpty) {
          return [];
        }
        var client = http.Client();
        for (var item in mapSymbolName.entries) {
          try {
            String getIsin = await getIsinByName(client, item.value);
            /* if (getIsin.isEmpty) {
              continue;
            } */
            int indice = getIsin.indexOf(':');
            String isin = '';
            String divisa = '';
            if (indice != -1) {
              isin = getIsin.substring(0, indice);
              divisa = getIsin.substring(indice + 1);
            }
            fondos.add(Fondo(
              isin: isin,
              name: item.value,
              divisa: divisa,
              ticker: item.key,
            ));
          } catch (e) {
            return [];
          }
        }
        client.close();
        return fondos;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

/*   Future<List<String>> getFondoByName(String termino) async {
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      'HttpHeaders.contentTypeHeader': 'application/json',
    };
    final Map<String, String> queryParameters = {
      'q': termino,
      'newsCount': '0',
      'listsCount': '0',
      'quotesQueryId': 'tss_match_phrase_query',
    };
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v1/finance/search',
      queryParameters,
    );

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        SearchByName searchByName = SearchByName.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        return searchByName.listaFondos;
      } else {
        //response.statusCode != 200
        //print(response.statusCode);
        return [];
      }
    } catch (e) {
      //print(e.toString());
      return [];
    }
  } */

/*   Future<List<Fondo>> searchIsin(List<String> nameFondos) async {
    List<Fondo> fondos = [];
    var client = http.Client();
    for (var name in nameFondos) {
      try {
        String getIsin = await getIsinByName(client, name);
        int indice = getIsin.indexOf(':');
        String isin = '';
        String divisa = '';
        if (indice != -1) {
          isin = getIsin.substring(0, indice);
          divisa = getIsin.substring(indice + 1);
        }
        fondos.add(Fondo(isin: isin, name: name, divisa: divisa));
      } catch (e) {
        return fondos;
      }
    }
    client.close();
    return fondos;
  } */

  Future<String> getIsinByName(http.Client client, String nameFondo) async {
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      //'HttpHeaders.contentTypeHeader': 'application/json',
    };

    final Map<String, String> queryParameters = {
      'query': nameFondo.replaceAll(' ', '+'),
      'country': '',
      'assetClass': 'Fund',
    };
    final uri = Uri.https(
      'markets.ft.com',
      '/data/search',
      queryParameters,
    );
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var filas = document.getElementsByClassName('mod-ui-table__cell--text');
      if (filas.isNotEmpty) {
        return filas.last.innerHtml;
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

/*   Future<String> searchDivisa(String name, String isin) async {
    String divisaFound = '';
    const Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
      //'HttpHeaders.contentTypeHeader': 'application/json',
    };

    final Map<String, String> queryParameters = {
      'query': name.replaceAll(' ', '+'),
      'country': '',
      'assetClass': 'Fund',
    };
    final uri = Uri.https(
      'markets.ft.com',
      '/data/search',
      queryParameters,
    );
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var filas = document.getElementsByClassName('mod-ui-table__cell--text');
        if (filas.isNotEmpty) {
          String isinDivisa = filas.last.innerHtml;
          int indice = isinDivisa.indexOf(':');
          String isinFound = '';
          if (indice != -1) {
            isinFound = isinDivisa.substring(0, indice);
            divisaFound = isinDivisa.substring(indice + 1);
          }
          if (isinFound == isin) {
            return divisaFound;
          }
        }
      }
    } catch (e) {
      return '';
    }
    return '';
  } */
}
