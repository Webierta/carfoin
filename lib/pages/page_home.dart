import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
//import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/routes_const.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../utils/stats.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/my_drawer.dart';

class PageHome extends StatefulWidget {
  const PageHome({Key? key}) : super(key: key);
  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  bool _isCarterasByOrder = true;
  bool _isViewDetalleCarteras = true;
  bool _isFondosByOrder = true;
  bool _isConfirmDeleteCartera = true;
  late TextEditingController _controller;
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;

  getSharedPrefs() async {
    bool? isCarterasByOrder;
    bool? isFondosByOrder;
    bool? isConfirmDeleteCartera;
    bool? isViewDetalleCarteras;
    await PreferencesService.getBool(keyByOrderCarterasPref)
        .then((value) => isCarterasByOrder = value);
    await PreferencesService.getBool(keyViewCarterasPref)
        .then((value) => isViewDetalleCarteras = value);
    await PreferencesService.getBool(keyByOrderFondosPref)
        .then((value) => isFondosByOrder = value);
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref)
        .then((value) => isConfirmDeleteCartera = value);
    setState(() {
      _isCarterasByOrder = isCarterasByOrder ?? true;
      _isViewDetalleCarteras = isViewDetalleCarteras ?? true;
      _isFondosByOrder = isFondosByOrder ?? true;
      _isConfirmDeleteCartera = isConfirmDeleteCartera ?? true;
    });
  }

  setCarteras() async {
    try {
      //throw Exception();
      carteraProvider.carteras =
          await database.getCarteras(byOrder: _isCarterasByOrder);
      for (var cartera in carteraProvider.carteras) {
        await database.createTableCartera(cartera).whenComplete(() async {
          carteraProvider.fondos =
              await database.getFondos(cartera, byOrder: _isFondosByOrder);
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

  @override
  void initState() {
    carteraProvider = context.read<CarteraProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getSharedPrefs();
      await setCarteras();
    });
    _controller = TextEditingController();
    super.initState();
  }

  _ordenarCarteras() async {
    setState(() => _isCarterasByOrder = !_isCarterasByOrder);
    await setCarteras();
    PreferencesService.saveBool(keyByOrderCarterasPref, _isCarterasByOrder);
  }

  _viewCarteras() async {
    setState(() => _isViewDetalleCarteras = !_isViewDetalleCarteras);
    PreferencesService.saveBool(keyViewCarterasPref, _isViewDetalleCarteras);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: database.getCarteras(byOrder: _isCarterasByOrder),
      builder: (BuildContext context, AsyncSnapshot<List<Cartera>> snapshot) {
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
                        icon: const Icon(Icons.settings),
                        onPressed: () => context.go(settingsPage),
                      ),
                      IconButton(
                        icon: _isViewDetalleCarteras
                            ? const Icon(Icons.format_list_bulleted)
                            : const Icon(Icons.view_stream),
                        onPressed: () => _viewCarteras(),
                      ),
                      PopupMenuButton(
                        color: const Color(0xFF2196F3),
                        offset: Offset(0.0, AppBar().preferredSize.height),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        itemBuilder: (ctx) => [
                          buildMenuItem(Menu.ordenar, Icons.sort_by_alpha,
                              divider: true, isOrder: _isCarterasByOrder),
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
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: const Color(0xFFFFC107),
                    child: const Icon(Icons.add, color: Color(0xFF0D47A1)),
                    onPressed: () => _inputName(context),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 42),
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
                        if (!_isViewDetalleCarteras) {
                          return ListView.builder(
                            itemCount: data.carteras.length,
                            itemBuilder: (context, index) {
                              Cartera cartera = data.carteras[index];
                              return VistaCompacta(
                                  delete: _deleteCartera,
                                  cartera: cartera,
                                  goCartera: _goCartera);
                            },
                          );
                        }
                        return ListView.builder(
                          itemCount: data.carteras.length,
                          itemBuilder: (context, index) {
                            Cartera cartera = data.carteras[index];
                            /*List<Fondo> fondos = cartera.fondos ?? [];
                            double capitalCarteraEur = 0.0;
                            double capitalCarteraUsd = 0.0;
                            double capitalCarteraOtra = 0.0;
                            double rendimientoCarteraEur = 0.0;
                            double rendimientoCarteraUsd = 0.0;
                            double rendimientoCarteraOtra = 0.0;
                            double participacionesCartera = 0.0;
                            bool isTrueCapitalCarteraEur = false;
                            bool isTrueCapitalCarteraUsd = false;
                            bool isTrueCapitalCarteraOtra = false;
                            bool isTrueRendCarteraEur = false;
                            bool isTrueRendCarteraUsd = false;
                            bool isTrueRendCarteraOtra = false;*/
                            /*if (fondos.isNotEmpty) {
                              for (var fondo in fondos) {
                                if (fondo.valores != null &&
                                    fondo.valores!.isNotEmpty) {
                                  Stats stats = Stats(fondo.valores!);
                                  participacionesCartera +=
                                      stats.totalParticipaciones() ?? 0.0;
                                  if (participacionesCartera > 0) {
                                    if (fondo.divisa == 'EUR') {
                                      if (stats.resultado() != null) {
                                        isTrueCapitalCarteraEur = true;
                                      }
                                      if (stats.balance() != null) {
                                        isTrueRendCarteraEur = true;
                                      }
                                      capitalCarteraEur +=
                                          stats.resultado() ?? 0.0;
                                      rendimientoCarteraEur +=
                                          stats.balance() ?? 0.0;
                                    } else if (fondo.divisa == 'USD') {
                                      if (stats.resultado() != null) {
                                        isTrueCapitalCarteraUsd = true;
                                      }
                                      if (stats.balance() != null) {
                                        isTrueRendCarteraUsd = true;
                                      }
                                      capitalCarteraUsd +=
                                          stats.resultado() ?? 0.0;
                                      rendimientoCarteraUsd +=
                                          stats.balance() ?? 0.0;
                                    } else {
                                      if (stats.resultado() != null) {
                                        isTrueCapitalCarteraOtra = true;
                                      }
                                      if (stats.balance() != null) {
                                        isTrueRendCarteraOtra = true;
                                      }
                                      capitalCarteraOtra +=
                                          stats.resultado() ?? 0.0;
                                      rendimientoCarteraOtra +=
                                          stats.balance() ?? 0.0;
                                    }
                                  }
                                }
                              }
                            }*/

                            /*Widget _builTextCartera(double valorStats,
                                {String divisa = '', bool color = false}) {
                              return Text(
                                '${NumberFormat.decimalPattern('es').format(double.parse(valorStats.toStringAsFixed(2)))} $divisa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: color == true
                                      ? valorStats < 0
                                          ? Colors.red
                                          : Colors.green
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              );
                            }*/

                            return VistaDetalle(
                              cartera: cartera,
                              delete: _deleteCartera,
                              goCartera: _goCartera,
                              inputName: _inputName,
                              goFondo: _goFondo,
                            );

                            /*return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: const Color(0xFFF44336),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                alignment: Alignment.centerRight,
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.delete,
                                      color: Color(0xFFFFFFFF)),
                                ),
                              ),
                              onDismissed: (_) => _deleteCartera(cartera),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.5),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              const Color(0xFFFFFFFF),
                                          child: CircleAvatar(
                                            backgroundColor:
                                                const Color(0xFFFFC107),
                                            child: IconButton(
                                              onPressed: () {
                                                ScaffoldMessenger.of(context)
                                                    .removeCurrentSnackBar();
                                                carteraProvider.carteraSelect =
                                                    cartera;
                                                context.go(carteraPage);
                                              },
                                              icon: const Icon(
                                                Icons.business_center,
                                                color: Color(0xFF0D47A1),
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          cartera.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Color(0xFF2196F3),
                                          ),
                                        ),
                                        trailing: PopupMenuButton(
                                          color: const Color(0xFF2196F3),
                                          icon: const Icon(Icons.more_vert,
                                              color: Color(0xFF2196F3)),
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 1,
                                              child: ListTile(
                                                leading: Icon(Icons.edit,
                                                    color: Color(0xFFFFFFFF)),
                                                title: Text(
                                                  'Renombrar',
                                                  style: TextStyle(
                                                      color: Color(0xFFFFFFFF)),
                                                ),
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 2,
                                              child: ListTile(
                                                leading: Icon(
                                                    Icons.delete_forever,
                                                    color: Color(0xFFFFFFFF)),
                                                title: Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                      color: Color(0xFFFFFFFF)),
                                                ),
                                              ),
                                            )
                                          ],
                                          onSelected: (value) {
                                            if (value == 1) {
                                              _inputName(context,
                                                  cartera: cartera);
                                            } else if (value == 2) {
                                              _deleteCartera(cartera);
                                            }
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFBBDEFB),
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          //child: (cartera.fondos != null && cartera.fondos!.isNotEmpty)
                                          child: fondos.isNotEmpty
                                              ? Theme(
                                                  data: Theme.of(context)
                                                      .copyWith(
                                                          dividerColor: Colors
                                                              .transparent),
                                                  child: ExpansionTile(
                                                    childrenPadding:
                                                        const EdgeInsets.only(
                                                            bottom: 10,
                                                            left: 20),
                                                    expandedCrossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    expandedAlignment:
                                                        Alignment.topLeft,
                                                    maintainState: true,
                                                    iconColor: Colors.blue,
                                                    collapsedIconColor:
                                                        Colors.blue,
                                                    tilePadding:
                                                        const EdgeInsets.all(
                                                            0.0),
                                                    backgroundColor:
                                                        const Color(0xFFBBDEFB),
                                                    title: ChipFondo(
                                                        lengthFondos:
                                                            fondos.length),
                                                    children: [
                                                      for (var fondo in fondos)
                                                        TextButton(
                                                          onPressed: () {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .removeCurrentSnackBar();
                                                            carteraProvider
                                                                    .carteraSelect =
                                                                cartera;
                                                            carteraProvider
                                                                    .fondoSelect =
                                                                fondo;
                                                            context
                                                                .go(fondoPage);
                                                          },
                                                          child: Text(
                                                            fondo.name,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                            style: const TextStyle(
                                                                color: Color(
                                                                    0xFF0D47A1)),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                )
                                              : const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 6),
                                                  child: ChipFondo(
                                                      lengthFondos: null),
                                                ),
                                        ),
                                      ),
                                      if (fondos.isNotEmpty &&
                                          participacionesCartera > 0 &&
                                          (isTrueCapitalCarteraEur ||
                                              isTrueCapitalCarteraUsd ||
                                              isTrueCapitalCarteraOtra) &&
                                          (isTrueRendCarteraEur ||
                                              isTrueRendCarteraUsd ||
                                              isTrueRendCarteraOtra))
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Valor',
                                                      style: TextStyle(
                                                          fontSize: 16)),
                                                  const Spacer(),
                                                  Column(
                                                    children: [
                                                      if (isTrueCapitalCarteraEur)
                                                        _builTextCartera(
                                                            capitalCarteraEur,
                                                            divisa: 'EUR'),
                                                      if (isTrueCapitalCarteraUsd)
                                                        _builTextCartera(
                                                            capitalCarteraUsd,
                                                            divisa: 'USD'),
                                                      if (isTrueCapitalCarteraOtra)
                                                        _builTextCartera(
                                                            capitalCarteraOtra),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Rendimiento',
                                                      style: TextStyle(
                                                          fontSize: 16)),
                                                  const Spacer(),
                                                  Column(
                                                    children: [
                                                      if (isTrueRendCarteraEur)
                                                        _builTextCartera(
                                                            rendimientoCarteraEur,
                                                            divisa: 'EUR',
                                                            color: true),
                                                      if (isTrueRendCarteraUsd)
                                                        _builTextCartera(
                                                            rendimientoCarteraUsd,
                                                            divisa: 'USD',
                                                            color: true),
                                                      if (isTrueRendCarteraOtra)
                                                        _builTextCartera(
                                                            rendimientoCarteraOtra,
                                                            color: true),
                                                    ],
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
                            );*/
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
          return const LoadingProgress(titulo: 'Actualizando carteras...');
        }
      },
    );
  }

  _export(BuildContext context) async {
    // TODO: DIALOGO NOMBRE FILE

    await _inputName(context, isSave: true);

    if (_errorText != null) return '';
    String nombreDb = _controller.value.text.trim();
    nombreDb = '$nombreDb.db';
    _controller.clear();

    bool okSave = false;
    final String dbPath = await database.getDatabasePath();
    var dbFile = File(dbPath);
    final dbAsBytes = await dbFile.readAsBytes();
    String filePath = '';

    /* Future<String> _getFilePath() async {
      Directory? directory = await getExternalStorageDirectory();
      //if (directory == null || directory.path.isEmpty || !await directory.exists()) return '';
      if (directory == null) return '';
      if ((!await directory.exists())) directory.create();
      String path = directory.path;
      String filePath = '$path/$nombreDb';
      return filePath;
    } */

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;
      filePath = '$selectedDirectory/$nombreDb';

      //filePath = await _getFilePath();

      if (filePath.isEmpty) throw Exception(); // o return ??
      File file = File(filePath);

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        await file.writeAsBytes(dbAsBytes);
        okSave = true;
      } else {
        throw Exception();
      }
    } catch (e) {
      //TODO: mensaje de error
      print(e.toString());
      //return;
      okSave = false;
    }

    //_dialogResultSave(okSave, filePath);
    await _resultProcess(isImport: false, isOk: okSave, filePath: filePath);
  }

  _resultProcess(
      {required bool isImport,
      required bool isOk,
      String filePath = ''}) async {
    String path = filePath;
    if (!isImport) {
      if (filePath.contains('0/')) {
        var index = filePath.indexOf('0/');
        path = filePath.substring(index + 2);
      }
    }
    String line1 =
        isOk ? 'El proceso ha concluido con éxito.' : 'El proceso ha fallado.';
    String line2 = isImport
        ? 'La app se reiniciará.'
        : isOk
            ? 'La copia se ha almacenado en $path'
            : 'Intenta guardar la copia de seguridad en el almacenamiento interno (dependiendo de la '
                'versión de Android de tu dispositivo puede que la app no tenga permiso para escribir en la tarjeta SD).';

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Resultado'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(line1),
                  Text(line2),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  isImport ? Restart.restartApp() : Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
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
                  Text(
                      'La nueva base de datos sobreescribirá los datos actuales, '
                      'que se perderán y no podrán ser recuperados.'),
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

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    bool okImport = false;
    final String dbPath = await database.getDatabasePath();
    PlatformFile archivo = result.files.first;

    // TODO: ESTUDIAR POSIBILIDAD DE RECUPERAR BD ORIGINAL: EXPORTAR AUTO??
    //var dbFile = File(dbPath);
    //var dbBackup = await dbFile.readAsBytes();

    if (archivo.extension == 'db' &&
        archivo.path != null &&
        await database.isDatabase(archivo.path!)) {
      try {
        //throw Exception();
        File file = File(archivo.path!);
        final dbAsBytes = await file.readAsBytes();
        //final dbDir = await getDatabasesPath();
        //final String dbPath = join(dbDir, 'database.db');
        await deleteDatabase(dbPath);
        //await database.deleteDatabase(dbPath);
        await File(dbPath).writeAsBytes(dbAsBytes);
        okImport = true;
      } catch (e) {
        print('EXCEPCION');
        print(e);
        // TODO: DIALOGO ERROR: RECUPERAR BD ??
        //await deleteDatabase(dbPath);
        //await database.deleteDatabase(dbPath);
        //await File(dbPath).writeAsBytes(dbBackup);
        // TODO: RECUPERAR BD AUTOGUARDADA ??
        //await deleteDatabase(dbPath);
        okImport = false;
      } finally {
        //await _dialogResultImport(okImport);
        await _resultProcess(isImport: true, isOk: okImport);
        //Restart.restartApp();
      }
    } else {
      //  msg: formato archivo incorrecto
      print('archivo no reconocido');
      return;
    }
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
                          if (isSave)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'Después selecciona el destino donde almacenar '
                                  'la copia de seguridad (se recomienda utilizar '
                                  'el almacenamiento interno del dispositivo '
                                  'porque dependiendo de tu versión de Android '
                                  'puede que la app no tenga permiso para escribir '
                                  'en la tarjeta SD).'),
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

  void _submit(Cartera? cartera) async {
    if (_errorText == null) {
      var input = _controller.value.text.trim();
      var existe = [for (var cartera in carteraProvider.carteras) cartera.name]
          .contains(input);
      if (existe) {
        _controller.clear();
        _pop();
        _showMsg(
            msg: 'Ya existe una cartera con ese nombre.', color: Colors.red);
      } else if (cartera != null) {
        print('RENAME RENAME');
        print('${cartera.id}');
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

  _dialogDeleteConfirm(BuildContext context, [String? carteraName]) async {
    return showDialog(
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

  _goCartera(BuildContext context, Cartera cartera) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    carteraProvider.carteraSelect = cartera;
    context.go(carteraPage);
  }

  _goFondo(BuildContext context, Cartera cartera, Fondo fondo) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    carteraProvider.carteraSelect = cartera;
    carteraProvider.fondoSelect = fondo;
    context.go(fondoPage);
  }

  _deleteCartera(Cartera cartera) async {
    _eliminar() async {
      await database.deleteAllFondos(cartera);
      await database.deleteCartera(cartera);
      carteraProvider.removeAllFondos(cartera);
      carteraProvider.removeCartera(cartera);
      await setCarteras();
    }

    if (_isConfirmDeleteCartera) {
      var resp = await _dialogDeleteConfirm(context, cartera.name);
      resp ? _eliminar() : setState(() {});
    } else {
      _eliminar();
    }
  }

  void _deleteConfirm(BuildContext context) async {
    var resp = await _dialogDeleteConfirm(context);
    if (resp) {
      for (var cartera in carteraProvider.carteras) {
        await database.deleteAllFondos(cartera);
        carteraProvider.removeAllFondos(cartera);
      }
      await database.deleteAllCarteras();
      carteraProvider.removeAllCarteras();
      await setCarteras();
    }
  }

  void _showMsg({required String msg, MaterialColor color = Colors.grey}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );

  void _pop() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).pop();
  }
}

class ChipFondo extends StatelessWidget {
  final int? lengthFondos;
  const ChipFondo({Key? key, this.lengthFondos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title;
    if (lengthFondos == null || lengthFondos == 0) {
      title = 'Sin fondos';
    } else if (lengthFondos == 1) {
      title = '$lengthFondos Fondo';
    } else {
      title = '$lengthFondos Fondos';
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Chip(
        padding: const EdgeInsets.only(left: 10, right: 20),
        backgroundColor: const Color(0xFFBBDEFB),
        avatar: const Icon(Icons.poll, color: Color(0xFF0D47A1), size: 32),
        label: Text(
          title,
          style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 18),
        ),
      ),
    );
  }
}

class VistaCompacta extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function goCartera;
  const VistaCompacta(
      {Key? key,
      required this.cartera,
      required this.delete,
      required this.goCartera})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFF44336),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.delete, color: Color(0xFFFFFFFF)),
        ),
      ),
      onDismissed: (_) => delete(cartera),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InputChip(
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            avatar: CircleAvatar(
              backgroundColor: const Color(0xFFFFC107),
              child: Text(
                cartera.name[0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            backgroundColor: const Color(0xFFBBDEFB),
            label: Text(cartera.name),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2196F3),
            ),
            onPressed: () => goCartera(context, cartera)),
      ),
    );
  }
}

