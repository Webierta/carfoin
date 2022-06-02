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

  /* TABLA CARFOIN DE CARTERAS */
  Future<int> insertCartera(Cartera cartera) async {
    Database db = await database;
    return await db.insert(table, cartera.toDb());
  }

  Future<List<Cartera>> getCarteras({bool byOrder = false}) async {
    Database db = await database;
    final List<Map<String, dynamic>> query =
        byOrder ? await db.query(table, orderBy: '$columnNameCartera ASC') : await db.query(table);
    return query.map((e) => Cartera.fromMap(e)).toList();
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
}
