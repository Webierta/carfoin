import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../utils/fecha_util.dart';
import '../../utils/number_util.dart';

const Map<String, int> filtroTemp = {
  'Total': 0,
  'Últimos 30 días': 30,
  'Últimos 6 meses': 30 * 6,
  'Último año': 365,
  'Últimos 3 años': 365 * 3
};

class GraficoFondo extends StatefulWidget {
  const GraficoFondo({Key? key}) : super(key: key);
  @override
  State<GraficoFondo> createState() => _GraficoFondoState();
}

class _GraficoFondoState extends State<GraficoFondo> {
  int filtroTempSelect = filtroTemp.values.first;

  @override
  Widget build(BuildContext context) {
    final valores = context.watch<CarteraProvider>().valores;
    List<Valor> valoresFilter = valores;
    if (filtroTempSelect != 0) {
      DateTime now = DateTime.now();
      DateTime? lastTime;
      lastTime = now.subtract(Duration(days: filtroTempSelect));
      var lastEpoch = FechaUtil.dateToEpoch(lastTime);
      valoresFilter = valores.where((v) => v.date > lastEpoch).toList();
    }
    final List<double> precios =
        valoresFilter.reversed.map((v) => v.precio).toList();
    final List<int> fechas = valoresFilter.reversed.map((v) => v.date).toList();

    double precioMedio = 0;
    double precioMax = 0;
    double precioMin = 0;
    String? fechaMax;
    String? fechaMin;
    int epochMax = 0; // int? nullable
    int epochMin = 0;
    int timestamp = 0;
    if (precios.length > 1) {
      precioMedio = precios.reduce((a, b) => a + b) / precios.length;
      precioMax = precios.reduce((curr, next) => curr > next ? curr : next);
      precioMin = precios.reduce((curr, next) => curr < next ? curr : next);
      //fechaMax = _epochFormat(fechas[precios.indexOf(precioMax)]);
      // fechaMin = _epochFormat(fechas[precios.indexOf(precioMin)]);
      fechaMax = FechaUtil.epochToString(fechas[precios.indexOf(precioMax)]);
      fechaMin = FechaUtil.epochToString(fechas[precios.indexOf(precioMin)]);
      epochMax = fechas[precios.indexOf(precioMax)];
      epochMin = fechas[precios.indexOf(precioMin)];
      timestamp = FechaUtil.epochToDate(fechas.last)
          .difference(FechaUtil.epochToDate(fechas.first))
          .inDays;
    }

    var mapData = {for (var valor in valoresFilter) valor.date: valor.precio};
    final spots = <FlSpot>[
      for (final entry in mapData.entries)
        FlSpot(entry.key.toDouble(), entry.value)
    ];

    List<VerticalLine> getVerticalLines() {
      List<VerticalLine> verticalLines = [];
      for (var valor in valoresFilter) {
        if (valor.tipo == 0 || valor.tipo == 1) {
          var color = valor.tipo == 0 ? Colors.red : Colors.green;
          double date = valor.date.toDouble();
          verticalLines.add(VerticalLine(
            x: date,
            color: color,
            strokeWidth: 2,
            dashArray: [2, 2],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(fontSize: 12),
              labelResolver: (line) =>
                  'Part: ${valor.participaciones}\nImporte: '
                  '${NumberUtil.currency(valor.participaciones! * valor.precio)}',
            ),
          ));
        }
      }
      return verticalLines;
    }

    getDotPainter(int index) {
      if (valoresFilter[index].tipo == 0 || valoresFilter[index].tipo == 1) {
        var color = valoresFilter[index].tipo == 0 ? Colors.red : Colors.green;
        return FlDotSquarePainter(
          size: 10,
          color: color,
          strokeWidth: 5,
          strokeColor: Colors.blue[900],
        );
      }
      return FlDotCirclePainter(
        color: const Color(0xFF2196F3),
      );
    }

    final lineChartData = LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: const Color(0xFF2196F3),
          barWidth: 2,
          isCurved: false,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                getDotPainter(index),
          ),
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
              DateTime dateTime =
                  DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
              //var fecha = DateFormat('d/MM/yy').format(dateTime);
              var fecha = FechaUtil.dateToString(date: dateTime);
              final textStyle = TextStyle(
                color: touchedSpot.bar.gradient?.colors[0] ??
                    touchedSpot.bar.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              );
              return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(2)}\n$fecha', textStyle);
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
            //interval: (epochMax - epochMin) > 2592000 ? 22592000 : 2592000, // 1 mes
            //interval: 20000000,
            //interval: (epochMax - epochMin) / spots.length,
            interval: 2629743 * 6,
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
              //return Text(FechaUtil.dateToString(date: dateTime, formato: 'yMMM'));
              return Text(
                  FechaUtil.dateToString(date: dateTime, formato: 'MM/yy'));
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        verticalLines:
            //VerticalLine(x: x),
            getVerticalLines(),
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
              labelResolver: (line) =>
                  'Media: ${NumberUtil.decimalFixed(precioMedio)}',
              //'Media: ${precioMedio.toStringAsFixed(2)}',
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
              labelResolver: (line) =>
                  'Máx: ${NumberUtil.decimalFixed(precioMax)} - ${fechaMax ?? ''}',
              //'Máx: ${precioMax.toStringAsFixed(2)} - ${fechaMax ?? ''}',
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
              labelResolver: (line) =>
                  'Mín: ${NumberUtil.decimalFixed(precioMin)} - ${fechaMin ?? ''}',
              //'Mín: ${precioMin.toStringAsFixed(2)} - ${fechaMin ?? ''}',
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        DropdownButton<int>(
          isDense: true,
          value: filtroTempSelect,
          onChanged: (int? value) {
            setState(() => filtroTempSelect = value ?? 0);
          },
          items: filtroTemp
              .map((String txt, int value) => MapEntry(
                  txt,
                  DropdownMenuItem<int>(
                    value: value,
                    child: Text(txt),
                  )))
              .values
              .toList(),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.only(
                    top: 30, left: 5, right: 5, bottom: 10),
                /*width: spots.length < 100 && timestamp < 100
                    //|| (filtroTempSelect != 0 && filtroTempSelect < 30 * 60)
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.height * 2,*/
                width: spots.length > 50 || timestamp > 30 * 3
                    //|| (filtroTempSelect != 0 && filtroTempSelect > 364)
                    ? MediaQuery.of(context).size.height * 2
                    : MediaQuery.of(context).size.width,
                child: spots.length > 1
                    ? LineChart(
                        lineChartData,
                        //swapAnimationDuration: const Duration(milliseconds: 2000),
                        //swapAnimationCurve: Curves.linear,
                      )
                    : const Center(child: Text('No hay suficientes datos')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
