import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/cartera.dart';

class DatabaseHelper {
  // DATABASE
  static const _databaseName = 'database.db';
  static const _databaseVersion = 1;
  // TABLA CARFOIN DE CARTERAS
  static const table = 'carfoin';
  static const columnId = 'id';
  static const columnNameCartera = 'name';
  // TABLA _CARTERA.ID DE FONDOS
  static const columnIsin = 'isin';
  static const columnNameFondo = 'name';
  static const columnDivisa = 'divisa';
  // TABLA _CARTERA.ID + FONDO.ISIN DE VALORES
  static const columnDate = 'date';
  static const columnPrecio = 'precio';
  static const columnTipoOperacion = 'tipo';
  static const columnParticipaciones = 'participaciones';

  // TODO: CAPTURA DE EXCEPCIONES EN TODAS LAS LLAMADAS A DB
  // SI EXCEPCIÓN (archivo corrupto): ELIMINAR BD Y REINICIAR

  Future<Database>? _database;

  get database async {
    _database ??= _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final String dbPath = join(dbFolder, _databaseName);
    //final String dbPath = await getDatabasePath();
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY NOT NULL,
          $columnNameCartera TEXT NOT NULL)
        ''');
      },
    );
  }

  getDatabaseFolder() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    return dbFolder;
  }

  Future<String> getDatabasePath() async {
    final dbFolder = await getDatabasesPath();
    final String dbPath = join(dbFolder, _databaseName);
    return dbPath;
  }

  Future<bool> isDatabase(String path) async {
    Database? db;
    bool isDatabase = false;
    try {
      db = await openReadOnlyDatabase(path);
      int version = await db.getVersion();
      if (version == _databaseVersion) {
        isDatabase = true;
      }
    } catch (_) {
      isDatabase = false;
    } finally {
      await db?.close();
    }
    return isDatabase;
  }

  // TODO: comprobar si se ejecuta desde aquí sin error
  /*deleteDatabase(String dbPath) async {
    await deleteDatabase(dbPath);
  }*/

  /* handleError() async {
    print('HANDLE ERROR');
    var pixelRatio = window.devicePixelRatio;
    var logicalScreenSize = window.physicalSize / pixelRatio;
    var logicalHeight = logicalScreenSize.height;
    var paddingTop = window.padding.top / window.devicePixelRatio;
    var paddingBottom = window.padding.bottom / window.devicePixelRatio;
    var safeHeight = logicalHeight - paddingTop - paddingBottom;
    var screenHeightPixels = window.physicalSize.longestSide;
    SnackBar snackBar = SnackBar(
      action: SnackBarAction(
        label: 'Cerrar',
        onPressed: () async {
          //Database db = await database;
          //await database.close();
          await deleteDatabase(await getDatabasePath());
          Restart.restartApp();
        },
      ),
      content: const SizedBox(
        height: 300,
        child: Text(
            'Archivo corrupto. La base de datos será eliminada y la aplicación se reiniciará.'),
      ),
      //duration: Duration(seconds: double.infinity),
      duration: const Duration(days: 365),
    );
    //snackbarKey.currentState?.showSnackBar(snackBar);
    snackbarKey.currentState?.showMaterialBanner(MaterialBanner(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      forceActionsBelow: true,
      //overflowAlignment: OverflowBarAlignment.center,
      content: SingleChildScrollView(
        child: ListBody(
          children: const [
            Text('Archivo corrupto.'),
            Text('La base de datos será eliminada y la aplicación se reiniciará.'),
          ],
        ),
      ),
      //leading: const Icon(Icons.bug_report),
      contentTextStyle: const TextStyle(
        fontSize: 18,
        color: Colors.red,
        fontStyle: FontStyle.italic,
      ),
      actions: [
        TextButton(
          onPressed: () async {
            snackbarKey.currentState?.clearMaterialBanners();
            //Database db = await database;
            //await database.close();
            await deleteDatabase(await getDatabasePath());
            Restart.restartApp();
          },
          child: const Text('CERRAR'),
        ),
      ],
    ));
    /* Database db = await database;
    await db.close();
    await deleteDatabase(await getDatabasePath()); */
  } */

  /* TABLA CARFOIN DE CARTERAS */
  Future<int> insertCartera(Cartera cartera) async {
    Database db = await database;
    return await db.insert(table, cartera.toDb());

    /* try {
      //throw Exception();
      Database db = await database;
      return await db.insert(table, cartera.toDb());
    } catch (e) {
      handleError();
      return 0;
    } */
  }

  Future<List<Cartera>> getCarteras({bool byOrder = false}) async {
    Database db = await database;
    final List<Map<String, dynamic>> query =
        byOrder ? await db.query(table, orderBy: '$columnNameCartera ASC') : await db.query(table);
    return query.map((e) => Cartera.fromMap(e)).toList();

    /* try {
      Database db = await database;
      final List<Map<String, dynamic>> query = byOrder
          ? await db.query(table, orderBy: '$columnNameCartera ASC')
          : await db.query(table);
      return query.map((e) => Cartera.fromMap(e)).toList();
    } catch (e) {
      handleError();
      return [];
    } */
  }

  Future<int> updateCartera(Cartera cartera) async {
    Database db = await database;
    return await db.update(table, cartera.toDb(), where: '$columnId = ?', whereArgs: [cartera.id]);
  }

  Future<int> deleteCartera(Cartera cartera) async {
    Database db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [cartera.id]);
  }

  Future<int> deleteAllCarteras() async {
    Database db = await database;
    return await db.delete(table);
  }

  Future<void> eliminarCarteras() async {
    Database db = await database;
    await db.rawUpdate("DELETE FROM $table");
  }

  /* TABLA _CARTERA.ID DE FONDOS */
  Future<void> createTableCartera(Cartera cartera) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $nameTable (
      $columnIsin TEXT PRIMARY KEY,
      $columnNameCartera TEXT NOT NULL,
      $columnDivisa TEXT)
    ''');
  }

  Future<void> insertFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.insert(nameTable, fondo.toDb());
  }

  Future<List<Fondo>> getFondos(Cartera cartera, {bool byOrder = false}) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    final List<Map<String, dynamic>> query = byOrder
        ? await db.query(nameTable, orderBy: '$columnNameFondo ASC')
        : await db.query(nameTable);
    return query.map((e) => Fondo.fromMap(e)).toList();
  }

  Future<void> updateFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.update(nameTable, fondo.toDb(), where: '$columnIsin = ?', whereArgs: [fondo.isin]);
  }

  Future<void> deleteFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.delete(nameTable, where: '$columnIsin = ?', whereArgs: [fondo.isin]);
  }

  Future<void> deleteAllFondos(Cartera cartera) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.delete(nameTable);
  }

  /* TABLA _CARTERA.ID DE FONDOS */

  Future<void> createTableFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $nameTable (
        $columnDate INTEGER PRIMARY KEY,
        $columnPrecio REAL NOT NULL,
        $columnTipoOperacion INTEGER,
        $columnParticipaciones REAL)
      ''');
  }

  Future<void> insertValor(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.insert(nameTable, valor.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Valor>> getValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    final List<Map<String, dynamic>> query = await db.query(nameTable, orderBy: '$columnDate DESC');
    return query.map((e) => Valor.fromMap(e)).toList();
  }

  Future<List<Valor>> getOperaciones(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    final List<Map<String, dynamic>> query = await db.query(nameTable,
        orderBy: '$columnDate ASC', where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
    return query.map((e) => Valor.fromMap(e)).toList();
  }

  /*Future<List<Valor>> getOperacionesPosteriores(Cartera cartera, Fondo fondo, Valor op) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    final List<Map<String, dynamic>> query = await db.query(nameTable,
        orderBy: '$columnDate ASC', where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
    return query.map((e) => Valor.fromMap(e)).toList();
  }*/

  Future<void> updateValor(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.update(nameTable, valor.toDb(), where: '$columnDate = ?', whereArgs: [valor.date]);
  }

  Future<Valor?> getValorByDate(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    var query = await db.query(nameTable, where: '$columnDate = ?', whereArgs: [valor.date]);
    var value = query.map((e) => Valor.fromMap(e)).toList();
    if (value.isNotEmpty) {
      return value.first;
    } else {
      return null;
    }
  }

  Future<void> updateOperacion(Cartera cartera, Fondo fondo, Valor valor) async {
    //Database db = await database;
    //var nameTable = '_${cartera.id}${fondo.isin}';
    Valor? existeValor = await getValorByDate(cartera, fondo, valor);
    if (existeValor == null) {
      //await db.update(nameTable, valor.toDb(), where: '$columnDate = ?', whereArgs: [valor.date]);
      print('NO EXISTE');
      await insertValor(cartera, fondo, valor);
    } else {
      print('EXISTE');
      var upValor = Valor(
          date: valor.date,
          precio: valor.precio,
          participaciones: existeValor.participaciones,
          tipo: existeValor.tipo);
      //await db.update(nameTable, updateValor.toDb(), where: '$columnDate = ?', whereArgs: [valor.date]);
      await updateValor(cartera, fondo, upValor);
    }
  }

  Future<void> deleteValor(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.delete(nameTable, where: '$columnDate = ?', whereArgs: [valor.date]);
  }

  Future<void> deleteValorByDate(Cartera cartera, Fondo fondo, int date) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.delete(nameTable, where: '$columnDate = ?', whereArgs: [date]);
  }

  Future<void> deleteAllValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.delete(nameTable);
  }

  Future<void> deleteOperacion(Cartera cartera, Fondo fondo, Valor op) async {
    if (op.tipo == 1) {
      await deleteAllOperacionesPosteriores(cartera, fondo, op);
    }
    Valor newValor = Valor(date: op.date, precio: op.precio, tipo: null, participaciones: null);
    await updateValor(cartera, fondo, newValor);
  }

  Future<void> deleteAllOperaciones(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.delete(nameTable, where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
  }

  Future<void> deleteAllOperacionesPosteriores(Cartera cartera, Fondo fondo, Valor op) async {
    List<Valor> operaciones = await getOperaciones(cartera, fondo);
    if (operaciones.isNotEmpty) {
      for (var ope in operaciones) {
        if (ope.date > op.date) {
          Valor newValor =
              Valor(date: ope.date, precio: ope.precio, tipo: null, participaciones: null);
          await updateValor(cartera, fondo, newValor);
        }
      }
    }
  }
}
