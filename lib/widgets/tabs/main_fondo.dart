import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../router/routes_const.dart';
import '../../services/database_helper.dart';
import '../../services/preferences_service.dart';
import '../../utils/fecha_util.dart';
import '../../utils/number_util.dart';
import '../../utils/stats.dart';
import '../../utils/styles.dart';
import '../hoja_calendario.dart';

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
  bool _isConfirmDelete = true;
  late Stats stats;

  getSharedPrefs() async {
    await PreferencesService.getBool(keyConfirmDeletePref).then((value) {
      setState(() => _isConfirmDelete = value);
    });
  }

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
      await getSharedPrefs();
      await setValores(carteraSelect, fondoSelect);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final carteraProvider = context.read<CarteraProvider>();
    //final carteraSelect = carteraProvider.carteraSelect;
    //final fondoSelect = carteraProvider.fondoSelect;
    final List<Valor> valores = context.watch<CarteraProvider>().valores;
    final List<Valor> operaciones =
        context.watch<CarteraProvider>().operaciones;

    /*int dia = 0;
    String mesYear = '';
    if (valores.isNotEmpty) {
      dia = FechaUtil.epochToDate(valores.first.date).day;
      mesYear = FechaUtil.epochToString(valores.first.date, formato: 'MMM yy');
    }*/

    stats = Stats(valores);
    //carteraProvider.addValores(carteraSelect, fondoSelect, valores);

    double? _getDiferencia() {
      if (valores.length > 1) {
        var last = valores.first.precio;
        var prev = valores[1].precio;
        return last - prev;
      }
      return null;
    }

    _confirmDeleteOperacion(BuildContext context, Valor op) async {
      return showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text('Eliminar Operación'),
              content: const Text(
                  'Esta acción elimina esta operación (y eventualmente operaciones posteriores) '
                  'pero mantiene los valores liquidativos de las fechas afectadas'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    primary: const Color(0xFFFFFFFF),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          });
    }

    _deleteOperacion(Valor op) async {
      await database.deleteOperacion(carteraSelect, fondoSelect, op);
      carteraProvider.removeOperacion(fondoSelect, op);
      await setValores(carteraSelect, fondoSelect);
    }

    List<DataColumn> _createColumns() {
      return const <DataColumn>[
        DataColumn(label: Text('FECHA')),
        DataColumn(label: Text('PART.')),
        DataColumn(label: Text('V.L.')),
        DataColumn(label: Text('IMPORTE')),
        DataColumn(label: Text('')),
      ];
    }

    List<DataRow> _createRows() {
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
                style: TextStyle(
                  color: op.tipo == 1
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              //child: Text(NumberFormat.decimalPattern('es').format(op.precio)),
              child: Text(NumberUtil.decimal(op.precio)),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              /*child: Text(NumberFormat.decimalPattern('es').format(double.parse(
                  ((op.participaciones ?? 0) * op.precio).toStringAsFixed(2)))),*/
              child: Text(NumberUtil.decimalFixed(
                  (op.participaciones ?? 0) * op.precio,
                  long: false)),
            )),
            DataCell(IconButton(
              onPressed: () async {
                if (_isConfirmDelete) {
                  var resp = await _confirmDeleteOperacion(context, op);
                  if (resp) {
                    _deleteOperacion(op);
                  }
                } else {
                  if (op.tipo == 1) {
                    var resp = await _confirmDeleteOperacion(context, op);
                    if (resp) {
                      _deleteOperacion(op);
                    }
                  } else {
                    _deleteOperacion(op);
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
                    /*? NumberFormat.decimalPattern('es').format(double.parse(
                        stats.totalParticipaciones()!.toStringAsFixed(2)))*/
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
                //NumberFormat.decimalPattern('es').format(valores.first.precio),
                NumberUtil.decimal(valores.first.precio),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                stats.resultado() != null
                    /*? NumberFormat.decimalPattern('es').format(
                        double.parse(stats.resultado()!.toStringAsFixed(2)))*/
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

    double? _inversion;
    double? _resultado;
    double? _rendimiento;
    double? _rentabilidad;
    double? _rentAnual;
    double? _twr;
    double? _tae;
    double? _mwr;
    double? _mwrAcum;
    if (operaciones.isNotEmpty) {
      _inversion = stats.inversion();
      _resultado = stats.resultado();
      _rendimiento = stats.balance();
      _rentabilidad = stats.rentabilidad();
      if (_rentabilidad != null) {
        _rentAnual = stats.anualizar(_rentabilidad);
      }
      _twr = stats.twr();
      if (_twr != null) {
        _tae = stats.anualizar(_twr);
      }
      _mwr = stats.mwr();
      if (_mwr != null) {
        _mwrAcum = stats.mwrAcum(_mwr);
      }
    }

    bool _allStatsIsNull() {
      List<double?> listStats = [
        _inversion,
        _resultado,
        _rendimiento,
        _rentabilidad,
        _rentAnual,
        _twr,
        _tae,
        _mwr,
        _mwrAcum
      ];
      for (var st in listStats) {
        if (st != null) return false;
      }
      return true;
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            //padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            //padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.assessment,
                    size: 32,
                    color: Color(0xFF2196F3),
                  ),
                  title: Text(
                    fondoSelect.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: styleTitle,
                    /*style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2196F3),
                    ),*/
                  ),
                  subtitle: Text(
                    fondoSelect.isin,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
                valores.isEmpty
                    ? const Text(
                        'Sin datos. Descarga el último valor o un intervalo de valores históricos.')
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
                                    if (fondoSelect.divisa == 'EUR' ||
                                        fondoSelect.divisa == 'USD')
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Text(
                                          '${fondoSelect.divisa}',
                                          textScaleFactor: 2.5,
                                          style: const TextStyle(
                                              color: Color(0xFF90CAF9)),
                                        ),
                                      ),
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
                                              '${valores.first.precio}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                                //fontSize: 16,
                                                //fontWeight: FontWeight.bold,
                                                color: Color(0xFF0D47A1),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.sell,
                                                color: Color(0xFF2196F3)),
                                          ],
                                        ),
                                        if (_getDiferencia() != null)
                                          Row(
                                            children: [
                                              Text(
                                                _getDiferencia()!
                                                    .toStringAsFixed(2),
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w400,
                                                    color: textRedGreen(
                                                        _getDiferencia()!)),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.iso,
                                                  color: Color(0xFF2196F3)),
                                            ],
                                          ),
                                      ],
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
                                                stats.precioMedio()!)
                                            : ''),
                                        Text(stats.volatilidad() != null
                                            ? NumberUtil.decimalFixed(
                                                stats.volatilidad()!)
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: [
                ListTile(
                  //contentPadding: const EdgeInsets.all(12),
                  leading: const Icon(Icons.compare_arrows,
                      size: 32, color: Color(0xFF2196F3)),
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
                      backgroundColor: const Color(0xFFFFC107),
                      child: IconButton(
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Color(0xFF0D47A1),
                        ),
                        onPressed: () => context.go(mercadoPage),
                      ),
                    ),
                  ),
                ),
                operaciones.isEmpty
                    ? const Text('Sin datos de operaciones.\n'
                        'Ordena transacciones en el mercado para seguir la evolución de tu inversión.')
                    : Column(
                        //crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FittedBox(
                            fit: BoxFit.fill,
                            child: DataTable(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF2196F3),
                                  width: 2,
                                ),
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
                              columns: _createColumns(),
                              rows: _createRows(),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (operaciones.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.balance,
                      size: 32,
                      color: Color(0xFF2196F3),
                    ), // Icons.balance
                    title: const Text(
                      'BALANCE',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFFFFFF),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFFFC107),
                        child: IconButton(
                          onPressed: () => context.go(infoBalancePage),
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF0D47A1),
                          ),
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
                          if (_allStatsIsNull())
                            const Text('Error en los cálculos'),
                          if (_inversion != null)
                            RowBalance(
                              label: 'Inversión',
                              data: NumberUtil.decimalFixed(_inversion),
                            ),
                          if (_resultado != null) const SizedBox(height: 10),
                          if (_resultado != null)
                            RowBalance(
                              label: 'Resultado',
                              data: NumberUtil.decimalFixed(_resultado),
                            ),
                          if (_rendimiento != null) const SizedBox(height: 10),
                          if (_rendimiento != null)
                            RowBalance(
                              label: 'Rendimiento',
                              data: NumberUtil.decimalFixed(_rendimiento),
                            ),
                          if (_rentabilidad != null ||
                              _twr != null ||
                              _mwrAcum != null)
                            const SizedBox(height: 10),
                          if (_rentabilidad != null ||
                              _twr != null ||
                              _mwrAcum != null)
                            const Center(child: Text('RENTABILIDAD')),
                          if (_rentabilidad != null) const SizedBox(height: 10),
                          if (_rentabilidad != null)
                            RowBalance(
                              label: 'Simple',
                              data: NumberUtil.percent(_rentabilidad),
                              color: textRedGreen(_rentabilidad),
                            ),
                          if (_twr != null) const SizedBox(height: 10),
                          if (_twr != null)
                            RowBalance(
                              label: 'TWR',
                              data: NumberUtil.percent(_twr),
                              color: textRedGreen(_twr),
                            ),
                          if (_mwr != null) const SizedBox(height: 10),
                          if (_mwrAcum != null)
                            RowBalance(
                              label: 'MWR Acum.',
                              data: NumberUtil.percent(_mwrAcum),
                              color: textRedGreen(_mwrAcum),
                            ),
                          if (_rentAnual != null ||
                              _tae != null ||
                              _mwr != null)
                            const SizedBox(height: 10),
                          if (_rentAnual != null ||
                              _tae != null ||
                              _mwr != null)
                            const Center(child: Text('RENTABILIDAD ANUAL')),
                          if (_rentAnual != null) const SizedBox(height: 10),
                          if (_rentAnual != null)
                            RowBalance(
                              label: 'Simple Anual',
                              data: NumberUtil.percent(_rentAnual),
                              color: textRedGreen(_rentAnual),
                            ),
                          if (_tae != null) const SizedBox(height: 10),
                          if (_tae != null)
                            RowBalance(
                              label: 'TWR (TAE)',
                              data: NumberUtil.percent(_tae),
                              color: textRedGreen(_tae),
                            ),
                          if (_mwr != null) const SizedBox(height: 10),
                          if (_mwr != null)
                            RowBalance(
                              label: 'MWR',
                              data: NumberUtil.percent(_mwr),
                              color: textRedGreen(_mwr),
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
            child: FittedBox(
              //fit: BoxFit.scaleDown,
              child: Text(
                data,
                style: TextStyle(color: color, fontSize: 16),
                maxLines: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
