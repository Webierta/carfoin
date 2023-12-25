import 'package:flutter/material.dart';

import '../themes/styles_theme.dart';
import '../utils/fecha_util.dart';

class DiaCalendario extends StatelessWidget {
  final int epoch;
  const DiaCalendario({super.key, required this.epoch});

  @override
  Widget build(BuildContext context) {
    int dia = FechaUtil.epochToDate(epoch).day;
    String mesYear = FechaUtil.epochToString(epoch, formato: 'MMM yy');
    return Container(
      decoration: const BoxDecoration(
          color: AppColor.blanco, shape: BoxShape.rectangle),
      child: FittedBox(
        fit: BoxFit.fill,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: AppColor.rojo900,
                child: Text(
                  mesYear,
                  style: const TextStyle(color: AppColor.blanco),
                )),
            Text(
              '$dia',
              style: const TextStyle(
                color: AppColor.negro,
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
