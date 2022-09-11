import 'package:carfoin/widgets/stepper_balance.dart';
import 'package:flutter/material.dart';

import '../models/cartera.dart';
import '../utils/fecha_util.dart';
import '../utils/number_util.dart';
import '../utils/stats.dart';
import '../utils/styles.dart';
import 'hoja_calendario.dart';

class DataCartera extends StatelessWidget {
  final Fondo fondo;
  final Function removeFondo;
  final Function goFondo;
  const DataCartera({
    Key? key,
    required this.fondo,
    required this.removeFondo,
    required this.goFondo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Valor>? valores = fondo.valores;
    Stats? stats;
    double? _inversion;
    double? _resultado;
    double? _balance;
    double? _tae;
    String lastDate = '';
    int dia = 0;
    String mesYear = '';
    String lastPrecio = '';

    double? diferencia;

    String divisa = fondo.divisa ?? '';
    String symbolDivisa = ' ';
    IconData icon = Icons.payments_outlined;
    if (divisa == 'EUR') {
      icon = Icons.euro;
      symbolDivisa = '€';
    } else if (divisa == 'USD') {
      icon = Icons.attach_money;
      symbolDivisa = '\$';
    }

    if (valores != null && valores.isNotEmpty) {
      int lastEpoch = valores.first.date;
      lastDate = FechaUtil.epochToString(lastEpoch);
      dia = FechaUtil.epochToDate(lastEpoch).day;
      //mes = FechaUtil.epochToDate(lastEpoch).month;
      //ano = FechaUtil.epochToDate(lastEpoch).year;
      mesYear = FechaUtil.epochToString(lastEpoch, formato: 'MMM yy');
      //lastPrecio = NumberFormat.decimalPattern('es').format(valores.first.precio);
      lastPrecio = NumberUtil.decimalFixed(valores.first.precio, long: false);
      if (valores.length > 1) {
        diferencia = valores.first.precio - valores[1].precio;
      }
      stats = Stats(valores);
      _inversion = stats.inversion();
      _resultado = stats.resultado();
      _balance = stats.balance();
      double? twr = stats.twr();
      if (twr != null) {
        _tae = stats.anualizar(twr);
      }
    }
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: bgDismissible,
      onDismissed: (_) async => await removeFondo(fondo),
      child: Card(
        //padding: const EdgeInsets.all(12),
        //decoration: boxDeco,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFFFFF),
                  child: CircleAvatar(
                    backgroundColor: amber,
                    child: IconButton(
                      onPressed: () => goFondo(context, fondo),
                      icon: const Icon(Icons.poll, color: blue900),
                    ),
                  ),
                ),
                title: Text(
                  fondo.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: styleTitle,
                ),
                subtitle: Text(
                  fondo.isin,
                  style: const TextStyle(fontSize: 16, color: blue900),
                ),
              ),
              if (valores != null && valores.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: boxDecoBlue,
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
                              //contentPadding: const EdgeInsets.all(0),
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: blue900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.sell, color: blue),
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
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                            color: textRedGreen(diferencia),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.iso, color: blue),
                                      ],
                                    )
                                  : null,
                              trailing: Text(
                                symbolDivisa,
                                textScaleFactor: 2.5,
                                style: const TextStyle(color: blue200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_inversion != null &&
                  _resultado != null &&
                  _balance != null &&
                  _tae != null &&
                  valores != null &&
                  valores.isNotEmpty)
                StepperBalance(
                  input: _inversion,
                  output: _resultado,
                  balance: _balance,
                  divisa: symbolDivisa,
                  firstDate: valores.reversed.first.date,
                  lastDate: valores.reversed.last.date,
                  //tae: _tae,
                ),
              if (_tae != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          NumberUtil.percentCompact(_tae),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: textRedGreen(_tae),
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
      ),
    );
  }
}
