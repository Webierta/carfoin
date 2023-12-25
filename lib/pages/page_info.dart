import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/routes_const.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/my_drawer.dart';

class PageInfo extends StatelessWidget {
  const PageInfo({super.key});

  static const String titulo = 'CARFOIN';

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => false,
      child: Container(
        decoration:
            theme.darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
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

**CARFOIN** es una utilidad para la gestión de múltiples Carteras de Fondos de Inversión. Permite crear fácilmente Carteras personalizadas y seguir su evolución. Opera rápidamente con los fondos para consultar, actualizar y archivar sus valores liquidativos.

Después de crear una Cartera, incorpora los fondos de inversión que te interesa seguir. A partir del nombre del fondo o de su código ISIN, puedes buscar y añadir un nuevo Fondo desde una base de datos local (offline) o bien a través de una búsqueda online:

* La **consulta offline** utiliza una base de datos local de 3775 fondos. La fuente de estos datos es la lista de fondos de inversión no monetarios de España publicada por el Banco de España a fecha de 22/12/2023. Una vez seleccionado un fondo, la app hace una consulta online para intentar obtener la divisa del fondo seleccionado y ajustar su nombre a los datos obtenidos de *Yahoo Finance*.
* La **consulta online** permite buscar un fondo tanto por su código ISIN como por parte de su nombre. Cuando se utiliza el ISIN, el programa utiliza el dígito de control para verificarlo. Cuando se utiliza el nombre del fondo, la aplicación intenta obtener online su código ISIN (si reconoce el fondo pero no es capaz de obtener su código ISIN se recomienda buscarlo en la base de datos local). A diferencia de la consulta offline, la consulta online siempre incluye la divisa del fondo seleccionado.

Después puedes seguir la evolución de los fondos añadidos y, en su caso, la rentabilidad obtenida, actualizando periódicamente su cotización (datos obtenidos de *Yahoo Finance*) y archivando el histórico de valores.

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
* Visualiza y descarga documentos de los fondos: folleto y último infome periódico (formato pdf). Para ampliar la vista del documento pulsa dos veces sobre la página y amplia con dos dedos. Pulsa otra vez dos veces para volver a la vista de páginas.
* Muestra el Rating de Morningstar (actualizado cada mes).
* Hace copias de seguridad del archivo principal del portafolio (base de datos SQLite3).
* Permite compartir carteras con otros usuarios de la App (archivos con extensión cfi).
* Próximamente más funciones...

""";
