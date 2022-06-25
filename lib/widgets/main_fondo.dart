import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';
import '../utils/stats.dart';
import 'hoja_calendario.dart';
//import 'hoja_calendario.dart';

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
    final List<Valor> operaciones = context.watch<CarteraProvider>().operaciones;

    int dia = 0;
    String mesYear = '';
    if (valores.isNotEmpty) {
      dia = FechaUtil.epochToDate(valores.first.date).day;
      mesYear = FechaUtil.epochToString(valores.first.date, formato: 'MMM yy');
    }

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
      return [
        for (var op in operaciones)
          DataRow(cells: [
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(FechaUtil.epochToString(op.date, formato: 'dd/MM/yy')),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                NumberFormat.decimalPattern('es')
                    .format(op.tipo == 1 ? op.participaciones : (op.participaciones ?? 0) * -1),
                style: TextStyle(
                  color: op.tipo == 1 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(NumberFormat.decimalPattern('es').format(op.precio)),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(NumberFormat.decimalPattern('es').format(
                  double.parse(((op.participaciones ?? 0) * op.precio).toStringAsFixed(2)))),
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
                FechaUtil.epochToString(valores.first.date, formato: 'dd/MM/yy'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                stats.totalParticipaciones() != null
                    ? NumberFormat.decimalPattern('es')
                        .format(double.parse(stats.totalParticipaciones()!.toStringAsFixed(2)))
                    : '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                NumberFormat.decimalPattern('es').format(valores.first.precio),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            DataCell(Align(
              alignment: Alignment.centerRight,
              child: Text(
                stats.resultado() != null
                    ? NumberFormat.decimalPattern('es')
                        .format(double.parse(stats.resultado()!.toStringAsFixed(2)))
                    : '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            )),
            const DataCell(Text('')),
          ],
        ),
      ];
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: [
                ListTile(
                  //contentPadding: const EdgeInsets.only(bottom: 12, left: 12, right: 12, top: 0),
                  leading: const Icon(Icons.assessment, size: 32, color: Color(0xFF2196F3)),
                  title: Text(
                    fondoSelect.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    fondoSelect.isin,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                valores.isEmpty
                    ? const Text(
                        'Sin datos. Descarga el último valor o un intervalo de valores históricos.')
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBDEFB),
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HojaCalendario(epoch: valores.first.date),
                                    /*Container(
                                      height: 80, // or AspectRadio() parent
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        border: Border.all(
                                          color: const Color(0xFF0D47A1),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            color: Colors.blue,
                                            child: Text(
                                              mesYear,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '$dia',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),*/
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'V.L. ${valores.first.precio} ${fondoSelect.divisa}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_getDiferencia() != null)
                                      Text(_getDiferencia()!.toStringAsFixed(2),
                                          style: TextStyle(
                                            //fontSize: 16,
                                            color: _getDiferencia()! < 0
                                                ? const Color(0xFFF44336)
                                                : const Color(0xFF4CAF50),
                                          )),
                                    const Spacer(),
                                    (stats.resultado() != null && stats.resultado() != 0)
                                        ? Text(
                                            '${NumberFormat.decimalPattern('es').format(double.parse(stats.resultado()!.toStringAsFixed(2)))} ${fondoSelect.divisa}',
                                            style: const TextStyle(
                                                color: Color(0xFF0D47A1), fontSize: 18),
                                          )
                                        : const Text('Sin inversiones'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                /*: FractionallySizedBox(
                        widthFactor: 0.9,
                        child: Container(
                          //padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2196F3), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  FechaUtil.epochToString(valores.first.date),
                                  //style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const VerticalDivider(color: Color(0xFF2196F3), thickness: 2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    '${valores.first.precio} ${fondoSelect.divisa}',
                                    //style: Theme.of(context).textTheme.titleLarge,
                                    style:
                                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const VerticalDivider(color: Color(0xFF2196F3), thickness: 2),
                                if (_getDiferencia() != null)
                                  Text(_getDiferencia()!.toStringAsFixed(2),
                                      style: TextStyle(
                                        //fontSize: 16,
                                        color: _getDiferencia()! < 0
                                            ? const Color(0xFFF44336)
                                            : const Color(0xFF4CAF50),
                                      )),
                              ],
                            ),
                          ),
                        ),
                      ),*/
                if (valores.isNotEmpty) const SizedBox(height: 20),
                if (valores.length > 1)
                  FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Mínimo', style: TextStyle(fontSize: 16)),
                            Text('Máximo', style: TextStyle(fontSize: 16)),
                            Text('Media', style: TextStyle(fontSize: 16)),
                            Text('Volatilidad', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                stats.datePrecioMinimo() != null
                                    ? FechaUtil.epochToString(stats.datePrecioMinimo()!,
                                        formato: 'dd/MM/yy')
                                    : '',
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                stats.datePrecioMaximo() != null
                                    ? FechaUtil.epochToString(stats.datePrecioMaximo()!,
                                        formato: 'dd/MM/yy')
                                    : '',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(NumberFormat.decimalPattern('es').format(stats.precioMinimo()),
                                style: const TextStyle(fontSize: 16)),
                            Text(NumberFormat.decimalPattern('es').format(stats.precioMaximo()),
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                stats.precioMedio() != null
                                    ? NumberFormat.decimalPattern('es').format(
                                        double.parse(stats.precioMedio()!.toStringAsFixed(2)))
                                    : '',
                                style: const TextStyle(fontSize: 16)),
                            Text(
                              stats.volatilidad() != null
                                  ? NumberFormat.decimalPattern('es')
                                      .format(double.parse(stats.volatilidad()!.toStringAsFixed(2)))
                                  : '',
                              style: const TextStyle(fontSize: 16),
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
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const Icon(Icons.compare_arrows, size: 32, color: Color(0xFF2196F3)),
                  /*title: FittedBox(
                    child: Text('OPERACIONES', style: Theme.of(context).textTheme.titleLarge),
                  ),*/
                  title: const Text(
                    'OPERACIONES',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 20),
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: const Color(0xFFFFC107),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart, color: Color(0xFF0D47A1)),
                      onPressed: () => Navigator.of(context).pushNamed(RouteGenerator.mercadoPage),
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
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              //headingRowHeight: 0,
                              columnSpacing: 20,
                              dataRowHeight: 70,
                              //horizontalMargin: 10,
                              headingRowColor:
                                  MaterialStateColor.resolveWith((states) => Colors.blue),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              dataTextStyle: const TextStyle(fontSize: 18, color: Colors.black),
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(
                      Icons.balance,
                      size: 32,
                      color: Color(0xFF2196F3),
                    ), // Icons.balance
                    title: Text('BALANCE', style: TextStyle(fontSize: 20)),
                    /*subtitle: Align(
                      alignment: Alignment.topLeft,
                      child: Chip(
                        //padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: const Color(0xFFBBDEFB),
                        avatar:
                            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF0D47A1)),
                        label: Text(
                          FechaUtil.epochToString(
                            valores.first.date,
                            formato: 'dd/MM/yy',
                          ),
                          style: const TextStyle(color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ),*/
                    //trailing: HojaCalendario(epoch: valores.first.date),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text('Inversión', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                stats.inversion() != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(double.parse(stats.inversion()!.toStringAsFixed(2)))
                                    : '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Resultado', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                stats.resultado() != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(double.parse(stats.resultado()!.toStringAsFixed(2)))
                                    : '',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Rendimiento', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                stats.balance() != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(double.parse(stats.balance()!.toStringAsFixed(2)))
                                    : '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: fondoSelect.balance != null && fondoSelect.balance! < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 16,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Rentabilidad', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                stats.rentabilidad() != null
                                    ? NumberFormat.decimalPercentPattern(
                                        locale: 'es',
                                        decimalDigits: 2,
                                      ).format(stats.rentabilidad())
                                    : '',
                                style: TextStyle(
                                  color: fondoSelect.rentabilidad != null &&
                                          fondoSelect.rentabilidad! < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('TAE', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                stats.tae() != null
                                    ? NumberFormat.decimalPercentPattern(
                                        locale: 'es',
                                        decimalDigits: 2,
                                      ).format(stats.tae())
                                    : '',
                                style: TextStyle(
                                  color: fondoSelect.tae != null && fondoSelect.tae! < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 16,
                                ),
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
      ],
    );
  }
}
