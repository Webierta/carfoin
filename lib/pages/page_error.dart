import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../themes/styles_theme.dart';
import 'page_home.dart';

class PageError extends StatelessWidget {
  const PageError({super.key});

  @override
  Widget build(BuildContext context) {
    DatabaseHelper database = DatabaseHelper();
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Center(
                child: Text(
                  'ERROR: ARCHIVO NO VÁLIDO',
                  style: TextStyle(fontSize: 18, color: AppColor.rojo),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                  'El archivo de la Base de Datos no es válido y será eliminado. '
                  'Todos los datos de las carteras, fondos, valores y operaciones se perderán.'),
              const SizedBox(height: 20),
              const Text(
                  'Posibles causas de este error son una base de datos con una versión no '
                  'compatible, o que no se reconoce un archivo importado.'),
              const SizedBox(height: 20),
              //const Text('La aplicación se reiniciará.'),
              const Text(
                  'Si el problema persiste, contacta con el desarrollador a través de GitHub en:'),
              const SizedBox(height: 10),
              const Center(
                child: Text('https://github.com/Webierta/carfoin/issues'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await database.eliminarDatabase();
                    if (!context.mounted) return;
                    // TODO: REVISAR SIN REINICIAR
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PageHome()),
                    );
                  },
                  child: const Text('CERRAR'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
