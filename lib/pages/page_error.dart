import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_helper.dart';

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
            //mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Center(
                child: Text(
                  'ERROR: ARCHIVO CORRUPTO',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
              const Text('El archivo de la base de datos está dañado y será eliminado. '
                  'Todos los datos de las carteras, fondos, valores y operaciones se perderán.'),
              const SizedBox(height: 20),
              const Text(
                  'Una posible causa de este error es que no se reconoce un archivo importado '
                  '(porque ha sido manipulado o creado con otra aplicación).'),
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