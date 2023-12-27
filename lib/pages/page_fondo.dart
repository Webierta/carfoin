import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../models/preferences_provider.dart';
import '../router/router_utils.dart';
import '../router/routes_const.dart';
import '../services/database_helper.dart';
import '../services/doc_cnmv.dart';
import '../services/yahoo_finance.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../utils/fecha_util.dart';
import '../utils/status_api_service.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/flutter_expandable_fab.dart';
import '../widgets/loading_progress.dart';
import '../widgets/menus.dart';
import '../widgets/tabs/grafico_fondo.dart';
import '../widgets/tabs/main_fondo.dart';
import '../widgets/tabs/tabla_fondo.dart';

class PageFondo extends StatefulWidget {
  const PageFondo({super.key});
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
  late YahooFinance yahooFinance;
  late TabController _tabController;
  late PreferencesProvider prefProvider;

  setValores(Cartera cartera, Fondo fondo) async {
    try {
      carteraProvider.valores = await database.getValores(cartera, fondo);
      fondo.valores = carteraProvider.valores;
      valoresSelect = carteraProvider.valores;

      carteraProvider.operaciones =
          await database.getOperaciones(cartera, fondo);
      operacionesSelect = carteraProvider.operaciones;
      setState(() {}); // ??
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        context.go(errorPage);
      });
    }
  }

  @override
  void initState() {
    yahooFinance = YahooFinance();
    _tabController = TabController(vsync: this, length: 3);
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;
    prefProvider = context.read<PreferencesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      database
          .createTableFondo(carteraSelect, fondoSelect)
          .whenComplete(() async {
        await setValores(carteraSelect, fondoSelect);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;

    return FutureBuilder(
      future: database.getValores(carteraSelect, fondoSelect),
      builder: (BuildContext context, AsyncSnapshot<List<Valor>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingProgress(titulo: 'Actualizando valores...');
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) => false,
            child: Container(
              decoration:
                  darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    // TODO: set carteraOn antes de navigator??
                    onPressed: () {
                      context.go(carteraPage);
                    },
                  ),
                  title: ListTile(
                    dense: true,
                    title: Text(
                      fondoSelect.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.business_center, size: 18),
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
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => context.go(homePage),
                      icon: const Icon(Icons.home),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      offset: Offset(0.0, AppBar().preferredSize.height),
                      shape: AppBox.roundBorder,
                      itemBuilder: (ctx) => [
                        buildMenuItem(MenuFondo.mercado, Icons.shopping_cart),
                        buildMenuItem(MenuFondo.eliminar, Icons.delete_forever),
                      ],
                      onSelected: (item) async {
                        if (item == MenuFondo.mercado) {
                          context.go(mercadoPage);
                        } else if (item == MenuFondo.eliminar) {
                          if (carteraProvider.valores.isEmpty) {
                            showMsg(msg: 'Nada que eliminar');
                          } else {
                            String content = '';
                            if (prefProvider.isDeleteOperaciones == true &&
                                carteraProvider.operaciones.isNotEmpty) {
                              content =
                                  '¿Eliminar todos los valores del fondo y '
                                  'las operaciones asociadas? (en Ajustes puedes configurar esta '
                                  'acción para mantener esas operaciones)';
                            } else if (prefProvider.isDeleteOperaciones ==
                                    false &&
                                carteraProvider.operaciones.isNotEmpty) {
                              content = '¿Eliminar todos los valores del fondo '
                                  'manteniendo las operaciones asociadas? (en Ajustes puedes configurar '
                                  'esta acción para eliminar también esas operaciones)';
                            }
                            bool? resp = await ConfirmDialog(
                              context: context,
                              title: 'Eliminar Valores',
                              content: content,
                            ).generateDialog();
                            if (resp == true) {
                              if (prefProvider.isDeleteOperaciones == true) {
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
                  color: darkTheme ? AppColor.dark900 : AppColor.light900,
                  //shape: const CircularNotchedRectangle(),
                  clipBehavior: Clip.antiAlias,
                  //notchMargin: 5,
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    alignment: FractionalOffset.bottomLeft,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFFFFFFFF),
                      unselectedLabelColor: const Color(0x62FFFFFF),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(5.0),
                      indicatorColor: AppColor.light,
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
                floatingActionButton: ExpandableFab(
                  isEndDocked: true,
                  children: [
                    ChildFab(
                      icon: const Icon(Icons.date_range),
                      label: 'Valores Históricos',
                      onPressed: () => _getRangeApi(context),
                    ),
                    ChildFab(
                      icon: const Icon(Icons.update),
                      label: 'Actualizar Valor',
                      onPressed: () => _getDataApi(context),
                    ),
                  ],
                  child: const Icon(Icons.refresh),
                ),
              ),
            ),
          );
        }
        return const LoadingProgress(titulo: 'Actualizando valores...');
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

  _updateRating() async {
    updatingRating() async {
      var docCnmv = DocCnmv(isin: fondoSelect.isin);
      int rating = await docCnmv.getRating();
      if (rating != 0) {
        fondoSelect.rating = rating;
      }
    }

    if (valoresSelect.isNotEmpty) {
      var lastEpoch = valoresSelect.first.date;
      var lastDate = FechaUtil.epochToDate(lastEpoch);
      DateTime now = DateTime.now();
      int difDays = now.difference(lastDate).inDays;
      if (difDays > 30) {
        await updatingRating();
      }
    } else {
      await updatingRating();
    }
  }

  void _getDataApi(BuildContext context) async {
    _dialogProgress(context);
    await _updateRating();
    final newValores = await yahooFinance.getYahooFinanceResponse(fondoSelect);
    if (newValores != null && newValores.isNotEmpty) {
      var newValor = newValores[0];
      await database.updateFondo(carteraSelect, fondoSelect);
      await database.updateOperacion(carteraSelect, fondoSelect, newValor);
      await setValores(carteraSelect, fondoSelect);
      _pop();
      showMsg(msg: 'Descarga de datos completada.');
    } else {
      _pop();
      if (yahooFinance.status == StatusApiService.okHttp) {
        showMsg(
            msg: 'Error al escribir en la base de datos',
            color: AppColor.rojo900);
      } else {
        String msg = yahooFinance.status.msg == ''
            ? 'Fondo no actualizado: Error en la descarga de datos'
            : yahooFinance.status.msg;
        showMsg(msg: msg, color: AppColor.rojo900);
      }
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
      final newValores = await yahooFinance.getYahooFinanceResponse(
        fondoSelect,
        range.end,
        range.start,
      );
      if (newValores != null && newValores.isNotEmpty) {
        for (var valor in newValores) {
          await database.updateOperacion(carteraSelect, fondoSelect, valor);
        }
        await setValores(carteraSelect, fondoSelect);
        _pop();
        showMsg(msg: 'Descarga de datos completada.');
      } else {
        _pop();
        showMsg(
            msg:
                'Error en la descarga de datos. Es posible que no existan datos para esas fechas.',
            color: AppColor.rojo900);
      }
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
