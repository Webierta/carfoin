import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../models/cartera_provider.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/fecha_util.dart';

class PageInputRange extends StatefulWidget {
  const PageInputRange({super.key});
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
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    final fondoSelect = context.read<CarteraProvider>().fondoSelect;
    final carteraSelect = context.read<CarteraProvider>().carteraSelect;
    return Container(
      decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
      child: Scaffold(
        appBar: AppBar(title: const Text('Descarga histórico')),
        body: ListView(
          //padding: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.assessment, size: 32),
                      title: Text(
                        fondoSelect.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: const Icon(Icons.business_center),
                          label: Text(carteraSelect.name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(left: 18),
                      child: Text('Selecciona un intervalo de fechas:'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        title: InkWell(
                          onTap: () async {
                            var newRange = await _datePicker(context,
                                DatePickerEntryMode.inputOnly, darkTheme);
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(_dateRange?.start ?? _initDateRange.start)} - '
                                    '${DateFormat('dd/MM/yyyy').format(_dateRange?.end ?? _initDateRange.end)}',
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      color: AppColor.light),
                                ],
                              ),
                            ),
                          ),
                        ),
                        trailing: CircleAvatar(
                          backgroundColor: AppColor.ambar,
                          child: IconButton(
                            icon: const Icon(Icons.date_range,
                                color: AppColor.light900),
                            onPressed: () async {
                              var newRange = await _datePicker(context,
                                  DatePickerEntryMode.calendarOnly, darkTheme);
                              if (newRange != null) {
                                setState(() => _dateRange = newRange);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('CANCELAR'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('ACEPTAR'),
                          onPressed: () {
                            if (_dateRange != null) {
                              var range = DateTimeRange(
                                  start: _dateRange!.start,
                                  end: _dateRange!.end);
                              Navigator.pop(context, range);
                            } else {
                              var range = _initDateRange;
                              Navigator.pop(context, range);
                            }
                          },
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
    );
  }

  _datePicker(
      BuildContext context, DatePickerEntryMode mode, bool isDark) async {
    DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      //builder: (BuildContext context, Widget? child) {
      //return child ?? const Text('');
      /* return Theme(
          data: ThemeData(
            primarySwatch: Colors.blue,
            dialogBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColor.azul,
              elevation: 10,
              foregroundColor: Color(0xFFFFFFFF),
            ),
          ),
          child: child ?? const Text(''),
        ); */
      //},
      initialDateRange: DateTimeRange(
        start: _initDateRange.start,
        end: _initDateRange.end,
      ),
      firstDate: DateTime(1997, 1, 1),
      lastDate: DateTime.now(),
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

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? AppColor.boxDark : AppColor.light,
            ),
          ),
          child: child ?? const Text(''),
        );
      },
    );

    if (newRange != null) {
      DateTime start = FechaUtil.dateToDateHms(newRange.start);
      DateTime end = FechaUtil.dateToDateHms(newRange.end);
      newRange = DateTimeRange(start: start, end: end);
    }
    return newRange;
  }
}
