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
  mercado,
  info,
  about,
  support,
  settings,
  error,
}

extension AppPageExtension on AppPage {
  String get routePath {
    switch (this) {
      case AppPage.home:
        return homePage;
      case AppPage.cartera:
        return carteraPage;
      case AppPage.fondo:
        return fondoPage;
      case AppPage.mercado:
        return mercadoPage;
      case AppPage.infoBalance:
        return infoBalancePage;
      case AppPage.info:
        return infoPage;
      case AppPage.about:
        return aboutPage;
      case AppPage.support:
        return supportPage;
      case AppPage.settings:
        return settingsPage;
      case AppPage.error:
        return errorPage;
      default:
        return homePage;
    }
  }

  String get subRoutePath {
    switch (this) {
      case AppPage.searchFondo:
        return searchFondoSub;
      case AppPage.inputFondo:
        return inputFondoSub;
      case AppPage.inputRange:
        return inputRangeSub;
      default:
        return '/';
    }
  }

  get routeClass {
    switch (this) {
      case AppPage.inputFondo:
        return const PageInputFondo();
      case AppPage.searchFondo:
        return const PageSearchFondo();
      case AppPage.inputRange:
        return const PageInputRange();
      default:
        return const ErrorScreen();
    }
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
