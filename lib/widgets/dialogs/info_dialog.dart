import 'package:flutter/material.dart';

class InfoDialog {
  final BuildContext context;
  final String title;
  final Widget content;

  const InfoDialog(
      {required this.context, required this.title, required this.content});

  generateDialog() async {
    await showDialog<void>(
      barrierDismissible: false,
      useSafeArea: true,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: SingleChildScrollView(
            child: AlertDialog(
              // insetPadding: const EdgeInsets.all(10),
              title: Text(title),
              content: content,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
