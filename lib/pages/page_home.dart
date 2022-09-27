import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../models/logger.dart';
import '../models/preferences_provider.dart';
import '../router/routes_const.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/exchange_api.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../utils/fecha_util.dart';
import '../utils/file_util.dart';
import '../utils/konstantes.dart';
import '../utils/styles.dart';
import '../utils/update_all.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/expandable_fab.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/my_drawer.dart';
import '../widgets/views/vista_compacta.dart';
import '../widgets/views/vista_detalle.dart';

class PageHome extends StatefulWidget {
  const PageHome({Key? key}) : super(key: key);
  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  late PreferencesProvider prefProvider;
  late CarteraProvider carteraProvider;

  late TextEditingController _controller;
  DatabaseHelper database = DatabaseHelper();
  late ApiService apiService;
  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';
  bool cargandoShare = false;

  getSharedPrefs() async {
    await PreferencesService.getBool(keyByOrderCarterasPref)
        .then((value) => prefProvider.isByOrderCarteras = value);
    await PreferencesService.getBool(keyViewCarterasPref)
        .then((value) => prefProvider.isViewDetalleCarteras = value);
    await PreferencesService.getBool(keyByOrderFondosPref)
        .then((value) => prefProvider.isByOrderFondos = value);
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref)
        .then((value) => prefProvider.isConfirmDeleteCartera = value);
    await PreferencesService.getBool(keyAutoExchangePref)
        .then((value) => prefProvider.isAutoExchange = value);
    await PreferencesService.getDateExchange(keyDateExchange)
        .then((value) => prefProvider.dateExchange = value);
    await PreferencesService.getBool(keyStorageLoggerPref)
        .then((value) => prefProvider.isStorageLogger = value);

