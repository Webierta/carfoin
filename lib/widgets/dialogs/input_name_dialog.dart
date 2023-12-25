import 'package:flutter/material.dart';

class RouterInputName {
  final String title;
  final String? label;
  const RouterInputName({required this.title, this.label});

  PageRouteBuilder<String> builder() {
    return PageRouteBuilder<String>(
      transitionDuration: const Duration(milliseconds: 500),
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (BuildContext context, Animation<double> animation, _) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: animation,
              child: InputNameDialog(title: title, label: label),
            ),
          ),
        );
      },
    );
  }
}

class InputNameDialog extends StatefulWidget {
  final String title;
  final String? label;
  const InputNameDialog({super.key, required this.title, this.label = ''});

  @override
  State<InputNameDialog> createState() => _InputNameDialogState();
}

class _InputNameDialogState extends State<InputNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _errorText {
    final text = _controller.value.text.trim();
    if (text.isEmpty) {
      return 'Campo requerido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, TextEditingValue value, __) {
              return SingleChildScrollView(
                child: AlertDialog(
                  alignment: Alignment.topCenter,
                  insetPadding: const EdgeInsets.only(top: 40),
                  //scrollable: true,
                  title: Text(widget.title),
                  content: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nombre',
                      errorMaxLines: 4,
                      errorText: _errorText,
                      labelText: widget.label,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: _errorText == null
                          ? () {
                              String input = _controller.value.text.trim();
                              Navigator.pop(context, input);
                            }
                          : null,
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
