import 'package:go_router/go_router.dart';

import '../pages/page_error.dart';
import 'error_screen.dart';
import 'router_utils.dart';

import '../pages/page_about.dart';
import '../pages/page_cartera.dart';
import '../pages/page_fondo.dart';
import '../pages/page_home.dart';
import '../pages/page_info.dart';
import '../pages/page_input_fondo.dart';
import '../pages/page_input_range.dart';
import '../pages/page_search_fondo.dart';
import '../pages/page_settings.dart';
import '../pages/page_mercado.dart';
import '../pages/page_support.dart';

class AppRouter {
  get router => _router;

  final _router = GoRouter(
    //refreshListenable: homePage,
    //debugLogDiagnostics: true,
    //urlPathStrategy: UrlPathStrategy.path,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: AppPage.home.routePath,
        builder: (context, state) => const PageHome(),
      ),
      GoRoute(
        path: AppPage.cartera.routePath,
        //path: '/cartera',
        builder: (context, state) => const PageCartera(),
        routes: [
          GoRoute(
            //path: AppPage.searchFondo.routePath,
            path: 'searchFondo',
            builder: (context, state) => const PageSearchFondo(),
          ),
          GoRoute(
            //path: AppPage.inputFondo.routePath,
            path: 'inputFondo',
            builder: (context, state) => const PageInputFondo(),
          ),
        ],
      ),
      GoRoute(
        path: AppPage.fondo.routePath,
        //path: '/fondo',
        builder: (context, state) => const PageFondo(),
        routes: [
          GoRoute(
            //path: AppPage.inputRange.routePath,
            path: 'inputRange',
            builder: (context, state) => const PageInputRange(),
          ),
        ],
      ),
      GoRoute(
        path: AppPage.mercado.routePath,
        //path: '/mercado',
        builder: (context, state) => const PageMercado(),
      ),
      GoRoute(
        path: AppPage.settings.routePath,
        builder: (context, state) => const PageSettings(),
      ),
      GoRoute(
        path: AppPage.info.routePath,
        builder: (context, state) => const PageInfo(),
      ),
      GoRoute(
        path: AppPage.about.routePath,
        builder: (context, state) => const PageAbout(),
      ),
      GoRoute(
        path: AppPage.support.routePath,
        builder: (context, state) => const PageSupport(),
      ),
      GoRoute(
        path: AppPage.error.routePath,
        builder: (context, state) => const PageError(),
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),

    // TODO Add Redirect
    // redirect: (state) {});
  );
}
