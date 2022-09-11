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
import '../utils/fecha_util.dart';
import '../utils/styles.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/tabs/grafico_fondo.dart';
import '../widgets/tabs/main_fondo.dart';
import '../widgets/tabs/tabla_fondo.dart';

class PageFondo extends StatefulWidget {
  const PageFondo({Key? key}) : super(key: key);
  @override
  State<PageFondo> createState() => _PageFondoState();
}

class _PageFondoState extends State<PageFondo>
    with SingleTickerProviderStateMixin {
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late Fondo fondoSelect;
  late List<Valor> valoresSelect;
  late List<Valor> operacionesSelect;
  late ApiService apiService;
  late TabController _tabController;
  bool _deleteOp = false;

  setValores(Cartera cartera, Fondo fondo) async {
    try {
      carteraProvider.valores = await database.getValores(cartera, fondo);
      fondo.valores = carteraProvider.valores;
      valoresSelect = carteraProvider.valores;

      carteraProvider.operaciones =
          await database.getOperaciones(cartera, fondo);
      operacionesSelect = carteraProvider.operaciones;
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        context.go(errorPage);
      });
    }
  }

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      database
          .createTableFondo(carteraSelect, fondoSelect)
          .whenComplete(() async {
        await setValores(carteraSelect, fondoSelect);
      });
    });
    apiService = ApiService();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  SpeedDialChild _buildSpeedDialChild(
    BuildContext context, {
    required IconData icono,
    required String label,
    required Function action,
  }) {
    return SpeedDialChild(
      child: Icon(icono),
      label: label,
      backgroundColor: const Color(0xFFFFC107),
      foregroundColor: const Color(0xFF0D47A1),
      onTap: () async {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        action(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: database.getValores(carteraSelect, fondoSelect),
      builder: (BuildContext context, AsyncSnapshot<List<Valor>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingProgress(titulo: 'Actualizando valores...');
        }
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            decoration: scaffoldGradient,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    // TODO: set carteraOn antes de navigator??
                    context.go(carteraPage);
                  },
                ),
                title: ListTile(
                  title: Text(
                    fondoSelect.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: blue900),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.business_center, color: blue900),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          carteraSelect.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: blue900),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    color: blue,
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      buildMenuItem(MenuFondo.mercado, Icons.shopping_cart),
                      buildMenuItem(MenuFondo.eliminar, Icons.delete_forever),
                    ],
                    onSelected: (item) async {
                      if (item == MenuFondo.mercado) {
                        context.go(mercadoPage);
                      } else if (item == MenuFondo.eliminar) {
                        if (carteraProvider.valores.isEmpty) {
                          _showMsg(msg: 'Nada que eliminar');
                        } else {
                          var resp = await _deleteConfirm(context);
                          if (resp == null || resp == false) {
                            setState(() {});
                          } else {
                            if (_deleteOp) {
                              await database.deleteAllValores(
                                  carteraSelect, fondoSelect);
                            } else {
                              await database.deleteOnlyValores(
                                  carteraSelect, fondoSelect);
                            }
                            await setValores(carteraSelect, fondoSelect);
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              body: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [MainFondo(), TablaFondo(), GraficoFondo()],
              ),
              bottomNavigationBar: BottomAppBar(
                color: blue900,
                shape: const CircularNotchedRectangle(),
                notchMargin: 5,
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  alignment: FractionalOffset.bottomLeft,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFFFFFFF),
                    unselectedLabelColor: const Color(0x62FFFFFF),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(5.0),
                    indicatorColor: blue,
                    tabs: const [
                      Tab(icon: Icon(Icons.assessment, size: 32)),
                      Tab(icon: Icon(Icons.table_rows_outlined, size: 32)),
                      Tab(icon: Icon(Icons.timeline, size: 32)),
                    ],
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endDocked,
              floatingActionButton: SpeedDial(
                icon: Icons.refresh,
                foregroundColor: blue900,
                backgroundColor: amber,
                spacing: 8,
                spaceBetweenChildren: 4,
                overlayColor: gris,
                overlayOpacity: 0.4,
                children: [
                  _buildSpeedDialChild(
                    context,
                    icono: Icons.date_range,
                    label: 'Descargar valores históricos',
                    action: _getRangeApi,
                  ),
                  _buildSpeedDialChild(
                    context,
                    icono: Icons.update,
                    label: 'Actualizar último valor',
                    action: _getDataApi,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _dialogProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Loading(titulo: 'Descargando datos...');
      },
    );
  }

  void _getDataApi(BuildContext context) async {
    _dialogProgress(context);
    final getDataApi = await apiService.getDataApi(fondoSelect.isin);
    if (getDataApi != null) {
      /// TEST EPOCH HMS
      var date = FechaUtil.epochToEpochHms(getDataApi.epochSecs);

      var newValor = Valor(date: date, precio: getDataApi.price);
      fondoSelect.divisa = getDataApi.market;
      //TODO: POSIBLE ERROR SI CHOCA CON VALOR INTRODUCIDO DESDE MERCADO CON FECHA ANTERIOR
      //TODO check newvalor repetido por date ??
      //TODO: ESTE INSERT DESORDENA LOS FONDOS (pone al final el actualizado)

      // TODO: si existe update si no existe insert

      ///?
      //await database.insertFondo(carteraSelect, fondoSelect);
      //await database.insertValor(carteraSelect, fondoSelect, newValor);
      // NUEVO EN PRUEBA
      await database.updateFondo(carteraSelect, fondoSelect);
      // END PRUEBA
      await database.updateOperacion(carteraSelect, fondoSelect, newValor);
      await setValores(carteraSelect, fondoSelect);
      _pop();
      _showMsg(msg: 'Descarga de datos completada.');
    } else {
      _pop();
      _showMsg(msg: 'Error en la descarga de datos.', color: Colors.red);
    }
  }

  void _getRangeApi(BuildContext context) async {
    final newRange = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppPage.inputRange.routeClass),
    );
    if (newRange != null) {
      if (!mounted) return;
      _dialogProgress(context);
      var range = newRange as DateTimeRange;
      String from = FechaUtil.dateToString(
        date: range.start,
        formato: 'yyyy-MM-dd',
      );
      String to = FechaUtil.dateToString(
        date: range.end,
        formato: 'yyyy-MM-dd',
      );
      final getDateApiRange =
          await apiService.getDataApiRange(fondoSelect.isin, to, from);
      var newListValores = <Valor>[];
      if (getDateApiRange != null) {
        for (var dataApi in getDateApiRange) {
          /// TEST EPOCH HMS
          var date = FechaUtil.epochToEpochHms(dataApi.epochSecs);
          newListValores.add(Valor(date: date, precio: dataApi.price));
        }
        for (var valor in newListValores) {
          //await database.insertValor(carteraSelect, fondoSelect, valor);
          await database.updateOperacion(carteraSelect, fondoSelect, valor);
        }
        await setValores(carteraSelect, fondoSelect);
        // TODO set last valor (date y precio) desde VALORES cada vez en _updateValores
        _pop();
        _showMsg(msg: 'Descarga de datos completada.');
      } else {
        _pop();
        _showMsg(msg: 'Error en la descarga de datos.', color: Colors.red);
      }
    }
  }

  _deleteConfirm(BuildContext context) async {
    //var fondoOn = context.read<CarfoinProvider>().getFondo!;
    // TODO: necesario getValores si se usa provider watch ??
    //await carfoin.getValoresFondo(fondoOn);
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Eliminar Valores'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Esto eliminará todos los valores almacenados del fondo.'),
                    const SizedBox(height: 10),
                    if (carteraProvider.operaciones.isNotEmpty)
                      CheckboxListTile(
                        title: const Text('Eliminar operaciones'),
                        value: _deleteOp,
                        onChanged: (bool? newValue) {
                          setState(() => _deleteOp = newValue!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                );
              },
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  backgroundColor: red,
                  primary: const Color(0xFFFFFFFF),
                ),
                child: const Text('ACEPTAR'),
              ),
            ],
          );
        });
  }

  void _showMsg({required String msg, MaterialColor color = Colors.grey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _pop() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).pop();
  }
}
