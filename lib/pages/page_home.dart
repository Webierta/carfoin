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
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 22,
                                ),
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
          return const LoadingProgress(titulo: 'Actualizando carteras...');
        }
      },
    );
  }

  _export(BuildContext context) async {
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
            : 'Intenta guardar la copia de seguridad en el almacenamiento interno '
                '(dependiendo de la versión de Android de tu dispositivo puede '
                'que la app no tenga permiso para escribir en la tarjeta SD).';

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
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        _eliminar();
      }
    } else {
      _eliminar();
    }
  }

  void _deleteConfirm(BuildContext context) async {
    var resp = await _dialogDeleteConfirm(context);
    if (resp == true) {
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
