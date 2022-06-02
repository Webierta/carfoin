import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../routes.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/loading_progress.dart';
import '../widgets/my_drawer.dart';

enum Menu { renombrar, ordenar, exportar, eliminar }

class PageHome extends StatefulWidget {
  const PageHome({Key? key}) : super(key: key);
  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  bool _isCarterasByOrder = true;
  bool _isFondosByOrder = true;
  bool _isConfirmDeleteCartera = true;
  late TextEditingController _controller;
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;

  getSharedPrefs() async {
    bool? isCarterasByOrder;
    bool? isFondosByOrder;
    bool? isConfirmDeleteCartera;
    await PreferencesService.getBool(keyByOrderCarterasPref)
        .then((value) => isCarterasByOrder = value);
    await PreferencesService.getBool(keyByOrderFondosPref).then((value) => isFondosByOrder = value);
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref)
        .then((value) => isConfirmDeleteCartera = value);
    setState(() {
      _isCarterasByOrder = isCarterasByOrder ?? true;
      _isFondosByOrder = isFondosByOrder ?? true;
      _isConfirmDeleteCartera = isConfirmDeleteCartera ?? true;
    });
  }

  setCarteras() async {
    carteraProvider.carteras = await database.getCarteras(byOrder: _isCarterasByOrder);
    for (var cartera in carteraProvider.carteras) {
      await database.createTableCartera(cartera).whenComplete(() async {
        carteraProvider.fondos = await database.getFondos(cartera, byOrder: _isFondosByOrder);
        //carteraProvider.addFondos(cartera, carteraProvider.fondos);
        cartera.fondos = carteraProvider.fondos;
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

  final List<Icon> options = const [Icon(Icons.edit), Icon(Icons.delete_forever)];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: database.getCarteras(byOrder: _isCarterasByOrder),
      builder: (BuildContext context, AsyncSnapshot<List<Cartera>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
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
            drawer: const MyDrawer(),
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
                    Cartera cartera = data.carteras[index];
                    //List<Fondo> fondos = cartera.fondos ?? [];
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
                      onDismissed: (_) => _deleteCartera(cartera),
                      child: Card(
                        child: ListTile(
                          onTap: () {
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            carteraProvider.carteraSelect = cartera;
                            Navigator.of(context).pushNamed(RouteGenerator.carteraPage);
                          },
                          //leading: const Icon(Icons.business_center, size: 32),
                          //leading: Text('${carteras[index].id}'),
                          leading: Text('${cartera.id}'),
                          title: Text(cartera.name),
                          subtitle: Align(
                            alignment: Alignment.topLeft,
                            child: Chip(
                              padding: const EdgeInsets.only(left: 10, right: 20),
                              backgroundColor: const Color(0xFFFFC107),
                              avatar: const Icon(
                                Icons.poll,
                                color: Color(0xFF0D47A1),
                              ),
                              label: Text(
                                '${cartera.fondos?.length ?? 'Sin fondos'}',
                                style: const TextStyle(color: Color(0xFF0D47A1)),
                              ),
                            ),
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 1,
                                child: ListTile(
                                  leading: Icon(Icons.edit, color: Color(0xFF2196F3)),
                                  title: Text('Renombrar'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 2,
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever, color: Color(0xFF2196F3)),
                                  title: Text('Eliminar'),
                                ),
                              )
                            ],
                            onSelected: (value) {
                              if (value == 1) {
                                print('RENOMBRAR');
                              } else if (value == 2) {
                                _deleteCartera(cartera);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        } else {
          return const LoadingProgress(titulo: 'Actualizando carteras...');
        }
      },
    );
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
      resp ? _eliminar() : setState(() {});
    } else {
      _eliminar();
    }
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
      var input = _controller.value.text.trim();
      var existe = [for (var cartera in carteraProvider.carteras) cartera.name].contains(input);
      if (existe) {
        _controller.clear();
        _pop();
        _showMsg(msg: 'Ya existe una cartera con ese nombre.', color: Colors.red);
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
        context: context,
        builder: (BuildContext ctx) {
          String title =
              carteraName == null ? 'Eliminar todas las carteras' : 'Eliminar $carteraName';
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

  void _deleteConfirm(BuildContext context) async {
    var resp = await _dialogDeleteConfirm(context);
    if (resp) {
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
