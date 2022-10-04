import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/cartera_provider.dart';
import 'models/preferences_provider.dart';
import 'router/app_router.dart';
import 'utils/styles.dart';

Future main() async {
  Provider.debugCheckInvalidValueType = null;
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarteraProvider()),
        Provider<PreferencesProvider>(create: (_) => PreferencesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = AppRouter().router;
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
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: blue,
        /*colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color(0xFFFFC107)),*/
        colorScheme: const ColorScheme(
          primary: blue,
          secondary: amber,
          surface: grisOp,
          background: Colors.transparent,
          error: red900,
          onPrimary: Colors.white,
          onSecondary: blue900,
          onSurface: blue900,
          onBackground: blue900,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: blue900),
          //actionsIconTheme: IconThemeData(color: Colors.red),
          foregroundColor: blue900,
          //titleTextStyle: TextStyle(color: blue900),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: blue900,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        //iconTheme: const IconThemeData(color: Colors.red),
        cardTheme: CardTheme(
          //color: const Color.fromRGBO(255, 255, 255, 0.5),
          color: grisOp,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: amber,
          foregroundColor: blue900,
        ),
      ),
    );
  }
}
