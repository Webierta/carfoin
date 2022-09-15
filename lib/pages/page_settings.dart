import 'package:carfoin/models/logger.dart';
import 'package:carfoin/models/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/routes_const.dart';
import '../services/exchange_api.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../utils/styles.dart';
import '../widgets/my_drawer.dart';

enum ResultStatus { pendiente, nuevo, viejo, error }

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

  bool _isStorageLogger = false;
  bool _isAutoExchange = false;
  int _dateExchange = dateExchangeInit;
  double _rateExchange = rateExchangeInit;
  bool onSyncExchange = false;

  String pathLogger = '';

  getSharedPrefs() async {
    bool isCarterasByOrder = true;
    bool isViewDetalleCarteras = true;
    bool isConfirmDeleteCartera = true;
    bool isFondosByOrder = true;
    bool isConfirmDeleteFondo = true;
    bool isAutoUpdate = true;
    bool isConfirmDelete = true;

    bool isStorageLogger = false;
    bool isAutoExchange = false;
    int? dateExchange;
    double? rateExchange;

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

    await PreferencesService.getBool(keyAutoExchangePref)
        .then((value) => isAutoExchange = value);
    await PreferencesService.getDateExchange(keyDateExchange)
        .then((value) => dateExchange = value);
    await PreferencesService.getRateExchange(keyRateExchange)
        .then((value) => rateExchange = value);
    await PreferencesService.getBool(keyStorageLoggerPref)
        .then((value) => isStorageLogger = value);

    setState(() {
      _isCarterasByOrder = isCarterasByOrder;
      _isViewDetalleCarteras = isViewDetalleCarteras;
      _isConfirmDeleteCartera = isConfirmDeleteCartera;
      _isFondosByOrder = isFondosByOrder;
      _isConfirmDeleteFondo = isConfirmDeleteFondo;
      _isAutoUpdate = isAutoUpdate;
      _isConfirmDelete = isConfirmDelete;

      _isAutoExchange = isAutoExchange;
      _dateExchange = dateExchange ?? _dateExchange;
      _rateExchange = rateExchange ?? _rateExchange;
      _isStorageLogger = isStorageLogger;
    });
  }

  Future<String> getPathLogger() async {
    return await const Logger().localPath;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getSharedPrefs();
      pathLogger = await getPathLogger();
    });

    super.initState();
  }

  syncExchange() async {
    ResultStatus result = ResultStatus.pendiente;
    Rate? exchangeApi = await ExchangeApi().latestRate();
    if (exchangeApi != null) {
      if (_dateExchange >= exchangeApi.date) {
        result = ResultStatus.viejo;
      } else {
        result = ResultStatus.nuevo;
        setState(() {
          _dateExchange = exchangeApi.date;
          _rateExchange = exchangeApi.rate;
        });
        await PreferencesService.saveDateExchange(
            keyDateExchange, _dateExchange);
        await PreferencesService.saveRateExchange(
            keyRateExchange, _rateExchange);
      }
    } else {
      result = ResultStatus.error;
    }
    if (result == ResultStatus.nuevo) {
      _showMsg(msg: 'Cotización actualizada');
    } else if (result == ResultStatus.viejo) {
      _showMsg(msg: 'No se requiere actualización');
    } else if (result == ResultStatus.error) {
      _showMsg(msg: 'Servicio no disponible', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    var prefProvider = Provider.of<PreferencesProvider>(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: scaffoldGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('Ajustes'),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  context.go(homePage);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('GENERAL'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.currency_exchange, color: blue900),
                title: const Text('Cotización USD EUR'),
                subtitle: const Text('Pulsa para actualizar el tipo de cambio'),
                trailing: onSyncExchange
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () async {
                          setState(() => onSyncExchange = true);
                          await syncExchange();
                          setState(() => onSyncExchange = false);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: blue, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              FechaUtil.epochToString(_dateExchange),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Text(
                                NumberUtil.decimalFixed(_rateExchange,
                                    decimals: 3),
                                //style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.update, color: blue900),
                title: const Text('Actualización automática'),
                subtitle: const Text('El tipo de cambio se actualiza '
                    'cuando se inicia la aplicación si hace más de un '
                    'día desde la cotización almacenada'),
                trailing: Switch(
                  value: _isAutoExchange,
                  onChanged: (value) {
                    setState(() => _isAutoExchange = value);
                    PreferencesService.saveBool(
                        keyAutoExchangePref, _isAutoExchange);
                  },
                ),
              ),
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('CARTERAS'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.sort_by_alpha, color: blue900),
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
                leading: const Icon(Icons.view_stream, color: blue900),
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
                leading: const Icon(Icons.delete_forever, color: blue900),
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
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('FONDOS'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.sort_by_alpha, color: blue900),
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
                leading: const Icon(Icons.delete_forever, color: blue900),
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
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('VALORES'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.refresh, color: blue900),
                title: const Text('Actualizar último valor al añadir Fondo'),
                subtitle:
                    const Text('Recomendado para obtener la divisa del fondo'),
                trailing: Switch(
                  value: _isAutoUpdate,
                  onChanged: (value) {
                    setState(() => _isAutoUpdate = value);
                    PreferencesService.saveBool(
                        keyAutoUpdatePref, _isAutoUpdate);
                  },
                ),
              ),
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('OPERACIONES'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.delete_forever, color: blue900),
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
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('MANTENIMIENTO'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.memory, color: blue900),
                title: const Text('Limpiar caché'),
                subtitle: const Text('Pulsa para eliminar archivos de carteras '
                    'compartidas almacenadas en caché'),
                trailing: CircleAvatar(
                  child: IconButton(
                    icon: const Icon(Icons.cleaning_services),
                    onPressed: () async {
                      //await DefaultCacheManager().emptyCache();
                      var clearCache = await ShareCsv.clearCache();
                      if (clearCache) {
                        _showMsg(msg: 'Memoria caché liberada');
                      } else {
                        _showMsg(
                            msg: 'No ha sido posible liberar la memoria caché',
                            color: Colors.red);
                      }
                    },
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.bug_report, color: blue900),
                title: const Text('Activar Registro de errores'),
                subtitle: const Text(
                    'Registra posibles errores en un archicvo de texto. '
                    'No almacena ninguna información personal ni envía ningún dato'),
                // TODO: Switch storage true or false
                trailing: Switch(
                  value: _isStorageLogger,
                  //value: prefProvider.storage,
                  onChanged: (value) {
                    setState(() => _isStorageLogger = value);
                    PreferencesService.saveBool(
                        keyStorageLoggerPref, _isStorageLogger);
                    //context.read<PreferencesProvider>().storage = _isStorageLogger;
                    prefProvider.storage = _isStorageLogger;
                  },
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.description, color: blue900),
                title: const Text('Abrir Registro de errores'),
                subtitle: const Text('Pulsa para ver el contenido del archivo'),
                trailing: CircleAvatar(
                  child: IconButton(
                    icon: const Icon(Icons.find_in_page),
                    onPressed: () async {
                      await const Logger().read().then((value) {
                        Navigator.of(context)
                            .push(FullScreenModal(data: value));
                      });
                    },
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.send, color: blue900),
                title: const Text('Enviar Registro de errores'),
                subtitle: const Text(
                    'Copia el archivo logfile.txt en la carpeta de Descargas y '
                    'abre el sitio web donde adjuntar el archivo copiado'),
                trailing: CircleAvatar(
                  child: IconButton(
                    icon: const Icon(Icons.file_present),
                    onPressed: () async {
                      bool copy = await const Logger().copy();
                      if (copy == true) {
                        const String url =
                            'https://www.dropbox.com/request/TmdVW7RFPTyP5NQdhLmz';
                        if (!await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication)) {
                          Logger.log(
                            dataLog: DataLog(
                                msg: 'Could not launch $url',
                                file: 'page_settings',
                                clase: '_PageSettingsState',
                                funcion: 'build'),
                          );
                        }
                      } else {
                        _showMsg(
                          msg: 'El archivo logfile.txt no existe o está vacío',
                          color: Colors.red,
                        );
                      }
                    },
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.delete, color: blue900),
                title: const Text('Eliminar Archivo de Registro'),
                subtitle: const Text(
                    'Pulsa para eliminar el archivo logfile.txt del directorio '
                    'de la app (permanece en la carpeta Descargas si se ha enviado)'),
                trailing: CircleAvatar(
                  child: IconButton(
                    icon: const Icon(Icons.restore_page),
                    onPressed: () async {
                      if (await const Logger().clear()) {
                        _showMsg(msg: 'Archivo de registro eliminado');
                      } else {
                        _showMsg(
                          msg: 'Archivo no encontrado',
                          color: Colors.red,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMsg({required String msg, MaterialColor color = Colors.grey}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

class FullScreenModal extends ModalRoute {
  final String data;
  FullScreenModal({required this.data});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.8);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: blue900,
          foregroundColor: Colors.white,
          title: const Text('logfile.txt'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Text(
              data,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // add fade animation
    return FadeTransition(
      opacity: animation,
      // add slide animation
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation),
        // add scale animation
        child: ScaleTransition(
          scale: animation,
          child: child,
        ),
      ),
    );
  }
}
