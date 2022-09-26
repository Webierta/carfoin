import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;

import '../utils/styles.dart';

class LoadingProgress extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const LoadingProgress({Key? key, required this.titulo, this.subtitulo = ''})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: blue900,
      // systemNavigationBarColor / statusBarIconBrightness / systemNavigationBarDividerColor
    ));

    return Loading(titulo: titulo, subtitulo: subtitulo);
  }
}

class Loading extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const Loading({Key? key, required this.titulo, this.subtitulo = ''})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              const Spacer(flex: 1),
              Column(
                children: [
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: blue, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    subtitulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: blue, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
