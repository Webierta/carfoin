import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/preferences_service.dart';
import '../utils/konstantes.dart';
import '../widgets/my_drawer.dart';

class PageSettings extends StatefulWidget {
  const PageSettings({Key? key}) : super(key: key);
  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  bool _isCarterasByOrder = true;
  bool _isConfirmDeleteCartera = true;
  bool _isFondosByOrder = true;
  bool _isAutoUpdate = true;
  bool _isConfirmDelete = true;

  getSharedPrefs() async {
    await PreferencesService.getBool(keyByOrderCarterasPref).then((value) {
      setState(() => _isCarterasByOrder = value);
    });
    await PreferencesService.getBool(keyConfirmDeleteCarteraPref).then((value) {
      setState(() => _isConfirmDeleteCartera = value);
    });
    await PreferencesService.getBool(keyByOrderFondosPref).then((value) {
      setState(() => _isFondosByOrder = value);
    });
    await PreferencesService.getBool(keyAutoUpdatePref).then((value) {
      setState(() => _isAutoUpdate = value);
    });
    await PreferencesService.getBool(keyConfirmDeletePref).then((value) {
      setState(() => _isConfirmDelete = value);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSharedPrefs();
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
                Navigator.of(context).pushNamed(RouteGenerator.homePage);
              },
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          children: [
            const Text('CARTERAS'),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha, color: Color(0xFF0D47A1)),
              title: const Text('Carteras ordenadas por nombre'),
              trailing: Switch(
                value: _isCarterasByOrder,
                onChanged: (value) {
                  setState(() => _isCarterasByOrder = value);
                  PreferencesService.saveBool(keyByOrderCarterasPref, _isCarterasByOrder);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFF0D47A1)),
              title: const Text('Confirmar antes de eliminar una cartera y todos sus fondos'),
              subtitle:
                  const Text('La eliminación de todas las carteras siempre requiere confirmación'),
              trailing: Switch(
                value: _isConfirmDeleteCartera,
                onChanged: (value) {
                  setState(() => _isConfirmDeleteCartera = value);
                  PreferencesService.saveBool(keyConfirmDeleteCarteraPref, _isConfirmDeleteCartera);
                },
              ),
            ),
            const Divider(color: Color(0xFF9E9E9E), height: 30),
            const Text('FONDOS'),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha, color: Color(0xFF0D47A1)),
              title: const Text('Fondos ordenados por nombre'),
              subtitle: const Text('Por defecto se ordenan por fecha de creación o actualización'),
              trailing: Switch(
                value: _isFondosByOrder,
                onChanged: (value) {
                  setState(() => _isFondosByOrder = value);
                  PreferencesService.saveBool(keyByOrderFondosPref, _isFondosByOrder);
                },
              ),
            ),
            const Divider(color: Color(0xFF9E9E9E), height: 30),
            const Text('VALORES'),
            ListTile(
              leading: const Icon(Icons.sync, color: Color(0xFF0D47A1)),
              title: const Text('Actualizar último valor al añadir Fondo'),
              subtitle: const Text('Recomendado para obtener la divisa del fondo'),
              trailing: Switch(
                value: _isAutoUpdate,
                onChanged: (value) {
                  setState(() => _isAutoUpdate = value);
                  PreferencesService.saveBool(keyAutoUpdatePref, _isAutoUpdate);
                },
              ),
            ),
            const Divider(color: Color(0xFF9E9E9E), height: 30),
            const Text('OPERACIONES'),
            ListTile(
              leading: const Icon(Icons.check, color: Color(0xFF0D47A1)),
              title: const Text('Confirmar antes de eliminar operación'),
              trailing: Switch(
                value: _isConfirmDelete,
                onChanged: (value) {
                  setState(() => _isConfirmDelete = value);
                  PreferencesService.saveBool(keyConfirmDeletePref, _isConfirmDelete);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
