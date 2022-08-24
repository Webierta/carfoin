import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

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

    // TODO: ESTUDIAR POSIBILIDAD DE RECUPERAR BD ORIGINAL: EXPORTAR AUTO??
    //var dbFile = File(dbPath);
    //var dbBackup = await dbFile.readAsBytes();

    if (archivo.extension == 'db' &&
        archivo.path != null &&
        await database.isDatabase(archivo.path!)) {
      try {
        File file = File(archivo.path!);
        final dbAsBytes = await file.readAsBytes();
        //final dbDir = await getDatabasesPath();
        //final String dbPath = join(dbDir, 'database.db');
        await deleteDatabase(dbPath);
        //await database.deleteDatabase(dbPath);
        await File(dbPath).writeAsBytes(dbAsBytes);
        return Resultado(Status.ok);
      } catch (e) {
        print('EXCEPCION');
        print(e);
        // TODO: DIALOGO ERROR: RECUPERAR BD ??
        //await deleteDatabase(dbPath);
        //await database.deleteDatabase(dbPath);
        //await File(dbPath).writeAsBytes(dbBackup);
        // TODO: RECUPERAR BD AUTOGUARDADA ??
        //await deleteDatabase(dbPath);
        // AÑADIR msg: e ??
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

    /* Future<String> _getFilePath() async {
      Directory? directory = await getExternalStorageDirectory();
      //if (directory == null || directory.path.isEmpty || !await directory.exists()) return '';
      if (directory == null) return '';
      if ((!await directory.exists())) directory.create();
      String path = directory.path;
      String filePath = '$path/$nombreDb';
      return filePath;
    } */

    try {
      ///var storages = await ExternalPath.getExternalStorageDirectories();

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return Resultado(Status.abortado);

      filePath = '$selectedDirectory/$nombreDb';
      //filePath = await _getFilePath();
      if (filePath.isEmpty) throw Exception(); // o return okSave ??
      File file = File(filePath);

      var permiso = await Permission.storage.status;
      if (!permiso.isGranted) {
        permiso = await Permission.storage.request();
      }
      if (permiso.isGranted) {
        await file.writeAsBytes(dbAsBytes);
        return Resultado(Status.ok, msg: filePath);
      } else {
        throw Exception();
      }
    } catch (e) {
      //TODO: mensaje de error : msg: e ??
      print(e.toString());
      return Resultado(Status.error);
    }
  }
}
