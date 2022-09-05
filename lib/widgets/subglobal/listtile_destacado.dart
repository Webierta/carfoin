import 'package:flutter/material.dart';

import '../../utils/number_util.dart';
import '../../utils/styles.dart';
import 'konstantes_global.dart';
import 'models.dart';

class ListTileDestacado extends StatelessWidget {
  final Destacado destacado;
  final IconData icon;
  final Function goFondo;
  const ListTileDestacado(
      {Key? key,
      required this.destacado,
      required this.icon,
      required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      //onTap: () => goFondo(context, destacado.cartera, destacado.fondo),
      //selected: true,
      //selectedColor: Colors.white,
      leading: Icon(icon, color: blue900),
      title: InkWell(
        onTap: () => goFondo(context, destacado.cartera, destacado.fondo),
        child: Text(
          destacado.fondo.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: blue,
            color: Colors.transparent,
            shadows: [Shadow(offset: Offset(0, -4), color: Colors.black)],
          ),
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.business_center),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              destacado.cartera.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          NumberUtil.percentCompact(destacado.tae),
          //'123%',
          //'1234%5678%9123456789',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: textRedGreen(destacado.tae)),
        ),
      ),
    );
  }
}
