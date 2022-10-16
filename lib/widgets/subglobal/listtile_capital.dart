import 'package:flutter/material.dart';

import '../../themes/styles_theme.dart';
import '../../utils/number_util.dart';

class ListTileCapital extends StatelessWidget {
  final double inversion;
  final double capital;
  final double balance;
  const ListTileCapital(
      {Key? key, required this.inversion, required this.capital, required this.balance})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.euro),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberUtil.decimalFixed(capital, long: false)} €',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${NumberUtil.decimalFixed(inversion, long: false)} €',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColor.negro54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${NumberUtil.decimalFixed(balance, long: false, limit: 100000)} €',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.textRedGreen(balance),
                ),
          ),
        ],
      ),
    );
  }
}
