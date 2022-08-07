import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/cartera_provider.dart';
import 'router/app_router.dart';
//import 'routes.dart';

Future main() async {
  Provider.debugCheckInvalidValueType = null;
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CarteraProvider())],
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
        //brightness: Brightness.dark,
        //primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFFC107)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        //scaffoldBackgroundColor: const Color(0xFF64B5F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF0D47A1),
          //foregroundColor: Color(0xFFFFFFFF),
        ),
        cardTheme: CardTheme(
          color: const Color.fromRGBO(255, 255, 255, 0.5),
          // 33 150 243
          //color: const Color.fromRGBO(33, 150, 243, 0.1),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      //initialRoute: '/',
      //onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
