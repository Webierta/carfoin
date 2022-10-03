import 'package:flutter/material.dart';

const BoxDecoration scaffoldGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    stops: [0.2, 0.5, 0.8, 0.7],
    colors: [
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
      Color(0xFF90CAF9),
      Color(0xFF64B5F6)
    ],
  ),
);

/*BoxDecoration boxDeco = BoxDecoration(
  color: const Color.fromRGBO(255, 255, 255, 0.5),
  border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
  borderRadius: BorderRadius.circular(12),
);*/

BoxDecoration boxDecoBlue = BoxDecoration(
  color: const Color(0xFFBBDEFB),
  border: Border.all(color: const Color(0xFFFFFFFF), width: 1),
  borderRadius: BorderRadius.circular(12),
);

const TextStyle styleTitle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 18,
  color: Color(0xFF2196F3),
);

const TextStyle styleTitleCompact = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 20,
  color: Color(0xFF2196F3),
);

TextStyle labelGrafico = TextStyle(
  fontWeight: FontWeight.bold,
  background: Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 17
    ..style = PaintingStyle.stroke,
);

/* PALETA DE COLORES */

const Color blue = Color(0xFF2196F3);
const Color blue100 = Color(0xFFBBDEFB);
const Color blue200 = Color(0xFF90CAF9);
const Color blue900 = Color(0xFF0D47A1);
const Color amber = Color(0xFFFFC107);
const Color gris = Color(0xFF9E9E9E);
const Color green = Color(0xFF4CAF50);
const Color red = Color(0xFFF44336);
const Color red900 = Color(0xFFB71C1C);

Color textRedGreen(num number) {
  return number < 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50);
}

Color backgroundRedGreen(num number) {
  return number < 0 ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7);
}
