import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/styles.dart';
import '../background_dismissible.dart';

class VistaCompactaFondos extends StatelessWidget {
  final Fondo fondo;
  final Function updateFondo;
  final Function removeFondo;
  final Function goFondo;
  const VistaCompactaFondos(
      {Key? key,
      required this.fondo,
      required this.updateFondo,
      required this.removeFondo,
      required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: const BackgroundDismissible(
        slide: Slide.right,
        label: 'Actualizar',
        icon: Icons.refresh,
      ),
      secondaryBackground: const BackgroundDismissible(
        slide: Slide.left,
        label: 'Eliminar',
        icon: Icons.delete,
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await removeFondo(fondo);
        } else {
          await updateFondo(fondo);
        }
      },
      child: Card(
        child: ListTile(
          onTap: () => goFondo(context, fondo),
          enabled: true,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFFFFF),
            child: CircleAvatar(
              backgroundColor: amber,
              child: Text(
                fondo.name[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: blue900,
                ),
              ),
            ),
          ),
          title: Text(fondo.name, style: styleTitleCompact),
        ),
      ),
    );
  }
}
