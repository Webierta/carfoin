import 'package:flutter/material.dart';

import '../../models/cartera.dart';
import '../../utils/stats.dart';
import '../../utils/styles.dart';
import '../stepper_balance.dart';

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
    double inversionCarteraEur = 0.0;
    double inversionCarteraUsd = 0.0;
    double inversionCarteraOtra = 0.0;
    double capitalCarteraEur = 0.0;
    double capitalCarteraUsd = 0.0;
    double capitalCarteraOtra = 0.0;
    double rendimientoCarteraEur = 0.0;
    double rendimientoCarteraUsd = 0.0;
    double rendimientoCarteraOtra = 0.0;

    int firstDate = 0;
    int lastDate = 0;

    bool isTrueInversionCarteraEur = false;
    bool isTrueInversionCarteraUsd = false;
    bool isTrueInversionCarteraOtra = false;
    bool isTrueCapitalCarteraEur = false;
    bool isTrueCapitalCarteraUsd = false;
    bool isTrueCapitalCarteraOtra = false;
    bool isTrueRendCarteraEur = false;
    bool isTrueRendCarteraUsd = false;
    bool isTrueRendCarteraOtra = false;

    if (fondos.isNotEmpty) {
      List<int> firstDates = [];
      List<int> lastDates = [];
      for (var fondo in fondos) {
        if (fondo.valores != null && fondo.valores!.isNotEmpty) {
          firstDates.add(fondo.valores!.reversed.first.date);
          lastDates.add(fondo.valores!.reversed.last.date);
          Stats stats = Stats(fondo.valores!);
          double participacionesFondo = stats.totalParticipaciones() ?? 0.0;
          if (participacionesFondo > 0) {
            if (fondo.divisa == 'EUR') {
              if (stats.inversion() != null) {
                isTrueInversionCarteraEur = true;
              }
              if (stats.resultado() != null) {
                isTrueCapitalCarteraEur = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraEur = true;
              }
              inversionCarteraEur += stats.inversion() ?? 0.0;
              capitalCarteraEur += stats.resultado() ?? 0.0;
              rendimientoCarteraEur += stats.balance() ?? 0.0;
            } else if (fondo.divisa == 'USD') {
              if (stats.inversion() != null) {
                isTrueInversionCarteraUsd = true;
              }
              if (stats.resultado() != null) {
                isTrueCapitalCarteraUsd = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraUsd = true;
              }
              inversionCarteraUsd += stats.inversion() ?? 0.0;
              capitalCarteraUsd += stats.resultado() ?? 0.0;
              rendimientoCarteraUsd += stats.balance() ?? 0.0;
            } else {
              if (stats.inversion() != null) {
                isTrueInversionCarteraOtra = true;
              }
              if (stats.resultado() != null) {
                isTrueCapitalCarteraOtra = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraOtra = true;
              }
              inversionCarteraOtra += stats.inversion() ?? 0.0;
              capitalCarteraOtra += stats.resultado() ?? 0.0;
              rendimientoCarteraOtra += stats.balance() ?? 0.0;
            }
          }
        }
      }
      firstDates.sort();
      lastDates.sort();
      if (firstDates.isNotEmpty && lastDates.isNotEmpty) {
        firstDate = firstDates.first;
        lastDate = lastDates.last;
      }
    }

    bool isTrueDivisaEur() {
      if (isTrueInversionCarteraEur &&
          isTrueCapitalCarteraEur &&
          isTrueRendCarteraEur) {
        return true;
      }
      return false;
    }

    bool isTrueDivisaUsd() {
      if (isTrueInversionCarteraUsd &&
          isTrueCapitalCarteraUsd &&
          isTrueRendCarteraUsd) {
        return true;
      }
      return false;
    }

    bool isTrueDivisaOtra() {
      if (isTrueInversionCarteraOtra &&
          isTrueCapitalCarteraOtra &&
          isTrueRendCarteraOtra) {
        return true;
      }
      return false;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: bgDismissible,
      onDismissed: (_) => delete(cartera),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                minLeadingWidth: 0,
                horizontalTitleGap: 10,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFFFFF),
                  child: CircleAvatar(
                    backgroundColor: amber,
                    child: IconButton(
                      onPressed: () => goCartera(context, cartera),
                      icon: const Icon(Icons.business_center, color: blue900),
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
                  color: blue,
                  icon: const Icon(Icons.more_vert, color: blue),
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
                        leading: Icon(
                          Icons.delete_forever,
                          color: Color(0xFFFFFFFF),
                        ),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  decoration: boxDecoBlue,
                  child: fondos.isNotEmpty
                      ? Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            childrenPadding:
                                const EdgeInsets.only(bottom: 5, left: 20),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
                            maintainState: true,
                            iconColor: blue,
                            collapsedIconColor: blue,
                            tilePadding: const EdgeInsets.all(0.0),
                            backgroundColor: blue100,
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
                                        decoration: TextDecoration.underline),
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
              //if (isTrueDivisaEur()) const SizedBox(height: 10),
              if (isTrueDivisaEur())
                StepperBalance(
                  input: inversionCarteraEur,
                  output: capitalCarteraEur,
                  balance: rendimientoCarteraEur,
                  divisa: '€',
                  firstDate: firstDate,
                  lastDate: lastDate,
                ),
              //if (isTrueDivisaUsd()) const SizedBox(height: 10),
              if (isTrueDivisaUsd())
                StepperBalance(
                  input: inversionCarteraUsd,
                  output: capitalCarteraUsd,
                  balance: rendimientoCarteraUsd,
                  divisa: '\$',
                  firstDate: firstDate,
                  lastDate: lastDate,
                ),
              //if (isTrueDivisaOtra()) const SizedBox(height: 10),
              if (isTrueDivisaOtra())
                StepperBalance(
                  input: inversionCarteraOtra,
                  output: capitalCarteraOtra,
                  balance: rendimientoCarteraOtra,
                  divisa: '',
                  firstDate: firstDate,
                  lastDate: lastDate,
                ),
              const SizedBox(height: 10),
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
        backgroundColor: blue100,
        avatar: const Icon(Icons.poll, color: blue900, size: 32),
        label: Text(
          title,
          style: const TextStyle(color: blue900, fontSize: 14),
        ),
      ),
    );
  }
}
