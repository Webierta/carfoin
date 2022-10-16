import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../themes/styles_theme.dart';
import '../../themes/theme_provider.dart';
import '../../utils/stats.dart';
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
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;

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
      if (isTrueInversionCarteraEur && isTrueCapitalCarteraEur && isTrueRendCarteraEur) {
        return true;
      }
      return false;
    }

    bool isTrueDivisaUsd() {
      if (isTrueInversionCarteraUsd && isTrueCapitalCarteraUsd && isTrueRendCarteraUsd) {
        return true;
      }
      return false;
    }

    bool isTrueDivisaOtra() {
      if (isTrueInversionCarteraOtra && isTrueCapitalCarteraOtra && isTrueRendCarteraOtra) {
        return true;
      }
      return false;
    }

    return Card(
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
                  backgroundColor: AppColor.ambar,
                  child: IconButton(
                    onPressed: () => goCartera(context, cartera),
                    icon: const Icon(Icons.business_center, color: AppColor.light900),
                  ),
                ),
              ),
              title: Text(
                cartera.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              trailing: PopupMenuButton(
                shape: AppBox.roundBorder,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Renombrar'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading: Icon(Icons.delete_forever),
                      title: Text('Eliminar'),
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
              //padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                decoration: AppBox.buildBoxDecoration(darkTheme),
                child: fondos.isNotEmpty
                    ? Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          maintainState: true,
                          title: ChipFondo(lengthFondos: fondos.length),
                          children: [
                            for (var fondo in fondos)
                              TextButton(
                                onPressed: () => goFondo(context, cartera, fondo),
                                child: Text(
                                  fondo.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColor.light),
                                ),
                              )
                          ],
                        ),
                      )
                    /* ? Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          childrenPadding: const EdgeInsets.only(bottom: 5, left: 20),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          expandedAlignment: Alignment.topLeft,
                          maintainState: true,
                          iconColor: darkTheme ? AppColor.blanco : AppColor.light,
                          collapsedIconColor: darkTheme ? AppColor.blanco : AppColor.light,
                          tilePadding: const EdgeInsets.all(0.0),
                          //backgroundColor: darkTheme ? AppColor.rojo : AppColor.azul100,
                          title: ChipFondo(lengthFondos: fondos.length),
                          children: [
                            for (var fondo in fondos)
                              TextButton(
                                onPressed: () => goFondo(context, cartera, fondo),
                                child: Text(
                                  fondo.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColor.light),
                                ),
                              )
                          ],
                        ),
                      ) */
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: ChipFondo(lengthFondos: null),
                      ),
              ),
            ),
            if (isTrueDivisaEur())
              StepperBalance(
                input: inversionCarteraEur,
                output: capitalCarteraEur,
                balance: rendimientoCarteraEur,
                divisa: '€',
                firstDate: firstDate,
                lastDate: lastDate,
              ),
            if (isTrueDivisaUsd())
              StepperBalance(
                input: inversionCarteraUsd,
                output: capitalCarteraUsd,
                balance: rendimientoCarteraUsd,
                divisa: '\$',
                firstDate: firstDate,
                lastDate: lastDate,
              ),
            if (isTrueDivisaOtra())
              StepperBalance(
                input: inversionCarteraOtra,
                output: capitalCarteraOtra,
                balance: rendimientoCarteraOtra,
                divisa: '',
                firstDate: firstDate,
                lastDate: lastDate,
              ),
            //const SizedBox(height: 10),
          ],
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
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    String title;
    if (lengthFondos == null || lengthFondos == 0) {
      title = 'Sin fondos';
    } else if (lengthFondos == 1) {
      title = '$lengthFondos Fondo';
    } else {
      title = '$lengthFondos Fondos';
    }
    /* return Align(
      alignment: Alignment.topLeft,
      child: Chip(
        padding: const EdgeInsets.only(left: 10, right: 20),
        backgroundColor: blue100,
        side: const BorderSide(color: Colors.transparent, width: 0),
        avatar: const Icon(Icons.poll, color: blue900, size: 32),
        label: Text(
          title,
          style: const TextStyle(color: blue900, fontSize: 14),
        ),
      ),
    ); */
    /* return ListTile(
      leading: const Icon(Icons.poll),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      horizontalTitleGap: 0,
      dense: true,
    ); */
    return Align(
      alignment: Alignment.topLeft,
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(Icons.poll, color: darkTheme ? AppColor.blanco : AppColor.light),
        label: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
