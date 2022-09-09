import 'package:flutter/material.dart';

import '../../utils/number_util.dart';
import '../../utils/styles.dart';
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue900),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                    onTap: () =>
                        goFondo(context, destacado.cartera, destacado.fondo),
                    child: Text(
                      destacado.fondo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: blue,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(
                            offset: Offset(0, -4),
                            color: Colors.black,
                          )
                        ],
                      ),
                    )),
                Row(
                  children: [
                    const Icon(Icons.business_center, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(destacado.cartera.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            NumberUtil.percentCompact(destacado.tae),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: textRedGreen(destacado.tae)),
          ),
        ],
      ),
    );
  }
}
