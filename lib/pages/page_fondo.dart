import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../widgets/grafico_fondo.dart';
import '../widgets/loading_progress.dart';
import '../widgets/main_fondo.dart';
import '../widgets/tabla_fondo.dart';

enum Menu { mercado, eliminar, exportar }

class PageFondo extends StatefulWidget {
  const PageFondo({Key? key}) : super(key: key);
  @override
  State<PageFondo> createState() => _PageFondoState();
}

class _PageFondoState extends State<PageFondo> with SingleTickerProviderStateMixin {
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late Fondo fondoSelect;
  late List<Valor> valoresSelect;
  late List<Valor> operacionesSelect;
  late ApiService apiService;
  late TabController _tabController;

  setValores(Cartera cartera, Fondo fondo) async {
    carteraProvider.valores = await database.getValores(cartera, fondo);
    fondo.valores = carteraProvider.valores;
    valoresSelect = carteraProvider.valores;

    carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
    operacionesSelect = carteraProvider.operaciones;
  }

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;

    //valoresSelect = [];
    //operacionesSelect = [];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      database.createTableFondo(carteraSelect, fondoSelect).whenComplete(() async {
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

  PopupMenuItem<Menu> _buildMenuItem(Menu menu, IconData iconData, {bool divider = false}) {
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
          ),
          if (divider) const Divider(color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }

  SpeedDialChild _buildSpeedDialChild(BuildContext context,
      {required IconData icono, required String label, required Function action}) {
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
        if (snapshot.connectionState == ConnectionState.done) {
          return Container(
            decoration: scaffoldGradient,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    // TODO: set carteraOn antes de navigator??
                    //Navigator.of(context).pushNamed(RouteGenerator.carteraPage, arguments: true);
                    Navigator.of(context).pushNamed(RouteGenerator.carteraPage);
                  },
                ),
                title: ListTile(
                  title: Text(fondoSelect.name, style: const TextStyle(color: Color(0xFF0D47A1))),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.business_center, color: Color(0xFF0D47A1)),
                      const SizedBox(width: 10),
                      Text(carteraSelect.name, style: const TextStyle(color: Color(0xFF0D47A1))),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    color: const Color(0xFF2196F3),
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      //_buildMenuItem(Menu.editar, Icons.edit, divider: true),
                      //_buildMenuItem(Menu.suscribir, Icons.login),
                      _buildMenuItem(Menu.mercado, Icons.shopping_cart, divider: true),
                      _buildMenuItem(Menu.eliminar, Icons.delete_forever),
                      _buildMenuItem(Menu.exportar, Icons.download),
                    ],
                    onSelected: (Menu item) {
                      //TODO: ACCIONES PENDIENTES
                      if (item == Menu.mercado) {
                        Navigator.of(context).pushNamed(RouteGenerator.mercadoPage);
                      } else if (item == Menu.eliminar) {
                        _deleteConfirm(context);
                      } else if (item == Menu.exportar) {
                        print('EXPORTAR');
                      }
                    },
                  ),
                ],
              ),
              body: TabBarView(
                controller: _tabController,
                children: const [MainFondo(), TablaFondo(), GraficoFondo()],
              ),
              bottomNavigationBar: BottomAppBar(
                color: const Color(0xFF0D47A1),
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
                    indicatorColor: const Color(0xFF2196F3),
                    tabs: const [
                      Tab(icon: Icon(Icons.assessment, size: 32)),
                      Tab(icon: Icon(Icons.table_rows_outlined, size: 32)),
                      Tab(icon: Icon(Icons.timeline, size: 32)),
                    ],
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
              floatingActionButton: SpeedDial(
                icon: Icons.refresh,
                foregroundColor: const Color(0xFF0D47A1),
                backgroundColor: const Color(0xFFFFC107),
                spacing: 8,
                spaceBetweenChildren: 4,
                overlayColor: const Color(0xFF9E9E9E),
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
          );
        } else {
          return const LoadingProgress(titulo: 'Actualizando valores...');
        }
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
      var newValor = Valor(date: getDataApi.epochSecs, precio: getDataApi.price);
      fondoSelect.divisa = getDataApi.market;
      //TODO: POSIBLE ERROR SI CHOCA CON VALOR INTRODUCIDO DESDE MERCADO CON FECHA ANTERIOR
      //TODO check newvalor repetido por date ??
      //TODO: ESTE INSERT DESORDENA LOS FONDOS (pone al final el actualizado)

      // TODO: si existe update si no existe insert

      ///?
      //await database.insertFondo(carteraSelect, fondoSelect);

      //await database.insertValor(carteraSelect, fondoSelect, newValor);

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
    final newRange = await Navigator.of(context).pushNamed(RouteGenerator.inputRange);
    if (newRange != null) {
      if (!mounted) return;
      _dialogProgress(context);
      var range = newRange as DateTimeRange;
      String from = FechaUtil.dateToString(date: range.start, formato: 'yyyy-MM-dd');
      String to = FechaUtil.dateToString(date: range.end, formato: 'yyyy-MM-dd');
      final getDateApiRange = await apiService.getDataApiRange(fondoSelect.isin, to, from);
      var newListValores = <Valor>[];
      if (getDateApiRange != null) {
        for (var dataApi in getDateApiRange) {
          newListValores.add(Valor(date: dataApi.epochSecs, precio: dataApi.price));
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

  void _deleteConfirm(BuildContext context) async {
    //var fondoOn = context.read<CarfoinProvider>().getFondo!;
    // TODO: necesario getValores si se usa provider watch ??
    //await carfoin.getValoresFondo(fondoOn);
    if (carteraProvider.valores.isEmpty) {
      _showMsg(msg: 'Nada que eliminar');
    } else {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text('Eliminar todo'),
              content: const Text('Esto eliminará todos los valores almacenados del fondo.'),
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
                    await database.deleteAllValores(carteraSelect, fondoSelect);
                    await setValores(carteraSelect, fondoSelect);
                    _pop();
                    //_tabController.animateTo(_tabController.index);
                  },
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          });
    }
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
