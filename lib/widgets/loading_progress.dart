import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';

class LoadingProgress extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const LoadingProgress({Key? key, required this.titulo, this.subtitulo = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Loading(titulo: titulo, subtitulo: subtitulo);
  }
}

class Loading extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const Loading({Key? key, required this.titulo, this.subtitulo = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: darkTheme ? AppColor.gradientDark2 : AppColor.blanco,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo, textAlign: TextAlign.center),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                        color: darkTheme ? AppColor.blanco : AppColor.light),
                  ),
                ),
                Text(subtitulo, textAlign: TextAlign.center),
                //const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