class VistaDetalle extends StatelessWidget {
  final Cartera cartera;
  final Function delete;
  final Function goCartera;
  final Function inputName;
  final Function goFondo;
  const VistaDetalle({
    Key? key,
    required this.cartera,
    required this.delete,
    required this.goCartera,
    required this.inputName,
    required this.goFondo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Fondo> fondos = cartera.fondos ?? [];
    double capitalCarteraEur = 0.0;
    double capitalCarteraUsd = 0.0;
    double capitalCarteraOtra = 0.0;
    double rendimientoCarteraEur = 0.0;
    double rendimientoCarteraUsd = 0.0;
    double rendimientoCarteraOtra = 0.0;
    double participacionesCartera = 0.0;
    bool isTrueCapitalCarteraEur = false;
    bool isTrueCapitalCarteraUsd = false;
    bool isTrueCapitalCarteraOtra = false;
    bool isTrueRendCarteraEur = false;
    bool isTrueRendCarteraUsd = false;
    bool isTrueRendCarteraOtra = false;
    if (fondos.isNotEmpty) {
      for (var fondo in fondos) {
        if (fondo.valores != null && fondo.valores!.isNotEmpty) {
          Stats stats = Stats(fondo.valores!);
          participacionesCartera += stats.totalParticipaciones() ?? 0.0;
          if (participacionesCartera > 0) {
            if (fondo.divisa == 'EUR') {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraEur = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraEur = true;
              }
              capitalCarteraEur += stats.resultado() ?? 0.0;
              rendimientoCarteraEur += stats.balance() ?? 0.0;
            } else if (fondo.divisa == 'USD') {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraUsd = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraUsd = true;
              }
              capitalCarteraUsd += stats.resultado() ?? 0.0;
              rendimientoCarteraUsd += stats.balance() ?? 0.0;
            } else {
              if (stats.resultado() != null) {
                isTrueCapitalCarteraOtra = true;
              }
              if (stats.balance() != null) {
                isTrueRendCarteraOtra = true;
              }
              capitalCarteraOtra += stats.resultado() ?? 0.0;
              rendimientoCarteraOtra += stats.balance() ?? 0.0;
            }
          }
        }
      }
    }

