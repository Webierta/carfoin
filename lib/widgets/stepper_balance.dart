import 'package:flutter/material.dart';

import '../utils/fecha_util.dart';
import '../utils/number_util.dart';
import '../utils/styles.dart';

class StepperBalance extends StatelessWidget {
  final double input;
  final double output;
  final double balance;
  final String divisa;
  final int firstDate;
  final int lastDate;
  const StepperBalance(
      {Key? key,
      required this.input,
      required this.output,
      required this.balance,
      required this.divisa,
      required this.firstDate,
      required this.lastDate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String spaceDivisa = (divisa == '€' || divisa == '\$') ? ' $divisa' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0.0, 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FechaUtil.epochToString(firstDate),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  FechaUtil.epochToString(lastDate),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child:
                    Divider(thickness: 1, indent: 0, endIndent: 4, color: gris),
              ),
              Chip(
                backgroundColor: const Color(0xFFFFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                visualDensity: const VisualDensity(vertical: -4),
                shape: const StadiumBorder(side: BorderSide(color: gris)),
                label: Text(
                    '${NumberUtil.decimalFixed(balance, long: false)}$spaceDivisa'),
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textRedGreen(balance),
                ),
              ),
              const Expanded(
                child:
                    Divider(thickness: 1, indent: 4, endIndent: 4, color: gris),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0.0, -5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberUtil.decimalFixed(input, long: false)}$spaceDivisa',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${NumberUtil.decimalFixed(output, long: false)}$spaceDivisa',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
