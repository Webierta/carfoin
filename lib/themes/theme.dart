import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'styles_theme.dart';

class AppTheme {
  final bool isDark;
  const AppTheme({required this.isDark});

  ThemeData get themeData {
    //TextTheme txtTheme =(isDark ? ThemeData.dark() : ThemeData.light(useMaterial3: true)).textTheme;

    ColorScheme colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColor.dark : AppColor.light,
      secondary: AppColor.ambar,
      surface: isDark ? AppColor.dark700 : AppColor.light,
      background: Colors.transparent,
      error: AppColor.rojo900,
      onPrimary: AppColor.blanco,
      onSecondary: AppColor.light900,
      onSurface: isDark ? AppColor.blanco : AppColor.light900,
      onBackground: isDark ? AppColor.blanco : AppColor.light900,
      onError: AppColor.blanco,
    );

    IconThemeData iconTheme =
        IconThemeData(color: isDark ? AppColor.blanco : AppColor.light900);

    Typography typography = Typography(
      black: AppText.textTheme(AppColor.light900),
      white: AppText.textTheme(AppColor.blanco),
      //black: AppText(color: AppColor.light900).textTheme,
      //white: AppText(color: AppColor.blanco).textTheme,
    );

    AppBarTheme appBarTheme = AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme:
          IconThemeData(color: isDark ? AppColor.blanco : AppColor.light900),
      foregroundColor: isDark ? AppColor.blanco : AppColor.light900,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: isDark ? AppColor.blanco : AppColor.light900,
        statusBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    CardTheme cardTheme = CardTheme(
      color: isDark ? AppColor.darkAlfa : AppColor.grisAlfa,
      elevation: 0.0,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColor.blanco),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    ListTileThemeData listTileTheme = ListTileThemeData(
      iconColor: isDark ? AppColor.blanco : AppColor.light900,
    );

    DialogTheme dialogTheme = DialogTheme(
      backgroundColor: isDark ? AppColor.gradientDark2 : AppColor.blanco,
      elevation: 10,
    );

    TextButtonThemeData textButtonTheme =
        TextButtonThemeData(style: ButtonStyle(
      foregroundColor: MaterialStateColor.resolveWith((state) {
        if (state.contains(MaterialState.disabled)) {
          return AppColor.gris;
        }
        return isDark ? AppColor.blanco : AppColor.light900;
      }),
    ));

    ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColor.dark900 : AppColor.blanco,
      ),
    );

    SwitchThemeData switchTheme = SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((state) {
        if (state.contains(MaterialState.selected)) {
          return isDark ? AppColor.ambarAccent : AppColor.lightAccent;
        }
        return AppColor.blanco;
      }),
      trackColor: MaterialStateProperty.resolveWith((state) {
        if (state.contains(MaterialState.selected)) {
          return isDark ? AppColor.ambar : AppColor.light;
        }
        return AppColor.gris;
      }),
    );

    ChipThemeData chipTheme = ChipThemeData(
      backgroundColor: isDark ? AppColor.dark700 : AppColor.light100,
      labelStyle:
          TextStyle(color: isDark ? AppColor.dark100 : AppColor.light900),
      iconTheme:
          IconThemeData(color: isDark ? AppColor.dark100 : AppColor.light900),
      brightness: isDark ? Brightness.dark : Brightness.light,
      side: BorderSide(
          color: isDark ? AppColor.dark100 : AppColor.light900, width: 0.7),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0))),
      padding: const EdgeInsets.only(left: 4),
    );

    PopupMenuThemeData popupMenuTheme = PopupMenuThemeData(
      color: isDark ? AppColor.boxDark : AppColor.blanco,
      textStyle:
          TextStyle(color: isDark ? AppColor.dark100 : AppColor.light900),
      elevation: 10,
    );

    FloatingActionButtonThemeData floatingActionButtonTheme =
        const FloatingActionButtonThemeData(
      backgroundColor: AppColor.ambar,
      foregroundColor: AppColor.light900,
    );

    ExpansionTileThemeData expansionTileTheme = ExpansionTileThemeData(
      childrenPadding: const EdgeInsets.only(bottom: 5, left: 20),
      expandedAlignment: Alignment.topLeft,
      iconColor: isDark ? AppColor.blanco : AppColor.light,
      collapsedIconColor: isDark ? AppColor.blanco : AppColor.light,
      tilePadding: const EdgeInsets.all(0.0),
    );

    return ThemeData(
      useMaterial3: true,
      typography: typography,
      primaryColor: isDark ? AppColor.dark : AppColor.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      iconTheme: iconTheme,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      listTileTheme: listTileTheme,
      dialogTheme: dialogTheme,
      textButtonTheme: textButtonTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      switchTheme: switchTheme,
      chipTheme: chipTheme,
      popupMenuTheme: popupMenuTheme,
      floatingActionButtonTheme: floatingActionButtonTheme,
      expansionTileTheme: expansionTileTheme,
    );
  }
}
