import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';

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

  getSharedPrefs() async {
    await PreferencesService.getBool(keyConfirmDeletePref).then((value) {
      setState(() => _isConfirmDelete = value);
    });
  }

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
      await getSharedPrefs();
      await setValores(carteraSelect, fondoSelect);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final carteraProvider = context.read<CarteraProvider>();
    final carteraSelect = carteraProvider.carteraSelect;
    final fondoSelect = carteraProvider.fondoSelect;
    final valores = context.watch<CarteraProvider>().valores;
    final operaciones = context.watch<CarteraProvider>().operaciones;

    double? _getDiferencia() {
      if (valores.length > 1) {
        var last = valores.first.precio;
        var prev = valores[1].precio;
        return last - prev;
      }
      return null;
    }

    List<DataColumn> _createColumns() {
      return const <DataColumn>[
        DataColumn(label: Text('FECHA')),
        DataColumn(label: Text('PART.')),
        DataColumn(label: Text('PRECIO')),
        DataColumn(label: Text('VALOR')),
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
                  // TODO: DIALOGO CONFIRMAR
                  // TODO: AÑADIR OPCION AL MENU
                  print('OPEN DIALOGO CONFIRMAR');
                } else {
                  await database.deleteOperacion(carteraSelect, fondoSelect, op);
                  carteraProvider.removeOperacion(fondoSelect, op);
                  await setValores(carteraSelect, fondoSelect);
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
                NumberFormat.decimalPattern('es').format(fondoSelect.totalParticipaciones),
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
                NumberFormat.decimalPattern('es')
                    .format(double.parse(fondoSelect.resultado!.toStringAsFixed(2))),
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
      padding: const EdgeInsets.all(10),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: [
                ListTile(
                  //contentPadding: const EdgeInsets.all(10),
                  leading: const Icon(Icons.assessment, size: 32, color: Color(0xFF0D47A1)),
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
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0D47A1), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              FechaUtil.epochToString(valores.first.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${valores.first.precio} ${fondoSelect.divisa}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_getDiferencia() != null)
                              Text(_getDiferencia()!.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _getDiferencia()! < 0
                                        ? const Color(0xFFF44336)
                                        : const Color(0xFF4CAF50),
                                  )),
                          ],
                        ),
                      ),
                if (valores.isNotEmpty) const SizedBox(height: 20),
                if (valores.length > 1)
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Mínimo', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  fondoSelect.dateMinimo != null
                                      ? FechaUtil.epochToString(fondoSelect.dateMinimo!,
                                          formato: 'dd/MM/yy')
                                      : '',
                                  style: const TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                fondoSelect.precioMinimo != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(fondoSelect.precioMinimo)
                                    : '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Máximo', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  fondoSelect.dateMaximo != null
                                      ? FechaUtil.epochToString(fondoSelect.dateMaximo!,
                                          formato: 'dd/MM/yy')
                                      : '',
                                  style: const TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                fondoSelect.precioMaximo != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(fondoSelect.precioMaximo)
                                    : '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Media', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                fondoSelect.precioMedio != null
                                    ? NumberFormat.decimalPattern('es')
                                        .format(fondoSelect.precioMedio)
                                    : '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Volatilidad', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                fondoSelect.volatilidad != null
                                    ? fondoSelect.volatilidad!.toStringAsFixed(2)
                                    : '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                  leading: const Icon(Icons.compare_arrows, size: 32, color: Color(0xFF0D47A1)),
                  title: Text('OPERACIONES', style: Theme.of(context).textTheme.titleLarge),
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
                  ListTile(
                    leading: const Icon(
                      Icons.savings,
                      size: 32,
                      color: Color(0xFF0D47A1),
                    ), // Icons.balance
                    title: Text('BALANCE', style: Theme.of(context).textTheme.titleLarge),
                    trailing: Chip(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: const Color(0xFF0D47A1),
                      avatar: const Icon(Icons.calendar_today, size: 20, color: Color(0xFFFFFFFF)),
                      label: Text(
                        FechaUtil.epochToString(
                          valores.first.date,
                          formato: 'dd/MM/yy',
                        ),
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text('Inversión', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  NumberFormat.decimalPattern('es').format(
                                      double.parse(fondoSelect.inversion!.toStringAsFixed(2))),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ))
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Resultado', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  NumberFormat.decimalPattern('es').format(
                                      double.parse(fondoSelect.resultado!.toStringAsFixed(2))),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Rendimiento', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  NumberFormat.decimalPattern('es').format(
                                      double.parse(fondoSelect.balance!.toStringAsFixed(2))),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: fondoSelect.balance! < 0 ? Colors.red : Colors.green,
                                    fontSize: 16,
                                  ))
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Rentabilidad', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              Text(
                                  NumberFormat.decimalPercentPattern(
                                    locale: 'es',
                                    decimalDigits: 2,
                                  ).format(fondoSelect.rentabilidad),
                                  style: TextStyle(
                                    color:
                                        fondoSelect.rentabilidad! < 0 ? Colors.red : Colors.green,
                                    fontSize: 16,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('TAE', style: TextStyle(fontSize: 16)),
                              const Spacer(),
                              FittedBox(
                                child: Text(
                                    NumberFormat.decimalPercentPattern(
                                      locale: 'es',
                                      decimalDigits: 2,
                                    ).format(fondoSelect.tae),
                                    style: TextStyle(
                                      color: fondoSelect.tae! < 0 ? Colors.red : Colors.green,
                                      fontSize: 16,
                                    )),
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
