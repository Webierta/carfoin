import 'dart:io';

import 'package:carfoin/utils/fecha_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/router_utils.dart';
import '../router/routes_const.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../utils/konstantes.dart';
import '../utils/styles.dart';
import '../utils/update_all.dart';
import '../widgets/data_cartera.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';

class PageCartera extends StatefulWidget {
  const PageCartera({Key? key}) : super(key: key);
  @override
  State<PageCartera> createState() => _PageCarteraState();
}

class _PageCarteraState extends State<PageCartera> {
  bool _isFondosByOrder = true;
  bool _isAutoUpdate = true;
  bool _isConfirmDeleteFondo = true;
  late ApiService apiService;
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';

  //late Stats stats;
  getSharedPrefs() async {
    bool? isFondosByOrder;
    bool? isAutoUpdate;
    bool? isConfirmDeleteFondo;
    await PreferencesService.getBool(keyByOrderFondosPref)
        .then((value) => isFondosByOrder = value);
    await PreferencesService.getBool(keyAutoUpdatePref)
        .then((value) => isAutoUpdate = value);
    await PreferencesService.getBool(keyConfirmDeleteFondoPref)
        .then((value) => isConfirmDeleteFondo = value);
    setState(() {
      _isFondosByOrder = isFondosByOrder ?? true;
      _isAutoUpdate = isAutoUpdate ?? true;
      _isConfirmDeleteFondo = isConfirmDeleteFondo ?? true;
    });
  }

  setFondos(Cartera cartera) async {
    try {
      carteraProvider.fondos =
          await database.getFondos(cartera, byOrder: _isFondosByOrder);
      //carteraProvider.addFondos(cartera, carteraProvider.fondos);
      /// ????
      carteraSelect.fondos = carteraProvider.fondos;
      for (var fondo in carteraProvider.fondos) {
        await database.createTableFondo(cartera, fondo).whenComplete(() async {
          carteraProvider.valores = await database.getValores(cartera, fondo);
          fondo.valores = carteraProvider.valores;
          carteraProvider.operaciones =
              await database.getOperaciones(cartera, fondo);
        });
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
    carteraSelect = carteraProvider.carteraSelect;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getSharedPrefs();
      await database.createTableCartera(carteraSelect).whenComplete(() async {
        await setFondos(carteraSelect);
      });
    });
    apiService = ApiService();
    super.initState();
  }

  _ordenarFondos() async {
    setState(() => _isFondosByOrder = !_isFondosByOrder);
    await setFondos(carteraSelect);
    PreferencesService.saveBool(keyByOrderFondosPref, _isFondosByOrder);
  }

