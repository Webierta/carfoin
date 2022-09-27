import 'package:flutter/material.dart';

import '../utils/fecha_util.dart';
import '../utils/styles.dart';

class DiaCalendario extends StatelessWidget {
  final int epoch;
  const DiaCalendario({Key? key, required this.epoch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int dia = FechaUtil.epochToDate(epoch).day;
    String mesYear = FechaUtil.epochToString(epoch, formato: 'MMM yy');
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: blue,
        shape: BoxShape.rectangle,
        //border: Border.all(width: 1.0, color: Colors.blue),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mesYear,
              style: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
            Text(
              '$dia',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
