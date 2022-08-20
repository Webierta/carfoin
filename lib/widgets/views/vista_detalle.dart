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
          participacionesCartera += stats.totalParticipaciones() ?? 0.0;
          if (participacionesCartera > 0) {
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

    Widget _builTextCartera(double valorStats,
        {String divisa = '', bool color = false}) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${NumberUtil.decimalFixed(valorStats)} $divisa',
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color == true
                ? valorStats < 0
                    ? Colors.red
                    : Colors.green
                : Colors.black,
            fontSize: 16,
          ),
        ),
      );
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
                                  onPressed: () {
                                    goFondo(context, cartera, fondo);
                                  },
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VALOR', style: TextStyle(fontSize: 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isTrueCapitalCarteraEur)
                                _builTextCartera(capitalCarteraEur,
                                    divisa: 'EUR'),
                              if (isTrueCapitalCarteraUsd)
                                _builTextCartera(capitalCarteraUsd,
                                    divisa: 'USD'),
                              if (isTrueCapitalCarteraOtra)
                                _builTextCartera(capitalCarteraOtra),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BALANCE', style: TextStyle(fontSize: 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isTrueRendCarteraEur)
                                _builTextCartera(rendimientoCarteraEur,
                                    divisa: 'EUR', color: true),
                              if (isTrueRendCarteraUsd)
                                _builTextCartera(rendimientoCarteraUsd,
                                    divisa: 'USD', color: true),
                              if (isTrueRendCarteraOtra)
                                _builTextCartera(rendimientoCarteraOtra,
                                    color: true),
                            ],
                          ),
                        ],
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
