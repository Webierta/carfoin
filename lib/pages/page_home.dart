import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/control_center.dart';
import '../services/preferences_service.dart';
import '../utils/konstantes.dart';
import '../widgets/loading_progress.dart';

enum Menu { renombrar, ordenar, exportar, eliminar }

class PageHome extends StatefulWidget {
  const PageHome({Key? key}) : super(key: key);

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  late ControlCenter controlCenter;
  late bool _isCarterasByOrder;
  late bool _isFondosByOrder;
  late TextEditingController _controller;

  getSharedPrefs() async {
    await PreferencesService.getBool(keyByOrderCarterasPref).then((value) {
      setState(() => _isCarterasByOrder = value);
    });
    await PreferencesService.getBool(keyByOrderFondosPref).then((value) {
      setState(() => _isFondosByOrder = value);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSharedPrefs();
    });
    _controller = TextEditingController();
    controlCenter = ControlCenter(context);
    controlCenter.openDb().whenComplete(() async {
      await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
    });
    super.initState();
  }

  _ordenarCarteras() async {
    setState(() => _isCarterasByOrder = !_isCarterasByOrder);
    PreferencesService.saveBool(keyByOrderCarterasPref, _isCarterasByOrder);
    await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
  }

  @override
  void dispose() {
    _controller.dispose();
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
            trailing: menu == Menu.ordenar
                ? Icon(
                    _isCarterasByOrder ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFFFFFFFF),
                  )
                : null,
          ),
          if (divider == true) const Divider(color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: controlCenter.openDb(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}', style: const TextStyle(fontSize: 18)),
            );
          } else if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('MIS CARTERAS'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteGenerator.settingsPage);
                    },
                  ),
                  PopupMenuButton(
                    color: Colors.blue,
                    offset: Offset(0.0, AppBar().preferredSize.height),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    itemBuilder: (ctx) => [
                      _buildMenuItem(Menu.renombrar, Icons.edit, divider: false),
                      _buildMenuItem(Menu.ordenar, Icons.sort_by_alpha, divider: true),
                      _buildMenuItem(Menu.exportar, Icons.save, divider: false),
                      _buildMenuItem(Menu.eliminar, Icons.delete_forever, divider: false),
                    ],
                    onSelected: (item) async {
                      //TODO: ACCIONES PENDIENTES
                      if (item == Menu.renombrar) {
                        print('RENAME');
                      } else if (item == Menu.ordenar) {
                        _ordenarCarteras();
                      } else if (item == Menu.exportar) {
                        print('EXPORTAR');
                      } else if (item == Menu.eliminar) {
                        _deleteConfirm(context);
                      }
                    },
                  ),
                ],
              ),
              //drawer: const MyDrawer(),
              floatingActionButton: FloatingActionButton(
                backgroundColor: const Color(0xFFFFC107),
                child: const Icon(Icons.add, color: Color(0xFF0D47A1)),
                onPressed: () => _carteraInput(context),
              ),
              /*body: carteras.isEmpty
                  ? const Center(child: Text('No hay carteras guardadas.')) : Consumer...*/
              body: Consumer<CarteraProvider>(
                builder: (context, data, child) {
                  if (data.carteras.isEmpty) {
                    return const Center(child: Text('No hay carteras guardadas.'));
                  }
                  return ListView.builder(
                    itemCount: data.carteras.length,
                    itemBuilder: (context, index) {
                      //int nFondos = carfoin.getMapIdCarteraNFondos[carteras[index].id] ?? 0;
                      ///int nFondos = carteras[index].fondos.length;
                      Cartera cart = data.carteras[index];
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
                        //onDismissed: (_) => _onDismissed(index),
                        onDismissed: (_) => _onDismissed(cart),
                        child: Card(
                          child: ListTile(
                            //leading: const Icon(Icons.business_center, size: 32),
                            //leading: Text('${carteras[index].id}'),
                            leading: Text('${cart.id}'),
                            title: Text(cart.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                // TODO: RECUPERAR DATOS REALES ??
                                Text('Inversión: 2.156,23 €'),
                                Text('Valor (12/04/2019): 4.5215,14 €'),
                                Text('Rendimiento: +2.345,32 €'),
                                Text('Rentabilidad: 10 %'),
                              ],
                            ),
                            //trailing: CircleAvatar(child: Text('$nFondos')),
                            trailing: CircleAvatar(child: Text('${cart.fondos.length}')),
                            onTap: () {
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              controlCenter.providerOnCartera(cart);
                              Navigator.of(context).pushNamed(RouteGenerator.carteraPage);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
        }
        return const LoadingProgress(titulo: 'Actualizando carteras...');
      },
    );
  }

  _onDismissed(Cartera cart) async {
    //final carteraProvider = context.read<CarteraProvider>();
    //carteraProvider.removeCartera(cart);
    await controlCenter.deleteDbCartera(cart);
    await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
  }

  Future<void> _carteraInput(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, TextEditingValue value, __) {
                  return SingleChildScrollView(
                    child: AlertDialog(
                      title: const Text('Nueva Cartera'),
                      content: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Nombre',
                          errorMaxLines: 4,
                          errorText: _errorText,
                        ),
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
                          onPressed: _controller.value.text.trim().isNotEmpty ? _submit : null,
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

  void _submit() async {
    if (_errorText == null) {
      final carteraProvider = context.read<CarteraProvider>();
      var input = _controller.value.text.trim();
      var existe = [for (var cartera in carteraProvider.carteras) cartera.name].contains(input);
      if (existe) {
        _controller.clear();
        _pop();
        _showMsg(msg: 'Ya existe una cartera con ese nombre.', color: Colors.red);
      } else {
        int id = await controlCenter.insertDbCartera(input);
        //await controlCenter.createTableCartera(id);
        await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
        _controller.clear();
        _pop();
      }
    }
  }

  void _deleteConfirm(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Eliminar todo'),
            content: const Text('Esto eliminará todas las carteras y sus fondos.'),
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
                  //final carteraProvider = context.read<CarteraProvider>();
                  //TODO: dialogo loading
                  /*for (var cartera in carteraProvider.carteras) {
                    await controlCenter.deleteDbCartera(cartera);
                  }*/
                  await controlCenter.deleteAllCarteras();
                  await controlCenter.updateCarteras(_isCarterasByOrder, _isFondosByOrder);
                  //carteraProvider.removeAllCarteras();
                  _pop();
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          );
        });
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
