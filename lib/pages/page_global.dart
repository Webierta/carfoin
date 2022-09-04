import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../utils/fecha_util.dart';
import '../utils/number_util.dart';
import '../utils/stats.dart';
import '../utils/styles.dart';
import '../widgets/my_drawer.dart';

const double minLeadingWidth0 = 0.0;
const double horizontalTitleGap10 = 10.0;
const double trailingMaxWidth80 = 80.0;

class CarteraFondo {
  final Cartera cartera;
  final Fondo fondo;
  const CarteraFondo({required this.cartera, required this.fondo});
}

class Destacado extends CarteraFondo {
  final double tae;
  const Destacado(
      {required super.cartera, required super.fondo, required this.tae});
}

class LastOp extends CarteraFondo {
  final Valor valor;
  const LastOp(
      {required super.cartera, required super.fondo, required this.valor});
}

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
            /*leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                context.go(homePage);
              },
            ),*/
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
                    children: [
                      const Text('PORTAFOLIO', textAlign: TextAlign.start),
                      ListTile(
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
                      ),
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

class ListTileDestacado extends StatelessWidget {
  final Destacado destacado;
  final IconData icon;
  final Function goFondo;
  const ListTileDestacado(
      {Key? key,
      required this.destacado,
      required this.icon,
      required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      //onTap: () => goFondo(context, destacado.cartera, destacado.fondo),
      //selected: true,
      //selectedColor: Colors.white,
      leading: Icon(icon, color: blue900),
      title: InkWell(
        onTap: () => goFondo(context, destacado.cartera, destacado.fondo),
        child: Text(
          destacado.fondo.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: blue,
            color: Colors.transparent,
            shadows: [Shadow(offset: Offset(0, -4), color: Colors.black)],
          ),
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.business_center),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              destacado.cartera.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          NumberUtil.percentCompact(destacado.tae),
          //'123%',
          //'1234%5678%9123456789',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: textRedGreen(destacado.tae)),
        ),
      ),
    );
  }
}

class ListTileLastOp extends StatelessWidget {
  final LastOp lastOp;
  final Function goFondo;
  const ListTileLastOp({Key? key, required this.lastOp, required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      //onTap: () => goFondo(context, lastOp.cartera, lastOp.fondo),
      //selected: true,
      //selectedColor: Colors.white,
      //leading: Text(FechaUtil.epochToString(lastOp.valor.date)),
      leading: Icon(
        lastOp.valor.tipo == 1 ? Icons.add_circle : Icons.remove_circle,
        color: blue900,
      ),
      title: InkWell(
        onTap: () => goFondo(context, lastOp.cartera, lastOp.fondo),
        child: Text(
          lastOp.fondo.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: blue,
            color: Colors.transparent,
            shadows: [Shadow(offset: Offset(0, -4), color: Colors.black)],
          ),
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.business_center),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastOp.cartera.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      //TODO: hacerlo columna para evitar overflow ??
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          FechaUtil.epochToString(lastOp.valor.date),
          style: const TextStyle(color: Color(0xFF000000)),
        ),
      ),
      /*trailing: Text(
        NumberUtil.decimalFixed(
            lastOp.valor.precio * lastOp.valor.participaciones!,
            long: false),
        style: TextStyle(
            color: lastOp.valor.tipo == 1 ? Colors.green : Colors.red),
      ),*/
    );
  }
}

class ListTileCapital extends StatelessWidget {
  final double inversion;
  final double capital;
  final double balance;
  final String divisa;
  final IconData icon;
  const ListTileCapital(
      {Key? key,
      required this.inversion,
      required this.capital,
      required this.balance,
      required this.divisa,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      leading: Icon(icon, color: blue900),
      title: Row(
        children: [
          Text(
            '${NumberUtil.decimalFixed(capital, long: false)} $divisa',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            '${NumberUtil.decimalFixed(inversion, long: false)} $divisa',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          '${NumberUtil.decimalFixed(balance, long: false)} $divisa',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: textRedGreen(balance)),
        ),
      ),
    );
  }
}
