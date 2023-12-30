import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../models/logger.dart';
import '../models/preferences_provider.dart';
import '../router/routes_const.dart';
import '../services/database_helper.dart';
import '../services/exchange_api.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/fecha_util.dart';
import '../utils/file_util.dart';
import '../utils/konstantes.dart';
import '../utils/update_all.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../widgets/dialogs/input_name_dialog.dart';
import '../widgets/flutter_expandable_fab.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/my_drawer.dart';
import '../widgets/views/vista_compacta.dart';
import '../widgets/views/vista_detalle.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});
  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  late PreferencesProvider prefProvider;
  late CarteraProvider carteraProvider;
  DatabaseHelper database = DatabaseHelper();
  //late YahooFinance yahooFinance;
  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';
  bool cargandoShare = false;

  bool isBadgeVisible = false;

  getSharedPrefs() async {
    await PreferencesService.getBool(keyByOrderCarterasPref)
        .then((value) => prefProvider.isByOrderCarteras = value);
    await PreferencesService.getBool(keyViewCarterasPref)
        .then((value) => prefProvider.isViewDetalleCarteras = value);
    await PreferencesService.getBool(keyByOrderFondosPref)
        .then((value) => prefProvider.isByOrderFondos = value);
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref)
        .then((value) => prefProvider.isConfirmDeleteCartera = value);
    await PreferencesService.getBool(keyDeleteOperaciones)
        .then((value) => prefProvider.isDeleteOperaciones = value);
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

    int dateSinceNotice =
        await PreferencesService.getDateSinceNotice(keyDateSinceNotice);
    if (dateSinceNotice == 0) {
      isBadgeVisible = true;
    } else {
      DateTime dateNotice = FechaUtil.epochToDate(dateSinceNotice);
      int difDaysNotice = now.difference(dateNotice).inDays;
      if (difDaysNotice > 30) {
        isBadgeVisible = true;
      }
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
    //yahooFinance = YahooFinance();
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
          color: AppColor.rojo900,
        );
      }
    }).catchError((onError) {
      showMsg(
        msg: 'Error en el proceso de carga de la cartera compartida',
        color: AppColor.rojo900,
      );
    }).whenComplete(() {
      setState(() => cargandoShare = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    return FutureBuilder(
      future: database.getCarteras(byOrder: prefProvider.isByOrderCarteras),
      builder: (BuildContext context, AsyncSnapshot<List<Cartera>> snapshot) {
        if (cargandoShare) {
          return const LoadingProgress(titulo: 'Cargando cartera...');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingProgress(titulo: 'Cargando carteras...');
        }
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) => false,
          child: Center(
            child: Container(
              decoration:
                  darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
              child: Scaffold(
                drawer: const MyDrawer(),
                appBar: AppBar(
                  title: const Text('Carteras'),
                  actions: [
                    if (isBadgeVisible)
                      Badge(
                        child: IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    const Text('NOTA'),
                                    const SizedBox(height: 20),
                                    const Text(
                                        'Recuerda guardar regularmente una copia de seguridad '
                                        'de la base de datos con la opción EXPORTAR. Después '
                                        'puedes recuperarla con la opción IMPORTAR.'),
                                    const SizedBox(height: 20),
                                    const Text(
                                        'También puedes salvar cada cartera por separado con la '
                                        'opción COMPARTIR y recuperarla desde la página principal '
                                        'como una nueva cartera compartida.'),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () async {
                                        setState(() => isBadgeVisible = false);
                                        await PreferencesService
                                            .saveDateSinceNotice(
                                          keyDateSinceNotice,
                                          FechaUtil.dateToEpoch(DateTime.now()),
                                        );
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Cerrar'),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.feedback),
                        ),
                      ),
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
                      icon: const Icon(Icons.more_vert),
                      offset: Offset(0.0, AppBar().preferredSize.height),
                      shape: AppBox.roundBorder,
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
                floatingActionButtonLocation: ExpandableFab.location,
                floatingActionButton: ExpandableFab(
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
                  child: const Icon(Icons.add),
                ),
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Consumer<CarteraProvider>(
                    builder: (context, data, child) {
                      if (data.carteras.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Empieza creando una cartera',
                              style: TextStyle(
                                  color: AppColor.blanco, fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (!prefProvider.isViewDetalleCarteras) {
                        return ListView.builder(
                          itemCount: data.carteras.length,
                          itemBuilder: (context, index) {
                            Cartera cartera = data.carteras[index];
                            return VistaCompacta(
                              cartera: cartera,
                              delete: _deleteCartera,
                              rename: _inputName,
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
      },
    );
  }

  List<ListTile> _buildChildrenContent(List<Update> updates) {
    List<ListTile> contentWidgets = [];
    for (var update in updates) {
      contentWidgets.add(ListTile(
        dense: true,
        title: Text(update.nameFondo),
        subtitle: Text(update.nameCartera),
        trailing: update.isUpdate
            ? const Icon(Icons.check_box, color: AppColor.verde)
            : const Icon(Icons.disabled_by_default, color: AppColor.rojo),
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
    if (carteraProvider.carteras.isNotEmpty) {
      var updateAll = UpdateAll(
        context: context,
        setStateDialog: _setStateDialog,
      );
      updateResultados = await updateAll.updateCarteras();
      if (updateResultados.isNotEmpty) {
        await setCarteras();
      }
    }
    _pop();
    if (updateResultados.isNotEmpty) {
      List<ListTile> contentWidgets = _buildChildrenContent(updateResultados);
      if (!context.mounted) return;
      await InfoDialog(
        context: context,
        title: 'Resultado',
        content: Column(children: contentWidgets),
      ).generateDialog();
    } else {
      showMsg(msg: 'Nada que actualizar');
    }
  }

  _setStateDialog(String newText) {
    if (_dialogKey.currentState != null && _dialogKey.currentState!.mounted) {
      _dialogKey.currentState!.setState(() {
        _loadingText = newText;
      });
    }
  }

  _export(BuildContext context) async {
    String? nombreDb = await Navigator.of(context).push(const RouterInputName(
      title: 'Exportar Base de Datos',
      label: 'Nombre del archivo sin extensión',
    ).builder());
    if (nombreDb != null) {
      nombreDb = '$nombreDb.db';
      var resultExport = await FileUtil.exportar(nombreDb);
      String content = '';
      if (resultExport.status == Status.ok) {
        content = 'Proceso de exportación terminado con éxito.';
        if (resultExport.msg != null) {
          if (resultExport.msg!.contains('0/')) {
            var index = resultExport.msg!.indexOf('0/');
            String path = resultExport.msg!.substring(index + 2);
            content += '\n\nCopia guardada en $path';
          }
        }
      } else if (resultExport.status == Status.error) {
        content = 'Error en el proceso de exportación.\n\n'
            'Intenta guardar la copia de seguridad en el almacenamiento '
            'interno (dependiendo de la versión de Android de tu dispositivo puede '
            'que la App no tenga permiso para escribir en la tarjeta SD).';
      } else if (resultExport.status == Status.abortado) {
        content = 'Proceso abortado';
        if (resultExport.msg != null) {
          content += '\n\n${resultExport.msg}';
        }
      }
      if (!context.mounted) return;
      await InfoDialog(
        context: context,
        title: 'Resultado',
        content: Text(content),
      ).generateDialog();
    }
  }

  _import(BuildContext context) async {
    const String content =
        'La nueva base de datos sobreescribirá los datos actuales, que se perderán y no podrán ser recuperados.\n\n'
        'Se recomienda exportar una copia de seguridad antes de importar una nueva base de datos.\n\n'
        '¿Quieres continuar con el proceso de importación?';
    bool? isConfirm = await ConfirmDialog(
            context: context, title: 'Importar Base de Datos', content: content)
        .generateDialog();
    if (isConfirm == null || isConfirm == false) return;
    var resultImport = await FileUtil.importar();
    String contentInfo = '';
    if (resultImport.status == Status.ok) {
      contentInfo = 'Proceso de importación terminado con éxito.';
    } else if (resultImport.status == Status.error) {
      contentInfo = 'Error en el proceso de importación.';
    } else if (resultImport.status == Status.abortado) {
      contentInfo = 'Proceso abortado';
    }
    if (resultImport.requiredRestart == true) {
      //contentInfo += '\n\nLa app se reiniciará.';
    } else {
      if (resultImport.msg != null) {
        contentInfo += '\n\n${resultImport.msg}';
      }
    }
    //setState(() {});
    if (!context.mounted) return;
    await InfoDialog(
      context: context,
      title: 'Resultado',
      content: Text(contentInfo),
    ).generateDialog();

    if (resultImport.requiredRestart == true) {
      setState(() {});
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PageHome()),
      );
      // TODO: REVISAR SIN REINICIAR
    }
  }

  Future<void> _inputName(BuildContext context, {Cartera? cartera}) async {
    String title = cartera?.name ?? 'Nueva Cartera';
    String? input = await Navigator.of(context)
        .push(RouterInputName(title: title).builder());
    if (input != null) {
      _submit(cartera, input);
    } else {
      setState(() {});
    }
  }

  _loadCartera(Cartera cartera) async {
    var existe = [for (var cartera in carteraProvider.carteras) cartera.name]
        .contains(cartera.name);
    if (existe) {
      showMsg(
          msg: 'Ya existe una cartera con ese nombre', color: AppColor.rojo900);
      return;
    } else {
      try {
        await database.createTableCartera(cartera).whenComplete(() async {
          await database.insertCartera(cartera);
        });
      } catch (e, s) {
        showMsg(
            msg: 'Proceso interrumpido: Error en la carga del archivo',
            color: AppColor.rojo900);
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
              if (fondo.valores != null && fondo.valores!.isNotEmpty) {
                for (var valor in fondo.valores!) {
                  await database.insertValor(cartera, fondo, valor);
                }
              }
            });
          }
        }
        await setCarteras();
      } catch (e, s) {
        showMsg(
            msg: 'Proceso interrumpido: Error en la carga del archivo',
            color: AppColor.rojo900);
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

  void _submit(Cartera? cartera, String input) async {
    var existe = [for (var cartera in carteraProvider.carteras) cartera.name]
        .contains(input);
    if (existe) {
      showMsg(
          msg: 'Ya existe una cartera con ese nombre', color: AppColor.rojo900);
    } else if (cartera != null) {
      cartera.name = input;
      await database.updateCartera(cartera);
      await setCarteras();
    } else {
      Cartera cartera = Cartera(name: input);
      await database.insertCartera(cartera);
      await setCarteras();
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

  _deleteCartera(Cartera cartera) async {
    if (prefProvider.isConfirmDeleteCartera) {
      bool? resp = await ConfirmDialog(
        context: context,
        title: 'Eliminar Cartera',
        content: '¿Eliminar la cartera ${cartera.name} y todos sus fondos?',
      ).generateDialog();
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
    await database.deleteAllFondos(cartera);
    await database.deleteCartera(cartera);

    await database.dropAllTablesFondos(cartera);
    await database.dropTableCartera(cartera);

    carteraProvider.removeAllFondos(cartera);
    carteraProvider.removeCartera(cartera);
    await setCarteras();
  }

  void _deleteConfirm(BuildContext context) async {
    bool? resp = await ConfirmDialog(
      context: context,
      title: 'Eliminar carteras',
      content: '¿Eliminar todas las carteras y sus fondos?',
    ).generateDialog();
    if (resp == true) {
      for (var cartera in carteraProvider.carteras) {
        _eliminar(cartera);
      }
      await database.deleteAllCarteras();
      await database.dropAllTables();
      carteraProvider.removeAllCarteras();
      await setCarteras();
    }
  }

  void showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
