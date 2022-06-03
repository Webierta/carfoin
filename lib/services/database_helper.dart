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
    await db.insert(nameTable, valor.toDb());
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

  Future<void> updateValor(Cartera cartera, Fondo fondo, Valor valor) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.update(nameTable, valor.toDb(), where: '$columnDate = ?', whereArgs: [valor.date]);
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
    Valor newValor = Valor(date: op.date, precio: op.precio, tipo: null, participaciones: null);
    await updateValor(cartera, fondo, newValor);
  }

  Future<void> deleteAllOperaciones(Cartera cartera, Fondo fondo) async {
    Database db = await database;
    var nameTable = '_${cartera.id}${fondo.isin}';
    await db.delete(nameTable, where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
  }
}
