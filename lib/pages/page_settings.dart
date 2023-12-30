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
import '../services/share_csv.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_pref.dart';
import '../themes/theme_provider.dart';
import '../utils/fecha_util.dart';
import '../utils/konstantes.dart';
import '../utils/number_util.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/full_screen_modal.dart';
import '../widgets/my_drawer.dart';

enum ResultStatus { pendiente, nuevo, viejo, error }

class PageSettings extends StatefulWidget {
  const PageSettings({super.key});
  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  late PreferencesProvider prefProvider;
  late ThemeProvider themeProvider;
  bool onSyncExchange = false;
  String pathLogger = '';

  Future<String> getPathLogger() async {
    return await const Logger().localPath;
  }

  @override
  void initState() {
    prefProvider = context.read<PreferencesProvider>();
    themeProvider = context.read<ThemeProvider>();
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
      _showMsg(msg: 'Servicio no disponible', color: AppColor.rojo900);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    final TextStyle? titleMediumBold = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold, wordSpacing: 0);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => false,
      child: Container(
        decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.brightness_4),
                title: Text('Tema Oscuro', style: titleMediumBold),
                trailing: Switch(
                  value: themeProvider.darkTheme,
                  onChanged: (value) async {
                    setState(() => themeProvider.darkTheme = value);
                    await ThemePref().setTheme(value);
                  },
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.currency_exchange),
                title: Text('Cotización USD EUR', style: titleMediumBold),
                subtitle: const Text('Actualizar el tipo de cambio'),
                trailing: onSyncExchange
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() => onSyncExchange = true);
                          await syncExchange();
                          setState(() => onSyncExchange = false);
                        },
                        style: ElevatedButton.styleFrom(
                          //backgroundColor: Colors.white,
                          shape: AppBox.roundBorder,
                          side: BorderSide(
                            width: 0.8,
                            color: darkTheme ? AppColor.blanco : AppColor.light,
                          ), // color: blue
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 4),
                          //shadowColor: Colors.grey,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              FechaUtil.epochToString(
                                  prefProvider.dateExchange),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: darkTheme
                                      ? AppColor.blanco
                                      : AppColor.light900),
                              //style: Theme.of(context).textTheme.bodySmall,
                            ),
                            FittedBox(
                                fit: BoxFit.fill,
                                child: Text(
                                  NumberUtil.decimalFixed(
                                      prefProvider.rateExchange,
                                      decimals: 3),
                                  style: TextStyle(
                                    color: darkTheme
                                        ? AppColor.ambar
                                        : AppColor.light,
                                  ),
                                )),
                          ],
                        ),
                      ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.update),
                title: Text('Actualización automática', style: titleMediumBold),
                subtitle: const Text(
                    'El tipo de cambio se actualiza si hace más de un día '
                    'desde la cotización almacenada'),
                trailing: Switch(
                  value: prefProvider.isAutoExchange,
                  onChanged: (value) {
                    setState(() => prefProvider.isAutoExchange = value);
                    PreferencesService.saveBool(keyAutoExchangePref, value);
                  },
                ),
              ),
              const Divider(
                  color: AppColor.gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('CARTERAS'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.sort_by_alpha),
                title: Text('Ordenadas por nombre', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.view_stream),
                title:
                    Text('Modo presentación: detalle', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.delete_forever),
                title: Text(
                    'Confirmar antes de eliminar una cartera y sus fondos',
                    style: titleMediumBold),
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
              const Divider(
                  color: AppColor.gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('FONDOS'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.sort_by_alpha),
                title: Text('Ordenados por nombre', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.view_stream),
                title:
                    Text('Modo presentación: detalle', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.delete_forever),
                title:
                    Text('Confirmar antes de eliminar', style: titleMediumBold),
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
              const Divider(
                  color: AppColor.gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('VALORES'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.refresh),
                title: Text('Actualizar último valor al añadir Fondo',
                    style: titleMediumBold),
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
              const Divider(
                  color: AppColor.gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('OPERACIONES'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.delete_forever),
                title:
                    Text('Confirmar antes de eliminar', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.remove_shopping_cart),
                title: Text('Eliminar operaciones asociadas',
                    style: titleMediumBold),
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
              const Divider(
                  color: AppColor.gris, height: 30, indent: 20, endIndent: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('MANTENIMIENTO'),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.memory),
                title: Text('Limpiar caché', style: titleMediumBold),
                subtitle: const Text('Eliminar archivos de carteras '
                    'compartidas almacenadas en caché'),
                trailing: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColor.blanco,
                  child: CircleAvatar(
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
                            color: AppColor.rojo900,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.bug_report),
                title:
                    Text('Activar registro de errores', style: titleMediumBold),
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
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.description),
                title:
                    Text('Abrir registro de errores', style: titleMediumBold),
                subtitle:
                    const Text('Muestra el contenido del archivo logfile.txt'),
                trailing: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColor.blanco,
                  child: CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.find_in_page),
                      onPressed: () async {
                        await const Logger().read().then((value) {
                          var data = Text(
                            value,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          );
                          Navigator.of(context).push(FullScreenModal(
                              title: 'logfile.txt', data: data));
                        });
                      },
                    ),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.send),
                title:
                    Text('Enviar registro de errores', style: titleMediumBold),
                subtitle:
                    const Text('Reportar el archivo logfile.txt al sistema '
                        'de incidencias de la aplicación'),
                trailing: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColor.blanco,
                  child: CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.file_present),
                      onPressed: () async => await _reportFileLogs(),
                    ),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                //horizontalTitleGap: 0,
                leading: const Icon(Icons.delete),
                title: Text('Eliminar registro de errores',
                    style: titleMediumBold),
                subtitle: const Text('Elimina el archivo logfile.txt'),
                trailing: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColor.blanco,
                  child: CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.restore_page),
                      onPressed: () async {
                        if (await const Logger().clear()) {
                          _showMsg(msg: 'Archivo eliminado');
                        } else {
                          _showMsg(
                              msg: 'Archivo no encontrado',
                              color: AppColor.rojo900);
                        }
                      },
                    ),
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
      _showMsg(msg: 'Sin registro de errores', color: AppColor.rojo900);
      return;
    }
    if (await _checkEnviado()) {
      _showMsg(
          msg: 'El registro de errores ya ha sido reportado',
          color: AppColor.rojo900);
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
      _showMsg(
          msg: 'Error al reportar el registro de errores',
          color: AppColor.rojo900);
    }
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}
