import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/my_drawer.dart';

class PageInfo extends StatelessWidget {
  const PageInfo({Key? key}) : super(key: key);

  static const String titulo = 'CarFoIn!';

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
        child: ListView(
          children: [
            Center(
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
            ),
          ],
        ),
      ),
    );
  }
}
