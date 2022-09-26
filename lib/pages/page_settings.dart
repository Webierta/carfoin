import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/logger.dart';
import '../models/preferences_provider.dart';
import '../router/routes_const.dart';
import '../services/exchange_api.dart';
import '../services/preferences_service.dart';
import '../services/share_csv.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../utils/styles.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/my_drawer.dart';

enum ResultStatus { pendiente, nuevo, viejo, error }

class PageSettings extends StatefulWidget {
  const PageSettings({Key? key}) : super(key: key);
  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  late PreferencesProvider prefProvider;
  bool onSyncExchange = false;
  String pathLogger = '';

  Future<String> getPathLogger() async {
    return await const Logger().localPath;
  }

  @override
  void initState() {
    prefProvider = context.read<PreferencesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      pathLogger = await getPathLogger();
    });
    super.initState();
  }

  syncExchange() async {
    ResultStatus result = ResultStatus.pendiente;
    Rate? exchangeApi = await ExchangeApi().latestRate();
    if (exchangeApi != null) {
      if (prefProvider.dateExchange >= exchangeApi.date) {
        result = ResultStatus.viejo;
      } else {
        result = ResultStatus.nuevo;
        /*setState(() {
          _dateExchange = exchangeApi.date;
          _rateExchange = exchangeApi.rate;
        });*/
        prefProvider.dateExchange = exchangeApi.date;
        prefProvider.rateExchange = exchangeApi.rate;
        await PreferencesService.saveDateExchange(
            keyDateExchange, exchangeApi.date);
        await PreferencesService.saveRateExchange(
            keyRateExchange, exchangeApi.rate);
      }
    } else {
      result = ResultStatus.error;
    }
    if (result == ResultStatus.nuevo) {
      _showMsg(msg: 'Cotización actualizada');
    } else if (result == ResultStatus.viejo) {
      _showMsg(msg: 'No se requiere actualización');
    } else if (result == ResultStatus.error) {
      _showMsg(msg: 'Servicio no disponible', color: red900);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  //ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
                              FechaUtil.epochToString(
                                  prefProvider.dateExchange),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Text(
                                NumberUtil.decimalFixed(
                                    prefProvider.rateExchange,
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
                  value: prefProvider.isAutoExchange,
                  onChanged: (value) {
                    setState(() => prefProvider.isAutoExchange = value);
                    PreferencesService.saveBool(keyAutoExchangePref, value);
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
                  value: prefProvider.isByOrderCarteras,
                  onChanged: (value) {
                    setState(() => prefProvider.isByOrderCarteras = value);
                    PreferencesService.saveBool(keyByOrderCarterasPref, value);
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
                  value: prefProvider.isViewDetalleCarteras,
                  onChanged: (value) {
                    setState(() => prefProvider.isViewDetalleCarteras = value);
                    PreferencesService.saveBool(keyViewCarterasPref, value);
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
                  value: prefProvider.isConfirmDeleteCartera,
                  onChanged: (value) {
                    setState(() => prefProvider.isConfirmDeleteCartera = value);
                    PreferencesService.saveBool(
                        keyConfirmDeleteCarteraPref, value);
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
                  value: prefProvider.isByOrderFondos,
                  onChanged: (value) {
                    setState(() => prefProvider.isByOrderFondos = value);
                    PreferencesService.saveBool(keyByOrderFondosPref, value);
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
                  value: prefProvider.isConfirmDeleteFondo,
                  onChanged: (value) {
                    setState(() => prefProvider.isConfirmDeleteFondo = value);
                    PreferencesService.saveBool(
                        keyConfirmDeleteFondoPref, value);
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
                subtitle: const Text(
                    'Recomendado para obtener la divisa y el rating del fondo'),
                trailing: Switch(
                  value: prefProvider.isAutoAudate,
                  onChanged: (value) {
                    setState(() => prefProvider.isAutoAudate = value);
                    PreferencesService.saveBool(keyAutoUpdatePref, value);
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
                  value: prefProvider.isConfirmDelete,
                  onChanged: (value) {
                    setState(() => prefProvider.isConfirmDelete = value);
                    PreferencesService.saveBool(keyConfirmDeletePref, value);
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
                          color: red900,
                        );
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
                  value: prefProvider.isStorageLogger,
                  onChanged: (value) {
                    setState(() => prefProvider.isStorageLogger = value);
                    PreferencesService.saveBool(keyStorageLoggerPref, value);
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
                          color: red900,
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
                        _showMsg(msg: 'Archivo no encontrado', color: red900);
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

  void _showMsg({required String msg, Color? color}) {
    CustomDialog customDialog = const CustomDialog();
    customDialog.generateDialog(context: context, msg: msg, color: color);
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
