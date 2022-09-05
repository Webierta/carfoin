import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../utils/stats.dart';
import '../utils/styles.dart';
import '../widgets/my_drawer.dart';
import '../widgets/subglobal/listtile_capital.dart';
import '../widgets/subglobal/listtile_destacado.dart';
import '../widgets/subglobal/listtile_lastop.dart';
import '../widgets/subglobal/models.dart';
import '../widgets/subglobal/pie_chart_global.dart';

class PageGlobal extends StatelessWidget {
  const PageGlobal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CarteraProvider carteraProvider = context.read<CarteraProvider>();
    final List<Cartera> carteras = carteraProvider.carteras;
    int nFondos = 0;
    List<Destacado> destacados = [];
    List<LastOp> lastOps = [];

    double inversionGlobalEur = 0.0;
    double inversionGlobalUsd = 0.0;
    double inversionGlobalOtra = 0.0;
    double valorGlobalEur = 0.0;
    double valorGlobalUsd = 0.0;
    double valorGlobalOtra = 0.0;
    double balanceGlobalEur = 0.0;
    double balanceGlobalUsd = 0.0;
    double balanceGlobalOtra = 0.0;

    calcularGlobal() {
      for (var cartera in carteras) {
        List<Fondo> fondos = cartera.fondos ?? [];
        nFondos += fondos.length;
        if (fondos.isNotEmpty) {
          for (var fondo in fondos) {
            if (fondo.valores != null && fondo.valores!.isNotEmpty) {
              Stats stats = Stats(fondo.valores!);
              double participacionesFondo = stats.totalParticipaciones() ?? 0.0;
              if (participacionesFondo > 0) {
                double? twr = stats.twr();
                if (twr != null) {
                  destacados.add(Destacado(
                      cartera: cartera,
                      fondo: fondo,
                      tae: stats.anualizar(twr)!));
                }
                List<Valor>? operaciones = fondo.valores
                    ?.where((v) => v.tipo == 1 || v.tipo == 0)
                    .toList();
                if (operaciones != null && operaciones.isNotEmpty) {
                  // ORDENAR OPERACIONES POR DATE ??
                  var lastOp = operaciones.first;
                  lastOps.add(
                      LastOp(cartera: cartera, fondo: fondo, valor: lastOp));
                  if (operaciones.length > 1) {
                    //var lastOp2 = operaciones[operaciones.length - 2];
                    var lastOp2 = operaciones[1];
                    lastOps.add(
                        LastOp(cartera: cartera, fondo: fondo, valor: lastOp2));
                  }
                }
                if (fondo.divisa == 'EUR') {
                  inversionGlobalEur += stats.inversion() ?? 0.0;
                  valorGlobalEur += stats.resultado() ?? 0.0;
                  balanceGlobalEur += stats.balance() ?? 0.0;
                } else if (fondo.divisa == 'USD') {
                  inversionGlobalUsd += stats.inversion() ?? 0.0;
                  valorGlobalUsd += stats.resultado() ?? 0.0;
                  balanceGlobalUsd += stats.balance() ?? 0.0;
                } else {
                  inversionGlobalOtra += stats.inversion() ?? 0.0;
                  valorGlobalOtra += stats.resultado() ?? 0.0;
                  balanceGlobalOtra += stats.balance() ?? 0.0;
                }
              }
            }
          }
        }
      }
      destacados.sort((a, b) => a.tae.compareTo(b.tae));
      lastOps.sort((a, b) => a.valor.date.compareTo(b.valor.date));
    }

    calcularGlobal();

    /*_goCartera(BuildContext context, Cartera cartera) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      carteraProvider.carteraSelect = cartera;
      context.go(carteraPage);
    }*/

