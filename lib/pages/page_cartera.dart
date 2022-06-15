import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../widgets/loading_progress.dart';

enum MenuCartera { ordenar, eliminar }

class PageCartera extends StatefulWidget {
  const PageCartera({Key? key}) : super(key: key);
  @override
  State<PageCartera> createState() => _PageCarteraState();
}

class _PageCarteraState extends State<PageCartera> {
  bool _isFondosByOrder = true;
  bool _isAutoUpdate = true;
  late ApiService apiService;
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';

  getSharedPrefs() async {
    bool? isFondosByOrder;
    bool? isAutoUpdate;
    await PreferencesService.getBool(keyByOrderFondosPref).then((value) => isFondosByOrder = value);
    await PreferencesService.getBool(keyAutoUpdatePref).then((value) => isAutoUpdate = value);
    setState(() {
      _isFondosByOrder = isFondosByOrder ?? true;
      _isAutoUpdate = isAutoUpdate ?? true;
    });
  }

  setFondos(Cartera cartera) async {
    carteraProvider.fondos = await database.getFondos(cartera, byOrder: _isFondosByOrder);
    //carteraProvider.addFondos(cartera, carteraProvider.fondos);
    /// ????
    carteraSelect.fondos = carteraProvider.fondos;
    for (var fondo in carteraProvider.fondos) {
      await database.createTableFondo(cartera, fondo).whenComplete(() async {
        carteraProvider.valores = await database.getValores(cartera, fondo);
        fondo.valores = carteraProvider.valores;
        carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
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

  PopupMenuItem<MenuCartera> _buildMenuItem(MenuCartera menu, IconData iconData,
      {bool divider = false}) {
    return PopupMenuItem(
      value: menu,
      child: Column(
        children: [
          ListTile(
            leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
            title: Text(
              '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
              style: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
            trailing: menu == MenuCartera.ordenar
                ? Icon(
                    _isFondosByOrder ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFFFFFFFF),
                  )
                : null,
          ),
          if (divider) const Divider(height: 10, color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }

  SpeedDialChild _buildSpeedDialChild(BuildContext context,
      {required IconData icono, required String label, required String page}) {
    return SpeedDialChild(
      child: Icon(icono),
      label: label,
      backgroundColor: const Color(0xFFFFC107),
      foregroundColor: const Color(0xFF0D47A1),
      onTap: () async {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        final newFondo = await Navigator.of(context).pushNamed(page);
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
        if (snapshot.connectionState == ConnectionState.done) {
          return Container(
            decoration: scaffoldGradient,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    Navigator.of(context).pushNamed(RouteGenerator.homePage);
                  },
                ),
                title: Row(
                  children: [
                    const Icon(Icons.business_center),
                    const SizedBox(width: 10),
                    Text(carteraSelect.name),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _dialogUpdateAll(context);
                    },
                  ),
                  PopupMenuButton(
                    color: const Color(0xFF2196F3),
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      _buildMenuItem(MenuCartera.ordenar, Icons.sort_by_alpha),
                      _buildMenuItem(MenuCartera.eliminar, Icons.delete_forever)
                    ],
                    onSelected: (MenuCartera item) async {
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
                  _buildSpeedDialChild(context,
                      icono: Icons.search,
                      label: 'Buscar online por ISIN',
                      page: RouteGenerator.inputFondo),
                  _buildSpeedDialChild(context,
                      icono: Icons.storage,
                      label: 'Base de Datos local',
                      page: RouteGenerator.searchFondo),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Consumer<CarteraProvider>(
                  builder: (context, data, child) {
                    if (data.fondos.isEmpty) {
                      return const Center(child: Text('No hay fondos guardados.'));
                    }
                    return ListView.builder(
                      itemCount: data.fondos.length,
                      itemBuilder: (context, index) {
                        Fondo fondo = data.fondos[index];
                        //List<Valor> valores = await database.getValores(carteraSelect, fondo);
                        //final valores = context.read<CarteraProvider>().valores;
                        List<Valor>? valores = data.fondos[index].valores;
                        String lastDate = '';
                        String lastPrecio = '';
                        double? diferencia;
                        if (valores != null && valores.isNotEmpty) {
                          int lastEpoch = valores.first.date;
                          lastDate = FechaUtil.epochToString(lastEpoch);
                          lastPrecio =
                              NumberFormat.decimalPattern('es').format(valores.first.precio);
                          if (valores.length > 1) {
                            diferencia = valores.first.precio - valores[1].precio;
                          }
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
                          onDismissed: (_) async {
                            await _removeFondo(fondo);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12.0),
                                leading: const Icon(Icons.assessment,
                                    size: 32, color: Color(0xFF0D47A1)),
                                title: Text(fondo.name),
                                subtitle: Text(fondo.isin),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // lastDate / lastPrecio / diferencia
                                    //Text('${fondo.dateMaximo ?? ''}'),
                                    Text(lastDate),
                                    Text(
                                      lastPrecio,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (diferencia != null)
                                      Text(
                                        diferencia.toStringAsFixed(2),
                                        style: TextStyle(
                                            color: diferencia < 0
                                                ? const Color(0xFFF44336)
                                                : const Color(0xFF4CAF50)),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                  carteraProvider.fondoSelect = fondo;
                                  Navigator.of(context).pushNamed(RouteGenerator.fondoPage);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          return const LoadingProgress(titulo: 'Actualizando fondos...');
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
            // return Dialog(child: Loading(...); ???
            return Loading(titulo: 'ACTUALIZANDO FONDOS...', subtitulo: _loadingText);
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
          var newValor = Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
          //TODO valor divisa??
          fondo.divisa = getDataApi.market;
          // cambiar insertar por update para no duplicar el fondo en la cartera
          //await carfoin.insertFondoCartera(fondo);

          //await carfoin.updateFondoCartera(fondo);
          //await carfoin.insertValorFondo(fondo, newValor);
          await database.updateFondo(carteraSelect, fondo);
          await database.insertValor(carteraSelect, fondo, newValor);
          mapResultados[fondo.name] = const Icon(Icons.check_box, color: Colors.green);
        } else {
          mapResultados[fondo.name] = const Icon(Icons.disabled_by_default, color: Colors.red);
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
                      ListTile(dense: true, title: Text(res.key), trailing: res.value),
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
      var newValor = Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
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
        return const Loading(titulo: 'FONDO AÑADIDO', subtitulo: 'Cargando último valor...');
      },
    );
    var update = await _getDataApi(newFondo);
    _pop();
    update
        ? _showMsg(msg: 'Fondo actualizado')
        : _showMsg(msg: 'Error al actualizar el fondo', color: Colors.red);
  }

  _addFondo(Fondo newFondo) async {
    var existe = [for (var fondo in carteraProvider.fondos) fondo.isin].contains(newFondo.isin);
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

  _removeFondo(Fondo fondo) async {
    await database.deleteFondo(carteraSelect, fondo);
    carteraProvider.removeFondo(carteraSelect, fondo);

    /// ???
    await setFondos(carteraSelect);
  }

  void _deleteAllConfirm(BuildContext context) {
    if (carteraProvider.fondos.isEmpty) {
      _showMsg(msg: 'Nada que eliminar');
    } else {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text('Eliminar todo'),
              content: Text(
                  'Esto eliminará todos los fondos almacenados en la cartera ${carteraSelect.name}'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    primary: const Color(0xFFFFFFFF),
                  ),
                  onPressed: () async {
                    await database.deleteAllFondos(carteraSelect);
                    carteraProvider.removeAllFondos(carteraSelect);

                    /// ???
                    await setFondos(carteraSelect);
                    _pop();
                  },
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          });
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

/*****

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/control_center.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../widgets/loading_progress.dart';

enum MenuCartera { ordenar, eliminar }

class PageCartera extends StatefulWidget {
  const PageCartera({Key? key}) : super(key: key);
  @override
  State<PageCartera> createState() => _PageCarteraState();
}

class _PageCarteraState extends State<PageCartera> {
  late ControlCenter controlCenter;
  bool _isFondosByOrder = false;
  bool _isCarterasByOrder = false;
  bool _isAutoUpdate = true;
  late ApiService apiService;
  final GlobalKey _dialogKey = GlobalKey();
  String _loadingText = '';

  getSharedPrefs() async {
    bool? isCarterasByOrder;
    bool? isFondosByOrder;
    bool? isAutoUpdate;
    await PreferencesService.getBool(keyByOrderCarterasPref).then((value) {
      isCarterasByOrder = value;
      //setState(() => _isCarterasByOrder = value);
    });
    await PreferencesService.getBool(keyByOrderFondosPref).then((value) {
      isFondosByOrder = value;
      //setState(() => _isFondosByOrder = value);
    });
    await PreferencesService.getBool(keyAutoUpdatePref).then((value) {
      isAutoUpdate = value;
      //setState(() => _isAutoUpdate = value);
    });
    setState(() {
      _isCarterasByOrder = isCarterasByOrder!;
      _isFondosByOrder = isFondosByOrder!;
      _isAutoUpdate = isAutoUpdate!;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSharedPrefs();
    });
    controlCenter = ControlCenter(context);
    controlCenter.openDb().whenComplete(() async {
      await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
    });
    apiService = ApiService();
    super.initState();
  }

  PopupMenuItem<MenuCartera> _buildMenuItem(MenuCartera menu, IconData iconData,
      {bool divider = false}) {
    return PopupMenuItem(
      value: menu,
      child: Column(
        children: [
          ListTile(
            leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
            title: Text(
              '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
              style: const TextStyle(color: Color(0xFFFFFFFF)),
            ),
            trailing: menu == MenuCartera.ordenar
                ? Icon(
                    _isFondosByOrder ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFFFFFFFF),
                  )
                : null,
          ),
          if (divider) const Divider(height: 10, color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }

  SpeedDialChild _buildSpeedDialChild(BuildContext context,
      {required IconData icono, required String label, required String page}) {
    return SpeedDialChild(
      child: Icon(icono),
      label: label,
      backgroundColor: const Color(0xFFFFC107),
      foregroundColor: const Color(0xFF0D47A1),
      onTap: () async {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        final newFondo = await Navigator.of(context).pushNamed(page);
        newFondo != null
            ? _addFondo(newFondo as Fondo)
            : _showMsg(msg: 'Sin cambios en la cartera.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    var fondos = context.watch<CarteraProvider>().fondos;
    return FutureBuilder<bool>(
      future: controlCenter.openDb(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // TODO : pendiente manejar error
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}', style: const TextStyle(fontSize: 18)),
            );
          } else if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    Navigator.of(context).pushNamed(RouteGenerator.homePage);
                  },
                ),
                title: Text(carteraOn.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _dialogUpdateAll(context);
                    },
                  ),
                  PopupMenuButton(
                    color: Colors.blue,
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      _buildMenuItem(MenuCartera.ordenar, Icons.sort_by_alpha),
                      _buildMenuItem(MenuCartera.eliminar, Icons.delete_forever)
                    ],
                    onSelected: (MenuCartera item) async {
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
                overlayColor: Colors.grey,
                overlayOpacity: 0.4,
                children: [
                  _buildSpeedDialChild(context,
                      icono: Icons.search,
                      label: 'Buscar online por ISIN',
                      page: RouteGenerator.inputFondo),
                  _buildSpeedDialChild(context,
                      icono: Icons.storage,
                      label: 'Base de Datos local',
                      page: RouteGenerator.searchFondo),
                ],
              ),
              /*body: carteraOn.fondos.isEmpty
                  ? const Center(child: Text('No hay fondos guardados.')) : Consumer..*/
              body: Consumer<CarteraProvider>(builder: (context, data, child) {
                if (data.carteras.isEmpty) {
                  return const Center(child: Text('No hay fondos guardados.'));
                }
                return ListView.builder(
                  //itemCount: carteraOn.fondos.length,
                  itemCount: data.carteraOn!.fondos.length,
                  itemBuilder: (context, index) {
                    Fondo cartFondo = data.fondos[index];
                    // cartFondo ============  carteraOn.fondos[index]
                    int? lastEpoch = _getLastDate(cartFondo);
                    String lastDate = lastEpoch != null ? FechaUtil.epochToString(lastEpoch) : '';
                    String lastPrecio = '${_getLastPrecio(cartFondo) ?? ''}';
                    double? diferencia = _getDiferencia(cartFondo);
                    return Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.centerRight,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                      onDismissed: (_) async {
                        await _removeFondo(cartFondo);
                      },
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.assessment, size: 32),
                          title: Text(cartFondo.name),
                          subtitle: Text(cartFondo.isin),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(lastDate),
                              Text(
                                lastPrecio,
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            controlCenter.providerOnFondo(cartFondo);

                            ///Navigator.of(context).pushNamed(RouteGenerator.fondoPage);
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            );
          }
        }
        return const LoadingProgress(titulo: 'Recuperando fondos...', subtitulo: 'Cargando...');
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
            return Loading(titulo: 'ACTUALIZANDO FONDOS...', subtitulo: _loadingText);
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
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    var fondosOn = carteraOn.fondos;
    _setStateDialog('Conectando...');
    var mapResultados = <String, Icon>{};
    if (fondosOn.isNotEmpty) {
      for (var fondo in fondosOn) {
        _setStateDialog(fondo.name);
        //TODO: NECESARIO  createTable ?
        await controlCenter.createTableFondo(carteraOn, fondo);
        final getDataApi = await apiService.getDataApi(fondo.isin);
        if (getDataApi != null) {
          var newValor = Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
          //TODO valor divisa??
          fondo.divisa = getDataApi.market;
          // cambiar insertar por update para no duplicar el fondo en la cartera
          //await carfoin.insertFondoCartera(fondo);
          //await carfoin.updateFondoCartera(fondo);
          await controlCenter.updateFondoCartera(carteraOn, fondo);
          //await carfoin.insertValorFondo(fondo, newValor);
          await controlCenter.insertValor(carteraOn, fondo, newValor);

          ///await controlCenter
          mapResultados[fondo.name] = const Icon(Icons.check_box, color: Colors.green);
        } else {
          mapResultados[fondo.name] = const Icon(Icons.disabled_by_default, color: Colors.red);
        }
      }
      //TODO: check si es necesario update (si no ha habido cambios porque todos los fondos han dado error)
      ///await carfoin.updateFondos(_isFondosByOrder);

      //await carfoin.updateDbCarteras(_isCarterasByOrder);
      await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
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
                      ListTile(dense: true, title: Text(res.key), trailing: res.value),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double? _getLastPrecio(Fondo fondo) {
    /*if (fondo.historico.isNotEmpty) {
      return fondo.historico.first.precio;
    }*/
    if (fondo.valores.isNotEmpty) {
      return fondo.valores.first.precio;
    }
    return null;
  }

  int? _getLastDate(Fondo fondo) {
    /*if (fondo.historico.isNotEmpty) {
      return fondo.historico.first.date;
    }*/
    if (fondo.valores.isNotEmpty) {
      return fondo.valores.first.date;
    }
    return null;
  }

  double? _getDiferencia(Fondo fondo) {
    /*if (fondo.historico.length > 1) {
      var last = fondo.historico.first.precio;
      var prev = fondo.historico[1].precio;
      return last - prev;
    }*/
    if (fondo.valores.length > 1) {
      return fondo.valores.first.precio - fondo.valores[1].precio;
    }
    return null;
  }

  _getDataApi(Fondo fondo) async {
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    //await carfoin.createTableFondo(fondo);
    await controlCenter.createTableFondo(carteraOn, fondo);
    final getDataApi = await apiService.getDataApi(fondo.isin);
    if (getDataApi != null) {
      var newValor = Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
      fondo.divisa = getDataApi.market;

      ///await carfoin.insertFondoCartera(fondo);
      //await carfoin.updateFondoCartera(fondo);
      //await carfoin.insertValorFondo(fondo, newValor);
      await controlCenter.updateFondoCartera(carteraOn, fondo);
      await controlCenter.insertValor(carteraOn, fondo, newValor);
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
        return const Loading(titulo: 'FONDO AÑADIDO', subtitulo: 'Cargando último valor...');
      },
    );
    var update = await _getDataApi(newFondo);
    _pop();
    update
        ? _showMsg(msg: 'Fondo actualizado')
        : _showMsg(msg: 'Error al actualizar el fondo', color: Colors.red);
  }

  _addFondo(Fondo newFondo) async {
    //var carteraOn = context.read<CarfoinProvider>().getCartera!;
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    var fondosOn = carteraOn.fondos;
    //var existe = [for (var fondo in carfoin.getFondos) fondo.isin].contains(newFondo.isin);
    var existe = [for (var fondo in fondosOn) fondo.isin].contains(newFondo.isin);
    if (existe) {
      _showMsg(
        msg: 'El fondo con ISIN ${newFondo.isin} ya existe en esta cartera.',
        color: Colors.red,
      );
    } else {
      //await carfoin.insertFondoCartera(newFondo);
      await controlCenter.insertFondo(carteraOn, newFondo);
      //var carteraOn = context.read<CarfoinProvider>().getCartera!;

      if (_isAutoUpdate) {
        if (!mounted) return;
        await _dialogAutoUpdate(context, newFondo);
      } else {
        _showMsg(msg: 'Fondo añadido');
      }

      ///await carfoin.updateFondos(_isFondosByOrder);
    }
    // TODO: por qué no es necesario aquí ??
    //await carfoin.updateDbCarteras(_isCarterasByOrder);
    await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
  }

  _removeFondo(Fondo fondo) async {
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    //await carfoin.deleteFondoCartera(fondo);
    //await carfoin.updateFondos(_isFondosByOrder);
    //await carfoin.updateDbCarteras(_isCarterasByOrder);
    await controlCenter.deleteFondo(carteraOn, fondo);
    await controlCenter.updateFondos(carteraOn, _isFondosByOrder);
    await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
  }

  _removeAllFondos(List<Fondo> fondos) async {
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    for (var fondo in fondos) {
      //await carfoin.deleteFondoCartera(fondo);
      await controlCenter.deleteFondo(carteraOn, fondo);
    }
    //await carfoin.updateFondos(_isFondosByOrder);
    //await carfoin.updateDbCarteras(_isCarterasByOrder);
    await controlCenter.updateFondos(carteraOn, _isFondosByOrder);
    await controlCenter.updateFondos(carteraOn, _isFondosByOrder);
  }

  _ordenarFondos() async {
    setState(() => _isFondosByOrder = !_isFondosByOrder);
    PreferencesService.saveBool(keyByOrderFondosPref, _isFondosByOrder);

    ///await carfoin.updateFondos(_isFondosByOrder);
    //await carfoin.updateDbCarteras(_isCarterasByOrder);
    await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
  }

  void _deleteAllConfirm(BuildContext context) {
    var carteraOn = context.read<CarteraProvider>().carteraOn!;
    //var carteraOn = context.read<CarfoinProvider>().getCartera!;
    var fondosOn = carteraOn.fondos;
    //if (carfoin.getFondos.isEmpty) {
    if (fondosOn.isEmpty) {
      _showMsg(msg: 'Nada que eliminar');
    } else {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            //var carteraOn = context.read<CarfoinProvider>().getCartera!;
            return AlertDialog(
              title: const Text('Eliminar todo'),
              content: Text(
                  'Esto eliminará todos los fondos almacenados en la cartera ${carteraOn.name}'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    primary: const Color(0xFFFFFFFF),
                  ),
                  onPressed: () async {
                    _removeAllFondos(fondosOn);
                    /*for (var fondo in carfoin.getFondos) {
                      //await carfoin.deleteFondo(fondo);
                      await carfoin.deleteFondoCartera(fondo);
                    }
                    await carfoin.updateFondos(_isFondosByOrder);
                    await carfoin.updateDbCarteras(_isCarterasByOrder);
                    carfoin.deleteAllFondosCarteras();*/
                    _pop();
                  },
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          });
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

    ***/
