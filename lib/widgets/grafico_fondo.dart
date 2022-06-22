import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cartera_provider.dart';
import '../utils/fecha_util.dart';

class GraficoFondo extends StatelessWidget {
  const GraficoFondo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final valores = context.watch<CarteraProvider>().valores;
    final List<double> precios = valores.reversed.map((v) => v.precio).toList();
    final List<int> fechas = valores.reversed.map((v) => v.date).toList();

    double precioMedio = 0;
    double precioMax = 0;
    double precioMin = 0;
    String? fechaMax;
    String? fechaMin;
    int epochMax = 0; // int? nullable
    int epochMin = 0;
    if (precios.length > 1) {
      precioMedio = precios.reduce((a, b) => a + b) / precios.length;
      precioMax = precios.reduce((curr, next) => curr > next ? curr : next);
      precioMin = precios.reduce((curr, next) => curr < next ? curr : next);
      //fechaMax = _epochFormat(fechas[precios.indexOf(precioMax)]);
      //fechaMin = _epochFormat(fechas[precios.indexOf(precioMin)]);
      fechaMax = FechaUtil.epochToString(fechas[precios.indexOf(precioMax)]);
      fechaMin = FechaUtil.epochToString(fechas[precios.indexOf(precioMin)]);
      epochMax = fechas[precios.indexOf(precioMax)];
      epochMin = fechas[precios.indexOf(precioMin)];
    }

    var mapData = {for (var valor in valores) valor.date: valor.precio};
    final spots = <FlSpot>[
      for (final entry in mapData.entries) FlSpot(entry.key.toDouble(), entry.value)
    ];

    final lineChartData = LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: const Color(0xFF2196F3),
          barWidth: 2,
          isCurved: false,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: const Color(0x802196F3)),
          // Colors.blue.withOpacity(0.5)),
        ),
      ],
      minY: precioMin.floor().toDouble(),
      //minY: ((((precioMin - precioMin.truncate()) * 10).floor()) / 10) + precioMin.floor(),
      // TODO: REVISAR
      maxY: precioMax.ceil().toDouble(),
      //maxY: (((((precioMax - precioMax.truncate()) * 10).floor()) / 10) + precioMax.floor()).ceilToDouble(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: const Color(0xFF000000), // red.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              var epoch = touchedSpot.x.toInt();
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
              //var fecha = DateFormat('d/MM/yy').format(dateTime);
              var fecha = FechaUtil.dateToString(date: dateTime);
              final textStyle = TextStyle(
                color: touchedSpot.bar.gradient?.colors[0] ?? touchedSpot.bar.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              );
              return LineTooltipItem('${touchedSpot.y.toStringAsFixed(2)}\n$fecha', textStyle);
            }).toList();
          },
        ),
        touchCallback: (_, __) {},
        handleBuiltInTouches: true,
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xff37434d), width: 1),
          left: BorderSide(color: Color(0xff37434d), width: 1),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      ),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, _) {
                // if (value.toInt() % 10 != 0) {
                //   return const Text('');
                // }
                return FittedBox(
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                  ),
                );
              }),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            //interval: 500000000 / spots.length,
            //interval: ((epochMax - epochMin) / spots.length) * 10,
            //interval: 1650057221 / spots.length,
            //TODO: REVISAR INTERVALO OPTIMO
            interval: (epochMax - epochMin) > 2592000 ? 22592000 : 2592000, // 1 mes
            //interval: (spots.last.x - spots.first.x),
            //interval: fechas.length / 2,
            getTitlesWidget: (double value, TitleMeta meta) {
              final epoch = value.toInt();
              //DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
              DateTime dateTime = FechaUtil.epochToDate(epoch);
              if (value == spots.last.x || value == spots.first.x) {
                return const Text('');
              }
              /*if (epoch.toInt() % 25 != 0) {
                return const Text('');
              }*/
              //return Text(DateFormat.MMMd().format(dateTime));
              //return Text(DateFormat.yMMM('es').format(dateTime));
              return Text(FechaUtil.dateToString(date: dateTime, formato: 'yMMM'));
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: precioMedio,
            color: const Color(0xFF2196F3),
            strokeWidth: 2,
            dashArray: [2, 2],
            label: HorizontalLineLabel(
              show: true,
              style: TextStyle(
                //backgroundColor: Colors.black,
                background: Paint()
                  ..color = const Color(0xFF000000)
                  ..strokeWidth = 13
                  ..style = PaintingStyle.stroke,
              ),
              alignment: Alignment.topRight,
              labelResolver: (line) => 'Media: ${precioMedio.toStringAsFixed(2)}',
            ),
          ),
          HorizontalLine(
            y: precioMax,
            color: const Color(0xFF4CAF50),
            strokeWidth: 2,
            dashArray: [2, 2],
            label: HorizontalLineLabel(
              show: true,
              style: TextStyle(
                background: Paint()
                  ..color = const Color(0xFF000000)
                  ..strokeWidth = 13
                  ..style = PaintingStyle.stroke,
              ),
              alignment: Alignment.topRight,
              labelResolver: (line) => 'Máx: ${precioMax.toStringAsFixed(2)} - ${fechaMax ?? ''}',
            ),
          ),
          HorizontalLine(
            y: precioMin,
            color: const Color(0xFFF44336),
            strokeWidth: 2,
            dashArray: [2, 2],
            label: HorizontalLineLabel(
              show: true,
              style: TextStyle(
                background: Paint()
                  ..color = const Color(0xFF000000)
                  ..strokeWidth = 13
                  ..style = PaintingStyle.stroke,
              ),
              alignment: Alignment.topRight,
              labelResolver: (line) => 'Mín: ${precioMin.toStringAsFixed(2)} - ${fechaMin ?? ''}',
            ),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.only(top: 30, left: 5, right: 5, bottom: 10),
        width: spots.length < 100
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height * 2,
        child: spots.length > 1
            ? LineChart(
                lineChartData,
                //swapAnimationDuration: const Duration(milliseconds: 2000),
                //swapAnimationCurve: Curves.linear,
              )
            : const Center(child: Text('No hay suficientes datos')),
      ),
    );
  }
}
