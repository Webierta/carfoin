import 'package:flutter/material.dart';

import '../../themes/styles_theme.dart';
import '../../utils/number_util.dart';
import 'models.dart';

class ListTileDestacado extends StatelessWidget {
  final Destacado destacado;
  final IconData icon;
  final Function goFondo;
  const ListTileDestacado(
      {super.key,
      required this.destacado,
      required this.icon,
      required this.goFondo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColor.light,
                          //color: Colors.transparent,
                          //shadows: [const Shadow(offset: Offset(0, -4), color: Colors.black)],
                        ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.business_center, color: AppColor.negro54),
                    const SizedBox(width: 4),
                    Text(
                      destacado.cartera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColor.negro54,
                          ),
                    ),
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
            style: TextStyle(
                fontSize: 16, color: AppColor.textRedGreen(destacado.tae)),
          ),
        ],
      ),
    );
  }
}
