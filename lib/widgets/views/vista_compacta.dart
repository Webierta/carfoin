import 'package:flutter/material.dart';

import '../../models/cartera.dart';

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
      background: Container(
        color: const Color(0xFFF44336),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.delete, color: Color(0xFFFFFFFF)),
        ),
      ),
      onDismissed: (_) => delete(cartera),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InputChip(
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            avatar: CircleAvatar(
              backgroundColor: const Color(0xFFFFC107),
              child: Text(
                cartera.name[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            backgroundColor: const Color(0xFFBBDEFB),
            label: Text(cartera.name),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2196F3),
            ),
            onPressed: () => goCartera(context, cartera)),
      ),
    );
  }
}
