import 'dart:convert' show utf8;
import 'dart:developer' show log;
import 'dart:io' show File, FileMode;

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/preferences_service.dart';
import '../utils/konstantes.dart';

class DataLog {
  String msg;
  String? file;
  String? clase;
  String? funcion;
  Object? error;
  StackTrace? stackTrace;

  DataLog(
      {required this.msg,
      this.file,
      this.clase,
      this.funcion,
      this.error,
      this.stackTrace});

  String getName() {
    var file = this.file ?? '-';
    var clase = this.clase ?? '-';
    var funcion = this.funcion ?? '-';
    return '$file/$clase/$funcion';
  }

  @override
  String toString() {
    String name = getName();
    String error = this.error != null ? this.error.toString() : '-';
    String stackTrace =
        this.stackTrace != null ? this.stackTrace.toString() : '-';
    return 'Log: $msg\n'
        '[$name]\n'
        'Error: $error\n'
        '$stackTrace\n';
  }
}

class Logger {
  const Logger();

  Future<bool> getStorage() async {
    return await PreferencesService.getBool(keyStorageLoggerPref);
  }

  Logger.log({required DataLog dataLog}) {
    String name = dataLog.getName();
    log(dataLog.msg, name: name, error: dataLog.error);
    getStorage().then((value) {
      if (value) _write(dataLog.toString());
    });
  }

  Future<String> get localPath async {
    var directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/logfile.txt');
  }

  Future<void> _write(String data) async {
    final file = await localFile;
    try {
      file.writeAsString('$data\n', mode: FileMode.append);
    } catch (e) {
      log('Catch write file: ${file.path}');
    }
  }

  Future<bool> copy() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isGranted) {
      final file = await localFile;
      try {
        if (await file.exists()) {
          file.copy('/storage/emulated/0/Download/logfile.txt');
          return true;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<String> read() async {
    final file = await localFile;
    try {
      if (await file.exists()) {
        return await file.readAsString(encoding: utf8);
      } else {
        return 'No se ha registrado ningún error';
      }
    } catch (e) {
      log('Catch read file: ${file.path}');
      return 'No se ha podido acceder al archivo logfile.txt';
    }
  }

  Future<bool> clear() async {
    final file = await localFile;
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      } else {
        throw Exception();
      }
    } catch (e) {
      log('Catch delete file: ${file.path}');
      return false;
    }
  }
}
