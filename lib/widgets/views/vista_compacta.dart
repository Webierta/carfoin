import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../themes/styles_theme.dart';
import '../background_dismissible.dart';

class VistaCompacta extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function rename;
  final Function goCartera;
  const VistaCompacta(
      {super.key,
      required this.cartera,
      required this.delete,
      required this.rename,
      required this.goCartera});

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
        direction == DismissDirection.endToStart
            ? delete(cartera)
            : rename(context, cartera: cartera);
      },
      child: Card(
        child: ListTile(
          onTap: () => goCartera(context, cartera),
          enabled: true,
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFFFFF),
            child: CircleAvatar(
              backgroundColor: AppColor.ambar,
              child: Text(
                cartera.name[0],
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColor.light900, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Text(cartera.name,
              style: Theme.of(context).textTheme.headlineMedium),
          trailing: const Icon(Icons.swipe, color: AppColor.light100),
        ),
      ),
    );
  }
}
