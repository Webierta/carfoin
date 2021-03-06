import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../routes.dart';
import '../widgets/my_drawer.dart';

class PageInfo extends StatelessWidget {
  const PageInfo({Key? key}) : super(key: key);

  static const String titulo = 'CARFOIN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INFO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              Navigator.of(context).pushNamed(RouteGenerator.homePage);
            },
          ),
        ],
        /* leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),*/

        /*actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],*/
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Markdown(
          data: mdstring,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(color: Colors.blue, fontSize: 40),
            h2: const TextStyle(color: Colors.blue, fontSize: 22),
            p: const TextStyle(fontSize: 18),
          ),
        ),
        /*child: ListView(
          children: [
            */ /*Center(
              child: Stack(
                children: <Widget>[
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 40,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 6
                        ..color = Colors.blue[700]!,
                    ),
                  ),
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 40, color: Colors.grey[300]),
                  ),
                ],
              ),
            ),*/ /*
            Container(
              child: Markdown(
                data: mdstring,
                */ /*styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(color: Colors.blue, fontSize: 40),
                ),*/ /*
              ),
            ),
          ],
        ),*/
      ),
    );
  }
}

const String mdstring = """
# CARFOIN

## App para la gesti??n de Carteras de Fondos de Inversi??n

**CARFOIN** es una utilidad para la gesti??n de m??ltiples Carteras de Fondos de Inversi??n. Permite crear f??cilmente Carteras personalizadas y seguir su evoluci??n. Opera r??pidamente con los Fondos para consultar, actualizar y archivar sus valores liquidativos.

Despu??s de crear una Cartera, incorpora los Fondos de Inversi??n que te interesa seguir. Puedes a??adir un nuevo Fondo desde la base de datos que incorpora el programa o bien online a partir de su c??digo ISIN ???el programa utiliza el d??gito de control para verificarlo???. Se incluyen algunos Fondos a modo de demostraci??n, puedes eliminarlos.

Despu??s puedes seguir la evoluci??n de los Fondos a??adidos actualizando peri??dicamente su cotizaci??n y archivando el hist??rico de valores. El programa calcula algunos ??ndices de rentabilidad y muestra los valores en una tabla y en un gr??fico.

---

## Funciones

* Permite crear m??ltiples Carteras personalizadas de Fondos de Inversi??n y seguir su evoluci??n.
* Verifica el c??digo ISIN de los Fondos con el d??gito de control.
* Actualiza v??a internet la ??ltima cotizaci??n o un intervalo de tiempo y archiva los valores liquidativos obtenidos.
* Consulta la evoluci??n de los valores guardados y muestra algunos ??ndices de rentabilidad.
* Permite simular operaciones de suscripci??n y reembolso para seguir la evoluci??n del capital invertido.
* Hace copias de seguridad de las Carteras y exporta el hist??rico de valores a un archivo csv para abrir con hoja de c??lculo.
* Pr??ximamente m??s funciones...

""";
