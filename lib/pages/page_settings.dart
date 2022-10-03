import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry/sentry_io.dart';

import '../models/logger.dart';
import '../models/preferences_provider.dart';
import '../router/routes_const.dart';
import '../services/exchange_api.dart';
import '../services/preferences_service.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../utils/styles.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/full_screen_modal.dart';
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
                onPressed: () => context.go(homePage),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          side: const BorderSide(color: blue, width: 2),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          shadowColor: Colors.grey,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              FechaUtil.epochToString(
                                  prefProvider.dateExchange),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black),
                            ),
                            FittedBox(
                                fit: BoxFit.fill,
                                child: Text(
                                  NumberUtil.decimalFixed(
                                      prefProvider.rateExchange,
                                      decimals: 3),
                                )),
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
                leading: const Icon(Icons.view_stream, color: blue900),
                title: const Text('Modo presentación: detalle'),
                subtitle: const Text('En caso contrario, vista compacta'),
                trailing: Switch(
                  value: prefProvider.isViewDetalleFondos,
                  onChanged: (value) {
                    setState(() => prefProvider.isViewDetalleFondos = value);
                    PreferencesService.saveBool(keyViewCarterasPref, value);
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
                subtitle: const Text('Eliminar operaciones de suscripción '
                    'siempre requiere confirmación y conlleva la eliminación de '
                    'todos los reembolsos posteriores'),
                trailing: Switch(
                  value: prefProvider.isConfirmDelete,
                  onChanged: (value) {
                    setState(() => prefProvider.isConfirmDelete = value);
                    PreferencesService.saveBool(keyConfirmDeletePref, value);
                  },
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.remove_shopping_cart, color: blue900),
                title: const Text('Eliminar operaciones asociadas'),
                subtitle: const Text('Cuando se eliminan valores en bloque, '
                    'eliminar también sus operaciones asociadas'),
                trailing: Switch(
                  value: prefProvider.isDeleteOperaciones,
                  onChanged: (value) {
                    setState(() => prefProvider.isDeleteOperaciones = value);
                    PreferencesService.saveBool(keyDeleteOperaciones, value);
                  },
                ),
              ),
              const Divider(color: gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('MANTENIMIENTO'),
              ),
              /*ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.memory, color: blue900),
                title: const Text('Limpiar caché'),
                subtitle: const Text('Pulsa para eliminar archivos de carteras '
                    'compartidas almacenadas en caché'),
                trailing: CircleAvatar(
                  backgroundColor: blue,
                  child: IconButton(
                    icon: const Icon(Icons.cleaning_services,
                        color: Colors.white),
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
              ),*/
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.bug_report, color: blue900),
                title: const Text('Activar Registro de errores'),
                subtitle: const Text(
                    'Registra posibles errores en un archicvo de texto. '
                    'No almacena ninguna información personal ni envía ningún dato'),
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
                subtitle: const Text(
                    'Pulsa para ver el contenido del archivo logfile.txt'),
                trailing: CircleAvatar(
                  backgroundColor: blue,
                  child: IconButton(
                    icon: const Icon(Icons.find_in_page, color: Colors.white),
                    onPressed: () async {
                      await const Logger().read().then((value) {
                        var data = Text(value,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14));
                        Navigator.of(context).push(
                            FullScreenModal(title: 'logfile.txt', data: data));
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
                subtitle: const Text('Pulsa para reportar el archivo '
                    'logfile.txt al sistema de incidencias de la aplicación'),
                trailing: CircleAvatar(
                  backgroundColor: blue,
                  child: IconButton(
                    icon: const Icon(Icons.file_present, color: Colors.white),
                    onPressed: () async => await _reportFileLogs(),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.delete, color: blue900),
                title: const Text('Eliminar Errores registrados'),
                subtitle:
                    const Text('Pulsa para eliminar el archivo logfile.txt'),
                trailing: CircleAvatar(
                  backgroundColor: blue,
                  child: IconButton(
                    icon: const Icon(Icons.restore_page, color: Colors.white),
                    onPressed: () async {
                      if (await const Logger().clear()) {
                        _showMsg(msg: 'Archivo eliminado');
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

  Future<bool> _checkEnviado() async {
    String textFile = await const Logger().read();
    if (textFile.isNotEmpty && textFile[textFile.length - 1] == '*') {
      return true;
    } else {
      return false;
    }
  }

  _reportFileLogs() async {
    File file = await const Logger().localFile;
    if (!await file.exists()) {
      _showMsg(msg: 'Sin registro de errores', color: red900);
      return;
    }
    if (await _checkEnviado()) {
      _showMsg(
        msg: 'El registro de errores ya ha sido reportado',
        color: red900,
      );
      return;
    }

    const String dsn =
        'https://9388fe715b9e4ce0bf7b41fd3e040eb7@o4503907179233280.ingest.sentry.io/4503907197517824';
    int epochLog = FechaUtil.dateToEpoch(DateTime.now());
    await Sentry.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 1.0;
        options.maxAttachmentSize = 5 * 1024 * 1024;
      },
    );
    try {
      await Sentry.captureMessage('$epochLog', withScope: (scope) {
        scope.transaction = 'Carfoin $kVersion';
        scope.addAttachment(IoSentryAttachment.fromFile(file));
      }).then((value) async {
        _showMsg(msg: 'Gracias por ayudar a mejorar la App');
        const Logger().write('\n*');
      }).onError((error, stackTrace) {
        throw Exception;
      }).whenComplete(() async {
        await Sentry.close();
      });
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch Sentry Capture Message',
              file: 'page_settings',
              clase: '_PageSettingsState',
              funcion: '_reportFileLogs',
              error: e,
              stackTrace: s));
      _showMsg(msg: 'Error al reportar el registro de errores', color: red900);
    }
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}
