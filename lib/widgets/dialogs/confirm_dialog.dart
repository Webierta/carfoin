import 'package:flutter/material.dart';

class ConfirmDialog {
  final BuildContext context;
  final String title;
  final String content;
  final String? falseButton;

  const ConfirmDialog(
      {required this.context,
      required this.title,
      required this.content,
      this.falseButton});

  generateDialog() {
    return showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: AlertDialog(
              //scrollable: ,
              title: Text(title),
              content: content != '' ? Text(content) : null,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                if (falseButton != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(falseButton!),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
