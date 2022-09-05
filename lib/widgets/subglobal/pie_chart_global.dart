import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/styles.dart';

class DataPie {
  final String nameCartera;
  final double nFondos;
  final Color color;

  const DataPie(
      {required this.nameCartera, required this.nFondos, required this.color});
}

class PieChartGlobal extends StatelessWidget {
  final List<Cartera> carteras;
  const PieChartGlobal({Key? key, required this.carteras}) : super(key: key);

  _dialogPie(BuildContext context, Cartera cartera) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: blue100,
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 10),
            title: Text(cartera.name),
            children: [
              for (var fondo in cartera.fondos!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(fondo.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<DataPie> dataPies = [];
    final random = Random();

    for (var cartera in carteras) {
      List<Fondo>? fondos = cartera.fondos;
      double nFondos = fondos?.length.toDouble() ?? 0.0;
      //MaterialColor color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
      final randomColor = Color.fromARGB(
          255, random.nextInt(256), random.nextInt(256), random.nextInt(256));

      dataPies.add(
        DataPie(
            nameCartera: cartera.name, nFondos: nFondos, color: randomColor),
      );
    }

    final pieChartSections = <PieChartSectionData>[
      for (int i = 0; i < dataPies.length; ++i)
        PieChartSectionData(
          title: dataPies[i].nameCartera,
          value: dataPies[i].nFondos,
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

    return PieChart(pieChartData);
  }
}
