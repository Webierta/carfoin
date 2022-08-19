import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes_const.dart';
import '../services/preferences_service.dart';
import '../widgets/my_drawer.dart';

class PageSettings extends StatefulWidget {
  const PageSettings({Key? key}) : super(key: key);
  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  bool _isCarterasByOrder = true;
  bool _isViewDetalleCarteras = true;
  bool _isConfirmDeleteCartera = true;
  bool _isFondosByOrder = true;
  bool _isConfirmDeleteFondo = true;
  bool _isAutoUpdate = true;
  bool _isConfirmDelete = true;

  getSharedPrefs() async {
    bool isCarterasByOrder = true;
    bool isViewDetalleCarteras = true;
    bool isConfirmDeleteCartera = true;
    bool isFondosByOrder = true;
    bool isConfirmDeleteFondo = true;
    bool isAutoUpdate = true;
    bool isConfirmDelete = true;

    await PreferencesService.getBool(keyByOrderCarterasPref)
        .then((value) => isCarterasByOrder = value);
    await PreferencesService.getBool(keyViewCarterasPref)
        .then((value) => isViewDetalleCarteras = value);
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref)
        .then((value) => isConfirmDeleteCartera = value);
    await PreferencesService.getBool(keyByOrderFondosPref)
        .then((value) => isFondosByOrder = value);
    await PreferencesService.getBool(keyConfirmDeleteFondoPref)
        .then((value) => isConfirmDeleteFondo = value);
    await PreferencesService.getBool(keyAutoUpdatePref)
        .then((value) => isAutoUpdate = value);
    await PreferencesService.getBool(keyConfirmDeletePref)
        .then((value) => isConfirmDelete = value);
    setState(() {
      _isCarterasByOrder = isCarterasByOrder;
      _isViewDetalleCarteras = isViewDetalleCarteras;
      _isConfirmDeleteCartera = isConfirmDeleteCartera;
      _isFondosByOrder = isFondosByOrder;
      _isConfirmDeleteFondo = isConfirmDeleteFondo;
      _isAutoUpdate = isAutoUpdate;
      _isConfirmDelete = isConfirmDelete;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getSharedPrefs();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajustes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                //Navigator.of(context).pushNamed(RouteGenerator.homePage);
                context.go(homePage);
              },
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text('CARTERAS'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.sort_by_alpha, color: Color(0xFF2196F3)),
              title: const Text('Ordenadas por nombre'),
              trailing: Switch(
                value: _isCarterasByOrder,
                onChanged: (value) {
                  setState(() => _isCarterasByOrder = value);
                  PreferencesService.saveBool(
                      keyByOrderCarterasPref, _isCarterasByOrder);
                },
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.view_stream, color: Color(0xFF2196F3)),
              title: const Text('Modo presentación: detalle'),
              subtitle: const Text('En caso contrario, vista compacta'),
              trailing: Switch(
                value: _isViewDetalleCarteras,
                onChanged: (value) {
                  setState(() => _isViewDetalleCarteras = value);
                  PreferencesService.saveBool(
                      keyViewCarterasPref, _isViewDetalleCarteras);
                },
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.delete_forever, color: Color(0xFF2196F3)),
              title: const Text(
                  'Confirmar antes de eliminar una cartera y sus fondos'),
              subtitle: const Text(
                  'Eliminar todas las carteras siempre requiere confirmación'),
              trailing: Switch(
                value: _isConfirmDeleteCartera,
                onChanged: (value) {
                  setState(() => _isConfirmDeleteCartera = value);
                  PreferencesService.saveBool(
                      keyConfirmDeleteCarteraPref, _isConfirmDeleteCartera);
                },
              ),
            ),
            const Divider(
                color: Color(0xFF9E9E9E),
                height: 30,
                indent: 20,
                endIndent: 20),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text('FONDOS'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.sort_by_alpha, color: Color(0xFF2196F3)),
              title: const Text('Ordenados por nombre'),
              subtitle: const Text(
                  'En caso contrario por fecha de creación o actualización'),
              trailing: Switch(
                value: _isFondosByOrder,
                onChanged: (value) {
                  setState(() => _isFondosByOrder = value);
                  PreferencesService.saveBool(
                      keyByOrderFondosPref, _isFondosByOrder);
                },
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.delete_forever, color: Color(0xFF2196F3)),
              title: const Text('Confirmar antes de eliminar'),
              subtitle: const Text('Eliminar todos los fondos de una cartera '
                  'siempre requiere confirmación'),
              trailing: Switch(
                value: _isConfirmDeleteFondo,
                onChanged: (value) {
                  setState(() => _isConfirmDeleteFondo = value);
                  PreferencesService.saveBool(
                      keyConfirmDeleteFondoPref, _isConfirmDeleteFondo);
                },
              ),
            ),
            const Divider(
                color: Color(0xFF9E9E9E),
                height: 30,
                indent: 20,
                endIndent: 20),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text('VALORES'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.sync, color: Color(0xFF2196F3)),
              title: const Text('Actualizar último valor al añadir Fondo'),
              subtitle:
                  const Text('Recomendado para obtener la divisa del fondo'),
              trailing: Switch(
                value: _isAutoUpdate,
                onChanged: (value) {
                  setState(() => _isAutoUpdate = value);
                  PreferencesService.saveBool(keyAutoUpdatePref, _isAutoUpdate);
                },
              ),
            ),
            const Divider(
                color: Color(0xFF9E9E9E),
                height: 30,
                indent: 20,
                endIndent: 20),
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text('OPERACIONES'),
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.delete_forever, color: Color(0xFF2196F3)),
              title: const Text('Confirmar antes de eliminar'),
              subtitle: const Text(
                  'Eliminar operaciones de suscripción siempre requiere confirmación '
                  'y conlleva la eliminación de todas las operaciones posteriores'),
              trailing: Switch(
                value: _isConfirmDelete,
                onChanged: (value) {
                  setState(() => _isConfirmDelete = value);
                  PreferencesService.saveBool(
                      keyConfirmDeletePref, _isConfirmDelete);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
