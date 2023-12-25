import '../pages/page_input_fondo.dart';
import '../pages/page_input_range.dart';
import '../pages/page_search_fondo.dart';
import 'error_screen.dart';
import 'routes_const.dart';

enum AppPage {
  home,
  cartera,
  fondo,
  searchFondo,
  inputFondo,
  inputRange,
  infoBalance,
  pdf,
  mercado,
  info,
  about,
  support,
  settings,
  error,
  global
}

extension AppPageExtension on AppPage {
  String get routePath {
    return switch (this) {
      AppPage.home => homePage,
      AppPage.cartera => carteraPage,
      AppPage.fondo => fondoPage,
      AppPage.pdf => pdfPage,
      AppPage.mercado => mercadoPage,
      AppPage.infoBalance => infoBalancePage,
      AppPage.info => infoPage,
      AppPage.about => aboutPage,
      AppPage.support => supportPage,
      AppPage.settings => settingsPage,
      AppPage.global => globalPage,
      AppPage.error => errorPage,
      _ => homePage
    };
  }

  String get subRoutePath {
    return switch (this) {
      AppPage.searchFondo => searchFondoSub,
      AppPage.inputFondo => inputFondoSub,
      AppPage.inputRange => inputRangeSub,
      _ => '/'
    };
  }

  get routeClass {
    return switch (this) {
      AppPage.inputFondo => const PageInputFondo(),
      AppPage.searchFondo => const PageSearchFondo(),
      AppPage.inputRange => const PageInputRange(),
      _ => const ErrorScreen()
    };
  }

/* String get routeName {
    switch (this) {
      case AppPage.home:
        return "HOME";
      case AppPage.cartera:
        return "ONBOARD";
      case AppPage.fondo:
        return "AUTH";
      default:
        return "HOME";
    }
  } */

/* String get routePageTitle {
    switch (this) {
      case AppPage.home:
        return "Astha";
      default:
        return "Astha";
    }
  } */
}
