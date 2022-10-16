import 'package:flutter/material.dart';

import '../../themes/styles_theme.dart';

class FullScreenModal extends ModalRoute {
  final String title;
  final Widget data;
  FullScreenModal({required this.title, required this.data});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.8);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColor.blanco),
          ),
          backgroundColor: AppColor.negro,
          foregroundColor: AppColor.blanco,
          //iconTheme: IconThemeData(color: Colors.white),
          //actionsIconTheme: IconThemeData(color: Colors.white),
          //titleTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          title: Text(title),
        ),
        body: DefaultTextStyle(
          style: const TextStyle(color: AppColor.blanco),
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [data],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(animation),
        child: ScaleTransition(scale: animation, child: child),
      ),
    );
  }
}
