import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/custom_dialog.dart';
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
  //int _date = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  double _participaciones = 0;
  double _precio = 0;

  @override
  void initState() {
    /// TEST EPOCH HMS
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

  Future<void> _dialogMercado(BuildContext context) async {
    return await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 0),
            scrollable: true,
            title: const Text('Operaciones'),
            content: ListBody(
              children: const [
                Text('Todas las operaciones de suscripción y reembolso son '
                    'simulaciones para ser comparadas con '
                    'transacciones reales, ficticias o potenciales.'),
                SizedBox(height: 8),
                Text('Cuando se realiza una operación en una fecha en la que '
                    'existe otra, la app consulta si se quiere sobrescribir '
                    'la primera o combinar ambas (una forma de añadir distintas '
                    'operaciones en una misma fecha).'),
                SizedBox(height: 8),
                Text('El resultado de combinar dos operaciones será una '
                    'nueva transacción: por ejemplo, combinar un aporte inicial de '
                    '20 part. con un reembolso de 30, resulta un reembolso de 10.'),
                SizedBox(height: 8),
                Text('Ten en cuenta que tanto añadir un reembolso como '
                    'eliminar un aporte (o reducir su número de part.) entre '
                    'operaciones, conlleva eliminar todos los reembolsos posteriores, '
                    'si los hubiera (para evitar potenciales descuadres).'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    //var carteraSelect = context.read<CarteraProvider>().carteraSelect;
    //var fondoSelect = context.read<CarteraProvider>().fondoSelect;
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
          body: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10),
            children: [
              ListTile(
                title: Align(
                  alignment: Alignment.center,
                  child: Text(fondoSelect.name),
                ),
                subtitle: Align(
                  alignment: Alignment.center,
                  child: Chip(
                    padding: const EdgeInsets.only(left: 10, right: 20),
                    backgroundColor: blue100,
                    avatar: const Icon(Icons.business_center, color: blue900),
                    label: Text(
                      carteraSelect.name,
                      style: const TextStyle(color: blue900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Center(
                  child: FittedBox(
                    child: ToggleButtons(
                      isSelected: _isSelected,
                      color: gris,
                      selectedColor: blue,
                      fillColor: blue100,
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'SUSCRIBIR',
                            style: TextStyle(
                              fontWeight:
                                  _tipo ? FontWeight.bold : FontWeight.w300,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'REEMBOLSAR',
                            style: TextStyle(
                              fontWeight:
                                  !_tipo ? FontWeight.bold : FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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

                              ///DateTime timeZone = fecha.add(const Duration(hours: 2));
                              ///_date = timeZone.millisecondsSinceEpoch ~/ 1000;

                              /// TEST EPOCH HMS
                              //DateTime fechaHMS = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0, 0, 0);
                              //_date = fecha.millisecondsSinceEpoch ~/ 1000;
                              _date = FechaUtil.dateToEpoch(fecha);
                              _date = FechaUtil.epochToEpochHms(_date);

                              _dateController.text =
                                  FechaUtil.dateToString(date: fecha);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 30),
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
                              //Loading(context).openDialog(title: 'Obteniendo valor liquidativo...');
                              //const LoadingProgress(titulo: 'Obteniendo valor liquidativo...');
                              ///var precioApi = await _getPrecioApi(context, fondoOn);
                              var precioApi =
                                  await _dialogProgress(context, fondoSelect);
                              if (!mounted) return;
                              //Loading(context).closeDialog();
                              if (precioApi != null) {
                                setState(() {
                                  _precio = precioApi;
                                  _precioController.text = precioApi.toString();
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
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 20),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: ElevatedButton(
                        onPressed:
                            _isValido == true ? () => _submit(context) : null,
                        child: const Text('ORDENAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showDialogOp(Valor valorDb) async {
    String tipoOp = valorDb.tipo == 1 ? 'una suscripción' : 'un reembolso';
    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 0),
          scrollable: true,
          actionsAlignment: MainAxisAlignment.spaceBetween,
          title: const Text('Operación previa'),
          content: ListBody(
            children: [
              Text('En esa fecha ya existe una operación: '
                  '$tipoOp de ${valorDb.participaciones} participaciones.'),
              const SizedBox(height: 8),
              const Text('Puedes sobrescribirla o combinar ambas '
                  'transacciones en una nueva operación.'),
              const SizedBox(height: 8),
              const Text('Si el resultado es un reembolso o una reducción de '
                  'participaciones se eliminarán los reembolsos posteriores, si existen.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Sobreescribir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Combinar'),
            ),
          ],
        );
      },
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
      //Stats stats = Stats(valoresSelect);
      //var participaciones = stats.totalParticipaciones() ?? 0;
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
        bool? combinarOp = await _showDialogOp(valorDb);
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
      /// TEST EPOCH HMS
      //return  = DateTime(picked.year, picked.month, picked.day, 0, 0, 0, 0, 0);
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

  void _showMsg({required String msg, Color? color}) {
    CustomDialog customDialog = const CustomDialog();
    customDialog.generateDialog(context: context, msg: msg, color: color);
  }

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
