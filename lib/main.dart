import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/cartera_provider.dart';
import 'models/preferences_provider.dart';
import 'router/app_router.dart';
import 'themes/theme.dart';
import 'themes/theme_pref.dart';
import 'themes/theme_provider.dart';

Future main() async {
  Provider.debugCheckInvalidValueType = null;
  WidgetsFlutterBinding.ensureInitialized();
  bool theme = await ThemePref().getTheme();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarteraProvider()),
        Provider<PreferencesProvider>(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(themePref: theme)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter().router;
    return Consumer<ThemeProvider>(
        builder: (BuildContext context, value, child) {
      return MaterialApp.router(
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES')],
        debugShowCheckedModeBanner: false,
        title: 'Carfoin',
        theme: const AppTheme(isDark: false).themeData,
        darkTheme: const AppTheme(isDark: true).themeData,
        themeMode: value.darkTheme ? ThemeMode.dark : ThemeMode.light,
      );
    });
  }
}
