import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/cartera.dart';
import '../models/logger.dart';
import '../router/app_router.dart';
import '../router/routes_const.dart';

class DatabaseHelper {
  // DATABASE
  static const _databaseName = 'database.db';
  static const _databaseVersion = 3;
  // TABLA CARFOIN DE CARTERAS
  static const table = 'carfoin';
  static const columnId = 'id';
  static const columnNameCartera = 'name';
  // TABLA _CARTERA.ID DE FONDOS
  static const columnIsin = 'isin';
  static const columnNameFondo = 'name';
  static const columnDivisa = 'divisa';
  static const columnRating = 'rating';
  static const columnTicker = 'ticker';
  // TABLA _CARTERA.ID + FONDO.ISIN DE VALORES
  static const columnDate = 'date';
  static const columnPrecio = 'precio';
  static const columnTipoOperacion = 'tipo';
  static const columnParticipaciones = 'participaciones';

  Future<Database>? _database;

  bool onUpgradeFrom2To3 = false;

  get database async {
    _database ??= _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    /* final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final String dbPath = join(dbFolder, _databaseName); */

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY NOT NULL,
          $columnNameCartera TEXT NOT NULL)
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < newVersion) {
          if (oldVersion == 2) {
            onUpgradeFrom2To3 = true;
          } else {
            Logger.log(
                dataLog: DataLog(
                    msg: 'Check Version Database',
                    file: 'database_helper.dart',
                    clase: 'DatabaseHelper',
                    funcion: '_initDb'));
            db.close();
            //final String dbPath = await getDatabasePath();
            //await deleteDatabase(dbPath);
            final context = navigatorKey.currentContext;
            if (context != null) {
              context.go(errorPage);
            }
          }
        }
      },
    );
  }

  /* getDatabaseFolder() async {
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
  } */

  eliminarDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      //await deleteDatabase(path);
      await deleteDatabase(path);
      // TODO: eliminar archivo ??
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Database',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteDatabase',
              error: e,
              stackTrace: s));
    }
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

  /*Future<bool> tableExists(String table) async {
    Database db = await database;
    int? count = firstIntValue(await db.query('sqlite_master',
        columns: ['COUNT(*)'],
        where: 'type = ? AND name = ?',
        whereArgs: ['table', table]));
    if (count != null) return count > 0;
    return false;
  }*/

  Future<List<String>> getNamesTables() async {
    Database db = await database;
    var namesTables = (await db
            .query('sqlite_master', where: 'type = ?', whereArgs: ['table']))
        .map((row) => row['name'] as String)
        .toList(growable: false);
    /*if (namesTables.isNotEmpty) {
      for (var name in namesTables) {
        print('TABLA: $name');
      }
    }*/
    return namesTables;
  }

  close() async {
    Database db = await database;
    await db.close();
  }

  dropTable(String nameTable) async {
    Database db = await database;
    await db.execute("DROP TABLE IF EXISTS $nameTable");
  }

  dropAllTables() async {
    List<String> namesTables = await getNamesTables();
    if (namesTables.isNotEmpty) {
      for (var name in namesTables) {
        if (name != table) {
          await dropTable(name);
        }
      }
    }
  }

  // TODO: comprobar si se ejecuta desde aquí sin error
  /*deleteDatabase(String dbPath) async {
    await deleteDatabase(dbPath);
    //await db.close();
    //await deleteDatabase(await getDatabasePath());
  }*/

  /* TABLA CARFOIN DE CARTERAS */
  Future<int> insertCartera(Cartera cartera) async {
    Database db = await database;
    return await db.insert(table, cartera.toDb());
  }

  Future<List<Cartera>> getCarteras({bool byOrder = false}) async {
    Database db = await database;
    final List<Map<String, dynamic>> query = byOrder
        ? await db.query(table, orderBy: '$columnNameCartera ASC')
        : await db.query(table);
    return query.map((e) => Cartera.fromMap(e)).toList();
  }

  Future<int> getLastId({bool byOrder = true}) async {
    Database db = await database;
    final List<Map<String, dynamic>> query = byOrder
        ? await db.query(table, orderBy: '$columnId ASC')
        : await db.query(table);
    return query.map((e) => Cartera.fromMap(e)).toList().last.id ?? 0;
  }

  Future<int> updateCartera(Cartera cartera) async {
    Database db = await database;
    return await db.update(table, cartera.toDb(),
        where: '$columnId = ?', whereArgs: [cartera.id]);
  }

  Future<int> deleteCartera(Cartera cartera) async {
    Database db = await database;
    return await db
        .delete(table, where: '$columnId = ?', whereArgs: [cartera.id]);
    //return await db.rawDelete('DELETE FROM $table WHERE $columnId = ?', [cartera.id]);
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
      $columnDivisa TEXT,
      $columnRating INTEGER,
      $columnTicker TEXT)
    ''');
    if (onUpgradeFrom2To3 == true) {
      await db.execute("ALTER TABLE $nameTable ADD $columnTicker TEXT");
    }
  }

  dropTableCartera(Cartera cartera) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    //await db.delete(nameTable);
    //await db.rawUpdate("DELETE FROM $table");
    await db.execute("DROP TABLE IF EXISTS $nameTable");
  }

  Future<bool> insertFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    try {
      await db.insert(nameTable, fondo.toDb());
      return true;
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch insert fondo',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'insertFondo',
              error: e,
              stackTrace: s));
      return false;
    }
    //await db.insert(nameTable, fondo.toDb(),
    //    conflictAlgorithm: ConflictAlgorithm.replace);
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

    await db.update(nameTable, fondo.toDb(),
        where: '$columnIsin = ?', whereArgs: [fondo.isin]);
  }

  Future<void> deleteFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    // ELIMINA TODOS SUS VALORES
    await deleteAllValores(cartera, fondo);
    var nameTable = '_${cartera.id}';
    try {
      await db
          .delete(nameTable, where: '$columnIsin = ?', whereArgs: [fondo.isin]);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Table Fondo',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteFondo',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteAllFondos(Cartera cartera) async {
    if (cartera.fondos != null && cartera.fondos!.isNotEmpty) {
      /*for (var fondo in cartera.fondos!) {
        await deleteFondo(cartera, fondo);
      }*/
      /*List<Fondo>.from(cartera.fondos!).forEach((fondo) async {
        if (cartera.fondos!.contains(fondo)) {
          await deleteFondo(cartera, fondo);
        }
      });*/
      for (var fondo in List<Fondo>.from(cartera.fondos!)) {
        if (cartera.fondos!.contains(fondo)) {
          try {
            await deleteFondo(cartera, fondo);
          } catch (e, s) {
            // continue;
            Logger.log(
                dataLog: DataLog(
                    msg: 'Catch Delete Fondo',
                    file: 'database_helper.dart',
                    clase: 'DatabaseHelper',
                    funcion: 'deleteAllFondos',
                    error: e,
                    stackTrace: s));
            //continue;
          }
        }
      }
    }
    Database db = await database;
    var nameTable = '_${cartera.id}';
    try {
      await db.delete(nameTable);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Table Cartera',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteAllFondos',
              error: e,
              stackTrace: s));
    }
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

  dropTableFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    //await db.delete(nameTable);
    //await db.rawUpdate("DELETE FROM $table");
    await db.execute("DROP TABLE IF EXISTS $nameTable");
  }

  dropAllTablesFondos(Cartera cartera) async {
    if (cartera.fondos != null && cartera.fondos!.isNotEmpty) {
      for (var fondo in List<Fondo>.from(cartera.fondos!)) {
        if (cartera.fondos!.contains(fondo)) {
          await dropTableFondo(cartera, fondo);
        }
      }
    }
  }

  Future<void> insertValor(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';

    await db.insert(nameTable, valor.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Valor>> getValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    final List<Map<String, dynamic>> query =
        await db.query(nameTable, orderBy: '$columnDate DESC');
    return query.map((e) => Valor.fromMap(e)).toList();
  }

  Future<List<Valor>> getOperaciones(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    final List<Map<String, dynamic>> query = await db.query(nameTable,
        orderBy: '$columnDate ASC',
        where: '$columnTipoOperacion IN (?, ?)',
        whereArgs: [1, 0]);
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

    await db.update(nameTable, valor.toDb(),
        where: '$columnDate = ?', whereArgs: [valor.date]);
  }

  Future<Valor?> getValorByDate(
      Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    var query = await db
        .query(nameTable, where: '$columnDate = ?', whereArgs: [valor.date]);
    var value = query.map((e) => Valor.fromMap(e)).toList();
    if (value.isNotEmpty) {
      return value.first;
    } else {
      return null;
    }
  }

  Future<void> updateOperacion(
      Cartera cartera, Fondo fondo, Valor valor) async {
    //Database db = await database;
    //var nameTable = '_${cartera.id}${fondo.isin}';
    Valor? existeValor = await getValorByDate(cartera, fondo, valor);
    if (existeValor == null) {
      //await db.update(nameTable, valor.toDb(), where: '$columnDate = ?', whereArgs: [valor.date]);
      await insertValor(cartera, fondo, valor);
    } else {
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
    try {
      await db
          .delete(nameTable, where: '$columnDate = ?', whereArgs: [valor.date]);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Valor',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteValor',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteValorByDate(Cartera cartera, Fondo fondo, int date) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    try {
      await db.delete(nameTable, where: '$columnDate = ?', whereArgs: [date]);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Valor',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteValorByDate',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteAllValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    try {
      await db.delete(nameTable);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete All Valores',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteAllValores',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteOnlyValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    //await db.delete(nameTable, where: '$columnTipoOperacion = ?', whereArgs: [-1]);
    try {
      await db.delete(nameTable,
          where: '$columnTipoOperacion IN (?)', whereArgs: [-1]);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete Valor where operación -1',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteOnlyValores',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteOperacion(Cartera cartera, Fondo fondo, Valor op) async {
    if (op.tipo == 1) {
      //await deleteAllOperacionesPosteriores(cartera, fondo, op);
      await deleteAllReembolsosPosteriores(cartera, fondo, op);
    }
    Valor newValor = Valor(
        date: op.date, precio: op.precio, tipo: null, participaciones: null);
    await updateValor(cartera, fondo, newValor);
  }

  Future<void> deleteAllOperaciones(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    try {
      await db.delete(nameTable,
          where: '$columnTipoOperacion IN (?, ?)', whereArgs: [0, 1]);
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Delete All Operaciones',
              file: 'database_helper.dart',
              clase: 'DatabaseHelper',
              funcion: 'deleteAllOperaciones',
              error: e,
              stackTrace: s));
    }
  }

  Future<void> deleteAllOperacionesPosteriores(
      Cartera cartera, Fondo fondo, Valor op) async {
    List<Valor> operaciones = await getOperaciones(cartera, fondo);
    if (operaciones.isNotEmpty) {
      for (var ope in operaciones) {
        if (ope.date > op.date) {
          Valor newValor = Valor(
              date: ope.date,
              precio: ope.precio,
              tipo: null,
              participaciones: null);
          await updateValor(cartera, fondo, newValor);
        }
      }
    }
  }

  Future<void> deleteAllReembolsosPosteriores(
      Cartera cartera, Fondo fondo, Valor op) async {
    List<Valor> operaciones = await getOperaciones(cartera, fondo);
    if (operaciones.isNotEmpty) {
      for (var ope in operaciones) {
        if (ope.date > op.date && ope.tipo == 0) {
          Valor newValor = Valor(
              date: ope.date,
              precio: ope.precio,
              tipo: null,
              participaciones: null);
          await updateValor(cartera, fondo, newValor);
        }
      }
    }
  }
}