  SpeedDialChild _buildSpeedDialChild(BuildContext context,
      {required IconData icono, required String label, required AppPage page}) {
    return SpeedDialChild(
      child: Icon(icono),
      label: label,
      backgroundColor: amber,
      foregroundColor: blue900,
      onTap: () async {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        //final newFondo = await Navigator.of(context).pushNamed(page);
        final newFondo = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page.routeClass),
        );
        newFondo != null
            ? _addFondo(newFondo as Fondo)
            : _showMsg(msg: 'Sin cambios en la cartera.');
      },
    );
  }

  /*_dialogConfirmShare(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Compartir Cartera'),
          content: const Text('Primero selecciona una carpeta donde almacenar '
              'el archivo generado y luego una aplicación para compartirlo, '
              'por ejemplo vía email.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }*/

  _onShare(Cartera cartera, File file) async {
    final box = context.findRenderObject() as RenderBox?;
    if (file.path.isNotEmpty) {
      await Share.shareFiles([file.path],
          text: cartera.name,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: database.getFondos(carteraSelect, byOrder: _isFondosByOrder),
      builder: (BuildContext context, AsyncSnapshot<List<Fondo>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingProgress(titulo: 'Actualizando fondos...');
        }
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            decoration: scaffoldGradient,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    context.go(homePage);
                  },
                ),
                title: Row(
                  children: [
                    const Icon(Icons.business_center),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(carteraSelect.name,
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async => await _dialogUpdateAll(context),
                  ),
                  PopupMenuButton(
                    color: blue,
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      buildMenuItem(
                        MenuCartera.ordenar,
                        Icons.sort_by_alpha,
                        isOrder: _isFondosByOrder,
                      ),
                      buildMenuItem(MenuCartera.compartir, Icons.share),
                      buildMenuItem(MenuCartera.eliminar, Icons.delete_forever)
                    ],
                    onSelected: (item) async {
                      if (item == MenuCartera.ordenar) {
                        _ordenarFondos();
                      } else if (item == MenuCartera.compartir) {
                        var shareCartera =
                            await ShareCsv.shareCartera(carteraSelect);
                        if (shareCartera != null) {
                          _onShare(carteraSelect, shareCartera);
                        }
                      } else if (item == MenuCartera.eliminar) {
                        _deleteAllConfirm(context);
                      }
                    },
                  ),
                ],
              ),
              floatingActionButton: SpeedDial(
                icon: Icons.addchart,
                foregroundColor: blue900,
                backgroundColor: amber,
                spacing: 8,
                spaceBetweenChildren: 4,
                overlayColor: gris,
                overlayOpacity: 0.4,
                children: [
                  _buildSpeedDialChild(
                    context,
                    icono: Icons.search,
                    label: 'Buscar online por ISIN',
                    page: AppPage.inputFondo,
                  ),
                  _buildSpeedDialChild(
                    context,
                    icono: Icons.storage,
                    label: 'Base de Datos local',
                    page: AppPage.searchFondo,
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: Consumer<CarteraProvider>(
                  builder: (context, data, child) {
                    if (data.fondos.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Añade fondos a esta cartera',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: data.fondos.length,
                      itemBuilder: (context, index) {
                        Fondo fondo = data.fondos[index];
                        return DataCartera(
                          fondo: fondo,
                          removeFondo: _removeFondo,
                          goFondo: _goFondo,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _goFondo(BuildContext context, Fondo fondo) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    carteraProvider.fondoSelect = fondo;
    context.go(fondoPage);
  }

  _dialogUpdateAll(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          key: _dialogKey,
          builder: (context, setState) {
            // return Dialog(child: Loading(...); ???
            return Loading(
                titulo: 'ACTUALIZANDO FONDOS...', subtitulo: _loadingText);
          },
        );
      },
    );

    List<Update> updateResultados = [];
    if (carteraSelect.fondos != null && carteraSelect.fondos!.isNotEmpty) {
      var updateAll =
          UpdateAll(context: context, setStateDialog: _setStateDialog);
      updateResultados =
          await updateAll.updateFondos(carteraSelect, carteraSelect.fondos!);
      if (updateResultados.isNotEmpty) {
        await setFondos(carteraSelect);
      }
    }
    _pop();
    updateResultados.isNotEmpty
        ? await _showResultados(updateResultados)
        : _showMsg(msg: 'Nada que actualizar');
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

  _getDataApi(Fondo fondo) async {
    //await carfoin.createTableFondo(fondo);
    await database.createTableFondo(carteraSelect, fondo);
    final getDataApi = await apiService.getDataApi(fondo.isin);
    if (getDataApi != null) {
      /// TEST EPOCH HMS
      var date = FechaUtil.epochToEpochHms(getDataApi.epochSecs);

      var newValor = Valor(date: date, precio: getDataApi.price);
      fondo.divisa = getDataApi.market;

      ///await carfoin.insertFondoCartera(fondo);
      //await carfoin.updateFondoCartera(fondo);
      //await carfoin.insertValorFondo(fondo, newValor);

      await database.updateFondo(carteraSelect, fondo);
      await database.insertValor(carteraSelect, fondo, newValor);
      await setFondos(carteraSelect);
      return true;
    } else {
      return false;
    }
  }

  _dialogAutoUpdate(BuildContext context, Fondo newFondo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Loading(
            titulo: 'FONDO AÑADIDO', subtitulo: 'Cargando último valor...');
      },
    );
    var update = await _getDataApi(newFondo);
    _pop();
    update
        ? _showMsg(msg: 'Fondo actualizado')
        : _showMsg(msg: 'Error al actualizar el fondo', color: Colors.red);
  }

  _addFondo(Fondo newFondo) async {
    var existe = [for (var fondo in carteraProvider.fondos) fondo.isin]
        .contains(newFondo.isin);
    if (existe) {
      _showMsg(
        msg: 'El fondo con ISIN ${newFondo.isin} ya existe en esta cartera.',
        color: Colors.red,
      );
    } else {
      await database.insertFondo(carteraSelect, newFondo);
      await setFondos(carteraSelect);
      if (_isAutoUpdate) {
        if (!mounted) return;
        await _dialogAutoUpdate(context, newFondo);
      } else {
        _showMsg(msg: 'Fondo añadido');
      }
    }
  }

  _dialogDeleteConfirm(BuildContext context, [String? fondoName]) async {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext ctx) {
          String title = fondoName == null
              ? 'Eliminar todos los fondos'
              : 'Eliminar $fondoName';
          String content = fondoName == null
              ? '¿Eliminar todos los fondos en la cartera ${carteraSelect.name}?'
              : '¿Eliminar el fondo $fondoName y todos sus valores?';
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
                  backgroundColor: red,
                  primary: const Color(0xFFFFFFFF),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ACEPTAR'),
              ),
            ],
          );
        });
  }

  _removeFondo(Fondo fondo) async {
    _eliminarFondo() async {
      await database.deleteAllValores(carteraSelect, fondo);
      await database.deleteFondo(carteraSelect, fondo);

      // PRUEBA ??
      await database.dropTableFondo(carteraSelect, fondo);

      carteraProvider.removeFondo(carteraSelect, fondo);
      await setFondos(carteraSelect);
    }

    if (_isConfirmDeleteFondo) {
      var resp = await _dialogDeleteConfirm(context, fondo.name);
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        _eliminarFondo();
      }
    } else {
      _eliminarFondo();
    }
  }

  void _deleteAllConfirm(BuildContext context) async {
    _removeAllFondos() async {
      //carteraSelect.fondos
      for (var fondo in carteraProvider.fondos) {
        await database.deleteAllValores(carteraSelect, fondo);
      }
      await database.deleteAllFondos(carteraSelect);

      // PRUEBA
      await database.dropAllTablesFondos(carteraSelect);

      carteraProvider.removeAllFondos(carteraSelect);

      /// ???
      await setFondos(carteraSelect);
    }

    if (carteraProvider.fondos.isEmpty) {
      _showMsg(msg: 'Nada que eliminar');
    } else {
      var resp = await _dialogDeleteConfirm(context);
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        _removeAllFondos();
      }
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
