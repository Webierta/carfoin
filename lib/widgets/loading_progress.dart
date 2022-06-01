import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoadingProgress extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const LoadingProgress({Key? key, required this.titulo, this.subtitulo = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0D47A1),
      // systemNavigationBarColor / statusBarIconBrightness / systemNavigationBarDividerColor
    ));

    return Loading(titulo: titulo, subtitulo: subtitulo);
  }
}

class Loading extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const Loading({Key? key, required this.titulo, this.subtitulo = ''}) : super(key: key);

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
                  Text(titulo, style: const TextStyle(color: Color(0xFF2196F3), fontSize: 18)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 20),
                  Text(subtitulo, style: const TextStyle(color: Color(0xFF2196F3), fontSize: 14)),
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
