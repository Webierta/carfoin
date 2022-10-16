import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/routes_const.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/my_drawer.dart';

class PageInfo extends StatelessWidget {
  const PageInfo({Key? key}) : super(key: key);

  static const String titulo = 'CARFOIN';

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: theme.darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('INFO'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(homePage),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Markdown(
              data: mdstring,
              styleSheet: AppMarkdown.buildMarkdownStyleSheet(theme.darkTheme),
            ),
          ),
        ),
      ),
    );
  }
}

const String mdstring = """
# CARFOIN

## App para la gestión de Carteras de Fondos de Inversión

**CARFOIN** es una utilidad para la gestión de múltiples Carteras de Fondos de Inversión. Permite crear fácilmente Carteras personalizadas y seguir su evolución. Opera rápidamente con los Fondos para consultar, actualizar y archivar sus valores liquidativos.

Después de crear una Cartera, incorpora los Fondos de Inversión que te interesa seguir. Puedes añadir un nuevo Fondo desde una base de datos local o bien online a partir de su código ISIN —el programa utiliza el dígito de control para verificarlo—.

Después puedes seguir la evolución de los Fondos añadidos actualizando periódicamente su cotización y archivando el histórico de valores.

El programa muestra los valores en una tabla y en un gráfico, y además calcula algunos estadísticos de los fondos (valor liquidativo medio, volatilidad...) e índices de rentabilidad acumulada y anualizada (TWR, MWR...). Ten en cuenta que estos cálculos dependen de los valores descargados y por tanto no son valores absolutos del fondo.

---

## Funciones principales:

* Permite crear múltiples Carteras personalizadas de Fondos de Inversión y seguir su evolución.
* Verifica el código ISIN de los Fondos con el dígito de control.
* Actualiza vía internet la última cotización o un intervalo de tiempo y archiva los valores liquidativos obtenidos.
* Presenta los datos mediante tablas y gráficos y calcula algunos índices estadísticos.  
* Permite simular operaciones de suscripción y reembolso para seguir la evolución del capital invertido y su rentabilidad (TWR y MWR).
* Vista resumida y gráfica de la posición global del portafolio.
* Obtiene la cotización del Dólar para comparar carteras con distintas divisas.
* Visualiza y descarga documentos de los fondos: folleto y último infome periódico (formato pdf).
* Muestra el Rating de Morningstar (actualizado cada mes).
* Hace copias de seguridad del archivo principal del portafolio (base de datos SQLite3).
* Permite compartir carteras con otros usuarios de la App (archivos con extensión cfi).
* Próximamente más funciones...

""";
