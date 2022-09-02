import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../utils/number_util.dart';
import '../utils/stats.dart';
import '../utils/styles.dart';

class PageGlobal extends StatelessWidget {
  const PageGlobal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Cartera> carteras = context.read<CarteraProvider>().carteras;
    int nFondos = 0;

    Map<List<String>, double> fondosTae = {};
    Map<List<String>, double> fondosTaeSort = {};

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
                  fondosTae[[fondo.name, cartera.name]] = stats.anualizar(twr)!;
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
      if (fondosTae.isNotEmpty) {
        fondosTaeSort = Map.fromEntries(fondosTae.entries.toList()
          ..sort((e1, e2) => e1.value.compareTo(e2.value)));
      }
    }

    calcularGlobal();

    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: scaffoldGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                context.go(homePage);
              },
            ),
            title: const Text('Posición Global'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              children: [
                const Text('PORTAFOLIO', textAlign: TextAlign.start),
                ListTile(
                  leading: const Icon(
                    Icons.business_center,
                    color: Color(0xFF2196F3),
                  ),
                  title: Text('${carteras.length} Carteras'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assessment,
                    color: Color(0xFF2196F3),
                  ),
                  title: Text('$nFondos Fondos'),
                ),
                const Divider(
                    color: Color(0xFF9E9E9E),
                    height: 0,
                    thickness: 0.5,
                    indent: 20,
                    endIndent: 20),
                const SizedBox(height: 20),
                const Text('FONDOS DESTACADOS (TAE)'),
                if (fondosTaeSort.isNotEmpty && fondosTaeSort.length > 1)
                  ListTileDestacado(
                      listKey: fondosTaeSort.keys.last,
                      value: fondosTaeSort.values.last,
                      icon: Icons.stars),
                if (fondosTaeSort.isNotEmpty && fondosTaeSort.length > 1)
                  ListTileDestacado(
                      listKey: fondosTaeSort.keys.first,
                      value: fondosTaeSort.values.first,
                      icon: Icons.warning),
                if (fondosTaeSort.isEmpty || fondosTaeSort.length < 2)
                  const Text('No es posible comparar fondos por rentabilidad.'),
                const Divider(
                    color: Color(0xFF9E9E9E),
                    height: 0,
                    thickness: 0.5,
                    indent: 20,
                    endIndent: 20),
                const SizedBox(height: 20),
                const Text('VALOR (BALANCE CAPITAL)'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListTileDestacado extends StatelessWidget {
  final List<String> listKey;
  final double value;
  final IconData icon;
  const ListTileDestacado(
      {Key? key,
      required this.listKey,
      required this.value,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2196F3)),
      title: Text(listKey[0]),
      subtitle: Row(
        children: [
          const Icon(Icons.business_center),
          const SizedBox(width: 5),
          Text(listKey[1]),
        ],
      ),
      trailing: Text(
        NumberUtil.percent(value),
        style: TextStyle(fontSize: 16, color: textRedGreen(value)),
      ),
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
      leading: Icon(icon, color: Color(0xFF2196F3)),
      title: Row(
        children: [
          Text('${NumberUtil.decimalFixed(capital)} $divisa'),
        ],
      ),
      subtitle: Row(
        children: [
          Text('${NumberUtil.decimalFixed(inversion)} $divisa'),
        ],
      ),
      trailing: Text(
        '${NumberUtil.decimalFixed(balance)} $divisa',
        style: TextStyle(
          color: textRedGreen(balance),
          fontSize: 16,
        ),
      ),
    );
  }
}
