import 'package:carfoin/widgets/background_dismissible.dart';
import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/styles.dart';

class VistaCompacta extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function rename;
  final Function goCartera;
  const VistaCompacta(
      {Key? key,
      required this.cartera,
      required this.delete,
      required this.rename,
      required this.goCartera})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      //key: Key(cartera.name),
      background: const BackgroundDismissible(
        slide: Slide.right,
        label: 'Renombrar',
        icon: Icons.edit,
      ),
      secondaryBackground: const BackgroundDismissible(
        slide: Slide.left,
        label: 'Eliminar',
        icon: Icons.delete,
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          delete(cartera);
        } else {
          rename(context, cartera: cartera);
        }
      },
      child: Card(
        child: ListTile(
          onTap: () => goCartera(context, cartera),
          enabled: true,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFFFFF),
            child: CircleAvatar(
              backgroundColor: amber,
              child: Text(
                cartera.name[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: blue900,
                ),
              ),
            ),
          ),
          title: Text(cartera.name, style: styleTitleCompact),
          trailing: const Icon(Icons.swipe, color: blue100),
        ),
      ),
    );
  }
}
