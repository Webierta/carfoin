import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import '../models/logger.dart';

class DocCnmv {
  final String isin;
  const DocCnmv({required this.isin});

  Future<Document?> _getDoc(String url) async {
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return parser.parse(response.body);
      } else {
        throw Exception('Status Code != 200');
      }
    } catch (e) {
      Logger.log(
        dataLog: DataLog(
            msg: 'Catch response CNMV: $e : $isin',
            file: 'doc_cnmv.dart',
            clase: 'DocCnmv',
            funcion: '_getDoc',
            error: e),
      );
    }
    return null;
  }

  Future<String?> getUrlFolleto() async {
    String? href;
    const String urlBase =
        'https://www.cnmv.es/Portal/Consultas/IIC/Fondo.aspx?isin=';
    final String url = urlBase + isin;

    try {
      Document? document = await _getDoc(url);
      if (document != null) {
        List<Element?>? selectElements = document
            .getElementById('ctl00_ContentPrincipal_gridDatos')
            ?.getElementsByTagName('td')
            .where((element) => element.attributes['data-th'] == 'Folleto')
            .map((item) => item.querySelector('a'))
            .toList();
        if (selectElements != null && selectElements.isNotEmpty) {
          href = selectElements.first?.attributes['href'];
          if (href != null) {
            return href;
          } else {
            throw Exception('url is null: $isin');
          }
        } else {
          throw Exception('selectElements is null: $isin');
        }
      } else {
        throw Exception('document is null: $isin');
      }
    } catch (e) {
      Logger.log(
        dataLog: DataLog(
          msg: '$e',
          file: 'doc_cnmv.dart',
          clase: 'DocCnmv',
          funcion: 'getUrlFolleto',
        ),
      );
    }
    return null;
  }

  Future<String?> getUrlInforme() async {
    String? href;
    const String urlBase =
        'https://www.cnmv.es/Portal/Consultas/IIC/Fondo.aspx?isin=';
    const String urlInfomesBase = 'https://www.cnmv.es/Portal/Consultas/IIC/';
    final String url = urlBase + isin;

    try {
      Document? document = await _getDoc(url);
      if (document != null) {
        Element? infoPeriodica =
            document.getElementById('ctl00_ContentPrincipal_wNavegacion_hlIPP');
        String? hrefInfoPeriodica = infoPeriodica?.attributes['href'];
        if (hrefInfoPeriodica != null) {
          var urlInformes = urlInfomesBase + hrefInfoPeriodica;
          Document? docInformes = await _getDoc(urlInformes);
          if (docInformes != null) {
            href = docInformes
                .getElementById(
                    'ctl00_ContentPrincipal_wIPPS_gridIPPS_ctl02_lnkPDF')
                ?.attributes['href'];

            if (href != null) {
              return href;
            } else {
              throw Exception('url is null: $isin');
            }
          } else {
            throw Exception('docInformes is null: $isin');
          }
        } else {
          throw Exception('hrefInfoPeriodica is null: $isin');
        }
      } else {
        throw Exception('document is null: $isin');
      }
    } catch (e) {
      Logger.log(
        dataLog: DataLog(
          msg: '$e',
          file: 'doc_cnmv.dart',
          clase: 'DocCnmv',
          funcion: 'getUrlInforme',
        ),
      );
    }
    return null;
  }

  Future<int> getRating() async {
    /*const String urlBase1 =
        'https://www.morningstar.es/es/screener/fund.aspx#?filtersSelectedValue=%7B%22term%22:%22';
    const String urlBase2 = '%22%7D&page=1&sortField=legalName&sortOrder=asc';
    String url = urlBase1 + isin + urlBase2;*/

    int? rating;
    const String baseUrl =
        'https://markets.ft.com/data/funds/tearsheet/ratings?s=';
    final String url = baseUrl + isin;

    try {
      Document? document = await _getDoc(url);
      if (document != null) {
        List<List<Element?>?>? elements = document
            .getElementsByTagName('span')
            .where((Element? element) =>
                element?.attributes['data-mod-stars-highlighted'] == 'true')
            .map((Element? item) => item?.getElementsByTagName('i'))
            .toList();
        if (elements.isNotEmpty) {
          rating = elements.first?.length;
          if (rating != null) {
            if (rating > 0 && rating < 6) {
              return rating;
            } else {
              throw Exception('rating < 0 || > 6');
            }
          } else {
            throw Exception('rating is null');
          }
        } else {
          throw Exception('elements is empty: return rating 0');
        }
      } else {
        throw Exception('document is null');
      }
    } catch (e) {
      Logger.log(
        dataLog: DataLog(
            msg: '$e: $isin',
            file: 'doc_cnmv.dart',
            clase: 'DocCnmv',
            funcion: 'getRating'),
      );
    }
    return 0;
  }
}
