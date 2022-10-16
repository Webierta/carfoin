import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_helper.dart';
import '../themes/styles_theme.dart';

class PageError extends StatelessWidget {
  const PageError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DatabaseHelper database = DatabaseHelper();
    return SafeArea(
      child: Scaffold(
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
              const Text('El archivo de la Base de Datos no es válido y será '
                  'eliminado. Todos los datos de las carteras, fondos, valores y operaciones se perderán.'),
              const SizedBox(height: 20),
              const Text('Posibles causas de este error son una base de datos '
                  'con una versión no compatible, o que no se reconoce un archivo importado.'),
              const SizedBox(height: 20),
              const Text('La aplicación se reiniciará.'),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final String dbPath = await database.getDatabasePath();
                    await deleteDatabase(dbPath);
                    Restart.restartApp();
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
