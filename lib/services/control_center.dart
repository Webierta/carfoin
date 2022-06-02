/****

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import 'sqlite.dart';

class ControlCenter {
  final BuildContext context;
  CarteraProvider carteraProvider;
  ControlCenter(this.context) : carteraProvider = context.read<CarteraProvider>();

  Future<bool> openDb() async {
    var db = Sqlite();
    return await db.openDb();
  }

  providerOnCartera(Cartera cartera) {
    carteraProvider.carteraOn = cartera;
  }

  providerOnFondo(Fondo fondo) {
    carteraProvider.fondoOn = fondo;
  }

  providerSetCarteras(List<Cartera> carteras) {
    carteraProvider.carteras = carteras;
  }

  providerAddFondo(Cartera cartera, Fondo fondo) {
    carteraProvider.addFondo(cartera, fondo);
  }

  providerAddFondos(Cartera cartera, List<Fondo> fondos) {
    carteraProvider.addFondos(cartera, fondos);
  }

  providerAddValores(Fondo fondo, List<Valor> valores) {
    carteraProvider.addValores(fondo, valores);
  }

  providerDeleteCartera(Cartera cartera) {
    carteraProvider.removeCartera(cartera);
  }

  providerDeleteFondo(Cartera cartera, Fondo fondo) async {
    carteraProvider.removeFondo(cartera, fondo);
  }

  providerDeleteAllCarteras() {
    carteraProvider.removeAllCarteras();
  }

  */ /*providerGetNFondos(Cartera cartera) {
    int nFondos = 0;
    var carteras = carteraProvider.carteras;
    for (var c in carteras) {
      if (c.name == cartera.name) {
        nFondos = c.fondos.length;
        break;
      }
    }
    return nFondos;
  }*/ /*

  updateCarteras(bool isCarterasByOrder, bool isFondosByOrder) async {
    var db = Sqlite();
    await db.openDb();
    await db.getCarteras(byOrder: isCarterasByOrder);
    providerSetCarteras(db.dbCarteras);
    for (var cartera in db.dbCarteras) {
      await updateFondos(cartera, isFondosByOrder);
    }
  }

  updateFondos(Cartera cartera, bool isFondosByOrder) async {
    var db = Sqlite();
    await db.openDb();
    var tableCartera = '_${cartera.id}';
    await db.createTableCartera(tableCartera);
    await db.getFondos(tableCartera, byOrder: isFondosByOrder);
    providerAddFondos(cartera, db.dbFondos);

    for (var fondo in db.dbFondos) {
      var tableFondo = '_${cartera.id}${fondo.isin}';
      await db.createTableFondo(tableFondo);
      await db.getValoresByOrder(tableFondo);
      providerAddValores(fondo, db.dbValoresByOrder);
    }
  }

  getDbNumberFondos(Cartera cartera) async {
    var db = Sqlite();
    await db.openDb();
    var tableCartera = '_${cartera.id}';
    await db.getNumberFondos(tableCartera);
    return db.dbNumFondos;
  }

  Future<int> insertDbCartera(String name) async {
    var db = Sqlite();
    await db.openDb();
    Map<String, dynamic> row = {'name': name};
    final int id = await db.insertCartera(row);
    //return id;
    var nameTable = '_$id';
    await db.createTableCartera(nameTable);
    return id;
  }

  createTableCartera(int id) async {
    var db = Sqlite();
    await db.openDb();
    var nameTable = '_$id';
    await db.createTableCartera(nameTable);
  }

  deleteDbCartera(Cartera cartera) async {
    var db = Sqlite();
    await db.openDb();
    var tableCartera = '_${cartera.id}';
    await db.getFondos(tableCartera);
    if (db.dbFondos.isNotEmpty) {
      for (var fondo in db.dbFondos) {
        var tableFondo = '_${cartera.id}${fondo.isin}';
        await db.eliminaTabla(tableFondo);
      }
    }
    await db.eliminaTabla(tableCartera);
    await db.deleteCartera(cartera);

    providerDeleteCartera(cartera);
  }

  deleteAllCarteras() async {
    var db = Sqlite();
    await db.openDb();
    await db.eliminarCarteras();
    providerDeleteAllCarteras();
  }

  insertFondo(Cartera cartera, Fondo fondo) async {
    var db = Sqlite();
    await db.openDb();
    var tableCartera = '_${cartera.id}';
    Map<String, dynamic> row = {'isin': fondo.isin, 'name': fondo.name, 'divisa': fondo.divisa};
    await db.insertFondo(tableCartera, row);
    providerAddFondo(cartera, fondo);
  }

  createTableFondo(Cartera cartera, Fondo fondo) async {
    var db = Sqlite();
    await db.openDb();
    var tableFondo = '_${cartera.id}${fondo.isin}';
    await db.createTableFondo(tableFondo);
  }

  updateFondoCartera(Cartera cartera, Fondo fondo) async {
    var db = Sqlite();
    await db.openDb();
    var tableCartera = '_${cartera.id}';
    Map<String, dynamic> row = {'isin': fondo.isin, 'name': fondo.name, 'divisa': fondo.divisa};
    await db.updateFondo(tableCartera, row);
    providerAddFondo(cartera, fondo);
  }

  deleteFondo(Cartera cartera, Fondo fondo) async {
    var db = Sqlite();
    await db.openDb();
    var tableFondo = '_${cartera.id}${fondo.isin}';
    await db.eliminaTabla(tableFondo);
    var tableCartera = '_${cartera.id}';
    await db.deleteFondo(tableCartera, fondo);
    providerDeleteFondo(cartera, fondo);
  }

  insertValor(Cartera cartera, Fondo fondo, Valor valor) async {
    var db = Sqlite();
    await db.openDb();
    var tableFondo = '_${cartera.id}${fondo.isin}';
    Map<String, dynamic> row = {'date': valor.date, 'precio': valor.precio};
    await db.insertValor(tableFondo, row);
    providerAddFondo(cartera, fondo);
  }
}

***/
