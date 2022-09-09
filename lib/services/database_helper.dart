import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    await database.close();
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
      $columnDivisa TEXT)
    ''');
  }

  dropTableCartera(Cartera cartera) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    //await db.delete(nameTable);
    //await db.rawUpdate("DELETE FROM $table");
    await db.execute("DROP TABLE IF EXISTS $nameTable");
  }

  Future<void> insertFondo(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}';
    await db.insert(nameTable, fondo.toDb());
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
    } catch (e) {
      print(e);
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
          } catch (e) {
            print(e);
            //continue;
          }
        }
      }
    }
    Database db = await database;
    var nameTable = '_${cartera.id}';
    try {
      await db.delete(nameTable);
    } catch (e) {
      print(e);
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
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteValorByDate(Cartera cartera, Fondo fondo, int date) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    try {
      await db.delete(nameTable, where: '$columnDate = ?', whereArgs: [date]);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteAllValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    try {
      await db.delete(nameTable);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteOnlyValores(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    //await db.delete(nameTable, where: '$columnTipoOperacion = ?', whereArgs: [-1]);
    try {
      await db.delete(nameTable,
          where: '$columnTipoOperacion IN (?)', whereArgs: [-1]);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteOperacion(Cartera cartera, Fondo fondo, Valor op) async {
    if (op.tipo == 1) {
      await deleteAllOperacionesPosteriores(cartera, fondo, op);
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
          where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
    } catch (e) {
      print(e);
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
}
