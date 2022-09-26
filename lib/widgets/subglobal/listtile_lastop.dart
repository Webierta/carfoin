import 'package:flutter/material.dart';

import '../../utils/fecha_util.dart';
import '../../utils/styles.dart';
import 'models.dart';

class ListTileLastOp extends StatelessWidget {
  final LastOp lastOp;
  final Function goFondo;
  const ListTileLastOp({Key? key, required this.lastOp, required this.goFondo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(lastOp.valor.tipo == 1 ? Icons.add_circle : Icons.remove_circle,
              color: blue900),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                    onTap: () => goFondo(context, lastOp.cartera, lastOp.fondo),
                    child: Text(
                      lastOp.fondo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: blue,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(offset: Offset(0, -4), color: Colors.black)
                        ],
                      ),
                    )),
                Row(
                  children: [
                    const Icon(Icons.business_center, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      lastOp.cartera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            FechaUtil.epochToString(lastOp.valor.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF000000)),
          ),
        ],
      ),
    );
  }
}
