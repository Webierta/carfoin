import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../models/preferences_provider.dart';
import '../router/routes_const.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/stats_global.dart';
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
  late StatsGlobal _statsGlobal;

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    CarteraProvider carteraProvider = context.read<CarteraProvider>();
    PreferencesProvider prefProvider = context.read<PreferencesProvider>();
    final List<Cartera> carteras = carteraProvider.carteras;
    _statsGlobal = StatsGlobal(rateExchange: prefProvider.rateExchange);
    _statsGlobal.calcular(carteras);

    goFondo(BuildContext context, Cartera cartera, Fondo fondo) {
      carteraProvider.carteraSelect = cartera;
      carteraProvider.fondoSelect = fondo;
      context.go(fondoPage);
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('Posición Global'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(homePage),
              ),
            ],
          ),
          body: carteras.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Resumen global de tu portafolio: empieza creando una cartera',
                      style: TextStyle(color: AppColor.blanco, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListView(
                    children: [
                      const Text('PORTAFOLIO', textAlign: TextAlign.start),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.business_center),
                            label: Text('${carteras.length} Carteras'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.assessment),
                            label: Text('${_statsGlobal.nFondos} Fondos'),
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
                              dropdownColor: darkTheme ? AppColor.boxDark : AppColor.blanco,
                              value: criterioPie,
                              onChanged: (CriterioPie? value) {
                                if (value! != criterioPie) {
                                  setState(() => criterioPie = value);
                                }
                              },
                              items: CriterioPie.values.map((CriterioPie criterioPie) {
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
                        )
                      else
                        const SizedBox(height: 10),
                      if (_statsGlobal.nFondos > 0)
                        PieChartGlobal(
                          carteras: carteras,
                          criterioPie: criterioPie,
                          rateExchange: prefProvider.rateExchange,
                          statsGlobal: _statsGlobal,
                        ),
                      const LineDivider(),
                      const SizedBox(height: 10),
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
                            child: Text('No se ha encontrado ninguna inversión')),
                      const LineDivider(),
                      const SizedBox(height: 10),
                      const Text('FONDOS DESTACADOS (TAE)'),
                      if (_statsGlobal.destacados.isNotEmpty)
                        ListTileDestacado(
                            destacado: _statsGlobal.destacados.last,
                            icon: Icons.stars,
                            goFondo: goFondo),
                      if (_statsGlobal.destacados.length > 1)
                        ListTileDestacado(
                            destacado: _statsGlobal.destacados.first,
                            icon: Icons.warning,
                            goFondo: goFondo),
                      if (_statsGlobal.destacados.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(10.0), child: Text('Nada que destacar')),
                      const LineDivider(),
                      const SizedBox(height: 10),
                      const Text('ÚLTIMAS OPERACIONES'),
                      if (_statsGlobal.lastOps.isNotEmpty)
                        ListTileLastOp(lastOp: _statsGlobal.lastOps.last, goFondo: goFondo),
                      if (_statsGlobal.lastOps.length > 1)
                        ListTileLastOp(
                            lastOp: _statsGlobal.lastOps[_statsGlobal.lastOps.length - 2],
                            goFondo: goFondo),
                      if (_statsGlobal.lastOps.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('No se ha encontrado ninguna operación')),
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
    return const Divider(color: AppColor.gris, height: 0, thickness: 0.5, indent: 8, endIndent: 8);
  }
}
