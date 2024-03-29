import 'dart:convert' show utf8;
import 'dart:io';

import 'package:csv/csv.dart' show ListToCsvConverter, CsvToListConverter;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

import '../models/cartera.dart';
import '../models/logger.dart';

class ShareCsv {
  const ShareCsv();

  static List<List<dynamic>> _carteraToList(Cartera cartera) {
    List<List<dynamic>> rowsBd = <List<dynamic>>[];
    List<dynamic> rowCartera = [];
    rowCartera.add(cartera.name);
    rowsBd.add(rowCartera);
    if (cartera.fondos != null && cartera.fondos!.isNotEmpty) {
      for (var fondo in cartera.fondos!) {
        List<dynamic> rowFondo = [];
        rowFondo.add(fondo.isin);
        rowFondo.add(fondo.name);
        rowFondo.add(fondo.divisa);
        rowFondo.add(fondo.rating);
        rowsBd.add(rowFondo);
        if (fondo.valores != null && fondo.valores!.isNotEmpty) {
          for (var valor in fondo.valores!) {
            List<dynamic> rowValor = [];
            rowValor.add(valor.date);
            rowValor.add(valor.precio);
            rowValor.add(valor.tipo);
            rowValor.add(valor.participaciones);
            rowsBd.add(rowValor);
          }
        }
      }
    }
    return rowsBd;
  }

  static String _listToCsv(List<List<dynamic>> dataBd) {
    String csv = const ListToCsvConverter().convert(dataBd);
    return csv;
  }

  static Future<File?> _storageFile(String csv, String nameCartera) async {
    File? file;
    try {
      Directory? tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      var directoryCarfoin =
          await Directory('$tempPath/carfoin').create(recursive: true);
      String carfoinPath = directoryCarfoin.path;

      String nameFile = '${nameCartera.trim()}.cfi'; // csv
      String filePath = '$carfoinPath/$nameFile';
      file = File(filePath);
      await file.writeAsString(csv);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Storage File',
              file: 'share_csv.dart',
              clase: 'ShareCsv',
              funcion: '_storageFile',
              error: e,
              stackTrace: s));
    }
    return file;
  }

  static Future<File?> shareCartera(Cartera cartera) async {
    List<List<dynamic>> dataList = _carteraToList(cartera);
    if (dataList.isNotEmpty) {
      String csv = _listToCsv(dataList);
      var file = await _storageFile(csv, cartera.name);
      if (file != null && await file.exists()) {
        return file;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<File?> _selectFile() async {
    File? file;
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      PlatformFile archivo = result.files.first;
      if (archivo.extension == 'cfi' && archivo.path != null) {
        file = File(archivo.path!);
      }
    }
    return file;
  }

  static Future<List<List>> _csvToList(File file) async {
    final input = File(file.path).openRead();
    final List<List> fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();
    return fields;
  }

  static Cartera? _listToCartera(List<List<dynamic>> fields, int lastIndex) {
    Cartera cartera = Cartera(id: lastIndex + 1, name: fields[0].first);
    List<Fondo> fondos = [];
    try {
      List<int> indexRowFondos = [];
      for (int i = 1; i < fields.length; i++) {
        var row = fields[i];
        if (row[0].runtimeType == String) {
          indexRowFondos.add(i);
        }
      }
      for (int i = 0; i < indexRowFondos.length; i++) {
        int indexRowFondo = indexRowFondos[i];
        var isin = fields[indexRowFondo][0];
        var nameFondo = fields[indexRowFondo][1];
        var divisa = fields[indexRowFondo][2];
        var rating = fields[indexRowFondo][3]; // ?? 0
        List<Valor> valores = [];
        int dif = indexRowFondo == indexRowFondos.last
            ? fields.length - indexRowFondo
            : indexRowFondos[i + 1] - indexRowFondo;
        if (dif > 1) {
          for (int j = indexRowFondo + 1; j < indexRowFondo + dif; j++) {
            var rowValor = fields[j];
            var date = rowValor[0];
            var precio = rowValor[1];
            var tipo = rowValor[2];
            var participaciones = rowValor[3];
            var newValor = Valor(
                date: date,
                precio: precio,
                tipo: tipo,
                participaciones: participaciones);
            valores.add(newValor);
          }
        }
        Fondo fondo = Fondo(
            isin: isin,
            name: nameFondo,
            divisa: divisa,
            valores: valores,
            rating: rating);
        fondos.add(fondo);
      }
      cartera.fondos = [...fondos];
      return cartera;
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Load Cartera Shared',
              file: 'share_csv.dart',
              clase: 'ShareCsv',
              funcion: '_listToCartera',
              error: e,
              stackTrace: s));
      return null;
    }
  }

  static Future<Cartera?> loadCartera(int lastIndex) async {
    File? file = await _selectFile();
    if (file != null) {
      List<List> fields = await _csvToList(file);
      Cartera? dbCartera = _listToCartera(fields, lastIndex);
      if (dbCartera != null) {
        return dbCartera;
      }
    }
    return null;
  }

  static Future<bool> clearCache() async {
    try {
      var cacheDir = await getTemporaryDirectory();

      if (Platform.isLinux){
        String tempPath = cacheDir.path;
        cacheDir = Directory('$tempPath/carfoin');
      }

      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      return true;
    } catch (e) {
      Logger.log(dataLog: DataLog(msg: 'Catch clear cache'));
      return false;
    }
  }
}
