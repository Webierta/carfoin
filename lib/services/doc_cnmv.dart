import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../models/logger.dart';

//const String url = 'https://www.cnmv.es/Portal/Consultas/IIC/Fondo.aspx?isin=ES0127215004';
//const String urlPdf = 'https://www.cnmv.es/Portal/verDoc.axd?t={974b9b47-2e77-464f-a19a-9f597b239912}';

class Informe {
  final String name;
  final String url;
  const Informe({required this.name, required this.url});
}

class DocCnmv {
  final String isin;
  const DocCnmv({required this.isin});

  Future<Document?> _getDoc(String url) async {
    http.Response response;
    try {
      response = await http.Client().get(Uri.parse(url));
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch response CNMV',
              file: 'doc_cnmv.dart',
              clase: 'DocCnmv',
              funcion: '_getDoc',
              error: e,
              stackTrace: s));
      return null;
    }
    if (response.statusCode == 200) {
      return parse(response.body);
    } else {
      Logger.log(
          dataLog: DataLog(
              msg: 'Response status code != 200',
              file: 'doc_cnmv.dart',
              clase: 'DocCnmv',
              funcion: '_getDoc'));
      return null;
    }
  }

  Future<String?> getUrlFolleto() async {
    const String urlBase =
        'https://www.cnmv.es/Portal/Consultas/IIC/Fondo.aspx?isin=';
    const String urlPdfBase = 'https://www.cnmv.es/Portal/';
    var url = urlBase + isin;
    Document? document = await _getDoc(url);
    if (document != null) {
      List<Element?>? selectElements = document
          .getElementById('id_tabladatos')
          ?.getElementsByTagName('td')
          .where((element) => element.attributes['data-th'] == 'Folleto')
          .map((item) => item.querySelector('a'))
          .toList();
      String? href;
      if (selectElements != null && selectElements.isNotEmpty) {
        href = selectElements.first?.attributes['href'];
      }
      if (href != null) {
        const startWord = "../../";
        final startIndex = href.indexOf(startWord);
        String urlPdf =
            urlPdfBase + href.substring(startIndex + startWord.length);
        return urlPdf;
      } else {
        Logger.log(
            dataLog: DataLog(
                msg: 'href is null',
                file: 'doc_cnmv.dart',
                clase: 'DocCnmv',
                funcion: 'getUrlFolleto'));
        return null;
      }
    } else {
      Logger.log(
          dataLog: DataLog(
              msg: 'document is null',
              file: 'doc_cnmv.dart',
              clase: 'DocCnmv',
              funcion: 'getUrlFolleto'));

      return null;
    }
  }

  Future<Informe?> getUrlInforme() async {
    const String urlBase =
        'https://www.cnmv.es/Portal/Consultas/IIC/Fondo.aspx?isin=';
    const String urlInfomesBase = 'https://www.cnmv.es/Portal/Consultas/IIC/';
    var url = urlBase + isin;
    Document? document = await _getDoc(url);
    if (document != null) {
      Element? infoPeriodica =
          document.getElementById('ctl00_ContentPrincipal_wNavegacion_hlIPP');
      String? hrefInfoPeriodica = infoPeriodica?.attributes['href'];
      if (hrefInfoPeriodica != null) {
        var urlInformes = urlInfomesBase + hrefInfoPeriodica;
        Document? docInformes = await _getDoc(urlInformes);
        if (docInformes != null) {
          List<Element?>? selectElements = docInformes
              .getElementById('tablaDatos')
              ?.getElementsByTagName('td')
              .where((element) => element.attributes['data-th'] == 'Documentos')
              .map((item) => item.querySelector('a'))
              .toList();
          List<Element>? ejercicioElements = docInformes
              .getElementById('tablaDatos')
              ?.getElementsByTagName('td')
              .where((element) => element.attributes['data-th'] == 'Ejercicio')
              .toList();
          List<Element>? periodoElements = docInformes
              .getElementById('tablaDatos')
              ?.getElementsByTagName('td')
              .where((element) => element.attributes['data-th'] == 'Periodo')
              .toList();
          String? ejercicio;
          String? periodo;
          if (ejercicioElements != null && ejercicioElements.isNotEmpty) {
            ejercicio = ejercicioElements.first.text;
          }
          if (periodoElements != null && periodoElements.isNotEmpty) {
            periodo = periodoElements.first.text.trim();
            periodo = periodo[periodo.length - 1];
            periodo = 'S$periodo';
          }
          String? href;
          if (selectElements != null && selectElements.isNotEmpty) {
            href = selectElements.first?.attributes['href'];
          }
          if (href != null && ejercicio != null && periodo != null) {
            var informeTime = '${ejercicio}_$periodo';
            const startWord = "../../";
            final startIndex = href.indexOf(startWord);
            String urlPdf =
                urlInfomesBase + href.substring(startIndex + startWord.length);
            return Informe(name: informeTime, url: urlPdf);
          } else {
            Logger.log(
                dataLog: DataLog(
                    msg: 'href or ejercicio or periodo == null',
                    file: 'doc_cnmv.dart',
                    clase: 'DocCnmv',
                    funcion: 'getUrlInforme'));
            return null;
          }
        } else {
          Logger.log(
              dataLog: DataLog(
                  msg: 'docInformes is null',
                  file: 'doc_cnmv.dart',
                  clase: 'DocCnmv',
                  funcion: 'getUrlInforme'));
          return null;
        }
      } else {
        Logger.log(
            dataLog: DataLog(
                msg: 'hrefInfoPeriodica is null',
                file: 'doc_cnmv.dart',
                clase: 'DocCnmv',
                funcion: 'getUrlInforme'));
        return null;
      }
    } else {
      Logger.log(
          dataLog: DataLog(
              msg: 'document is null',
              file: 'doc_cnmv.dart',
              clase: 'DocCnmv',
              funcion: 'getUrlInforme'));
      return null;
    }
  }

  Future<int> getRating() async {
    /*const String urlBase1 =
        'https://www.morningstar.es/es/screener/fund.aspx#?filtersSelectedValue=%7B%22term%22:%22';
    const String urlBase2 = '%22%7D&page=1&sortField=legalName&sortOrder=asc';
    String url = urlBase1 + isin + urlBase2;*/

    const String baseUrl =
        'https://markets.ft.com/data/funds/tearsheet/ratings?s=';
    String url = baseUrl + isin;

    Document? document = await _getDoc(url);
    if (document != null) {
      /*List<Element?> div = document
          //.getElementsByTagName('div')
          .getElementsByClassName('ec-table__ratingstar ng-scope')
          .where((element) =>
              element.attributes['data-ng-if'] == 'obj.starRatingM255')
          .toList();*/

      List<List<Element?>?>? elements = document
          .getElementsByTagName('span')
          .where((Element? element) =>
              element?.attributes['data-mod-stars-highlighted'] == 'true')
          .map((Element? item) => item?.getElementsByTagName('i'))
          .toList();
      if (elements.isNotEmpty) {
        int? i = elements.first?.length;
        if (i != null) {
          if (i > 0 && i < 6) {
            return i;
          }
        }
        return 0;
      } else {
        Logger.log(
            dataLog: DataLog(
                msg: 'elements is empty: return rating 0',
                file: 'doc_cnmv.dart',
                clase: 'DocCnmv',
                funcion: 'getRating'));
        return 0;
      }
    } else {
      Logger.log(
          dataLog: DataLog(
              msg: 'document is null',
              file: 'doc_cnmv.dart',
              clase: 'DocCnmv',
              funcion: 'getRating'));
      return 0;
    }
  }
}
