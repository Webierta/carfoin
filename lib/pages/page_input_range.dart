import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cartera_provider.dart';

class PageInputRange extends StatefulWidget {
  const PageInputRange({Key? key}) : super(key: key);
  @override
  State<PageInputRange> createState() => _PageInputRangeState();
}

class _PageInputRangeState extends State<PageInputRange> {
  DateTimeRange? _dateRange;
  final _initDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 5)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final fondoSelect = context.read<CarteraProvider>().fondoSelect;
    return Scaffold(
      appBar: AppBar(title: const Text('Descarga valores')),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.assessment, size: 32),
                  title: Text(fondoSelect.name),
                  subtitle: const Text('Selecciona un intervalo de fechas:'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: InkWell(
                    onTap: () async {
                      var newRange = await _datePicker(context, DatePickerEntryMode.inputOnly);
                      if (newRange != null) {
                        setState(() => _dateRange = newRange);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Fechas',
                      ),
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(_dateRange?.start ?? _initDateRange.start)} - '
                              '${DateFormat('dd/MM/yyyy').format(_dateRange?.end ?? _initDateRange.end)}',
                            ),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF2196F3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.date_range, color: Color(0xFF2196F3)),
                    onPressed: () async {
                      var newRange = await _datePicker(context, DatePickerEntryMode.calendarOnly);
                      if (newRange != null) {
                        setState(() => _dateRange = newRange);
                      }
                    },
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text('CANCELAR'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        child: const Text('ACEPTAR'),
                        onPressed: () {
                          if (_dateRange != null) {
                            var range =
                                DateTimeRange(start: _dateRange!.start, end: _dateRange!.end);
                            Navigator.pop(context, range);
                          } else {
                            var range = _initDateRange;
                            Navigator.pop(context, range);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _datePicker(BuildContext context, DatePickerEntryMode mode) async {
    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primarySwatch: Colors.blue,
            dialogBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2196F3),
              elevation: 10,
              foregroundColor: Color(0xFFFFFFFF),
            ),
          ),
          child: child ?? const Text(''),
        );
      },
      initialDateRange: DateTimeRange(
        //start: DateTime.now().subtract(const Duration(days: 5)),
        //end: DateTime.now(),
        start: _initDateRange.start,
        end: _initDateRange.end,
      ),
      firstDate: DateTime(2018, 1, 1),
      lastDate: DateTime.now(),
      //currentDate: DateTime.now(),
      //initialEntryMode: DatePickerEntryMode.inputOnly,
      //initialEntryMode = DatePickerEntryMode.calendarOnly,
      initialEntryMode: mode,
      locale: const Locale('es'),
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
      fieldStartHintText: 'dd/mm/aaaa',
      fieldEndHintText: 'dd/mm/aaaa',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
      saveText: 'ACEPTAR',
      errorFormatText: 'Formato no válido.',
      errorInvalidText: 'Fuera de rango.',
      errorInvalidRangeText: 'Período no válido.',
    );
    return newRange;
  }
}
