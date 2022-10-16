import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/routes_const.dart';
import '../services/database_helper.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/konstantes.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Drawer(
      child: Container(
        decoration: theme.darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.fill,
                        image: AssetImage('assets/drawer_header.png'),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'CARFOIN',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: const Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w100,
                                  ),
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'CARTERA DE FONDOS DE INVERSIÓN',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: const Color(0xFFFFFFFF)),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Copyleft 2022',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: const Color(0xFFFFFFFF)),
                        ),
                        Text(
                          'Jesús Cuerda (Webierta)',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: const Color(0xFFFFFFFF)),
                        ),
                        Text(
                          'All Wrongs Reserved. Licencia GPLv3',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: const Color(0xFFFFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Inicio'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(homePage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cases_rounded),
                    title: const Text('Portafolio'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(globalPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Ajustes'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(settingsPage);
                    },
                  ),
                  const Divider(color: AppColor.gris),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Info'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(infoPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(aboutPage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_cafe_outlined),
                    title: const Text('Donar'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(supportPage);
                    },
                  ),
                  const Divider(color: AppColor.gris),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Salir'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      DatabaseHelper database = DatabaseHelper();
                      await database.close();
                      SystemNavigator.pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppColor.gris),
            Container(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Versión $kVersion',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