    DateTime now = DateTime.now();
    DateTime dateRate = FechaUtil.epochToDate(prefProvider.dateExchange);
    int difDays = now.difference(dateRate).inDays;
    if (prefProvider.isAutoExchange && difDays > 1) {
      await syncExchange();
    }
  }

  setCarteras() async {
    try {
      carteraProvider.carteras =
          await database.getCarteras(byOrder: prefProvider.isByOrderCarteras);
      for (var cartera in carteraProvider.carteras) {
        await database.createTableCartera(cartera).whenComplete(() async {
          carteraProvider.fondos = await database.getFondos(cartera,
              byOrder: prefProvider.isByOrderFondos);
          //carteraProvider.addFondos(cartera, carteraProvider.fondos);
          cartera.fondos = carteraProvider.fondos;
        });
        if (cartera.fondos != null && cartera.fondos!.isNotEmpty) {
          for (var fondo in cartera.fondos!) {
            await database
                .createTableFondo(cartera, fondo)
                .whenComplete(() async {
              carteraProvider.valores =
                  await database.getValores(cartera, fondo);
              fondo.valores = carteraProvider.valores;
              carteraProvider.operaciones =
                  await database.getOperaciones(cartera, fondo);
            });
          }
        }
      }
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        context.go(errorPage);
      });
    }
  }

  syncExchange() async {
    Rate? exchangeApi = await ExchangeApi().latestRate();
    if (exchangeApi != null) {
      if (prefProvider.dateExchange < exchangeApi.date) {
        //setState(() => _dateExchange = exchangeApi.date);
        prefProvider.rateExchange = exchangeApi.rate;
        prefProvider.dateExchange = exchangeApi.date;
        await PreferencesService.saveDateExchange(
            keyDateExchange, exchangeApi.date);
        await PreferencesService.saveRateExchange(
            keyRateExchange, exchangeApi.rate);
      }
    }
  }

  @override
  void initState() {
    carteraProvider = context.read<CarteraProvider>();
    prefProvider = context.read<PreferencesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getSharedPrefs();
      await setCarteras();
    });
    _controller = TextEditingController();
    apiService = ApiService();
    super.initState();
  }

  _ordenarCarteras() async {
    prefProvider.isByOrderCarteras = !prefProvider.isByOrderCarteras;
    await setCarteras();
    PreferencesService.saveBool(
        keyByOrderCarterasPref, prefProvider.isByOrderCarteras);
  }

  _viewCarteras() async {
    setState(() => prefProvider.isViewDetalleCarteras =
        !prefProvider.isViewDetalleCarteras);
    PreferencesService.saveBool(
        keyViewCarterasPref, prefProvider.isViewDetalleCarteras);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<Icon> options = const [
    Icon(Icons.edit),
    Icon(Icons.delete_forever)
  ];

  _sharedCartera(BuildContext context) async {
    int index = 0;
    if (carteraProvider.carteras.isNotEmpty) {
      var carterasConIndex =
          carteraProvider.carteras.where((item) => item.id != null).toList();
      carterasConIndex.sort((a, b) => a.id!.compareTo(b.id!));
      if (carterasConIndex.isNotEmpty) {
        index = carterasConIndex.last.id!;
      }
    }
    //await database.getNamesTables();
    setState(() => cargandoShare = true);
    await ShareCsv.loadCartera(index).then((Cartera? value) async {
      if (value != null) {
        await _loadCartera(value);
      } else {
        showMsg(
          msg: 'Interrupción del proceso de carga de la cartera compartida',
          color: red900,
        );
      }
    }).catchError((onError) {
      showMsg(
        msg: 'Error en el proceso de carga de la cartera compartida',
        color: red900,
      );
    }).whenComplete(() {
      setState(() => cargandoShare = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: database.getCarteras(byOrder: prefProvider.isByOrderCarteras),
      builder: (BuildContext context, AsyncSnapshot<List<Cartera>> snapshot) {
        if (cargandoShare) {
          return const LoadingProgress(titulo: 'Cargando cartera...');
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                decoration: scaffoldGradient,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: const Text('Carteras'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async => await _dialogUpdateAll(context),
                      ),
                      IconButton(
                        icon: prefProvider.isViewDetalleCarteras
                            ? const Icon(Icons.format_list_bulleted)
                            : const Icon(Icons.splitscreen),
                        onPressed: () => _viewCarteras(),
                      ),
                      PopupMenuButton(
                        color: blue,
                        offset: Offset(0.0, AppBar().preferredSize.height),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        itemBuilder: (ctx) => [
                          buildMenuItem(Menu.ordenar, Icons.sort_by_alpha,
                              divider: true,
                              isOrder: prefProvider.isByOrderCarteras),
                          buildMenuItem(Menu.exportar, Icons.save),
                          buildMenuItem(Menu.importar, Icons.file_download,
                              divider: true),
                          buildMenuItem(Menu.eliminar, Icons.delete_forever),
                        ],
                        onSelected: (item) async {
                          if (item == Menu.ordenar) {
                            _ordenarCarteras();
                          } else if (item == Menu.exportar) {
                            _export(context);
                          } else if (item == Menu.importar) {
                            _import(context);
                          } else if (item == Menu.eliminar) {
                            _deleteConfirm(context);
                          }
                        },
                      ),
                    ],
                  ),
                  drawer: const MyDrawer(),
                  floatingActionButton: ExpandableFab(
                    icon: Icons.add,
                    children: [
                      ChildFab(
                        onPressed: () => _sharedCartera(context),
                        icon: const Icon(Icons.share),
                        label: 'Compartida',
                      ),
                      ChildFab(
                        onPressed: () => _inputName(context),
                        icon: const Icon(Icons.create),
                        label: 'Nueva',
                      ),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Consumer<CarteraProvider>(
                      builder: (context, data, child) {
                        if (data.carteras.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Empieza creando una cartera',
                                style: TextStyle(
                                    color: Color(0xFFFFFFFF), fontSize: 22),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        if (!prefProvider.isViewDetalleCarteras) {
                          return ListView.builder(
                            //padding: const EdgeInsets.all(8),
                            itemCount: data.carteras.length,
                            itemBuilder: (context, index) {
                              Cartera cartera = data.carteras[index];
                              return VistaCompacta(
                                delete: _deleteCartera,
                                cartera: cartera,
                                goCartera: _goCartera,
                              );
                            },
                          );
                        }
                        return ListView.builder(
                          itemCount: data.carteras.length,
                          itemBuilder: (context, index) {
                            Cartera cartera = data.carteras[index];
                            return VistaDetalle(
                              cartera: cartera,
                              delete: _deleteCartera,
                              goCartera: _goCartera,
                              inputName: _inputName,
                              goFondo: _goFondo,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const LoadingProgress(titulo: 'Cargando carteras...');
        }
      },
    );
  }

  _dialogUpdateAll(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            key: _dialogKey,
            builder: (context, setState) {
              return Loading(
                titulo: 'ACTUALIZANDO FONDOS...',
                subtitulo: _loadingText,
              );
            });
      },
    );
    List<Update> updateResultados = [];
    if (carteraProvider.carteras.isNotEmpty) {
      var updateAll =
          UpdateAll(context: context, setStateDialog: _setStateDialog);
      updateResultados = await updateAll.updateCarteras();
      if (updateResultados.isNotEmpty) {
        await setCarteras();
      }
    }
    _pop();
    updateResultados.isNotEmpty
        ? await _showResultados(updateResultados)
        : showMsg(msg: 'Nada que actualizar');
  }

  _setStateDialog(String newText) {
    if (_dialogKey.currentState != null && _dialogKey.currentState!.mounted) {
      _dialogKey.currentState!.setState(() {
        _loadingText = newText;
      });
    }
  }

  _showResultados(List<Update> updates) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Icon getIconUpdate(bool isUpdate) {
          if (isUpdate) {
            return const Icon(Icons.check_box, color: green);
          }
          return const Icon(Icons.disabled_by_default, color: red);
        }

        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            insetPadding: const EdgeInsets.all(10),
            title: const Text('Resultado'),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var update in updates)
                      ListTile(
                        dense: true,
                        title: Text(update.nameFondo),
                        subtitle: Text(update.nameCartera),
                        trailing: getIconUpdate(update.isUpdate),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _showResult(
      {required bool isImport,
      required Status status,
      String? msg,
      bool? requiredRestart}) async {
    String line1 = '';
    String line2 = '';
    if (isImport) {
      if (status == Status.ok) {
        line1 = 'Proceso de importación terminado con éxito.';
      } else if (status == Status.error) {
        line1 = 'Error en el proceso de importación.';
      } else if (status == Status.abortado) {
        line1 = 'Proceso abortado';
      }
      if (requiredRestart == true) {
        line2 = 'La app se reiniciará.';
      } else {
        line2 = msg ?? '';
      }
      /*} else if (msg != null) {
        line2 = msg;
      }*/
    } else {
      if (status == Status.ok) {
        line1 = 'Proceso de exportación terminado con éxito.';
        if (msg != null) {
          String path = msg;
          if (msg.contains('0/')) {
            var index = msg.indexOf('0/');
            path = msg.substring(index + 2);
          }
          line2 = 'Copia guardada en $path';
        }
      } else if (status == Status.error) {
        line1 = 'Error en el proceso de exportación.';
        line2 = 'Intenta guardar la copia de seguridad en el almacenamiento '
            'interno (dependiendo de la versión de Android de tu dispositivo puede '
            'que la App no tenga permiso para escribir en la tarjeta SD).';
      } else if (status == Status.abortado) {
        line1 = 'Proceso abortado';
        line2 = msg ?? '';
      }
    }

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Resultado'),
            content: SingleChildScrollView(
              child: ListBody(children: [Text(line1), Text(line2)]),
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  (isImport && requiredRestart == true)
                      ? Restart.restartApp()
                      : Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _export(BuildContext context) async {
    await _inputName(context, isSave: true);
    if (_errorText != null) return '';
    String nombreDb = _controller.value.text.trim();
    nombreDb = '$nombreDb.db';
    _controller.clear();
    var resultExport = await FileUtil.exportar(nombreDb);
    await _showResult(
      isImport: false,
      status: resultExport.status,
      msg: resultExport.msg,
    );
  }

  _import(BuildContext context) async {
    var isConfirm = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Importar Base de Datos'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const [
                  Text('La nueva base de datos sobreescribirá los datos '
                      'actuales, que se perderán y no podrán ser recuperados.'),
                  SizedBox(height: 10),
                  Text('Se recomienda exportar una copia de seguridad antes de '
                      'importar una nueva base de datos.'),
                  SizedBox(height: 10),
                  Text('¿Quieres continuar con el proceso de importación?'),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Aceptar'))
            ],
          );
        });

    if (await isConfirm == null || !await isConfirm) return;

    var resultImport = await FileUtil.importar();
    await _showResult(
      isImport: true,
      status: resultImport.status,
      requiredRestart: resultImport.requiredRestart,
      msg: resultImport.msg,
    );
  }

  Future<void> _inputName(BuildContext context,
      {Cartera? cartera, bool isSave = false}) async {
    //String title = cartera?.name ?? 'Nueva Cartera';
    String title;
    if (isSave == false) {
      title = cartera?.name ?? 'Nueva Cartera';
    } else {
      title = 'Exportar Base de Datos';
    }
    String label = isSave ? 'Nombre del archivo sin extensión' : '';
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, TextEditingValue value, __) {
                  return SingleChildScrollView(
                    child: AlertDialog(
                      title: Text(title),
                      content: Column(
                        children: [
                          TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Nombre',
                              errorMaxLines: 4,
                              errorText: _errorText,
                              labelText: label,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        OutlinedButton(
                          child: const Text('CANCELAR'),
                          onPressed: () {
                            _controller.clear();
                            Navigator.pop(context);
                          },
                        ),
                        ElevatedButton(
                          onPressed: _controller.value.text.trim().isNotEmpty
                              ? () {
                                  isSave
                                      ? Navigator.pop(context)
                                      : _submit(cartera);
                                }
                              : null,
                          child: const Text('ACEPTAR'),
                        ),
                      ],
                    ),
                  );
                });
          });
        });
  }

  String? get _errorText {
    final text = _controller.value.text.trim();
    if (text.isEmpty) {
      return 'Campo requerido';
    }
    /*if (text.startsWith('_')) {
      return 'Nombre no válido';
    }*/
    return null;
  }

  _loadCartera(Cartera cartera) async {
    var existe = [for (var cartera in carteraProvider.carteras) cartera.name]
        .contains(cartera.name);

    if (existe) {
      showMsg(msg: 'Ya existe una cartera con ese nombre', color: red900);
      return;
    } else {
      try {
        await database.createTableCartera(cartera).whenComplete(() async {
          await database.insertCartera(cartera);
          //await setCarteras();
        });
      } catch (e, s) {
        showMsg(
            msg: 'Proceso interrumpido: Error en la carga del archivo',
            color: red900);
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch create table cartera + insert cartera',
                file: 'page_home.dart',
                clase: '_PageHomeState',
                funcion: '_loadCartera',
                error: e,
                stackTrace: s));
        return;
      }

      try {
        if (cartera.fondos != null && cartera.fondos!.isNotEmpty) {
          for (var fondo in cartera.fondos!) {
            await database
                .createTableFondo(cartera, fondo)
                .whenComplete(() async {
              await database.insertFondo(
                  cartera,
                  Fondo(
                      isin: fondo.isin,
                      name: fondo.name,
                      divisa: fondo.divisa,
                      valores: fondo.valores,
                      rating: fondo.rating));
              //await setCarteras();
              if (fondo.valores != null && fondo.valores!.isNotEmpty) {
                for (var valor in fondo.valores!) {
                  await database.insertValor(cartera, fondo, valor);
                  //await setCarteras();
                }
              }
            });
          }
        }
        await setCarteras();
      } catch (e, s) {
        showMsg(
            msg: 'Proceso interrumpido: Error en la carga del archivo',
            color: red900);
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch create table fondo + insert fondo',
                file: 'page_home.dart',
                clase: '_PageHomeState',
                funcion: '_loadCartera',
                error: e,
                stackTrace: s));
        return;
      }
    }
  }

  void _submit(Cartera? cartera) async {
    if (_errorText == null) {
      var input = _controller.value.text.trim();
      var existe = [for (var cartera in carteraProvider.carteras) cartera.name]
          .contains(input);
      if (existe) {
        _controller.clear();
        _pop();
        showMsg(msg: 'Ya existe una cartera con ese nombre', color: red900);
      } else if (cartera != null) {
        cartera.name = input;
        await database.updateCartera(cartera);
        await setCarteras();
        _controller.clear();
        _pop();
      } else {
        Cartera cartera = Cartera(name: input);
        await database.insertCartera(cartera);
        await setCarteras();
        _controller.clear();
        _pop();
      }
    }
  }

  _goCartera(BuildContext context, Cartera cartera) {
    carteraProvider.carteraSelect = cartera;
    context.go(carteraPage);
  }

  _goFondo(BuildContext context, Cartera cartera, Fondo fondo) {
    carteraProvider.carteraSelect = cartera;
    carteraProvider.fondoSelect = fondo;
    context.go(fondoPage);
  }

  _dialogDeleteConfirm(BuildContext context, [String? carteraName]) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext ctx) {
          String title = carteraName == null
              ? 'Eliminar todas las carteras'
              : 'Eliminar $carteraName';
          String content = carteraName == null
              ? '¿Eliminar todas las carteras y sus fondos?'
              : '¿Eliminar la cartera $carteraName y todos sus fondos?';
          return AlertDialog(
            title: Text(title),
            content: Text(content),
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

  _deleteCartera(Cartera cartera) async {
    if (prefProvider.isConfirmDeleteCartera) {
      var resp = await _dialogDeleteConfirm(context, cartera.name);
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        _eliminar(cartera);
      }
    } else {
      _eliminar(cartera);
    }
  }

  _eliminar(Cartera cartera) async {
    //await database.deleteAllValores(cartera)
    await database.deleteAllFondos(cartera);
    await database.deleteCartera(cartera);

    await database.dropAllTablesFondos(cartera);
    await database.dropTableCartera(cartera);

    carteraProvider.removeAllFondos(cartera);
    carteraProvider.removeCartera(cartera);
    await setCarteras();
  }

  void _deleteConfirm(BuildContext context) async {
    var resp = await _dialogDeleteConfirm(context);
    if (resp == true) {
      for (var cartera in carteraProvider.carteras) {
        //await database.deleteAllFondos(cartera);
        //carteraProvider.removeAllFondos(cartera);
        _eliminar(cartera);
      }
      await database.deleteAllCarteras();
      await database.dropAllTables();

      carteraProvider.removeAllCarteras();
      await setCarteras();
    }
  }

  void showMsg({required String msg, Color? color}) {
    CustomDialog customDialog = const CustomDialog();
    customDialog.generateDialog(context: context, msg: msg, color: color);
  }

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
