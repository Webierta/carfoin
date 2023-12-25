import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes_const.dart';

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, this.error = 'Error'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => context.go(homePage),
              child: const Text('Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
