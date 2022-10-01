import 'package:flutter/material.dart';

import '../utils/styles.dart';

class LoadingProgress extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const LoadingProgress({Key? key, required this.titulo, this.subtitulo = ''})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: blue, fontSize: 18),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(),
                  ),
                ),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: blue, fontSize: 14),
                ),
                //const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
