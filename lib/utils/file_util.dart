import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/logger.dart';
import '../services/database_helper.dart';

enum Status { ok, error, abortado }

class Resultado {
  Status status;
  String? msg;
  bool requiredRestart;
  Resultado(this.status, {this.msg, this.requiredRestart = true});
}

class FileUtil {
  static Future<Resultado> importar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      return Resultado(Status.abortado, requiredRestart: false);
    }

    DatabaseHelper database = DatabaseHelper();
    //final String dbPath = await database.getDatabasePath();
    //print(dbPath);

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'database.db');

    PlatformFile archivo = result.files.first;

    if (archivo.extension == 'db' &&
        archivo.path != null &&
        await database.isDatabase(archivo.path!)) {
      try {
        File file = File(archivo.path!);
        final dbAsBytes = await file.readAsBytes();
        //await deleteDatabase(path); // dbPath
        await database.eliminarDatabase();
        await File(path).writeAsBytes(dbAsBytes); // dbPath
        //return Resultado(Status.ok, requiredRestart: true);
        return Resultado(Status.ok);
      } catch (e, s) {
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch Read and Write File',
                file: 'file_util.dart',
                clase: 'FileUtil',
                funcion: 'importar',
                error: e,
                stackTrace: s));
        return Resultado(Status.error);
      }
    } else {
      return Resultado(
        Status.error,
        requiredRestart: false,
        msg: 'Archivo no reconocido',
      );
    }
  }

  static Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  static Future<Resultado> savePdf(String filename, List<int> pdfBytes) async {
    //String filePath = '';
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return Resultado(Status.abortado, msg: 'Destino no seleccionado');
    }
    //filePath = '$selectedDirectory/$filename';
    File file = File('$selectedDirectory/$filename');

    if (Platform.isLinux || await _requestPermission(Permission.storage)) {
      try {
        await file.writeAsBytes(pdfBytes);
        return Resultado(Status.ok, msg: file.path);
      } catch (e, s) {
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch Write Pdf',
                file: 'file_util.dart',
                clase: 'FileUtil',
                funcion: 'savePdf',
                error: e,
                stackTrace: s));
        return Resultado(Status.error, msg: e.toString());
      }
    } else {
      return Resultado(Status.abortado, msg: 'Permiso denegado');
    }
  }

  static Future<Resultado> exportar(String nombreDb) async {
    //DatabaseHelper database = DatabaseHelper();
    //final String dbPath = await database.getDatabasePath();
    //var dbFile = File(dbPath);

    /*
    LINUX: /home/jcv/code/carfoin 3_0_0/carfoin/.dart_tool/sqflite_common_ffi/databases/database.db
    ANDROID: /data/user/0/com.github.webierta.carfoin/databases/database.db
    */

    final documentsDirectory = await getApplicationDocumentsDirectory();

    //String docPath = documentsDirectory.path;
    //var directoryCarfoin = await Directory('$docPath/carfoin').create(recursive: true);
    //String carfoinPath = directoryCarfoin.path;

    final path = join(documentsDirectory.path, 'database.db');

    /*
    LINUX: /home/jcv/Documentos/database.db
    ANDROID: /data/user/0/com.github.webierta.carfoin/app_flutter/database.db
    */

    var dbFile = File(path);
    final dbAsBytes = await dbFile.readAsBytes();
    String filePath = '';

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return Resultado(Status.abortado, msg: 'Destino no seleccionado');
    }
    filePath = '$selectedDirectory/$nombreDb';
    File file = File(filePath);

    if (Platform.isLinux || await _requestPermission(Permission.storage)) {
      try {
        await file.writeAsBytes(dbAsBytes);
        return Resultado(Status.ok, msg: filePath);
      } catch (e, s) {
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch Write File',
                file: 'file_util.dart',
                clase: 'FileUtil',
                funcion: 'exportar',
                error: e,
                stackTrace: s));
        return Resultado(Status.error, msg: e.toString());
      }
    } else {
      return Resultado(Status.abortado, msg: 'Permiso denegado');
    }
  }
}
