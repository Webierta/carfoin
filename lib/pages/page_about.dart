import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/my_drawer.dart';

class PageAbout extends StatelessWidget {
  const PageAbout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      body: const Text('ABOUT'),
    );
  }
}
