import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
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
import '../../utils/pdf_visor.dart';
import '../../utils/stats.dart';
import '../../utils/styles.dart';
import '../custom_dialog.dart';
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
  //bool _isConfirmDelete = true;
  late Stats stats;

  /*getSharedPrefs() async {
    await PreferencesService.getBool(keyConfirmDeletePref).then((value) {
      setState(() => _isConfirmDelete = value);
    });
  }*/

  setValores(Cartera cartera, Fondo fondo) async {
    carteraProvider.valores = await database.getValores(cartera, fondo);
    fondo.valores = carteraProvider.valores;
    //fondoSelect.valores = carteraProvider.valores;
    valoresSelect = carteraProvider.valores;
    carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
    operacionesSelect = carteraProvider.operaciones;
    //carteraProvider.addValores(carteraSelect, fondoSelect, valoresSelect);
    //carteraProvider.calculaStats(fondo);
    //carteraProvider.calculaInversion(fondo);
    //carteraProvider.calculaResultado(fondo);
    //stats = Stats(valoresSelect);
  }

  @override
  void initState() {
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await getSharedPrefs();
      await setValores(carteraSelect, fondoSelect);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PreferencesProvider prefProvider = context.read<PreferencesProvider>();
    //final carteraProvider = context.read<CarteraProvider>();
    //final carteraSelect = carteraProvider.carteraSelect;
    //final fondoSelect = carteraProvider.fondoSelect;
    final List<Valor> valores = context.watch<CarteraProvider>().valores;
    final List<Valor> operaciones =
        context.watch<CarteraProvider>().operaciones;

    stats = Stats(valores);
    //carteraProvider.addValores(carteraSelect, fondoSelect, valores);

    double? getDiferencia() {
      if (valores.length > 1) {
        var last = valores.first.precio;
        var prev = valores[1].precio;
        return last - prev;
      }
      return null;
    }

    confirmDeleteOperacion(BuildContext context, Valor op) async {
      String aviso = op.tipo == 1
          ? 'Esta acción elimina esta operación y los reembolsos posteriores '
              'pero mantiene los valores liquidativos de las fechas afectadas.'
          : 'Esta acción elimina esta operación manteniendo su valor liquidativo.';
      return showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text('Eliminar Operación'),
              content: Text(aviso),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFFFFF),
                    backgroundColor: red,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          });
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
                /*NumberFormat.decimalPattern('es').format(op.tipo == 1
                    ? op.participaciones
                    : (op.participaciones ?? 0) * -1),*/
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
                if (prefProvider.isConfirmDelete) {
                  var resp = await confirmDeleteOperacion(context, op);
                  if (resp) {
                    deleteOperacion(op);
                  }
                } else {
                  if (op.tipo == 1) {
                    var resp = await confirmDeleteOperacion(context, op);
                    if (resp) {
                      deleteOperacion(op);
                    }
                  } else {
                    deleteOperacion(op);
                  }
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
      padding: const EdgeInsets.all(8),
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
                        /*String? urlPdf =
                            await docCnmv.getUrlFolleto().whenComplete(() {
                          Future.delayed(Duration.zero, () {
                            Navigator.of(context).pop();
                          });
                        });*/
                        String? urlPdf = await docCnmv.getUrlFolleto();
                        if (urlPdf != null) {
                          String filename = 'folleto_${fondoSelect.isin}.pdf';
                          await loadPdfFromNetwork(urlPdf, filename)
                              .then((file) => openPdf(context, file, urlPdf))
                              .whenComplete(
                                  () => setState(() => openingPdf = false));
                        } else {
                          setState(() => openingPdf = false);
                          _showMsg(msg: 'Archivo no disponible', color: red900);
                          //if (mounted)
                          //Navigator.of(context).pop();
                          Logger.log(
                            dataLog: DataLog(
                              msg: 'urlPdf is null',
                              file: 'main_fondo.dart',
                              clase: '_MainFondoState',
                              funcion: 'build',
                            ),
                          );
                          //if (!mounted) return;
                        }
                        //setState(() => openingPdf = false);
                      },
                      icon: Image.asset('assets/pdf.gif'),
                      label: const Text('Folleto'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => openingPdf = true);
                        var docCnmv = DocCnmv(isin: fondoSelect.isin);
                        /*Informe? informe =
                            await docCnmv.getUrlInforme().whenComplete(() {
                          Future.delayed(Duration.zero, () {
                            Navigator.of(context).pop();
                          });
                        });*/
                        Informe? informe = await docCnmv.getUrlInforme();
                        if (informe != null) {
                          var name = informe.name;
                          var urlPdf = informe.url;
                          String filename = '${name}_${fondoSelect.isin}.pdf';
                          await loadPdfFromNetwork(urlPdf, filename)
                              .then((file) => openPdf(context, file, urlPdf))
                              .whenComplete(
                                  () => setState(() => openingPdf = false));
                        } else {
                          setState(() => openingPdf = false);
                          _showMsg(msg: 'Archivo no disponible', color: red900);
                          //if (mounted)
                          //Navigator.of(context).pop();
                          Logger.log(
                            dataLog: DataLog(
                              msg: 'informe is null',
                              file: 'main_fondo.dart',
                              clase: '_MainFondoState',
                              funcion: 'build',
                            ),
                          );
                          //if (!mounted) return;
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
                            'Ordena transacciones en el mercado para seguir la evolución de tu inversión.'),
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
                                    child: Divider(
                                  endIndent: 10,
                                  thickness: 1,
                                )),
                                Text('RENTABILIDAD'),
                                Expanded(
                                    child: Divider(
                                  indent: 10,
                                  thickness: 1,
                                )),
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
                                    child:
                                        Divider(endIndent: 10, thickness: 1)),
                                Text('RENTABILIDAD ANUAL'),
                                Expanded(
                                    child: Divider(indent: 10, thickness: 1)),
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
                              //data: NumberUtil.percentCompact(_tae),
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

  Future<File> loadPdfFromNetwork(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    return _storeFile(url, bytes, filename);
  }

  Future<File> _storeFile(String url, List<int> bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  _deleteFile(File file) async {
    try {
      await file.delete();
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
        msg: 'Catch delete File',
        file: 'main_fondo.dart',
        clase: '_MainFondoState',
        funcion: '_deleteFile',
        error: e,
        stackTrace: s,
      ));
    }
  }

  void openPdf(BuildContext context, File file, String url) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => PdfVisor(
                  file: file,
                  url: url,
                  isin: fondoSelect.isin,
                )))
        .whenComplete(() {
      _deleteFile(file);
      setState(() => openingPdf = false);
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop();
      });
    });
  }

  void _showMsg({required String msg, Color? color}) {
    CustomDialog customDialog = const CustomDialog();
    customDialog.generateDialog(context: context, msg: msg, color: color);
  }
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
      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
