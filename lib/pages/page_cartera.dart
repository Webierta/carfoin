import 'dart:io' show File;

import 'package:carfoin/widgets/flutter_expandable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../models/logger.dart';
import '../models/preferences_provider.dart';
import '../router/router_utils.dart';
import '../router/routes_const.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/doc_cnmv.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/status_api_service.dart';
import '../utils/styles.dart';
import '../utils/update_all.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/views/vista_compacta_fondos.dart';
import '../widgets/views/vista_detalle_fondos.dart';

class PageCartera extends StatefulWidget {
  const PageCartera({Key? key}) : super(key: key);
  @override
  State<PageCartera> createState() => _PageCarteraState();
}

class _PageCarteraState extends State<PageCartera> {
  late ApiService apiService;
  DatabaseHelper database = DatabaseHelper();

  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late PreferencesProvider prefProvider;

  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';

  bool addingFondo = false;

  setFondos(Cartera cartera) async {
    try {
      carteraProvider.fondos = await database.getFondos(cartera,
          byOrder: prefProvider.isByOrderFondos);
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
    prefProvider = context.read<PreferencesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await database.createTableCartera(carteraSelect).whenComplete(() async {
        await setFondos(carteraSelect);
      });
    });
    apiService = ApiService();
    super.initState();
  }

  _ordenarFondos() async {
    prefProvider.isByOrderFondos = !prefProvider.isByOrderFondos;
    await setFondos(carteraSelect);
    PreferencesService.saveBool(
        keyByOrderFondosPref, prefProvider.isByOrderFondos);
  }

  _viewFondos() async {
    setState(() =>
        prefProvider.isViewDetalleFondos = !prefProvider.isViewDetalleFondos);
    PreferencesService.saveBool(
        keyViewFondosPref, prefProvider.isViewDetalleFondos);
  }

  _searchFondo(BuildContext context, AppPage page) async {
    final newFondo = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => page.routeClass));
    newFondo != null
        ? _addFondo(newFondo as Fondo, page)
        : _showMsg(msg: 'Sin cambios en la cartera.');
  }

  _onShare(Cartera cartera, File file) async {
    final box = context.findRenderObject() as RenderBox?;
    if (file.path.isNotEmpty) {
      await Share.shareFiles(
        [file.path],
        text: cartera.name,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ).whenComplete(() async {
        try {
          //await file.delete();
          await ShareCsv.clearCache();
        } catch (e, s) {
          Logger.log(
              dataLog: DataLog(
                  msg: 'Catch clear cache',
                  file: 'page_cartera.dart',
                  clase: '_PageCarteraState',
                  funcion: '_onShare',
                  error: e,
                  stackTrace: s));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (addingFondo) return const LoadingProgress(titulo: 'Añadiendo fondo...');
    return FutureBuilder(
      future: database.getFondos(carteraSelect,
          byOrder: prefProvider.isByOrderFondos),
      builder: (BuildContext context, AsyncSnapshot<List<Fondo>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingProgress(titulo: 'Cargando fondos...');
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
                  onPressed: () => context.go(homePage),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.business_center),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        carteraSelect.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async => await _dialogUpdateAll(context),
                  ),
                  IconButton(
                    icon: prefProvider.isViewDetalleFondos
                        ? const Icon(Icons.format_list_bulleted)
                        : const Icon(Icons.splitscreen),
                    onPressed: () => _viewFondos(),
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
                        isOrder: prefProvider.isByOrderFondos,
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
              floatingActionButtonLocation: ExpandableFab.location,
              floatingActionButton: ExpandableFab(
                children: [
                  ChildFab(
                    icon: const Icon(Icons.search),
                    label: 'Buscar online por ISIN',
                    onPressed: () => _searchFondo(context, AppPage.inputFondo),
                  ),
                  ChildFab(
                    icon: const Icon(Icons.storage),
                    label: 'Base de Datos local',
                    onPressed: () => _searchFondo(context, AppPage.searchFondo),
                  ),
                ],
                child: const Icon(Icons.addchart),
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
                                color: Color(0xFFFFFFFF), fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (!prefProvider.isViewDetalleFondos) {
                      return ListView.builder(
                        itemCount: data.fondos.length,
                        itemBuilder: (context, index) {
                          Fondo fondo = data.fondos[index];
                          return VistaCompactaFondos(
                            fondo: fondo,
                            updateFondo: _updateFondo,
                            removeFondo: _removeFondo,
                            goFondo: _goFondo,
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      itemCount: data.fondos.length,
                      itemBuilder: (context, index) {
                        Fondo fondo = data.fondos[index];
                        return VistaDetalleFondos(
                          fondo: fondo,
                          updateFondo: _updateFondo,
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
    carteraProvider.fondoSelect = fondo;
    context.go(fondoPage);
  }

  List<ListTile> _buildChildrenContent(List<Update> updates) {
    List<ListTile> contentWidgets = [];
    for (var update in updates) {
      contentWidgets.add(ListTile(
        dense: true,
        title: Text(update.nameFondo),
        //subtitle: Text(update.nameCartera),
        trailing: update.isUpdate
            ? const Icon(Icons.check_box, color: green)
            : const Icon(Icons.disabled_by_default, color: red),
      ));
    }
    return contentWidgets;
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
    if (updateResultados.isNotEmpty) {
      List<ListTile> contentWidgets = _buildChildrenContent(updateResultados);
      await InfoDialog(
        context: context,
        title: 'Resultado',
        content: Column(children: contentWidgets),
      ).generateDialog();
    } else {
      _showMsg(msg: 'Nada que actualizar');
    }
  }

  _setStateDialog(String newText) {
    if (_dialogKey.currentState != null && _dialogKey.currentState!.mounted) {
      _dialogKey.currentState!.setState(() {
        _loadingText = newText;
      });
    }
  }

  Future<bool> _insertFondoDb(Fondo fondo) async {
    try {
      await database.updateFondo(carteraSelect, fondo);
      await database.insertValor(carteraSelect, fondo, fondo.valores!.first);
      await setFondos(carteraSelect);
      return true;
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch updateFondo / insertValor database',
              file: 'page_cartera.dart',
              clase: '_PageCarteraState',
              funcion: '_insertFondoDb',
              error: e,
              stackTrace: s));
      return false;
    }
  }

  Future<bool> _getDataApi(Fondo fondo) async {
    await database.createTableFondo(carteraSelect, fondo);
    final getDataApi = await apiService.getDataApi(fondo.isin);
    if (getDataApi != null) {
      var date = FechaUtil.epochToEpochHms(getDataApi.epochSecs);
      var newValor = Valor(date: date, precio: getDataApi.price);
      fondo.divisa = getDataApi.market;
      fondo.valores = [newValor];
      return _insertFondoDb(fondo);
    } else {
      return false;
    }
  }

  _updateFondo(Fondo fondo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Loading(
          titulo: fondo.name,
          subtitulo: 'Actualizando valor...',
        );
      },
    );
    bool update = await _getDataApi(fondo);
    _pop();
    if (update) {
      _showMsg(msg: 'Fondo actualizado');
    } else {
      if (apiService.status == StatusApiService.okHttp) {
        _showMsg(msg: 'Error al escribir en la base de datos', color: red900);
      } else {
        String msg = apiService.status.msg == ''
            ? 'Fondo no actualizado: Error en la descarga de datos'
            : apiService.status.msg;
        _showMsg(msg: msg, color: red900);
      }
    }
  }

  _dialogAutoUpdate(BuildContext context, Fondo newFondo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Loading(
          titulo: 'Fondo añadido',
          subtitulo: 'Cargando último valor...',
        );
      },
    );
    bool update = await _getDataApi(newFondo);
    _pop();
    if (update) {
      _showMsg(msg: 'Fondo actualizado');
    } else {
      if (apiService.status == StatusApiService.okHttp) {
        _showMsg(msg: 'Error al escribir en la base de datos', color: red900);
      } else {
        String msg = apiService.status.msg == ''
            ? 'Fondo no actualizado: Error en la descarga de datos'
            : apiService.status.msg;
        _showMsg(msg: msg, color: red900);
      }
    }
  }

  _addFondo(Fondo newFondo, AppPage page) async {
    var existe = [for (var fondo in carteraProvider.fondos) fondo.isin]
        .contains(newFondo.isin);
    if (existe) {
      _showMsg(
        msg: 'El fondo con ISIN ${newFondo.isin} ya existe en esta cartera.',
        color: red900,
      );
    } else {
      setState(() => addingFondo = true);
      if (prefProvider.isAutoAudate) {
        var docCnmv = DocCnmv(isin: newFondo.isin);
        int rating = await docCnmv.getRating();
        newFondo.rating = rating;
      }
      bool? insertOk;
      try {
        insertOk = await database.insertFondo(carteraSelect, newFondo);
      } catch (e, s) {
        Logger.log(
            dataLog: DataLog(
                msg: 'Catch insert new Fondo in database',
                file: 'page_cartera.dart',
                clase: '_PageCarteraState',
                funcion: '_addFondo',
                error: e,
                stackTrace: s));
      } finally {
        setState(() => addingFondo = false);
      }
      if (insertOk == true) {
        await setFondos(carteraSelect);
        if (prefProvider.isAutoAudate) {
          if (!mounted) return;
          if (page == AppPage.searchFondo) {
            await _dialogAutoUpdate(context, newFondo);
          } else {
            if (newFondo.valores != null &&
                newFondo.valores!.isNotEmpty &&
                newFondo.divisa != null) {
              bool insertFondo = await _insertFondoDb(newFondo);
              insertFondo
                  ? _showMsg(msg: 'Fondo añadido')
                  : _showMsg(msg: 'Error al añadir el Fondo', color: red900);
            } else {
              await _dialogAutoUpdate(context, newFondo);
            }
          }
        } else {
          _showMsg(msg: 'Fondo añadido');
        }
      } else {
        _showMsg(msg: 'Error al añadir el Fondo', color: red900);
      }
    }
  }

  _removeFondo(Fondo fondo) async {
    eliminarFondo() async {
      await database.deleteAllValores(carteraSelect, fondo);
      await database.deleteFondo(carteraSelect, fondo);
      await database.dropTableFondo(carteraSelect, fondo);
      carteraProvider.removeFondo(carteraSelect, fondo);
      await setFondos(carteraSelect);
    }

    if (prefProvider.isConfirmDeleteFondo) {
      bool? resp = await ConfirmDialog(
        context: context,
        title: 'Eliminar Fondo',
        content: '¿Eliminar el fondo ${fondo.name} y todos sus valores?',
      ).generateDialog();
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        eliminarFondo();
      }
    } else {
      eliminarFondo();
    }
  }

  void _deleteAllConfirm(BuildContext context) async {
    removeAllFondos() async {
      for (var fondo in carteraProvider.fondos) {
        await database.deleteAllValores(carteraSelect, fondo);
      }
      await database.deleteAllFondos(carteraSelect);
      await database.dropAllTablesFondos(carteraSelect);
      carteraProvider.removeAllFondos(carteraSelect);
      await setFondos(carteraSelect);
    }

    if (carteraProvider.fondos.isEmpty) {
      _showMsg(msg: 'Nada que eliminar');
    } else {
      bool? resp = await ConfirmDialog(
        context: context,
        title: 'Eliminar fondos',
        content:
            '¿Eliminar todos los fondos y sus valores en la cartera ${carteraSelect.name}?',
      ).generateDialog();
      if (resp == null || resp == false) {
        setState(() {});
      } else {
        removeAllFondos();
      }
    }
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
