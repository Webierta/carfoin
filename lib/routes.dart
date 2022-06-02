import 'package:flutter/material.dart';

import 'pages/page_about.dart';
import 'pages/page_cartera.dart';
import 'pages/page_home.dart';
import 'pages/page_info.dart';
import 'pages/page_input_fondo.dart';
import 'pages/page_search_fondo.dart';
import 'pages/page_settings.dart';

class RouteGenerator {
  static const String homePage = '/';
  static const String carteraPage = '/cartera';
  static const String fondoPage = '/fondo';
  static const String searchFondo = '/searchFondo';
  static const String inputFondo = '/inputFondo';
  static const String inputRange = '/inputRange';
  static const String mercadoPage = '/mercado';
  static const String infoPage = '/info';
  static const String aboutPage = '/about';
  static const String settingsPage = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homePage:
        return AnimatedRoute(const PageHome());
      case carteraPage:
        return AnimatedRoute(const PageCartera());
      //case fondoPage:
      //return AnimatedRoute(const PageFondo());
      case searchFondo:
        return AnimatedRoute(const PageSearchFondo());
      /*case inputFondo:
        return AnimatedRoute(const PageInputFondo());*/
      /*case inputRange:
        return AnimatedRoute(const PageInputRange());
      case mercadoPage:
        return AnimatedRoute(const PageMercado());*/
      case infoPage:
        return AnimatedRoute(const PageInfo());
      case aboutPage:
        return AnimatedRoute(const PageAbout());
      case settingsPage:
        return AnimatedRoute(const PageSettings());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: const Text('ERROR'), centerTitle: true),
        body: const Center(
          child: Text('Página no encontrada!'),
        ),
      );
    });
  }
}

class AnimatedRoute extends PageRouteBuilder {
  final Widget page;

  AnimatedRoute(this.page)
      : super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return page;
          },
          transitionsBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> anotherAnimation, Widget child) {
            animation = CurvedAnimation(
              curve: Curves.linear,
              parent: animation,
            );
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
