import 'package:flutter/material.dart';

import '../utils/fecha_util.dart';

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
        color: const Color(0xFF2196F3),
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

/*class HojaCalendario extends StatelessWidget {
  final int epoch;
  const HojaCalendario({Key? key, required this.epoch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int dia = FechaUtil.epochToDate(epoch).day;
    String mesYear = FechaUtil.epochToString(epoch, formato: 'MMM yy');

    return Container(
      height: 80, // or AspectRadio() parent
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(
          color: const Color(0xFF0D47A1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.blue,
            child: Text(
              mesYear,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$dia',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}*/
