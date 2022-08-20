import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../router/router_utils.dart';
import '../router/routes_const.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../utils/stats.dart';
import '../widgets/hoja_calendario.dart';
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
      backgroundColor: const Color(0xFFFFC107),
      foregroundColor: const Color(0xFF0D47A1),
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
                  PopupMenuButton(
                    color: const Color(0xFF2196F3),
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      buildMenuItem(MenuCartera.ordenar, Icons.sort_by_alpha,
                          isOrder: _isFondosByOrder),
                      buildMenuItem(MenuCartera.eliminar, Icons.delete_forever)
                    ],
                    onSelected: (item) async {
                      if (item == MenuCartera.ordenar) {
                        _ordenarFondos();
                      } else if (item == MenuCartera.eliminar) {
                        _deleteAllConfirm(context);
                      }
                    },
                  ),
                ],
              ),
              floatingActionButton: SpeedDial(
                icon: Icons.addchart,
                foregroundColor: const Color(0xFF0D47A1),
                backgroundColor: const Color(0xFFFFC107),
                spacing: 8,
                spaceBetweenChildren: 4,
                overlayColor: const Color(0xFF9E9E9E),
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
                padding: const EdgeInsets.all(12.0),
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
                    return ListView.builder(
                      itemCount: data.fondos.length,
                      itemBuilder: (context, index) {
                        Fondo fondo = data.fondos[index];
                        return DataCartera(
                          fondo: fondo,
                          removeFondo: _removeFondo,
                          goFondo: _goFondo,
                        );

                        /*
                        /// START WIDGET

                        //List<Valor> valores = await database.getValores(carteraSelect, fondo);
                        //final valores = context.read<CarteraProvider>().valores;
                        List<Valor>? valores = data.fondos[index].valores;
                        String lastDate = '';
                        int dia = 0;
                        String mesYear = '';
                        String lastPrecio = '';
                        String divisa = fondo.divisa ?? '';
                        double? diferencia;
                        if (valores != null && valores.isNotEmpty) {
                          int lastEpoch = valores.first.date;
                          lastDate = FechaUtil.epochToString(lastEpoch);
                          dia = FechaUtil.epochToDate(lastEpoch).day;
                          //mes = FechaUtil.epochToDate(lastEpoch).month;
                          //ano = FechaUtil.epochToDate(lastEpoch).year;
                          mesYear = FechaUtil.epochToString(lastEpoch,
                              formato: 'MMM yy');
                          //lastPrecio = NumberFormat.decimalPattern('es').format(valores.first.precio);
                          lastPrecio = NumberUtil.decimal(valores.first.precio);
                          if (valores.length > 1) {
                            diferencia =
                                valores.first.precio - valores[1].precio;
                          }
                          stats = Stats(valores);
                        }
                        // TODO: refactor widget DISMISSIBLE
                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: const Color(0xFFF44336),
                            margin: const EdgeInsets.symmetric(horizontal: 15),
                            alignment: Alignment.centerRight,
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child:
                                  Icon(Icons.delete, color: Color(0xFFFFFFFF)),
                            ),
                          ),
                          onDismissed: (_) async => await _removeFondo(fondo),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.5),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFFFFFFF),
                                      child: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFFFC107),
                                        child: IconButton(
                                          onPressed: () =>
                                              _goFondo(context, fondo),
                                          icon: const Icon(
                                            Icons.poll,
                                            color: Color(0xFF0D47A1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      fondo.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                    subtitle: Text(
                                      fondo.isin,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                    //trailing: const Icon(Icons.more_vert),
                                  ),
                                  if (valores != null && valores.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBBDEFB),
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //mainAxisAlignment: MainAxisAlignment.start,
                                              //crossAxisAlignment: CrossAxisAlignment.start,
                                              DiaCalendario(
                                                  epoch: valores.first.date),
                                              //const Spacer(),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    //const Spacer(),
                                                    Text(
                                                      'V.L. $lastPrecio $divisa',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF0D47A1),
                                                      ),
                                                    ),
                                                    if (diferencia != null)
                                                      Text(
                                                        diferencia
                                                            .toStringAsFixed(2),
                                                        style: TextStyle(
                                                          color: diferencia < 0
                                                              ? const Color(
                                                                  0xFFF44336)
                                                              : const Color(
                                                                  0xFF4CAF50),
                                                        ),
                                                      ),
                                                    //const Spacer(),
                                                    (stats.resultado() !=
                                                                null &&
                                                            stats.resultado() !=
                                                                0)
                                                        ? FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              'Capital: ${NumberUtil.decimalFixed(stats.resultado()!)} $divisa',
                                                              style:
                                                                  const TextStyle(
                                                                color: Color(
                                                                    0xFF0D47A1),
                                                                //fontSize: 14
                                                              ),
                                                            ),
                                                          )
                                                        : const Text(
                                                            'Sin inversiones'),
                                                    //const Spacer(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );

                        /// END WIDGET
                        */
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
    var mapResultados = await _updateAll(context);
    _pop();
    mapResultados.isNotEmpty
        ? await _showResultados(mapResultados)
        : _showMsg(msg: 'Nada que actualizar');
  }

  _setStateDialog(String newText) {
    if (_dialogKey.currentState != null && _dialogKey.currentState!.mounted) {
      _dialogKey.currentState!.setState(() {
        _loadingText = newText;
      });
    }
  }

  Future<Map<String, Icon>> _updateAll(BuildContext context) async {
    //var carteraOn = context.read<CarfoinProvider>().getCartera!;
    //var fondosOn = carteraOn.fondos;

    var fondosOn = carteraSelect.fondos;

    _setStateDialog('Conectando...');
    var mapResultados = <String, Icon>{};
    //await carfoin.getFondosCartera(_isFondosByOrder);
    //if (carfoin.getFondos.isNotEmpty) {
    if (fondosOn != null && fondosOn.isNotEmpty) {
      for (var fondo in fondosOn) {
        _setStateDialog(fondo.name);
        //TODO: NECESARIO  createTable ?
        ///await carfoin.createTableFondo(fondo);
        await database.createTableFondo(carteraSelect, fondo);
        final getDataApi = await apiService.getDataApi(fondo.isin);
        if (getDataApi != null) {
          var newValor =
              Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
          //TODO valor divisa??
          fondo.divisa = getDataApi.market;
          // cambiar insertar por update para no duplicar el fondo en la cartera
          //await carfoin.insertFondoCartera(fondo);

          //await carfoin.updateFondoCartera(fondo);
          //await carfoin.insertValorFondo(fondo, newValor);
          await database.updateFondo(carteraSelect, fondo);
          // NUEVO EN PRUEBA
          //await database.insertValor(carteraSelect, fondo, newValor);
          await database.updateOperacion(carteraSelect, fondo, newValor);
          // END PRUEBA

          mapResultados[fondo.name] =
              const Icon(Icons.check_box, color: Colors.green);
        } else {
          mapResultados[fondo.name] =
              const Icon(Icons.disabled_by_default, color: Colors.red);
        }
      }
      //TODO: check si es necesario update (si no ha habido cambios porque todos los fondos han dado error)
      ///await carfoin.updateFondos(_isFondosByOrder);

      //await carfoin.updateDbCarteras(_isCarterasByOrder);
      await setFondos(carteraSelect);
    }
    return mapResultados;
  }

  _showResultados(Map<String, Icon> mapResultados) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                    for (var res in mapResultados.entries)
                      ListTile(
                          dense: true,
                          title: Text(res.key),
                          trailing: res.value),
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
      var newValor =
          Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
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

  _removeFondo(Fondo fondo) async {
    _eliminarFondo() async {
      await database.deleteAllValores(carteraSelect, fondo);
      await database.deleteFondo(carteraSelect, fondo);
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

      //resp ? _removeAllFondos() : setState(() {});
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

class DataCartera extends StatelessWidget {
  final Fondo fondo;
  final Function removeFondo;
  final Function goFondo;
  const DataCartera({
    Key? key,
    required this.fondo,
    required this.removeFondo,
    required this.goFondo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Valor>? valores = fondo.valores;

    Stats? stats;
    String lastDate = '';
    int dia = 0;
    String mesYear = '';
    String lastPrecio = '';
    String divisa = fondo.divisa ?? '';
    double? diferencia;
    if (valores != null && valores.isNotEmpty) {
      int lastEpoch = valores.first.date;
      lastDate = FechaUtil.epochToString(lastEpoch);
      dia = FechaUtil.epochToDate(lastEpoch).day;
      //mes = FechaUtil.epochToDate(lastEpoch).month;
      //ano = FechaUtil.epochToDate(lastEpoch).year;
      mesYear = FechaUtil.epochToString(lastEpoch, formato: 'MMM yy');
      //lastPrecio = NumberFormat.decimalPattern('es').format(valores.first.precio);
      lastPrecio = NumberUtil.decimal(valores.first.precio);
      if (valores.length > 1) {
        diferencia = valores.first.precio - valores[1].precio;
      }
      stats = Stats(valores);
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
      onDismissed: (_) async => await removeFondo(fondo),
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
                      onPressed: () => goFondo(context, fondo),
                      icon: const Icon(Icons.poll, color: Color(0xFF0D47A1)),
                    ),
                  ),
                ),
                title: Text(
                  fondo.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2196F3),
                  ),
                ),
                subtitle: Text(
                  fondo.isin,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              if (valores != null && valores.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBDEFB),
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DiaCalendario(epoch: valores.first.date),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'V.L. $lastPrecio $divisa',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                if (diferencia != null)
                                  Text(
                                    diferencia.toStringAsFixed(2),
                                    style: TextStyle(
                                      color: diferencia < 0
                                          ? const Color(0xFFF44336)
                                          : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                (stats != null &&
                                        stats.resultado() != null &&
                                        stats.resultado() != 0)
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Capital: ${NumberUtil.decimalFixed(stats.resultado()!)} $divisa',
                                          style: const TextStyle(
                                            color: Color(0xFF0D47A1),
                                            //fontSize: 14
                                          ),
                                        ),
                                      )
                                    : const Text('Sin inversiones'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
