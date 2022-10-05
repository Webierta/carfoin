import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../utils/fecha_util.dart';
import '../utils/number_util.dart';
import '../utils/styles.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/full_screen_modal.dart';
import '../widgets/loading_progress.dart';

class PageMercado extends StatefulWidget {
  const PageMercado({Key? key}) : super(key: key);
  @override
  State<PageMercado> createState() => _MercadoState();
}

class _MercadoState extends State<PageMercado> {
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late Fondo fondoSelect;
  late List<Valor> valoresSelect;
  late List<Valor> operacionesSelect;

  late ApiService apiService;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool? _isValido = false;
  final _isSelected = <bool>[true, false];
  var _tipo = true;

  DateTime now = DateTime.now();
  int _date = 0;
  double _participaciones = 0;
  double _precio = 0;

  @override
  void initState() {
    _date = FechaUtil.dateToEpoch(now);
    _date = FechaUtil.epochToEpochHms(_date);

    carteraProvider = context.read<CarteraProvider>();
    // mejor? => carteraSelect = carteraProvider.carteraSelect;
    carteraSelect = context.read<CarteraProvider>().carteraSelect;
    fondoSelect = context.read<CarteraProvider>().fondoSelect;

    valoresSelect = context.read<CarteraProvider>().valores;
    operacionesSelect = context.read<CarteraProvider>().operaciones;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      apiService = ApiService();
      _dateController.text = FechaUtil.epochToString(_date);
      _partController.text = _participaciones.toString();
      _precioController.text = _precio.toString();
    });
    super.initState();
  }

  _resetControllers() {
    _dateController.text =
        FechaUtil.epochToString(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    _partController.text = '0.0';
    _precioController.text = '0.0';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _partController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  _dialogMercado(BuildContext context) async {
    const String txt =
        'Todas las operaciones de suscripción y reembolso son simulaciones para '
        'ser comparadas con transacciones reales, ficticias o potenciales.\n\n'
        'Cuando se realiza una operación en una fecha en la que existe otra, '
        'la app consulta si se quiere sobrescribir la primera o combinar ambas '
        '(una forma de añadir distintas operaciones en una misma fecha).\n\n'
        'El resultado de combinar dos operaciones será una nueva transacción: '
        'por ejemplo, combinar un aporte inicial de 20 part. con un reembolso '
        'de 30, resulta un reembolso de 10.\n\n'
        'Ten en cuenta que tanto añadir un reembolso como eliminar un aporte '
        '(o reducir su número de part.) entre operaciones, conlleva eliminar '
        'todos los reembolsos posteriores, si los hubiera (para evitar potenciales descuadres).';
    const data = Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(txt, style: TextStyle(fontSize: 16)),
    );
    await Navigator.of(context)
        .push(FullScreenModal(title: 'Operaciones', data: data));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: scaffoldGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(fondoPage),
            ),
            title: const Text('MERCADO'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () async => await _dialogMercado(context),
              ),
            ],
          ),
          body: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                Center(
                  child: Text(
                    fondoSelect.name,
                    style: const TextStyle(color: blue900),
                  ),
                ),
                Center(
                  child: InputChip(
                    label: Text(carteraSelect.name),
                    labelStyle: const TextStyle(color: blue900),
                    avatar: const Icon(Icons.business_center, color: blue900),
                    //iconTheme: const IconThemeData(color: blue900),
                    backgroundColor: blue100,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  alignment: Alignment.center,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return ToggleButtons(
                      renderBorder: false,
                      constraints: BoxConstraints.expand(
                          width: constraints.maxWidth / 2),
                      isSelected: _isSelected,
                      color: gris,
                      selectedColor: blue100,
                      fillColor: blue900,
                      borderColor: gris,
                      selectedBorderColor: blue,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      onPressed: (int index) {
                        setState(() {
                          _isSelected[0] = index == 0 ? true : false;
                          _isSelected[1] = index == 0 ? false : true;
                          _tipo = index == 0 ? true : false;
                        });
                        _resetControllers();
                      },
                      children: [
                        Text('SUSCRIBIR',
                            style: TextStyle(
                                fontWeight:
                                    _tipo ? FontWeight.bold : FontWeight.w300)),
                        Text('REEMBOLSAR',
                            style: TextStyle(
                                fontWeight: !_tipo
                                    ? FontWeight.bold
                                    : FontWeight.w300)),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  onChanged: () => setState(
                      () => _isValido = _formKey.currentState?.validate()),
                  child: Column(
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: TextFormField(
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            errorStyle: TextStyle(height: 0),
                            labelText: 'Fecha',
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          controller: _dateController,
                          validator: (value) {
                            return (value == null || value.isEmpty)
                                ? 'Campo requerido'
                                : null;
                          },
                          readOnly: true,
                          onTap: () async {
                            var fecha = await _selectDate(context);
                            if (fecha != null) {
                              setState(() {
                                // TODO: CONTROL OTRAS TIME ZONE PARA NO REPETIR DATE ??
                                // o epoch +/- 1 day ??
                                //DateTime timeZone = fecha.add(const Duration(hours: 2));
                                //_date = timeZone.millisecondsSinceEpoch ~/ 1000;
                                _date = FechaUtil.dateToEpoch(fecha);
                                _date = FechaUtil.epochToEpochHms(_date);
                                _dateController.text =
                                    FechaUtil.dateToString(date: fecha);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: TextFormField(
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            errorStyle: const TextStyle(fontSize: 0, height: 0),
                            labelText: 'Participaciones',
                            suffixIcon: Icon(_tipo
                                ? Icons.add_shopping_cart
                                : Icons.currency_exchange),
                            border: const OutlineInputBorder(),
                          ),
                          controller: _partController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'(^\-?\d*\.?\d*)'))
                          ],
                          keyboardType: TextInputType.number,
                          validator: (inputPart) {
                            if (inputPart == null ||
                                inputPart.isEmpty ||
                                double.tryParse(inputPart) == null ||
                                double.tryParse(inputPart)! <= 0.0) {
                              return 'Número de participaciones no válido.';
                            }
                            return null;
                          },
                          onTap: () => _partController.clear(),
                          onChanged: (value) {
                            setState(() =>
                                _participaciones = double.tryParse(value) ?? 0);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: TextFormField(
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            errorStyle: const TextStyle(fontSize: 0, height: 0),
                            labelText: 'Precio',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.download, color: blue),
                              onPressed: () async {
                                var precioApi =
                                    await _dialogProgress(context, fondoSelect);
                                if (!mounted) return;
                                if (precioApi != null) {
                                  setState(() {
                                    _precio = precioApi;
                                    _precioController.text =
                                        precioApi.toString();
                                  });
                                } else {
                                  if (!mounted) return;
                                  _showMsg(
                                    msg:
                                        'Dato no disponible. Introduce el precio manualmente',
                                    color: red900,
                                  );
                                }
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          controller: _precioController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'(^\-?\d*\.?\d*)'))
                          ],
                          keyboardType: TextInputType.number,
                          validator: (inputPrecio) {
                            if (inputPrecio == null ||
                                inputPrecio.isEmpty ||
                                double.tryParse(inputPrecio) == null ||
                                double.tryParse(inputPrecio)! <= 0) {
                              return 'Precio no válido.';
                            }
                            return null;
                          },
                          onTap: () {
                            if (_precioController.text == '0.0') {
                              _precioController.clear();
                            }
                          },
                          onChanged: (value) => setState(
                              () => _precio = double.tryParse(value) ?? 0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Importe',
                            border: OutlineInputBorder(),
                            fillColor: Color(0xFFD5D5D5),
                            filled: true,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isValido == true
                                    ? NumberUtil.currency(
                                        _participaciones * _precio)
                                    : '0.0',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: ElevatedButton(
                          onPressed:
                              _isValido == true ? () => _submit(context) : null,
                          child: const Text(
                            'ORDENAR',
                            style: TextStyle(color: blue900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double getPartPrev(Valor valor) {
    double partPre = 0.0;
    List<Valor> valoresPre = [];
    valoresPre = valoresSelect.where((v) => v.date < valor.date).toList();
    for (var valor in valoresPre) {
      if (valor.tipo == 1) {
        partPre += valor.participaciones ?? 0;
      } else if (valor.tipo == 0) {
        partPre -= valor.participaciones ?? 0;
      }
    }
    return partPre;
  }

  _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      Valor newOp = Valor(
          tipo: _tipo ? 1 : 0,
          date: _date,
          participaciones: _participaciones,
          precio: _precio);
      bool opCheck = false;
      bool minusPart = false;

      var valorDb =
          await database.getValorByDate(carteraSelect, fondoSelect, newOp);
      if (valorDb != null && valorDb.date == newOp.date && valorDb.tipo != -1) {
        String tipoOp = valorDb.tipo == 1 ? 'una suscripción' : 'un reembolso';
        String content = 'En esa fecha ya existe una operación: '
            '$tipoOp de ${valorDb.participaciones} participaciones.\n\n'
            'Puedes sobrescribirla o combinar ambas transacciones en una nueva operación.\n\n'
            'Si el resultado es un reembolso o una reducción de participaciones, '
            'se eliminarán los reembolsos posteriores, si existen.\n\n'
            '¿Combinar ambas operaciones?';
        bool? combinarOp = await ConfirmDialog(
          context: context,
          title: '¡Operación concurrente!',
          content: content,
          falseButton: 'Sobreescribir',
        ).generateDialog();

        if (combinarOp == true) {
          double partValordb = valorDb.tipo == 0
              ? -valorDb.participaciones!
              : valorDb.participaciones!;
          double partNewValor = newOp.tipo == 0
              ? -newOp.participaciones!
              : newOp.participaciones!;
          double partComb = partValordb + partNewValor;
          int tipoComb = partComb > 0 ? 1 : 0;
          partComb = partComb.abs();

          if (newOp.tipo == 0) {
            minusPart = true;
            var partPrev = getPartPrev(valorDb);
            var partResto = partPrev + valorDb.participaciones!;
            if (partResto <= 0 || partComb > partResto || partComb == 0) {
              opCheck = false;
            } else {
              opCheck = true;
            }
          } else {
            if (valorDb.participaciones! > partComb) {
              minusPart = true;
            }
            opCheck = true;
          }
          if (opCheck) {
            newOp.tipo = tipoComb;
            newOp.participaciones = partComb;
            if (partComb == 0) {
              newOp.tipo = -1;
              newOp.participaciones = null;
            }
          }
        } else if (combinarOp == false) {
          if (newOp.tipo == 0) {
            minusPart = true;
            var partPrev = getPartPrev(newOp);
            var partResto = partPrev; // - valorDb.participaciones!;
            if (partResto <= 0 || newOp.participaciones! > partResto) {
              opCheck = false;
            } else {
              opCheck = true;
            }
          } else {
            if (valorDb.participaciones! > newOp.participaciones!) {
              minusPart = true;
            }
            opCheck = true;
          }
        } else {
          return;
        }
      } else {
        if (newOp.tipo == 0) {
          minusPart = true;
          var partPrev = getPartPrev(newOp);
          var partResto = partPrev; // - valorDb.participaciones!;
          if (partResto <= 0 || newOp.participaciones! > partResto) {
            opCheck = false;
          } else {
            opCheck = true;
          }
        } else {
          opCheck = true;
        }
      }

      if (opCheck == false) {
        _showMsg(
            msg: 'No se puede hacer un reembolso de participaciones no '
                'disponibles ni operaciones sin ninguna participación',
            color: red900);
        return;
      }
      if (minusPart) {
        await database.deleteAllReembolsosPosteriores(
            carteraSelect, fondoSelect, newOp);
      }
      // INSERT O UPDATE OP ?? (SET VALORES PARA UPDATE UI ??)
      await database.insertValor(carteraSelect, fondoSelect, newOp);
      carteraProvider.addValor(carteraSelect, fondoSelect, newOp);
      if (!mounted) return;
      context.go(fondoPage);
    }
  }

  Future<DateTime?>? _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      locale: const Locale('es'),
      //initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime(1997, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      return FechaUtil.dateToDateHms(picked);
    }
    return picked;
  }

  _dialogProgress(BuildContext context, Fondo fondo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Loading(titulo: 'Cargando valor liquidativo...');
      },
    );
    double? getPrecio = await _getPrecioApi(context, fondo);
    _pop();
    return getPrecio;
  }

  Future<double?>? _getPrecioApi(BuildContext context, Fondo fondo) async {
    String fromAndTo = FechaUtil.epochToString(_date, formato: 'yyyy-MM-dd');
    final getDateApiRange =
        await apiService.getDataApiRange(fondo.isin, fromAndTo, fromAndTo);
    if (getDateApiRange != null && getDateApiRange.isNotEmpty) {
      return getDateApiRange.first.price;
    }
    return null;
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
