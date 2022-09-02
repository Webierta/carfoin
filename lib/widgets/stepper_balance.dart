import 'package:flutter/material.dart';

import '../utils/number_util.dart';
import '../utils/styles.dart';

class StepperBalance extends StatelessWidget {
  final double input;
  final double output;
  final double balance;
  final String divisa;
  final double? tae;
  const StepperBalance({
    Key? key,
    required this.input,
    required this.output,
    required this.balance,
    required this.divisa,
    this.tae,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String spaceDivisa = (divisa == '€' || divisa == '\$') ? ' $divisa' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${NumberUtil.decimalFixed(input, long: false)}$spaceDivisa',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${NumberUtil.decimalFixed(output, long: false)}$spaceDivisa',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9E9E9E),
                  ),
                  child: const Icon(Icons.login, color: Color(0xFFFFFFFF)),
                ),
                const Expanded(
                  child: Divider(
                    thickness: 1,
                    indent: 4,
                    endIndent: 4,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Chip(
                  backgroundColor: const Color(0xFFFFFFFF),
                  //backgroundColor: const Color(0xFFBDBDBD),
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  visualDensity: const VisualDensity(vertical: -4),
                  shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFF9E9E9E))),
                  /*avatar: const Icon(
                    Icons.iso,
                    color: Color(0xFFFFFFFF),
                  ),*/
                  onDeleted: () {},
                  deleteIcon: const Icon(
                    Icons.savings,
                    color: Color(0xFF9E9E9E),
                  ),
                  label: Text(
                      '${NumberUtil.decimalFixed(balance, long: false)}$spaceDivisa'),
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textRedGreen(balance),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    thickness: 1,
                    indent: 4,
                    endIndent: 4,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9E9E9E),
                  ),
                  child: const Icon(Icons.logout, color: Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
          if (tae != null)
            const SizedBox(
              height: 10,
              child: VerticalDivider(
                thickness: 2,
                //indent: 4,
                //endIndent: 4,
                color: Color(0xFF9E9E9E),
              ),
            ),
          if (tae != null)
            Chip(
              visualDensity: const VisualDensity(vertical: -4),
              backgroundColor: backgroundRedGreen(tae!),
              padding: const EdgeInsets.only(left: 10, right: 5),
              avatar: const FittedBox(child: Text('TAE')),
              label: Text(NumberUtil.percent(tae!)),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
