import 'dart:io';
import 'package:async/async.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/cartera.dart';

class Sqlite {
  // TABLA CARTERAS: CARFOIN
  static const _databaseName = 'database.db';
  static const _databaseVersion = 1;
  static const table = 'carfoin';
  static const columnId = 'id';
  static const columnNameCartera = 'name';
  // TABLA FONDOS: _CARTERA.ID
  static const columnIsin = 'isin';
  static const columnNameFondo = 'name';
  static const columnDivisa = 'divisa';
  // TABLA VALORES: _CARTERA.ID + FONDO.ISIN
  static const columnDate = 'date';
  static const columnPrecio = 'precio';
  static const columnTipoOperacion = 'tipo';
  static const columnParticipaciones = 'participaciones';

  final AsyncMemoizer _memoizer = AsyncMemoizer();

  late Database _db;
  List<Cartera> _dbCarteras = [];
  List<Fondo> _dbFondos = [];
  int _dbNumFondos = 0;
  List<Valor> _dbValoresByOrder = [];
  List<Valor> _dbOperacionesByOrder = [];

  List<Cartera> get dbCarteras => _dbCarteras;
  List<Fondo> get dbFondos => _dbFondos;
  int get dbNumFondos => _dbNumFondos;
  List<Valor> get dbValoresByOrder => _dbValoresByOrder;
  List<Valor> get dbOperacionesByOrder => _dbOperacionesByOrder;

  // TABLA CARTERAS
  Future<void> _initDb() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final dbPath = join(dbFolder, _databaseName);
    _db = await openDatabase(
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

  Future<bool> openDb() async {
    await _memoizer.runOnce(() async {
      await _initDb();
    });
    return true;
  }

  // TABLA FONDOS
  Future<void> createTableCartera(String nameTable) async {
    await openDb();
    await _db.execute('''
    CREATE TABLE IF NOT EXISTS $nameTable (
      $columnIsin TEXT PRIMARY KEY,
      $columnNameFondo TEXT NOT NULL,
      $columnDivisa TEXT)
    ''');
  }

  // TABLA VALORES
  Future<void> createTableFondo(String nameTable) async {
    await openDb();
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $nameTable (
        $columnDate INTEGER PRIMARY KEY,
        $columnPrecio REAL NOT NULL,
        $columnTipoOperacion INTEGER,
        $columnParticipaciones REAL)
      ''');
  }

  // TABLA CARTERAS
  Future<int> insertCartera(Map<String, dynamic> row) async {
    await openDb();
    return await _db.insert(table, row);
  }

  Future<void> getCarteras({bool byOrder = false}) async {
    await openDb();
    final List<Map<String, dynamic>> maps = byOrder
        ? await _db.query(table, orderBy: '$columnNameCartera ASC')
        : await _db.query(table);
    _dbCarteras = List.generate(maps.length, (i) {
      return Cartera(id: maps[i][columnId], name: maps[i][columnNameCartera]);
    });
  }

  Future<void> updateCartera(int id, Map<String, dynamic> row) async {
    await openDb();
    await _db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> deleteCartera(Cartera cartera) async {
    await openDb();
    await _db.delete(table, where: '$columnId = ?', whereArgs: [cartera.id]);
  }

  Future<void> eliminarCarteras() async {
    await openDb();
    await _db.rawUpdate("DELETE FROM $table");
  }

  /*Future<void> clearCarfoin() async {
    await openDb();
    await _db.delete(table);
  }*/

  // TABLA FONDOS
  Future<void> insertFondo(String tableFondos, Map<String, dynamic> row) async {
    await openDb();
    await _db.insert(tableFondos, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> getFondos(String tableFondos, {bool byOrder = false}) async {
    await openDb();
    final List<Map<String, dynamic>> maps = byOrder
        ? await _db.query(tableFondos, orderBy: '$columnNameFondo ASC')
        : await _db.query(tableFondos);
    _dbFondos = List.generate(
      maps.length,
      (i) => Fondo(
        isin: maps[i][columnIsin],
        name: maps[i][columnNameFondo],
        divisa: maps[i][columnDivisa],
      ),
    );
  }

  Future<void> getNumberFondos(String tableFondos) async {
    await openDb();
    final result = await _db.rawQuery('SELECT COUNT(*) FROM $tableFondos');
    _dbNumFondos = Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateFondo(String tableFondos, Map<String, dynamic> row) async {
    await openDb();
    String isin = row[columnIsin];
    await _db.update(tableFondos, row, where: '$columnIsin = ?', whereArgs: [isin]);
  }

  Future<void> deleteFondo(String tableFondos, Fondo fondo) async {
    await openDb();
    await _db.delete(tableFondos, where: '$columnIsin = ?', whereArgs: [fondo.isin]);
  }

  // TABLA VALORES
  Future<void> insertValor(String tableValores, Map<String, dynamic> row) async {
    await openDb();
    await _db.insert(tableValores, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> getValoresByOrder(String tableValores) async {
    await openDb();
    List<Map<String, dynamic>> maps = await _db.query(tableValores, orderBy: '$columnDate DESC');
    _dbValoresByOrder = List.generate(
      maps.length,
      (i) => Valor(date: maps[i][columnDate], precio: maps[i][columnPrecio]),
    );
  }

  Future<void> getOperacionesByOrder(String tableValores) async {
    await openDb();
    List<Map<String, dynamic>> maps = await _db.query(tableValores,
        orderBy: '$columnDate ASC', where: '$columnTipoOperacion IN (?, ?)', whereArgs: [1, 0]);
    _dbOperacionesByOrder = List.generate(
      maps.length,
      (i) => Valor(
        tipo: maps[i][columnTipoOperacion],
        date: maps[i][columnDate],
        participaciones: maps[i][columnParticipaciones],
        precio: maps[i][columnPrecio],
      ),
    );
  }

  Future<void> updateValor(String tableValores, Map<String, dynamic> row) async {
    await openDb();
    int date = row[columnDate];
    await _db.update(tableValores, row, where: '$columnDate = ?', whereArgs: [date]);
  }

  Future<void> deleteValor(String tableValores, int date) async {
    await openDb();
    await _db.delete(tableValores, where: '$columnDate = ?', whereArgs: [date]);
  }

  Future<void> eliminaTabla(String nameTable) async {
    await openDb();
    await _db.execute("DROP TABLE IF EXISTS $nameTable");
  }
}