    _goFondo(BuildContext context, Cartera cartera, Fondo fondo) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      carteraProvider.carteraSelect = cartera;
      carteraProvider.fondoSelect = fondo;
      context.go(fondoPage);
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: scaffoldGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('Posición Global'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  context.go(homePage);
                },
              ),
            ],
          ),
          body: carteras.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Resumen global de tu portafolio: empieza creando una cartera',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView(
                    //padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
                    children: [
                      const Text('PORTAFOLIO', textAlign: TextAlign.start),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Chip(
                            backgroundColor: blue100,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            avatar: const Icon(
                              Icons.business_center,
                              color: blue900,
                            ),
                            label: Text('${carteras.length} Carteras'),
                            labelStyle: const TextStyle(fontSize: 16),
                          ),
                          Chip(
                            backgroundColor: blue100,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            avatar: const Icon(
                              Icons.assessment,
                              color: blue900,
                            ),
                            label: Text('$nFondos Fondos'),
                            labelStyle: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(0),
                        width: MediaQuery.of(context).size.width * 0.95,
                        height: MediaQuery.of(context).size.width * 0.95 * 0.65,
                        child: PieChartGlobal(carteras: carteras),
                      ),
                      /*ListTile(
                        minLeadingWidth: minLeadingWidth0,
                        horizontalTitleGap: horizontalTitleGap10,
                        leading: const Icon(
                          Icons.business_center,
                          color: blue900,
                        ),
                        title: Text('${carteras.length} Carteras'),
                      ),
                      ListTile(
                        minLeadingWidth: minLeadingWidth0,
                        horizontalTitleGap: horizontalTitleGap10,
                        leading: const Icon(Icons.assessment, color: blue900),
                        title: Text('$nFondos Fondos'),
                      ),*/
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('CAPITAL: VALOR / INVERSIÓN'),
                      if (inversionGlobalEur > 0)
                        ListTileCapital(
                            inversion: inversionGlobalEur,
                            capital: valorGlobalEur,
                            balance: balanceGlobalEur,
                            divisa: '€',
                            icon: Icons.euro),
                      if (inversionGlobalUsd > 0)
                        ListTileCapital(
                            inversion: inversionGlobalUsd,
                            capital: valorGlobalUsd,
                            balance: balanceGlobalUsd,
                            divisa: '\$',
                            icon: Icons.attach_money),
                      if (inversionGlobalOtra > 0)
                        ListTileCapital(
                            inversion: inversionGlobalOtra,
                            capital: valorGlobalOtra,
                            balance: balanceGlobalOtra,
                            divisa: '',
                            icon: Icons.payments),
                      if (inversionGlobalEur == 0.0 &&
                          inversionGlobalUsd == 0.0 &&
                          inversionGlobalOtra == 0.0)
                        const Padding(
                            padding: EdgeInsets.all(10),
                            child:
                                Text('No se ha encontrado ninguna inversión')),
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('FONDOS DESTACADOS (TAE)'),
                      if (destacados.isNotEmpty && destacados.length > 1)
                        ListTileDestacado(
                            destacado: destacados.last,
                            icon: Icons.stars,
                            goFondo: _goFondo),
                      if (destacados.isNotEmpty && destacados.length > 1)
                        ListTileDestacado(
                            destacado: destacados.first,
                            icon: Icons.warning,
                            goFondo: _goFondo),
                      if (destacados.isEmpty || destacados.length < 2)
                        const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Nada que destacar')),
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('ÚLTIMAS OPERACIONES'),
                      if (lastOps.isNotEmpty)
                        ListTileLastOp(lastOp: lastOps.last, goFondo: _goFondo),
                      if (lastOps.isNotEmpty && lastOps.length > 1)
                        ListTileLastOp(
                            lastOp: lastOps[lastOps.length - 2],
                            goFondo: _goFondo),
                      if (lastOps.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(10.0),
                            child:
                                Text('No se ha encontrado ninguna operación')),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class LineDivider extends StatelessWidget {
  const LineDivider({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Divider(
        color: gris, height: 0, thickness: 0.5, indent: 20, endIndent: 20);
  }
}
