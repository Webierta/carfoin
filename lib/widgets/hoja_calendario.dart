import 'package:flutter/material.dart';

import '../utils/fecha_util.dart';

class HojaCalendario extends StatelessWidget {
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
}
