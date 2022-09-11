import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../services/preferences_service.dart';
import '../utils/konstantes.dart';
import '../utils/stats_global.dart';
import '../utils/styles.dart';
import '../widgets/my_drawer.dart';
import '../widgets/subglobal/listtile_capital.dart';
import '../widgets/subglobal/listtile_destacado.dart';
import '../widgets/subglobal/listtile_lastop.dart';
import '../widgets/subglobal/pie_chart_global.dart';

class PageGlobal extends StatefulWidget {
  const PageGlobal({Key? key}) : super(key: key);

  @override
  State<PageGlobal> createState() => _PageGlobalState();
}

class _PageGlobalState extends State<PageGlobal> {
  var criterioPie = CriterioPie.Fondos;
  double _rateExchange = 0.0;
  late StatsGlobal _statsGlobal; // = StatsGlobal(rateExchange: 0.0);

  getRateExchangePref() async {
    double? rateExchange;
    await PreferencesService.getRateExchange(keyRateExchange)
        .then((value) => rateExchange = value);
    setState(() => _rateExchange = rateExchange ?? 0.0);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getRateExchangePref();
      //_statsGlobal = StatsGlobal(rateExchange: _rateExchange);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    CarteraProvider carteraProvider = context.read<CarteraProvider>();
    final List<Cartera> carteras = carteraProvider.carteras;
    _statsGlobal = StatsGlobal(rateExchange: _rateExchange);
    _statsGlobal.calcular(carteras);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            label: Text('${_statsGlobal.nFondos} Fondos'),
                            labelStyle: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (_statsGlobal.nFondos > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Peso relativo de las Carteras: ',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<CriterioPie>(
                              value: criterioPie,
                              onChanged: (CriterioPie? value) {
                                if (value! != criterioPie) {
                                  setState(() => criterioPie = value);
                                }
                              },
                              items: CriterioPie.values
                                  .map((CriterioPie criterioPie) {
                                return DropdownMenuItem<CriterioPie>(
                                  value: criterioPie,
                                  child: Text(
                                    criterioPie.toString().split('.')[1],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      if (_statsGlobal.nFondos > 0)
                        PieChartGlobal(
                          carteras: carteras,
                          criterioPie: criterioPie,
                          rateExchange: _rateExchange,
                          statsGlobal: _statsGlobal,
                        ),
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('CAPITAL: VALOR / INVERSIÓN'),
                      if (_statsGlobal.inversionGlobal > 0)
                        ListTileCapital(
                          inversion: _statsGlobal.inversionGlobal,
                          capital: _statsGlobal.valorGlobal,
                          balance: _statsGlobal.balanceGlobal,
                        ),
                      if (_statsGlobal.inversionGlobal == 0)
                        const Padding(
                            padding: EdgeInsets.all(10),
                            child:
                                Text('No se ha encontrado ninguna inversión')),
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('FONDOS DESTACADOS (TAE)'),
                      if (_statsGlobal.destacados.isNotEmpty)
                        ListTileDestacado(
                            destacado: _statsGlobal.destacados.last,
                            icon: Icons.stars,
                            goFondo: _goFondo),
                      if (_statsGlobal.destacados.length > 1)
                        ListTileDestacado(
                            destacado: _statsGlobal.destacados.first,
                            icon: Icons.warning,
                            goFondo: _goFondo),
                      if (_statsGlobal.destacados.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Nada que destacar')),
                      const LineDivider(),
                      const SizedBox(height: 20),
                      const Text('ÚLTIMAS OPERACIONES'),
                      if (_statsGlobal.lastOps.isNotEmpty)
                        ListTileLastOp(
                            lastOp: _statsGlobal.lastOps.last,
                            goFondo: _goFondo),
                      if (_statsGlobal.lastOps.length > 1)
                        ListTileLastOp(
                            lastOp: _statsGlobal
                                .lastOps[_statsGlobal.lastOps.length - 2],
                            goFondo: _goFondo),
                      if (_statsGlobal.lastOps.isEmpty)
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
        color: gris, height: 0, thickness: 0.5, indent: 8, endIndent: 8);
  }
}
