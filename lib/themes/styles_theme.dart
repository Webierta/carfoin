import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/* STYLES TEXT */

class AppText {
  static textTheme(Color color) {
    return TextTheme(
      headlineLarge:
          TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w200),
      headlineMedium:
          TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w200),
      headlineSmall:
          TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w300),
      titleLarge: TextStyle(color: color),
      titleMedium: TextStyle(color: color),
      titleSmall: TextStyle(color: color),
      bodyLarge: TextStyle(color: color),
      bodyMedium: TextStyle(color: color),
      bodySmall: TextStyle(color: color, fontSize: 12, wordSpacing: 0),
      labelLarge: TextStyle(color: color),
      labelMedium: TextStyle(color: color),
      labelSmall: TextStyle(color: color),
    );
  }
}

/* PALETA DE COLORES */

class AppColor {
  static const blanco = Colors.white;
  static const negro = Colors.black;
  static const gris = Colors.grey;
  static const gris300 = Color(0xFFE0E0E0);
  static const gris700 = Color(0xFF616161);
  static const negro54 = Color(0x89000000);
  static const grisAlfa = Color(0x80FFFFFF);

  //LIGHT
  static const light = Colors.lightBlue;
  static const lightAccent = Colors.lightBlueAccent;
  static const light100 = Color(0xFFB3E5FC);
  static const light200 = Color(0xFF81D4FA);
  static const light300 = Color(0xFF4FC3F7);
  static const light700 = Color(0xFF0288D1);
  static const light900 = Color(0xFF01579B);

  static const boxLight = Color(0xFFBBDEFB);

  static const gradientLight1 = Color(0xFFE3F2FD);
  static const gradientLight2 = Color(0xFFBBDEFB);
  static const gradientLight3 = Color(0xFF90CAF9);
  static const gradientLight4 = Color(0xFF64B5F6);

  // DARK
  static const dark = Colors.blueGrey;
  static const dark100 = Color(0xFFCFD8DC);
  static const dark200 = Color(0xFFB0BEC5);
  static const dark700 = Color(0xFF455A64);
  static const dark900 = Color(0xFF263238);
  static const darkAlfa = Color(0x80284964);

  static const boxDark = Color(0xFF113147);

  static const gradientDark1 = Color(0xFF02121D);
  static const gradientDark2 = Color(0xFF284964);
  static const gradientDark3 = Color(0xFF61778A);
  static const gradientDark4 = Color(0xFFA4AFB8);

  // GRAFICO
  static const graficoAzul1 = Color(0xFF2196F3);
  static const graficoAzul2 = Color(0x802196F3);
  static const graficoBorde = Color(0xFF37434d);

  // SECUNDARY
  static const ambar = Colors.amber;
  static const ambarAccent = Colors.amberAccent;

  // ROJOS Y VERDES
  static const verde = Color(0xFF4CAF50);
  static const verdeAccent400 = Color(0xFF00E676);
  static const rojo = Color(0xFFF44336);
  static const rojo900 = Color(0xFFB71C1C);

  static Color textRedGreen(num number) {
    return number < 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50);
  }

  static Color backgroundRedGreen(num number) {
    return number < 0 ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7);
  }
}

/* BOX DECORATION */

class AppBox {
  static const BorderRadius borderRadius8 =
      BorderRadius.all(Radius.circular(8.0));

  static const roundBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
  );

  static BoxDecoration buildBoxDecoration(bool darkTheme) {
    var color =
        darkTheme ? AppColor.gradientDark2 : AppColor.boxLight; // light100
    var colorBorder = darkTheme ? AppColor.gris : AppColor.blanco;
    return BoxDecoration(
      color: color,
      border: Border.all(color: colorBorder, width: 1),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  static const BoxDecoration lightGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      stops: [0.2, 0.5, 0.8, 0.7],
      colors: [
        AppColor.gradientLight1,
        AppColor.gradientLight2,
        AppColor.gradientLight3,
        AppColor.gradientLight4
      ],
    ),
  );

  static const BoxDecoration darkGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      stops: [0.2, 0.5, 0.8, 0.7],
      colors: [
        AppColor.gradientDark1,
        AppColor.gradientDark2,
        AppColor.gradientDark3,
        AppColor.gradientDark4
      ],
    ),
  );
}

/* MARKDOWN */

class AppMarkdown {
  static MarkdownStyleSheet buildMarkdownStyleSheet(bool darkTheme) {
    var colorH = darkTheme ? AppColor.dark200 : AppColor.light;
    return MarkdownStyleSheet(
      h1: TextStyle(color: colorH, fontSize: 40),
      h2: TextStyle(color: colorH, fontSize: 22),
      h3: TextStyle(color: colorH, fontSize: 20),
      p: const TextStyle(fontSize: 18),
      blockquoteDecoration: BoxDecoration(
        color: darkTheme ? AppColor.dark : AppColor.blanco,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}
