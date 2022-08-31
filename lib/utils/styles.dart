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

Container bgDismissible = Container(
  color: const Color(0xFFF44336),
  margin: const EdgeInsets.symmetric(horizontal: 15),
  //alignment: Alignment.centerRight,
  alignment: AlignmentDirectional.centerEnd,
  child: const Padding(
    //padding: EdgeInsets.all(10.0),
    padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
    child: Icon(Icons.delete, color: Color(0xFFFFFFFF)),
  ),
);

const TextStyle styleTitle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 18,
  color: Color(0xFF2196F3),
);

Color textRedGreen(num number) {
  return number < 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50);
}

Color backgroundRedGreen(num number) {
  return number < 0 ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7);
}
