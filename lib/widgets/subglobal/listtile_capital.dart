import 'package:flutter/material.dart';

import '../../utils/number_util.dart';
import '../../utils/styles.dart';
import 'konstantes_global.dart';

class ListTileCapital extends StatelessWidget {
  final double inversion;
  final double capital;
  final double balance;
  final String divisa;
  final IconData icon;
  const ListTileCapital(
      {Key? key,
      required this.inversion,
      required this.capital,
      required this.balance,
      required this.divisa,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      //contentPadding: const EdgeInsets.only(left: 0.0, right: 10.0),
      minLeadingWidth: minLeadingWidth0,
      horizontalTitleGap: horizontalTitleGap10,
      leading: Icon(icon, color: blue900),
      title: Row(
        children: [
          Text(
            '${NumberUtil.decimalFixed(capital, long: false)} $divisa',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            '${NumberUtil.decimalFixed(inversion, long: false)} $divisa',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: trailingMaxWidth80),
        child: Text(
          '${NumberUtil.decimalFixed(balance, long: false, limit: 100000)} $divisa',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: textRedGreen(balance)),
        ),
      ),
    );
  }
}
