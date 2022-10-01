import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry/sentry.dart';

import 'models/cartera_provider.dart';
import 'models/preferences_provider.dart';
import 'router/app_router.dart';
import 'utils/styles.dart';

const String _dsn =
    'https://9388fe715b9e4ce0bf7b41fd3e040eb7@o4503907179233280.ingest.sentry.io/4503907197517824';

Future main() async {
  Provider.debugCheckInvalidValueType = null;
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Sentry.init(
    (options) {
      options.dsn = _dsn;
      options.tracesSampleRate = 1.0;
      options.maxAttachmentSize = 5 * 1024 * 1024;
    },
    appRunner: () => runApp,
  );

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
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color(0xFFFFC107)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF0D47A1),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: blue900,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        cardTheme: CardTheme(
          color: const Color.fromRGBO(255, 255, 255, 0.5),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}