    Widget _builTextCartera(double valorStats,
        {String divisa = '', bool color = false}) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${NumberUtil.decimalFixed(valorStats)} $divisa',
          //'${NumberFormat.decimalPattern('es').format(double.parse(valorStats.toStringAsFixed(2)))} $divisa',
          //'${NumberFormat.compactLong(locale: 'es').format(double.parse(valorStats.toStringAsFixed(2)))} $divisa',

          /*? NumberFormat.compactLong(
            locale: 'es')
            .format(double.parse(stats
            .resultado()!
            .toStringAsFixed(2)))*/
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color == true
                ? valorStats < 0
                    ? Colors.red
                    : Colors.green
                : Colors.black,
            fontSize: 16,
          ),
        ),
      );
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFF44336),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.delete, color: Color(0xFFFFFFFF)),
        ),
      ),
      onDismissed: (_) => delete(cartera),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.5),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFFFFF),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFFFC107),
                    child: IconButton(
                      onPressed: () => goCartera(context, cartera),
                      icon: const Icon(
                        Icons.business_center,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  cartera.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2196F3),
                  ),
                ),
                trailing: PopupMenuButton(
                  color: const Color(0xFF2196F3),
                  icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 1,
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Color(0xFFFFFFFF)),
                        title: Text(
                          'Renombrar',
                          style: TextStyle(color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: ListTile(
                        leading: Icon(Icons.delete_forever,
                            color: Color(0xFFFFFFFF)),
                        title: Text(
                          'Eliminar',
                          style: TextStyle(color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    )
                  ],
                  onSelected: (value) {
                    if (value == 1) {
                      inputName(context, cartera: cartera);
                    } else if (value == 2) {
                      delete(cartera);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: fondos.isNotEmpty
                      ? Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            childrenPadding:
                                const EdgeInsets.only(bottom: 10, left: 20),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
                            maintainState: true,
                            iconColor: Colors.blue,
                            collapsedIconColor: Colors.blue,
                            tilePadding: const EdgeInsets.all(0.0),
                            backgroundColor: const Color(0xFFBBDEFB),
                            title: ChipFondo(lengthFondos: fondos.length),
                            children: [
                              for (var fondo in fondos)
                                TextButton(
                                  onPressed: () {
                                    goFondo(context, cartera, fondo);
                                  },
                                  child: Text(
                                    fondo.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        color: Color(0xFF0D47A1)),
                                  ),
                                )
                            ],
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: ChipFondo(lengthFondos: null),
                        ),
                ),
              ),
              if (fondos.isNotEmpty &&
                  participacionesCartera > 0 &&
                  (isTrueCapitalCarteraEur ||
                      isTrueCapitalCarteraUsd ||
                      isTrueCapitalCarteraOtra) &&
                  (isTrueRendCarteraEur ||
                      isTrueRendCarteraUsd ||
                      isTrueRendCarteraOtra))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VALOR', style: TextStyle(fontSize: 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isTrueCapitalCarteraEur)
                                _builTextCartera(capitalCarteraEur,
                                    divisa: 'EUR'),
                              if (isTrueCapitalCarteraUsd)
                                _builTextCartera(capitalCarteraUsd,
                                    divisa: 'USD'),
                              if (isTrueCapitalCarteraOtra)
                                _builTextCartera(capitalCarteraOtra),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BALANCE', style: TextStyle(fontSize: 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isTrueRendCarteraEur)
                                _builTextCartera(rendimientoCarteraEur,
                                    divisa: 'EUR', color: true),
                              if (isTrueRendCarteraUsd)
                                _builTextCartera(rendimientoCarteraUsd,
                                    divisa: 'USD', color: true),
                              if (isTrueRendCarteraOtra)
                                _builTextCartera(rendimientoCarteraOtra,
                                    color: true),
                            ],
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
    );
  }
}
