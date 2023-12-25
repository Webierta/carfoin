import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/routes_const.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/konstantes.dart';
import '../widgets/my_drawer.dart';

class PageAbout extends StatelessWidget {
  const PageAbout({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;

    void launchweb(url) async {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => false,
      child: Container(
        decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ABOUT'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(homePage),
              ),
            ],
          ),
          drawer: const MyDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Markdown(
              onTapLink: (String text, String? url, String title) {
                if (text != 'donación') {
                  launchweb(url!);
                } else {
                  context.go(supportPage);
                }
              },
              data: mdstring,
              styleSheet: AppMarkdown.buildMarkdownStyleSheet(darkTheme),
            ),
          ),
        ),
      ),
    );
  }
}

const String mdstring = """
## Autor y Licencia

> Versión $kVersion
> Copyleft 2022
> Jesús Cuerda (Webierta)
> All Wrongs Reserved. Licencia GPLv3

Esta app se comparte libremente bajo las condiciones de la *GNU General Public License v.3* con la esperanza de que sea útil, pero SIN NINGUNA GARANTÍA. Este programa es **software libre**: usted puede redistribuirlo y / o modificarlo bajo los términos de la Licencia Pública General GNU publicada por la Fundación para el Software Libre, versión 3 (GPLv3). La Licencia Pública General de GNU no permite incorporar este programa en programas propietarios.

Se agradece cualquier sugerencia, crítica, comentario o aviso de error: [contacto vía GitHub](https://github.com/Webierta/carfoin/issues).

Si te gusta esta aplicación, por favor considera hacer una [donación](). Gracias.

Esta App para Android está inspirada en otra aplicación del mismo autor, Carfoin\$ (2015), utilidad multiplataforma desarrollada con Python, proyecto totalmente abandonado en la actualidad.

---

## Fuente de los datos y Permisos

A partir de la versión 3.0.0 ha cambiado la fuente de los datos por dejar de estar disponible la API utilizada previamente. Ahora esta app utiliza la API de código abierto *Yahoo Finance Data Reader* para obtener información de los mercados (Yahoo Finance) y elabora cálculos propios a partir de esos datos.

Por tanto, esta aplicación requiere conexión a internet para recabar la información y depende de la disponibilidad de ese servidor y de la funcionalidad de esa API. Esta aplicación no tiene ninguna vinculación oficial con Yahoo Finance.

Además, la aplicación obtiene la cotización del Dólar a través de Frankfurter, una API de código abierto para tipos de cambio de divisas publicados por el Banco Central Europeo. Los datos se actualizan todos los días laborables en torno a las 16:00 CET. Esto se utiliza para combinar importes en euros de carteras con distintas divisas (si la cartera no tiene moneda definida se presupone en euros).

Por último, la app accede a los documentos de los Fondos desde el Portal de la Comisión Nacional de Mercado de Valores (CNMV). Aprovechando el cambio de API, se ha cambiado el visor de archivos PDF pasando de una librería comercial a otra de código abierto con licencia más abierta.

Los únicos permisos que requiere esta App son:

* Acceso a internet (básicamente para buscar fondos y actualizar sus valores; también para actualizar la cotización del dólar).
* Acceso al almacenamiento del dispositivo (para almacenar o rescatar copias de seguridad). Algunas versiones de Android no otorgan permiso para acceder al almacenamiento externo de la tarjeta SD.

Esta aplicación usa una base de datos SQLite. Normalmente Android la cerrará cuando finalice la aplicación, pero si desea asegurarse de liberar recursos y cerrar la base de datos, cierre la aplicación desde la opción <<Salir>>.

Además, solo si ha compartido alguna Cartera, un archivo con extensión cfi (nombre-cartera.cfi) ha quedado almacenado en el directorio temporal de la aplicación. Puede eliminarlo limpiando la caché desde los Ajustes de la aplicación.

---

## Garantía, Seguridad y Privacidad

**Aplicación gratuita y sin publicidad**. No se utiliza ningún dato del usuario. **Software de código abierto** (código fuente en Github), libre de spyware, malware, virus o cualquier proceso que atente contra tu dispositivo o viole tu privacidad. Esta aplicación no extrae ni almacena ninguna información ni requiere ningún permiso extraño, y renuncia a la publicidad y a cualquier mecanismo de seguimiento.

No puede garantizarse que el contenido ofrecido esté libre de errores, ya sean errores en el servidor origen de los datos, en el proceso de acceso a los datos o en su tratamiento, por lo que la información presentada no cuenta con ninguna garantía, ni explícita ni implícita. El usuario acepta expresamente conocer esta circunstancia. La utilización de la información obtenida por esta App se realiza por parte del usuario bajo su propia cuenta y riesgo, correspondiéndole en exclusiva a él responder frente a terceros por daños que pudieran derivarse de ella. *Yahoo Finance* adquierte que *Todos los datos que aparecen en Yahoo Finanzas se brindan únicamente con propósitos informativos y no están destinados a fines comerciales o de inversión*.

El acceso, navegación y uso de los servicios webs de *Yahoo Finance* derivados del uso de la API están sujetos a sus Términos y condiciones y puede implicar la aceptación de su Política de Privacidad y uso Cookies. En concreto, Yahoo EMEA Limited es la empresa responsable de la política de privacidad y tratamiento y protección de los datos recopilados a través de sus servicios.

Frankfurter website doesn't track you. Its content is licensed CC BY NC SA 4.0.

---

## Créditos

### Dependencias:

* API Yahoo Finance Data Reader by incaview.com. License Apache-2.0.
* Printing by nfet.net. License Apache-2.0.
* Frankfurter currency conversion service. MIT License.
* Sentry by sentry.io. License BSD-3-Clause.

### Imágenes:

* Icono de la aplicación: Created by Freepik from [Flaticon](https://www.flaticon.com) (Flaticon License: Free for personal and commercial purpose with attribution).

""";
