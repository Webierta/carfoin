import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/number_util.dart';
import '../../utils/stats.dart';
import '../../utils/styles.dart';

class VistaDetalle extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function goCartera;
  final Function inputName;
  final Function goFondo;

  const VistaDetalle({
    Key? key,
    required this.cartera,
    required this.delete,
    required this.goCartera,
    required this.inputName,
    required this.goFondo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Fondo> fondos = cartera.fondos ?? [];
    double capitalCarteraEur = 0.0;
    double capitalCarteraUsd = 0.0;
    double capitalCarteraOtra = 0.0;
    double rendimientoCarteraEur = 0.0;
    double rendimientoCarteraUsd = 0.0;
    double rendimientoCarteraOtra = 0.0;
    double participacionesCartera = 0.0;
    double taeCartera = 0.0;
    int fondosConTae = 0;

    bool isTrueCapitalCarteraEur = false;
    bool isTrueCapitalCarteraUsd = false;
    bool isTrueCapitalCarteraOtra = false;
    bool isTrueRendCarteraEur = false;
    bool isTrueRendCarteraUsd = false;
    bool isTrueRendCarteraOtra = false;

    if (fondos.isNotEmpty) {
      for (var fondo in fondos) {
        if (fondo.valores != null && fondo.valores!.isNotEmpty) {
          Stats stats = Stats(fondo.valores!);
          double participacionesFondo = stats.totalParticipaciones() ?? 0.0;
          double? twrFondo = stats.twr();
          double? taeFondo;
          if (twrFondo != null) {
            taeFondo = stats.anualizar(twrFondo);
          }
          if (taeFondo != null) {
            fondosConTae++;
            taeCartera += taeFondo;
          }
          participacionesCartera += participacionesFondo;
          if (participacionesFondo > 0) {
            if (fondo.divisa == 'EUR') {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraEur = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraEur = true;
              }
              capitalCarteraEur += stats.resultado() ?? 0.0;
              rendimientoCarteraEur += stats.balance() ?? 0.0;
            } else if (fondo.divisa == 'USD') {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraUsd = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraUsd = true;
              }
              capitalCarteraUsd += stats.resultado() ?? 0.0;
              rendimientoCarteraUsd += stats.balance() ?? 0.0;
            } else {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraOtra = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraOtra = true;
              }
              capitalCarteraOtra += stats.resultado() ?? 0.0;
              rendimientoCarteraOtra += stats.balance() ?? 0.0;
            }
          }
        }
      }
      if (fondosConTae > 0) {
        taeCartera = taeCartera / fondos.length;
      }
    }

    int countItems() {
      int count = 0;
      if (isTrueCapitalCarteraEur && isTrueRendCarteraEur) {
        count++;
      }
      if (isTrueCapitalCarteraUsd && isTrueRendCarteraUsd) {
        count++;
      }
      if (isTrueCapitalCarteraOtra && isTrueRendCarteraOtra) {
        count++;
      }
      return count;
    }

    String selectedValue() {
      if (isTrueCapitalCarteraEur && isTrueRendCarteraEur) {
        return '€';
      }
      if (isTrueCapitalCarteraUsd && isTrueRendCarteraUsd) {
        return '\$';
      }
      return '?';
    }

    List<DropdownMenuItem<String>> getDropdownItems() {
      List<DropdownMenuItem<String>> menuItems = [];
      if (isTrueCapitalCarteraEur && isTrueRendCarteraEur) {
        menuItems.add(DropdownMenuItem(
          value: '€',
          child: ListTileCart(
            capital: capitalCarteraEur,
            balance: rendimientoCarteraEur,
            divisa: '€',
          ),
        ));
      }
      if (isTrueCapitalCarteraUsd && isTrueRendCarteraUsd) {
        menuItems.add(DropdownMenuItem(
          value: '\$',
          child: ListTileCart(
            capital: capitalCarteraUsd,
            balance: rendimientoCarteraUsd,
            divisa: '\$',
          ),
        ));
      }
      if (isTrueCapitalCarteraOtra && isTrueRendCarteraOtra) {
        menuItems.add(DropdownMenuItem(
          value: '?',
          child: ListTileCart(
            capital: capitalCarteraOtra,
            balance: rendimientoCarteraOtra,
            divisa: '',
          ),
        ));
      }
      return menuItems;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: bgDismissible,
      onDismissed: (_) => delete(cartera),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          //padding: const EdgeInsets.all(12),
          //decoration: boxDeco,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFFFFF),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFFFC107),
                      child: IconButton(
                        onPressed: () => goCartera(context, cartera),
                        icon: const Icon(
                          Icons.business_center,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    cartera.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: styleTitle,
                  ),
                  trailing: PopupMenuButton(
                    color: const Color(0xFF2196F3),
                    icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 1,
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Color(0xFFFFFFFF)),
                          title: Text(
                            'Renombrar',
                            style: TextStyle(color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: ListTile(
                          leading: Icon(Icons.delete_forever,
                              color: Color(0xFFFFFFFF)),
                          title: Text(
                            'Eliminar',
                            style: TextStyle(color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      )
                    ],
                    onSelected: (value) {
                      if (value == 1) {
                        inputName(context, cartera: cartera);
                      } else if (value == 2) {
                        delete(cartera);
                      }
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: boxDecoBlue,
                    child: fondos.isNotEmpty
                        ? Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              childrenPadding:
                                  const EdgeInsets.only(bottom: 10, left: 20),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              expandedAlignment: Alignment.topLeft,
                              maintainState: true,
                              iconColor: Colors.blue,
                              collapsedIconColor: Colors.blue,
                              tilePadding: const EdgeInsets.all(0.0),
                              backgroundColor: const Color(0xFFBBDEFB),
                              title: ChipFondo(lengthFondos: fondos.length),
                              children: [
                                for (var fondo in fondos)
                                  TextButton(
                                    onPressed: () =>
                                        goFondo(context, cartera, fondo),
                                    child: Text(
                                      fondo.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          color: Color(0xFF0D47A1)),
                                    ),
                                  )
                              ],
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: ChipFondo(lengthFondos: null),
                          ),
                  ),
                ),
                if (fondos.isNotEmpty &&
                    participacionesCartera > 0 &&
                    countItems() > 0 &&
                    getDropdownItems().isNotEmpty)
                  ListTile(
                    //visualDensity: const VisualDensity(horizontal: 0),
                    //horizontalTitleGap: double.infinity,
                    //contentPadding: const EdgeInsets.only(left: 50),
                    //minVerticalPadding: 0,
                    leading: Chip(
                      backgroundColor: backgroundRedGreen(taeCartera),
                      padding: const EdgeInsets.only(left: 10, right: 5),
                      avatar: const FittedBox(
                        child: Text('TAE'),
                      ),
                      label: Text(NumberUtil.percent(taeCartera)),
                      labelStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    title: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton(
                        //alignment: Alignment.centerRight,
                        //isExpanded: true,
                        value: selectedValue(),
                        items: getDropdownItems(),
                        onChanged:
                            countItems() == 1 ? null : (String? newValue) {},
                        icon: Visibility(
                            visible: countItems() > 1,
                            child: const Icon(Icons.arrow_downward)),
                        //underline: DropdownButtonHideUnderline(child: Container()),
                        underline: Container(),
                        //iconSize: countItems() == 1 ? 0.0 : 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChipFondo extends StatelessWidget {
  final int? lengthFondos;
  const ChipFondo({Key? key, this.lengthFondos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title;
    if (lengthFondos == null || lengthFondos == 0) {
      title = 'Sin fondos';
    } else if (lengthFondos == 1) {
      title = '$lengthFondos Fondo';
    } else {
      title = '$lengthFondos Fondos';
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Chip(
        padding: const EdgeInsets.only(left: 10, right: 20),
        backgroundColor: const Color(0xFFBBDEFB),
        avatar: const Icon(Icons.poll, color: Color(0xFF0D47A1), size: 32),
        label: Text(
          title,
          style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 16),
        ),
      ),
    );
  }
}

class ListTileCart extends StatelessWidget {
  final double capital;
  final double balance;
  final String divisa;
  const ListTileCart(
      {Key? key,
      required this.capital,
      required this.balance,
      required this.divisa})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Row _buildRow(double stats, {bool isTitle = true}) {
      Color fontColor = const Color(0xFF000000);
      double fontSsize = 16;
      IconData icon = Icons.savings;
      if (!isTitle) {
        fontColor = textRedGreen(stats);
        //stats < 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50);
        fontSsize = 14;
        icon = Icons.iso;
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        //mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${NumberUtil.decimalFixed(stats, long: false)} $divisa',
            textAlign: TextAlign.end,
            maxLines: 1,
            style: TextStyle(
              //fontWeight: FontWeight.w900,
              fontSize: fontSsize,
              color: fontColor,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: const Color(0xFF0D47A1)),
        ],
      );
    }

    // sizebox 200
    /*return SizedBox(
      width: 200,
      child: ListTile(
        //visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        //dense: true,
        //leading: Text(divisa),
        title: _buildRow(capital),
        subtitle: _buildRow(balance, isTitle: false),
      ),
    );*/
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildRow(capital),
        _buildRow(balance, isTitle: false),
      ],
    );
  }
}
