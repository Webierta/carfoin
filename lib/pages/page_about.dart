import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../widgets/my_drawer.dart';

class PageAbout extends StatelessWidget {
  const PageAbout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /*Future<void> _launchInBrowser(Uri url) async {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Could not launch $url';
      }
    }*/

    void _launchUrl(url) async {
      if (!await launchUrl(url)) throw 'Could not launch $url';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              Navigator.of(context).pushNamed(RouteGenerator.homePage);
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Markdown(
          onTapLink: (String text, String? url, String title) {
            if (text != 'donación') {
              _launchUrl(Uri.parse(url!));
            } else {
              //Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteGenerator.supportPage);
            }
          },
          data: mdstring,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(color: Colors.blue, fontSize: 40),
            h2: const TextStyle(color: Colors.blue, fontSize: 22),
            p: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

const String mdstring = """
## Autor y Licencia

> Versión 1.0.0
> Copyleft 2022
> Jesús Cuerda (Webierta)
> All Wrongs Reserved. Licencia GPLv3

Esta app se comparte libremente bajo las condiciones de la *GNU General Public License v.3* con la esperanza de que sea útil, pero SIN NINGUNA GARANTÍA. Este programa es **software libre**: usted puede redistribuirlo y / o modificarlo bajo los términos de la Licencia Pública General GNU publicada por la Fundación para el Software Libre, versión 3 (GPLv3). La Licencia Pública General de GNU no permite incorporar este programa en programas propietarios.

Se agradece cualquier sugerencia, crítica, comentario o aviso de error: [Contacto vía GitHub](https://github.com/Webierta/carfoin/issues).

Si te gusta esta aplicación, por favor considera hacer una [donación](). Gracias.

## Fuente de los datos y Permisos

Esta App utiliza información extraída de *Financial Times (FT) Markets Data* y otros cálculos de elaboración propia a partir de esos datos. Para la descarga de esos datos se utiliza la *API Funds (v1) by rpi4g* disponible en *rapidAPI*.

Por tanto, esta aplicación requiere conexión a internet para recabar la información y depende de la disponibilidad de ese servidor y de la funcionalidad de esa API. Esta aplicación no tiene ninguna vinculación oficial con Financial Times.

## Garantía, Seguridad y Privacidad

**Aplicación gratuita y sin publicidad**. No se utiliza ningún dato del usuario. **Software de código abierto** (código fuente en Github), libre de spyware, malware, virus o cualquier proceso que atente contra tu dispositivo o viole tu privacidad. Esta aplicación no extrae ni almacena ninguna información ni requiere ningún permiso extraño, y renuncia a la publicidad y a cualquier mecanismo de seguimiento.

No puede garantizarse que el contenido ofrecido esté libre de errores, ya sean errores en el servidor origen de los datos, en el proceso de acceso a los datos o en su tratamiento, por lo que la información presentada no cuenta con ninguna garantía, ni explícita ni implícita. El usuario acepta expresamente conocer esta circunstancia. La utilización de la información obtenida por esta App se realiza por parte del usuario bajo su propia cuenta y riesgo, correspondiéndole en exclusiva a él responder frente a terceros por daños que pudieran derivarse de ella.

El acceso, navegación y uso de los servicios webs (FT) derivados del uso de la API está sujeta a sus Términos y condiciones y puede implicar la aceptación de su Política de Privacidad y uso Cookies. En concreto, FT advierte que *All content on FT.com is for your general information and use only and is not intended to address your particular requirements. In particular, the content does not constitute any form of advice, recommendation, representation, endorsement or arrangement by FT and is not intended to be relied upon by users in making (or refraining from making) any specific investment or other decisions. Any information that you receive via FT.com is at best delayed intraday data and not "real time". Share price information may be rounded up/down and therefore not entirely accurate. FT is not responsible for any use of content by you outside its scope as stated in the FT Terms & Conditions*.

""";
