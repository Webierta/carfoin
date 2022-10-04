import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../models/logger.dart';
import '../../models/preferences_provider.dart';
import '../../router/routes_const.dart';
import '../../services/database_helper.dart';
import '../../services/doc_cnmv.dart';
import '../../utils/fecha_util.dart';
import '../../utils/number_util.dart';
import '../../utils/pdf_viewer.dart';
import '../../utils/stats.dart';
import '../../utils/styles.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/custom_messenger.dart';
import '../hoja_calendario.dart';
import '../loading_progress.dart';

class MainFondo extends StatefulWidget {
  const MainFondo({Key? key}) : super(key: key);
  @override
  State<MainFondo> createState() => _MainFondoState();
}

class _MainFondoState extends State<MainFondo> {
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late Fondo fondoSelect;
  late List<Valor> valoresSelect;
  late List<Valor> operacionesSelect;

  bool openingPdf = false;
  late Stats stats;

  setValores(Cartera cartera, Fondo fondo) async {
    carteraProvider.valores = await database.getValores(cartera, fondo);
    fondo.valores = carteraProvider.valores;
    valoresSelect = carteraProvider.valores;
    carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
    operacionesSelect = carteraProvider.operaciones;
  }

  @override
  void initState() {
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setValores(carteraSelect, fondoSelect);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PreferencesProvider prefProvider = context.read<PreferencesProvider>();
    final List<Valor> valores = context.watch<CarteraProvider>().valores;
    final List<Valor> operaciones =
        context.watch<CarteraProvider>().operaciones;
    stats = Stats(valores);

    double? getDiferencia() {
      if (valores.length > 1) {
        var last = valores.first.precio;
        var prev = valores[1].precio;
        return last - prev;
      }
      return null;
    }

    deleteOperacion(Valor op) async {
      await database.deleteOperacion(carteraSelect, fondoSelect, op);
      carteraProvider.removeOperacion(fondoSelect, op);
      await setValores(carteraSelect, fondoSelect);
    }

    List<DataColumn> createColumns() {
      return const <DataColumn>[
        DataColumn(label: Text('FECHA')),
        DataColumn(label: Text('PART.')),
        DataColumn(label: Text('V.L.')),
        DataColumn(label: Text('IMPORTE')),
        DataColumn(label: Text('')),
      ];
    }

    List<DataRow> createRows() {
      if (operaciones.isEmpty || valores.isEmpty) return <DataRow>[];
      return [
        for (var op in operaciones)
          // TODO: HACER AQUI CÁLCULOS
          DataRow(cells: [
            DataCell(Align(
              alignment: Alignment.centerRight,
              child:
                  Text(FechaUtil.epochToString(op.date, formato: 'dd/MM/yy')),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                op.tipo == 1
                    ? NumberUtil.decimal(op.participaciones ?? 0, long: false)
                    : NumberUtil.decimal((op.participaciones ?? 0) * -1,
                        long: false),
                style: TextStyle(color: op.tipo == 1 ? green : red),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(NumberUtil.decimal(op.precio)),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(NumberUtil.decimalFixed(
                  (op.participaciones ?? 0) * op.precio,
                  long: false)),
            )),
            DataCell(IconButton(
              onPressed: () async {
                if (prefProvider.isConfirmDelete || op.tipo == 1) {
                  String content = op.tipo == 1
                      ? 'Esta acción elimina esta operación y los reembolsos posteriores '
                          'pero mantiene los valores liquidativos de las fechas afectadas.'
                      : 'Esta acción elimina esta operación manteniendo su valor liquidativo.';
                  bool? resp = await ConfirmDialog(
                    context: context,
                    title: 'Eliminar Operación',
                    content: content,
                  ).generateDialog();
                  if (resp == true) {
                    deleteOperacion(op);
                  }
                } else {
                  deleteOperacion(op);
                }
              },
              icon: const Icon(Icons.delete_forever),
            )),
          ]),
        DataRow(
          color: MaterialStateColor.resolveWith((states) => Colors.blue),
          cells: [
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                FechaUtil.epochToString(valores.first.date,
                    formato: 'dd/MM/yy'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                stats.totalParticipaciones() != null
                    ? NumberUtil.decimalFixed(stats.totalParticipaciones()!,
                        long: false)
                    : '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                NumberUtil.decimal(valores.first.precio),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                stats.resultado() != null
                    ? NumberUtil.decimalFixed(stats.resultado()!, long: false)
                    : '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            const DataCell(Text('')),
          ],
        ),
      ];
    }

    /*String fechaPrecioMin() {
      if (stats.datePrecioMinimo() != null) {
        return FechaUtil.epochToString(stats.datePrecioMinimo()!,
            formato: 'dd/MM/yy');
      }
      return '';
    }

    String fechaPrecioMax() {
      int? x = stats.datePrecioMaximo();
      if (stats.datePrecioMaximo() != null) {
        return FechaUtil.epochToString(stats.datePrecioMaximo()!,
            formato: 'dd/MM/yy');
      }
      return '';
    }*/

    String fechaPrecio(int? precio) {
      if (precio != null) {
        return FechaUtil.epochToString(precio, formato: 'dd/MM/yy');
      }
      return '';
    }

    double? inversion;
    double? resultado;
    double? rendimiento;
    double? rentabilidad;
    double? rentAnual;
    double? twr;
    double? tae;
    double? mwr;
    double? mwrAcum;
    if (operaciones.isNotEmpty) {
      inversion = stats.inversion();
      resultado = stats.resultado();
      rendimiento = stats.balance();
      rentabilidad = stats.rentabilidad();
      if (rentabilidad != null) {
        rentAnual = stats.anualizar(rentabilidad);
      }
      twr = stats.twr();
      if (twr != null) {
        tae = stats.anualizar(twr);
      }
      mwr = stats.mwr();
      if (mwr != null) {
        mwrAcum = stats.mwrAcum(mwr);
      }
    }

    bool allStatsIsNull() {
      List<double?> listStats = [
        inversion,
        resultado,
        rendimiento,
        rentabilidad,
        rentAnual,
        twr,
        tae,
        mwr,
        mwrAcum
      ];
      for (var st in listStats) {
        if (st != null) return false;
      }
      return true;
    }

    showDialogLoading(BuildContext context) async {
      return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: LoadingProgress(titulo: 'Cargando documento...'),
            );
          });
    }

    List<Icon> getStarRating() {
      List<Icon> estrellas = [];
      int rating = fondoSelect.rating ?? 0;
      for (var i = 1; i < 6; i++) {
        var icon = Icon(Icons.star,
            color: rating >= i ? Colors.greenAccent[400] : Colors.grey);
        estrellas.add(icon);
      }
      return estrellas;
    }

    if (openingPdf) {
      Future.delayed(Duration.zero, () => showDialogLoading(context));
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  //dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  //contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  //leading: const Icon(Icons.assessment, size: 32, color: blue),
                  title: Text(
                    fondoSelect.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: styleTitle,
                  ),
                  subtitle: Text(
                    fondoSelect.isin,
                    style: const TextStyle(fontSize: 16, color: blue900),
                  ),
                ),
                Column(
                  children: [
                    const Text(
                      'Rating Morningstar',
                      style: TextStyle(fontSize: 10),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: getStarRating(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Row(children: [
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => openingPdf = true);
                        var docCnmv = DocCnmv(isin: fondoSelect.isin);
                        String? urlPdf = await docCnmv.getUrlFolleto();
                        if (urlPdf != null) {
                          String filename = 'folleto_${fondoSelect.isin}.pdf';
                          if (!mounted) return;
                          await openPdfViewer(context, filename, urlPdf);
                        } else {
                          setState(() => openingPdf = false);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _showMsg(msg: 'Archivo no disponible', color: red900);
                          Logger.log(
                              dataLog: DataLog(
                                  msg: 'urlPdf is null',
                                  file: 'main_fondo.dart',
                                  clase: '_MainFondoState',
                                  funcion: 'build'));
                        }
                      },
                      icon: Image.asset('assets/pdf.gif'),
                      label: const Text('Folleto'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => openingPdf = true);
                        var docCnmv = DocCnmv(isin: fondoSelect.isin);
                        Informe? informe = await docCnmv.getUrlInforme();
                        if (informe != null) {
                          var name = informe.name;
                          var urlPdf = informe.url;
                          String filename = '${name}_${fondoSelect.isin}.pdf';
                          if (!mounted) return;
                          await openPdfViewer(context, filename, urlPdf);
                        } else {
                          setState(() => openingPdf = false);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _showMsg(msg: 'Archivo no disponible', color: red900);
                          Logger.log(
                              dataLog: DataLog(
                                  msg: 'informe is null',
                                  file: 'main_fondo.dart',
                                  clase: '_MainFondoState',
                                  funcion: 'build'));
                        }
                      },
                      icon: Image.asset('assets/pdf.gif'),
                      label: const Text('Informe'),
                    ),
                  ]),
                ),
                valores.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('Sin datos. Descarga el último valor o '
                            'un intervalo de valores históricos.'),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: boxDecoBlue,
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    DiaCalendario(epoch: valores.first.date),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              NumberUtil.decimalFixed(
                                                  valores.first.precio,
                                                  long: false),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                        if (getDiferencia() != null)
                                          Row(
                                            children: [
                                              Text(
                                                NumberUtil.compactFixed(
                                                    getDiferencia()!),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w400,
                                                    color: textRedGreen(
                                                        getDiferencia()!)),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.iso,
                                                  color: blue),
                                            ],
                                          ),
                                      ],
                                    ),
                                    if (fondoSelect.divisa == 'EUR' ||
                                        fondoSelect.divisa == 'USD')
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Text(
                                          fondoSelect.divisa == 'EUR'
                                              ? '€'
                                              : '\$',
                                          textScaleFactor: 2.5,
                                          style:
                                              const TextStyle(color: blue200),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (valores.isNotEmpty)
                                const SizedBox(height: 10),
                              if (valores.length > 1)
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Mínimo  \t\t (${fechaPrecio(stats.datePrecioMinimo())})'),
                                        Text(
                                            'Máximo \t\t (${fechaPrecio(stats.datePrecioMaximo())})'),
                                        const Text('Media'),
                                        const Text('Volatilidad'),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(NumberUtil.decimal(
                                            stats.precioMinimo() ?? 0)),
                                        Text(NumberUtil.decimal(
                                            stats.precioMaximo() ?? 0)),
                                        Text(stats.precioMedio() != null
                                            ? NumberUtil.decimalFixed(
                                                stats.precioMedio()!,
                                                long: false)
                                            : ''),
                                        Text(stats.volatilidad() != null
                                            ? NumberUtil.decimalFixed(
                                                stats.volatilidad()!,
                                                long: false)
                                            : ''),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  //contentPadding: const EdgeInsets.all(12),
                  minLeadingWidth: 0,
                  leading:
                      const Icon(Icons.compare_arrows, size: 32, color: blue),
                  title: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'OPERACIONES',
                      //overflow: TextOverflow.ellipsis,
                      //maxLines: 1,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  trailing: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFFFFF),
                    child: CircleAvatar(
                      backgroundColor: amber,
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart, color: blue900),
                        onPressed: () => context.go(mercadoPage),
                      ),
                    ),
                  ),
                ),
                operaciones.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Sin datos de operaciones.\n'
                            'Ordena transacciones en el mercado para seguir la '
                            'evolución de tu inversión.'),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.fill,
                              child: DataTable(
                                decoration: BoxDecoration(
                                  border: Border.all(color: blue, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                //headingRowHeight: 0,
                                columnSpacing: 20,
                                dataRowHeight: 70,
                                //horizontalMargin: 10,
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.blue),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                dataTextStyle: const TextStyle(
                                    fontSize: 18, color: Colors.black),
                                columns: createColumns(),
                                rows: createRows(),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (operaciones.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    minLeadingWidth: 0,
                    leading: const Icon(Icons.balance,
                        size: 32, color: blue), // Icons.balance
                    title: const Text(
                      'BALANCE',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFFFFFF),
                      child: CircleAvatar(
                        backgroundColor: amber,
                        child: IconButton(
                          onPressed: () => context.go(infoBalancePage),
                          icon: const Icon(Icons.info_outline, color: blue900),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: boxDecoBlue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (allStatsIsNull())
                            const Text('Error en los cálculos'),
                          if (inversion != null)
                            RowBalance(
                              label: 'Inversión',
                              data: NumberUtil.decimalFixed(inversion,
                                  long: false),
                            ),
                          if (resultado != null) const SizedBox(height: 10),
                          if (resultado != null)
                            RowBalance(
                              label: 'Resultado',
                              data: NumberUtil.decimalFixed(resultado,
                                  long: false),
                            ),
                          if (rendimiento != null) const SizedBox(height: 10),
                          if (rendimiento != null)
                            RowBalance(
                              label: 'Rendimiento',
                              data: NumberUtil.decimalFixed(rendimiento,
                                  long: false),
                              color: textRedGreen(rendimiento),
                            ),
                          if (rentabilidad != null ||
                              twr != null ||
                              mwrAcum != null)
                            const SizedBox(height: 10),
                          if (rentabilidad != null ||
                              twr != null ||
                              mwrAcum != null)
                            Row(
                              children: const [
                                Expanded(
                                  child: Divider(endIndent: 10, thickness: 1),
                                ),
                                Text('RENTABILIDAD'),
                                Expanded(
                                  child: Divider(indent: 10, thickness: 1),
                                ),
                              ],
                            ),
                          if (rentabilidad != null) const SizedBox(height: 10),
                          if (rentabilidad != null)
                            RowBalance(
                              label: 'Simple',
                              data: NumberUtil.percentCompact(rentabilidad),
                              color: textRedGreen(rentabilidad),
                            ),
                          if (twr != null) const SizedBox(height: 10),
                          if (twr != null)
                            RowBalance(
                              label: 'TWR',
                              data: NumberUtil.percentCompact(twr),
                              color: textRedGreen(twr),
                            ),
                          if (mwr != null) const SizedBox(height: 10),
                          if (mwrAcum != null)
                            RowBalance(
                              label: 'MWR Acum.',
                              data: NumberUtil.percentCompact(mwrAcum),
                              color: textRedGreen(mwrAcum),
                            ),
                          if (rentAnual != null || tae != null || mwr != null)
                            const SizedBox(height: 10),
                          if (rentAnual != null || tae != null || mwr != null)
                            Row(
                              children: const [
                                Expanded(
                                  child: Divider(endIndent: 10, thickness: 1),
                                ),
                                Text('RENTABILIDAD ANUAL'),
                                Expanded(
                                  child: Divider(indent: 10, thickness: 1),
                                ),
                              ],
                            ),
                          if (rentAnual != null) const SizedBox(height: 10),
                          if (rentAnual != null)
                            RowBalance(
                              label: 'Simple Anual',
                              data: NumberUtil.percentCompact(rentAnual),
                              color: textRedGreen(rentAnual),
                            ),
                          if (tae != null) const SizedBox(height: 10),
                          if (tae != null)
                            RowBalance(
                              label: 'TWR (TAE)',
                              data: NumberUtil.percentCompact(tae),
                              color: textRedGreen(tae),
                            ),
                          if (mwr != null) const SizedBox(height: 10),
                          if (mwr != null)
                            RowBalance(
                              label: 'MWR',
                              data: NumberUtil.percentCompact(mwr),
                              color: textRedGreen(mwr),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  openPdfViewer(BuildContext context, String fileName, String url) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => PdfViewer(
                  fileName: fileName,
                  url: url,
                )))
        .whenComplete(() {
      setState(() => openingPdf = false);
      Navigator.of(context).pop();
    });
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}

class RowBalance extends StatelessWidget {
  final String label;
  final String data;
  final Color color;
  const RowBalance({
    Key? key,
    required this.label,
    required this.data,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              data,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
