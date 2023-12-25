import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../themes/styles_theme.dart';
import '../../themes/theme_provider.dart';
import '../../utils/number_util.dart';
import '../../utils/stats.dart';
import '../hoja_calendario.dart';
import '../stepper_balance.dart';

class VistaDetalleFondos extends StatelessWidget {
  final Fondo fondo;
  final Function updateFondo;
  final Function removeFondo;
  final Function goFondo;

  const VistaDetalleFondos({
    super.key,
    required this.fondo,
    required this.updateFondo,
    required this.removeFondo,
    required this.goFondo,
  });

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    List<Valor>? valores = fondo.valores;
    Stats? stats;
    double? inversion;
    double? resultado;
    double? balance;
    double? tae;
    //String lastDate = '';
    //int dia = 0;
    //String mesYear = '';
    String lastPrecio = '';

    double? diferencia;

    String divisa = fondo.divisa ?? '';
    String symbolDivisa = ' ';
    //IconData icon = Icons.payments_outlined;
    if (divisa == 'EUR') {
      //icon = Icons.euro;
      symbolDivisa = '€';
    } else if (divisa == 'USD') {
      //icon = Icons.attach_money;
      symbolDivisa = '\$';
    }

    if (valores != null && valores.isNotEmpty) {
      //int lastEpoch = valores.first.date;
      //lastDate = FechaUtil.epochToString(lastEpoch);
      //dia = FechaUtil.epochToDate(lastEpoch).day;
      //mes = FechaUtil.epochToDate(lastEpoch).month;
      //ano = FechaUtil.epochToDate(lastEpoch).year;
      //mesYear = FechaUtil.epochToString(lastEpoch, formato: 'MMM yy');
      //lastPrecio = NumberFormat.decimalPattern('es').format(valores.first.precio);
      lastPrecio = NumberUtil.decimalFixed(valores.first.precio, long: false);
      if (valores.length > 1) {
        diferencia = valores.first.precio - valores[1].precio;
      }
      stats = Stats(valores);
      inversion = stats.inversion();
      resultado = stats.resultado();
      balance = stats.balance();
      double? twr = stats.twr();
      if (twr != null) {
        tae = stats.anualizar(twr);
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColor.blanco,
                child: CircleAvatar(
                  backgroundColor: AppColor.ambar,
                  child: IconButton(
                    onPressed: () => goFondo(context, fondo),
                    icon: const Icon(Icons.poll, color: AppColor.light900),
                  ),
                ),
              ),
              title: Text(
                fondo.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                fondo.isin,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w300),
              ),
              trailing: PopupMenuButton(
                shape: AppBox.roundBorder,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Actualizar')),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Eliminar')),
                  )
                ],
                onSelected: (value) async {
                  value == 1
                      ? await updateFondo(fondo)
                      : await removeFondo(fondo);
                },
              ),
            ),
            if (valores != null && valores.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: AppBox.buildBoxDecoration(darkTheme),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: DiaCalendario(epoch: valores.first.date),
                        ),
                        Expanded(
                          child: ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.fromLTRB(0, 0, 8, 0),
                            //minLeadingWidth: 0,
                            horizontalTitleGap: 0,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  lastPrecio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.sell),
                              ],
                            ),
                            subtitle: diferencia != null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        NumberUtil.compactFixed(diferencia),
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                color: AppColor.textRedGreen(
                                                    diferencia)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.iso),
                                    ],
                                  )
                                : null,
                            trailing: Text(
                              symbolDivisa,
                              textScaler: const TextScaler.linear(2.5),
                              //textScaleFactor: 2.5,
                              style: const TextStyle(color: AppColor.light200),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (inversion != null &&
                resultado != null &&
                balance != null &&
                tae != null &&
                valores != null &&
                valores.isNotEmpty)
              StepperBalance(
                input: inversion,
                output: resultado,
                balance: balance,
                divisa: symbolDivisa,
                firstDate: valores.reversed.first.date,
                lastDate: valores.reversed.last.date,
              ),
            if (tae != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        NumberUtil.percentCompact(tae),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: AppColor.textRedGreen(tae),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('TAE'),
                  ],
                ),
              ),
            // TODO: Texto: sin inversiones ??
          ],
        ),
      ),
    );
  }
}
