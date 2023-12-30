import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../models/logger.dart';
import '../../models/preferences_provider.dart';
import '../../pages/page_pdf.dart';
import '../../router/routes_const.dart';
import '../../services/database_helper.dart';
import '../../themes/styles_theme.dart';
import '../../themes/theme_provider.dart';
import '../../utils/fecha_util.dart';
import '../../utils/number_util.dart';
import '../../utils/stats.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/custom_messenger.dart';
import '../hoja_calendario.dart';

class MainFondo extends StatefulWidget {
  const MainFondo({super.key});

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

  Stats stats = const Stats([]); //late Stats stats;
  double? inversion;
  double? resultado;
  double? rendimiento;
  double? rentabilidad;
  double? rentAnual;
  double? twr;
  double? tae;
  double? mwr;
  double? mwrAcum;

  setValores(Cartera cartera, Fondo fondo) async {
    carteraProvider.valores = await database.getValores(cartera, fondo);
    fondo.valores = carteraProvider.valores;
    valoresSelect = carteraProvider.valores;
    carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
    operacionesSelect = carteraProvider.operaciones;

    stats = Stats(valoresSelect);
    if (operacionesSelect.isNotEmpty) {
      calculateStats();
    }
  }

  calculateStats() {
    inversion = stats.inversion();
    resultado = stats.resultado();
    rendimiento = stats.balance();
    rentabilidad = stats.rentabilidad();
    if (rentabilidad != null) {
      rentAnual = stats.anualizar(rentabilidad!);
    }
    twr = stats.twr();
    if (twr != null) {
      tae = stats.anualizar(twr!);
    }
    mwr = stats.mwr();
    if (mwr != null) {
      mwrAcum = stats.mwrAcum(mwr!);
    }
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
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    PreferencesProvider prefProvider = context.read<PreferencesProvider>();
    final List<Valor> valores = context.watch<CarteraProvider>().valores;
    final List<Valor> operaciones =
        context.watch<CarteraProvider>().operaciones;

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
      if (operaciones.isEmpty || valores.isEmpty) {
        return <DataRow>[];
      }
      return [
        for (var op in operaciones)
          DataRow(cells: [
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                FechaUtil.epochToString(op.date, formato: 'dd/MM/yy'),
                style: TextStyle(
                  color: darkTheme ? AppColor.blanco : AppColor.light900,
                ),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                op.tipo == 1
                    ? NumberUtil.decimal(op.participaciones ?? 0, long: false)
                    : NumberUtil.decimal((op.participaciones ?? 0) * -1,
                        long: false),
                style: TextStyle(
                  color: op.tipo == 1 ? AppColor.verde : AppColor.rojo,
                ),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                NumberUtil.decimal(op.precio),
                style: TextStyle(
                  color: darkTheme ? AppColor.blanco : AppColor.light900,
                ),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                NumberUtil.decimalFixed((op.participaciones ?? 0) * op.precio,
                    long: false),
                style: TextStyle(
                    color: darkTheme ? AppColor.blanco : AppColor.light900),
              ),
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
          color: MaterialStateColor.resolveWith(
              (states) => darkTheme ? AppColor.boxDark : AppColor.light),
          cells: [
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                FechaUtil.epochToString(valores.first.date,
                    formato: 'dd/MM/yy'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColor.blanco),
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

    List<Icon> getStarRating() {
      List<Icon> estrellas = [];
      int rating = fondoSelect.rating ?? 0;
      for (var i = 1; i < 6; i++) {
        var icon = Icon(Icons.star,
            color: rating >= i ? AppColor.verdeAccent400 : AppColor.gris);
        estrellas.add(icon);
      }
      return estrellas;
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    fondoSelect.isin,
                    style: Theme.of(context).textTheme.titleSmall,
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
                        final bool? showPdf = await context.push<bool>(pdfPage,
                            extra: FondoDoc(
                              fondo: fondoSelect,
                              pdfDoc: PdfDoc.folleto,
                            ));
                        if (showPdf == null || showPdf == false) {
                          showPdfFalse(msg: 'error folleto');
                        }
                      },
                      icon: Image.asset('assets/pdf.gif'),
                      label: const Text('Folleto'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final bool? showPdf = await context.push<bool>(pdfPage,
                            extra: FondoDoc(
                              fondo: fondoSelect,
                              pdfDoc: PdfDoc.informe,
                            ));
                        if (showPdf == null || showPdf == false) {
                          showPdfFalse(msg: 'error informe');
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
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppBox.buildBoxDecoration(darkTheme),
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.sell),
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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColor.textRedGreen(
                                                              getDiferencia()!),
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.iso),
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
                                          textScaler:
                                              const TextScaler.linear(2.5),
                                          //textScaleFactor: 2.5,
                                          style: const TextStyle(
                                              color: AppColor.light200),
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
        //const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  //contentPadding: const EdgeInsets.all(12),
                  minLeadingWidth: 0,
                  leading: const Icon(Icons.compare_arrows, size: 32),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'OPERACIONES',
                      //overflow: TextOverflow.ellipsis,
                      //maxLines: 1,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  trailing: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFFFFF),
                    child: CircleAvatar(
                      backgroundColor: AppColor.ambar,
                      child: IconButton(
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: AppColor.light900,
                        ),
                        onPressed: () {
                          context.go(mercadoPage);
                        },
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
                                  border: Border.all(
                                      color: darkTheme
                                          ? AppColor.boxDark
                                          : AppColor.light,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                //headingRowHeight: 0,
                                columnSpacing: 20,
                                dataRowMaxHeight: 70,
                                //dataRowHeight: 70,
                                //horizontalMargin: 10,
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => darkTheme
                                        ? AppColor.boxDark
                                        : AppColor.light),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                dataTextStyle: const TextStyle(fontSize: 18),
                                columns: createColumns(),
                                rows: createRows(),
                              ),
                            ),
                            //const SizedBox(height: 10),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
        //const SizedBox(height: 10),
        if (operaciones.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    minLeadingWidth: 0,
                    leading: const Icon(Icons.balance, size: 32),
                    title: Text('BALANCE',
                        style: Theme.of(context).textTheme.titleLarge),
                    trailing: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFFFFFF),
                      child: CircleAvatar(
                        backgroundColor: AppColor.ambar,
                        child: IconButton(
                          onPressed: () => context.go(infoBalancePage),
                          icon: const Icon(Icons.info_outline,
                              color: AppColor.light900),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppBox.buildBoxDecoration(darkTheme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (allStatsIsNull())
                            const Text('Error en los cálculos'),
                          if (inversion != null)
                            RowBalance(
                              label: 'Inversión',
                              data: NumberUtil.decimalFixed(inversion!,
                                  long: false),
                              color: darkTheme
                                  ? AppColor.blanco
                                  : AppColor.light900,
                            ),
                          if (resultado != null) const SizedBox(height: 10),
                          if (resultado != null)
                            RowBalance(
                              label: 'Resultado',
                              data: NumberUtil.decimalFixed(resultado!,
                                  long: false),
                              color: darkTheme
                                  ? AppColor.blanco
                                  : AppColor.light900,
                            ),
                          if (rendimiento != null) const SizedBox(height: 10),
                          if (rendimiento != null)
                            RowBalance(
                              label: 'Rendimiento',
                              data: NumberUtil.decimalFixed(rendimiento!,
                                  long: false),
                              color: AppColor.textRedGreen(rendimiento!),
                            ),
                          if (rentabilidad != null ||
                              twr != null ||
                              mwrAcum != null)
                            const SizedBox(height: 10),
                          if (rentabilidad != null ||
                              twr != null ||
                              mwrAcum != null)
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    endIndent: 10,
                                    thickness: 1,
                                  ),
                                ),
                                Text('RENTABILIDAD'),
                                Expanded(
                                  child: Divider(
                                    indent: 10,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          if (rentabilidad != null) const SizedBox(height: 10),
                          if (rentabilidad != null)
                            RowBalance(
                              label: 'Simple',
                              data: NumberUtil.percentCompact(rentabilidad!),
                              color: AppColor.textRedGreen(rentabilidad!),
                            ),
                          if (twr != null) const SizedBox(height: 10),
                          if (twr != null)
                            RowBalance(
                              label: 'TWR',
                              data: NumberUtil.percentCompact(twr!),
                              color: AppColor.textRedGreen(twr!),
                            ),
                          if (mwr != null) const SizedBox(height: 10),
                          if (mwrAcum != null)
                            RowBalance(
                              label: 'MWR Acum.',
                              data: NumberUtil.percentCompact(mwrAcum!),
                              color: AppColor.textRedGreen(mwrAcum!),
                            ),
                          if (rentAnual != null || tae != null || mwr != null)
                            const SizedBox(height: 10),
                          if (rentAnual != null || tae != null || mwr != null)
                            const Row(
                              children: [
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
                              data: NumberUtil.percentCompact(rentAnual!),
                              color: AppColor.textRedGreen(rentAnual!),
                            ),
                          if (tae != null) const SizedBox(height: 10),
                          if (tae != null)
                            RowBalance(
                              label: 'TWR (TAE)',
                              data: NumberUtil.percentCompact(tae!),
                              color: AppColor.textRedGreen(tae!),
                            ),
                          if (mwr != null) const SizedBox(height: 10),
                          if (mwr != null)
                            RowBalance(
                              label: 'MWR',
                              data: NumberUtil.percentCompact(mwr!),
                              color: AppColor.textRedGreen(mwr!),
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

  void showPdfFalse({required String msg}) {
    Logger.log(
      dataLog: DataLog(
        msg: msg,
        file: 'main_fondo.dart',
        clase: '_MainFondoState',
        funcion: 'onPressed TextButton',
      ),
    );
    _showMsg();
  }

  void _showMsg() => CustomMessenger(
        context: context,
        msg: 'Archivo no disponible',
        color: AppColor.rojo900,
      ).generateDialog();
}

class RowBalance extends StatelessWidget {
  final String label;
  final String data;
  final Color color;

  const RowBalance({
    super.key,
    required this.label,
    required this.data,
    this.color = Colors.black,
  });

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
