import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/styles.dart';

class VistaCompacta extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function goCartera;
  const VistaCompacta(
      {Key? key,
      required this.cartera,
      required this.delete,
      required this.goCartera})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: bgDismissible,
      onDismissed: (_) => delete(cartera),
      child: Card(
        child: ListTile(
          onTap: () => goCartera(context, cartera),
          enabled: true,
          leading: CircleAvatar(
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
          title: Text(
            cartera.name,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
