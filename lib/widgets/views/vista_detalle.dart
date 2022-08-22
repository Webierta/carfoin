import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/number_util.dart';
import '../../utils/stats.dart';

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
    }

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
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.5),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2196F3),
                  ),
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
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  (isTrueCapitalCarteraEur ||
                      isTrueCapitalCarteraUsd ||
                      isTrueCapitalCarteraOtra) &&
                  (isTrueRendCarteraEur ||
                      isTrueRendCarteraUsd ||
                      isTrueRendCarteraOtra))
                Align(
                  alignment: Alignment.topRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      if (isTrueCapitalCarteraEur && isTrueRendCarteraEur)
                        ListTileCart(
                          capital: capitalCarteraEur,
                          balance: rendimientoCarteraEur,
                          divisa: '€',
                        ),
                      if (isTrueCapitalCarteraUsd && isTrueRendCarteraUsd)
                        ListTileCart(
                          capital: capitalCarteraUsd,
                          balance: rendimientoCarteraUsd,
                          divisa: '\$',
                        ),
                      if (isTrueCapitalCarteraOtra && isTrueRendCarteraOtra)
                        ListTileCart(
                          capital: capitalCarteraOtra,
                          balance: rendimientoCarteraOtra,
                          divisa: '?',
                        ),
                    ],
                  ),
                ),
            ],
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
          style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 18),
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
        fontColor =
            stats < 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50);
        fontSsize = 14;
        icon = Icons.iso;
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            child: Text(
              '${NumberUtil.decimalFixed(stats, long: false)} $divisa',
              textAlign: TextAlign.end,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: fontSsize,
                color: fontColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: const Color(0xFF0D47A1)),
        ],
      );
    }

    return SizedBox(
      width: 200,
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        title: _buildRow(capital),
        subtitle: _buildRow(balance, isTitle: false),
      ),
    );
  }
}
