import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/routes_const.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/my_drawer.dart';

const String btcAddress = '15ZpNzqbYFx9P7wg4U438JMwZr2q3W6fkS';
const String urlPayPal =
    'https://www.paypal.com/donate?hosted_button_id=986PSAHLH6N4L';
const String urlGitHub = 'https://github.com/Webierta/carfoin/issues';

class PageSupport extends StatelessWidget {
  const PageSupport({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    void launchweb(url) async {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    }

    void showMsg({required String msg, Color? color}) =>
        CustomMessenger(context: context, msg: msg, color: color)
            .generateDialog();

    clipboard() async {
      await Clipboard.setData(const ClipboardData(text: btcAddress));
      showMsg(msg: 'BTC Address copied to Clipboard');
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => false,
      child: Container(
        decoration:
            theme.darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('Buy Me a Coffee'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(homePage),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 40),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'CARFOIN es Software libre y de Código Abierto. '
                    'Por favor considera colaborar para mantener activo el desarrollo de esta App.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 18),
                    text:
                        '¿Crees que has encontrado un problema? Identificar y corregir errores hace que '
                        'esta App sea mejor para todos. Informa de un error o sugiere una nueva funcionalidad en ',
                    children: [
                      TextSpan(
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                        ),
                        text: 'GitHub issues.',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchweb(urlGitHub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Puedes colaborar con el desarrollo de ésta y otras aplicaciones con una pequeña '
                    'aportación a mi monedero de Bitcoins o vía PayPal.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Scan this QR code with your wallet application:',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Image.asset('assets/Bitcoin_QR.png'),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Or copy the BTC Wallet Address:',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: AppBox.borderRadius8,
                        border: Border.all(
                          color: Colors.black12,
                          style: BorderStyle.solid,
                        )),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppBox.borderRadius8,
                        border: Border.all(
                            color: const Color(0xFFFFFFFF), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(8.0),
                            decoration: const ShapeDecoration(
                              color: Color(0xFFF5F5F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  topLeft: Radius.circular(8),
                                  bottomRight: Radius.zero,
                                  topRight: Radius.zero,
                                ),
                                side: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.center,
                              child: Text(
                                btcAddress,
                                style: TextStyle(color: AppColor.dark700),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 50,
                            child: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => clipboard(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: Text(
                      'Donar vía PayPal (abre el sitio web de pago de PayPal):',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: ElevatedButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      elevation: 10.0,
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: () => launchweb(urlPayPal),
                    child: Image.asset('assets/paypal_logo.png'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
