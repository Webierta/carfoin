import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/number_util.dart';
import '../../utils/stats_global.dart';
import '../../utils/styles.dart';

enum CriterioPie { Fondos, Inversion, Valor, Balance }

class DataPie {
  final String nameCartera;
  final double data;
  final Color color;

  const DataPie(
      {required this.nameCartera, required this.data, required this.color});
}

class PieChartGlobal extends StatelessWidget {
  final List<Cartera> carteras;
  final CriterioPie criterioPie;
  final StatsGlobal statsGlobal;
  final double rateExchange;

  const PieChartGlobal(
      {Key? key,
      required this.carteras,
      required this.statsGlobal,
      required this.criterioPie,
      required this.rateExchange})
      : super(key: key);

  _dialogPie(BuildContext context, Cartera cartera) async {
    var statsGlobalCartera = StatsGlobal(rateExchange: rateExchange);
    statsGlobalCartera.calcular([cartera]);
    List<Widget> children = [];
    if (criterioPie == CriterioPie.Fondos) {
      for (var fondo in cartera.fondos!) {
        var child = Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(fondo.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
        children.add(child);
      }
    } else if (criterioPie == CriterioPie.Inversion) {
      var child = Text(
          'Inversión: ${NumberUtil.currency(statsGlobalCartera.inversionGlobal)} €');
      children.add(child);
    } else if (criterioPie == CriterioPie.Valor) {
      var child = Text(
          'Valor: ${NumberUtil.currency(statsGlobalCartera.valorGlobal)} €');
      children.add(child);
    }
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: blue100,
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 10),
            title: Text(cartera.name),
            children: children,
          );
        });
  }

  Color getColor() {
    final random = Random();
    return Color.fromARGB(
        255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  @override
  Widget build(BuildContext context) {
    if ((criterioPie == CriterioPie.Inversion ||
            criterioPie == CriterioPie.Valor) &&
        statsGlobal.inversionGlobal == 0) {
      return const PieChartNull();
    }

    if (criterioPie == CriterioPie.Balance && statsGlobal.inversionGlobal > 0) {
      //return const PieChartNull();
      return BarChartBalance(carteras: carteras, rateExchange: rateExchange);
    }

    final List<DataPie> dataPies = [];

    for (var cartera in carteras) {
      var statsGlobalCartera = StatsGlobal(rateExchange: rateExchange);
      statsGlobalCartera.calcular([cartera]);
      double data = 0.0;
      Color color = getColor();
      if (criterioPie == CriterioPie.Fondos) {
        List<Fondo>? fondos = cartera.fondos;
        data = fondos?.length.toDouble() ?? 0.0;
      } else if (criterioPie == CriterioPie.Inversion) {
        data = statsGlobalCartera.inversionGlobal;
      } else if (criterioPie == CriterioPie.Valor) {
        data = statsGlobalCartera.valorGlobal;
      }
      dataPies.add(
        DataPie(nameCartera: cartera.name, data: data, color: color),
      );
    }

    final pieChartSections = <PieChartSectionData>[
      for (int i = 0; i < dataPies.length; ++i)
        PieChartSectionData(
          title: dataPies[i].nameCartera,
          value: dataPies[i].data,
          color: dataPies[i].color,
          radius: MediaQuery.of(context).size.width / 4.44,
          titleStyle: const TextStyle(
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(offset: Offset(1.0, 1.0), color: Colors.black),
            ],
          ),
        )
    ];

    final pieChartData = PieChartData(
      sections: pieChartSections,
      centerSpaceRadius: 10,
      sectionsSpace: 4,
      //startDegreeOffset: 180,
      borderData: FlBorderData(show: false),
      pieTouchData: PieTouchData(
        enabled: true,
        touchCallback: (event, response) {
          if (response?.touchedSection != null) {
            var index = response!.touchedSection!.touchedSectionIndex;
            Cartera? carteraTouch;
            try {
              var carterasConFondos =
                  carteras.where((c) => c.fondos!.isNotEmpty).toList();
              carteraTouch = carterasConFondos[index];
            } catch (e) {
              carteraTouch = null;
            }
            if (carteraTouch != null &&
                carteraTouch.fondos != null &&
                carteraTouch.fondos!.isNotEmpty) {
              _dialogPie(context, carteraTouch);
            }
          }
        },
      ),
    );

    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        padding: const EdgeInsets.all(0),
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.width * 0.95 * 0.65,
        child: PieChart(pieChartData),
      ),
    );
  }
}

class PieChartNull extends StatelessWidget {
  const PieChartNull({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Text('Sin datos'),
      ),
    );
  }
}

class BarChartBalance extends StatelessWidget {
  final List<Cartera> carteras;
  final double rateExchange;
  const BarChartBalance(
      {Key? key, required this.carteras, required this.rateExchange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barChartGroupDatas = [];
    //List<double> importes = [];
    for (int i = 0; i < carteras.length; i++) {
      var cartera = carteras[i];
      var statsGlobalCartera = StatsGlobal(rateExchange: rateExchange);
      statsGlobalCartera.calcular([cartera]);
      //importes.add(statsGlobalCartera.inversionGlobal);
      //importes.add(statsGlobalCartera.valorGlobal);
      var bcgd = BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: statsGlobalCartera.inversionGlobal, color: Colors.blue),
          BarChartRodData(
            toY: statsGlobalCartera.valorGlobal,
            color: statsGlobalCartera.balanceGlobal > 0
                ? Colors.green
                : Colors.red,
          ),
        ],
      );
      barChartGroupDatas.add(bcgd);
    }

    //importes.sort();

    return Container(
      padding: const EdgeInsets.all(0),
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.width * 0.95 * 0.65,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(
            show: true,
            border: const Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFececec)),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  return Text(carteras[index].name);
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFececec),
              dashArray: null,
              strokeWidth: 1,
            ),
          ),
          barGroups: barChartGroupDatas,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (
                BarChartGroupData group,
                int groupIndex,
                BarChartRodData rod,
                int rodIndex,
              ) {
                var cartera = carteras[groupIndex];
                var statsGlobalCartera =
                    StatsGlobal(rateExchange: rateExchange);
                statsGlobalCartera.calcular([cartera]);
                double balance = statsGlobalCartera.balanceGlobal;
                return BarTooltipItem(
                  '${NumberUtil.currency(balance)} €',
                  TextStyle(color: balance < 0 ? Colors.red : Colors.green),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
