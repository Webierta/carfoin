import '../pages/page_input_fondo.dart';
import '../pages/page_input_range.dart';
import '../pages/page_search_fondo.dart';
import 'error_screen.dart';

enum AppPage {
  home,
  cartera,
  fondo,
  searchFondo,
  inputFondo,
  inputRange,
  mercado,
  info,
  about,
  support,
  settings,
}

extension AppPageExtension on AppPage {
  String get routePath {
    switch (this) {
      case AppPage.home:
        return '/';
      case AppPage.cartera:
        return '/cartera';
      case AppPage.fondo:
        return '/fondo';
      case AppPage.searchFondo:
        return 'searchFondo';
      case AppPage.inputFondo:
        return 'inputFondo';
      case AppPage.inputRange:
        return 'inputRange';
      case AppPage.mercado:
        return '/mercado';
      case AppPage.info:
        return '/info';
      case AppPage.about:
        return '/about';
      case AppPage.support:
        return '/support';
      case AppPage.settings:
        return '/settings';
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
        //return const PageHome();
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
