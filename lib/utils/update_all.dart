import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../services/database_helper.dart';
import '../services/doc_cnmv.dart';
import '../services/yahoo_finance.dart';
import 'fecha_util.dart';

class Update {
  final String nameCartera;
  final String nameFondo;
  final bool isUpdate;
  Update(
      {required this.nameCartera,
      required this.nameFondo,
      required this.isUpdate});
}

class UpdateAll {
  final BuildContext context;
  final Function setStateDialog;
  const UpdateAll({required this.context, required this.setStateDialog});

  Future<int> _updateRating(Fondo fondo) async {
    Future<int> updatingRating() async {
      var docCnmv = DocCnmv(isin: fondo.isin);
      return await docCnmv.getRating();
    }

    if (fondo.valores != null && fondo.valores!.isNotEmpty) {
      var lastEpoch = fondo.valores!.first.date;
      var lastDate = FechaUtil.epochToDate(lastEpoch);
      DateTime now = DateTime.now();
      int difDays = now.difference(lastDate).inDays;
      if (difDays > 30) {
        return await updatingRating();
      } else {
        return 0;
      }
    } else {
      return await updatingRating();
    }
  }

  Future<List<Update>> updateCarteras() async {
    //ApiService apiService = ApiService();
    DatabaseHelper database = DatabaseHelper();
    setStateDialog('Conectando...');
    List<Update> updates = [];
    final List<Cartera> carteras = context.read<CarteraProvider>().carteras;
    if (carteras.isNotEmpty) {
      for (var cartera in carteras) {
        List<Fondo>? fondos = cartera.fondos;
        if (fondos != null && fondos.isNotEmpty) {
          for (var fondo in fondos) {
            setStateDialog('${fondo.name}\n${cartera.name}');
            await database.createTableFondo(cartera, fondo);
            final newValores =
                await YahooFinance().getYahooFinanceResponse(fondo);
            if (newValores != null && newValores.isNotEmpty) {
              var newValor = newValores[0];
              int rating = await _updateRating(fondo);
              if (rating != 0) {
                fondo.rating = rating;
              }
              await database.updateFondo(cartera, fondo);
              await database.updateOperacion(cartera, fondo, newValor);
              updates.add(Update(
                  nameCartera: cartera.name,
                  nameFondo: fondo.name,
                  isUpdate: true));
            } else {
              updates.add(Update(
                  nameCartera: cartera.name,
                  nameFondo: fondo.name,
                  isUpdate: false));
            }
          }
        }
      }
    }
    return updates;
  }

  Future<List<Update>> updateFondos(Cartera cartera, List<Fondo> fondos) async {
    DatabaseHelper database = DatabaseHelper();
    setStateDialog('Conectando...');
    List<Update> updates = [];
    if (fondos.isNotEmpty) {
      for (var fondo in fondos) {
        setStateDialog(fondo.name);
        await database.createTableFondo(cartera, fondo);
        final newValores = await YahooFinance().getYahooFinanceResponse(fondo);
        if (newValores != null && newValores.isNotEmpty) {
          var newValor = newValores[0];
          int rating = await _updateRating(fondo);
          if (rating != 0) {
            fondo.rating = rating;
          }
          await database.updateFondo(cartera, fondo);
          await database.updateOperacion(cartera, fondo, newValor);
          updates.add(Update(
              nameCartera: cartera.name,
              nameFondo: fondo.name,
              isUpdate: true));
        } else {
          updates.add(Update(
              nameCartera: cartera.name,
              nameFondo: fondo.name,
              isUpdate: false));
        }
      }
    }
    return updates;
  }
}
