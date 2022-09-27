import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/number_util.dart';
import '../../utils/stats_global.dart';
import '../../utils/styles.dart';

class BarChartBalance extends StatelessWidget {
  final List<Cartera> carteras;
  final double rateExchange;
  const BarChartBalance(
      {Key? key, required this.carteras, required this.rateExchange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barChartGroupDatas = [];
    for (int i = 0; i < carteras.length; i++) {
      var cartera = carteras[i];
      var statsGlobalCartera = StatsGlobal(rateExchange: rateExchange);
      statsGlobalCartera.calcular([cartera]);

      var bcgd = BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: statsGlobalCartera.inversionGlobal,
            color: Colors.blue,
            borderRadius: const BorderRadius.all(Radius.zero),
          ),
          BarChartRodData(
            toY: statsGlobalCartera.valorGlobal,
            borderRadius: const BorderRadius.all(Radius.zero),
            color: statsGlobalCartera.balanceGlobal > 0
                ? Colors.green
                : Colors.red,
          ),
        ],
      );
      barChartGroupDatas.add(bcgd);
    }

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
                  return Text(carteras[index].name.substring(0, 3));
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
                  TextStyle(color: textRedGreen(balance)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
