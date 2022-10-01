import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

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
    final String dbPath = await database.getDatabasePath();
    PlatformFile archivo = result.files.first;

    if (archivo.extension == 'db' &&
        archivo.path != null &&
        await database.isDatabase(archivo.path!)) {
      try {
        File file = File(archivo.path!);
        final dbAsBytes = await file.readAsBytes();
        await deleteDatabase(dbPath);
        await File(dbPath).writeAsBytes(dbAsBytes);
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

  static Future<Resultado> exportar(String nombreDb) async {
    DatabaseHelper database = DatabaseHelper();
    final String dbPath = await database.getDatabasePath();
    var dbFile = File(dbPath);
    final dbAsBytes = await dbFile.readAsBytes();
    String filePath = '';

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return Resultado(Status.abortado, msg: 'Destino no seleccionado');
    }
    filePath = '$selectedDirectory/$nombreDb';
    File file = File(filePath);

    var permiso = await Permission.storage.status;
    if (!permiso.isGranted) {
      permiso = await Permission.storage.request();
    }
    if (permiso.isGranted) {
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
