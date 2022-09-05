import 'package:flutter/material.dart';

import '../../utils/fecha_util.dart';
import '../../utils/styles.dart';
import 'konstantes_global.dart';
import 'models.dart';

class ListTileLastOp extends StatelessWidget {
  final LastOp lastOp;
  final Function goFondo;
  const ListTileLastOp({Key? key, required this.lastOp, required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      //onTap: () => goFondo(context, lastOp.cartera, lastOp.fondo),
      //selected: true,
      //selectedColor: Colors.white,
      //leading: Text(FechaUtil.epochToString(lastOp.valor.date)),
      leading: Icon(
        lastOp.valor.tipo == 1 ? Icons.add_circle : Icons.remove_circle,
        color: blue900,
      ),
      title: InkWell(
        onTap: () => goFondo(context, lastOp.cartera, lastOp.fondo),
        child: Text(
          lastOp.fondo.name,
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
              lastOp.cartera.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      //TODO: hacerlo columna para evitar overflow ??
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          FechaUtil.epochToString(lastOp.valor.date),
          style: const TextStyle(color: Color(0xFF000000)),
        ),
      ),
      /*trailing: Text(
        NumberUtil.decimalFixed(
            lastOp.valor.precio * lastOp.valor.participaciones!,
            long: false),
        style: TextStyle(
            color: lastOp.valor.tipo == 1 ? Colors.green : Colors.red),
      ),*/
    );
  }
}
