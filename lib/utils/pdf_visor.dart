//import 'dart:async';
import 'dart:io' show File, Directory;

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart' show PDFView;
import 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory;
import 'package:permission_handler/permission_handler.dart';

import '../models/logger.dart';
import '../widgets/custom_dialog.dart';
import 'styles.dart';

class PdfVisor extends StatefulWidget {
  final File file;
  final String url;
  final String isin;
  const PdfVisor(
      {Key? key, required this.file, required this.url, required this.isin})
      : super(key: key);
  @override
  State<PdfVisor> createState() => _PdfVisorState();
}

class _PdfVisorState extends State<PdfVisor> {
  @override
  Widget build(BuildContext context) {
    var indexStar = widget.file.path.lastIndexOf('/');
    var title = widget.file.path.substring(indexStar + 1);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () async {
              await saveFile(widget.url, title).then((value) {
                _showMsg(msg: 'Archivo guardado en Doc_Carfoin');
                /*ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Archivo guardado en Doc_Carfoin')));*/
              }).onError((e, s) {
                Logger.log(
                  dataLog: DataLog(
                    msg: 'onError saveFile',
                    file: 'pdf_visor.dart',
                    clase: '_PdfVisorState',
                    funcion: 'build',
                    error: e,
                    stackTrace: s,
                  ),
                );
                _showMsg(msg: 'Error al guardar el archivo', color: red900);
                /*ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Error al guardar el archivo'),
                  backgroundColor: Colors.red,
                ));*/
              });
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.file.path,
        onError: (error) {
          Logger.log(
            dataLog: DataLog(
              msg: 'onError PDFView',
              file: 'pdf_visor.dart',
              clase: '_PdfVisorState',
              funcion: 'build',
              error: error,
            ),
          );
        },
      ),
    );
  }

  Future<bool> saveFile(String url, String fileName) async {
    try {
      if (await _requestPermission(Permission.storage)) {
        Directory? directory;
        directory = await getExternalStorageDirectory();
        String newPath = '';
        List<String> paths = directory!.path.split('/');
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != 'Android') {
            newPath += '/$folder';
          } else {
            break;
          }
        }
        newPath = '$newPath/Doc_Carfoin';
        directory = Directory(newPath);
        File saveFile = File('${directory.path}/$fileName');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        if (await directory.exists()) {
          try {
            await widget.file.copy(saveFile.path);
          } catch (e, s) {
            Logger.log(
              dataLog: DataLog(
                msg: 'Catch file copy',
                file: 'pdf_visor.dart',
                clase: '_PdfVisorState',
                funcion: 'saveFile',
                error: e,
                stackTrace: s,
              ),
            );
            return false;
          }
        }
      } else {
        Logger.log(
          dataLog: DataLog(
            msg: 'No permiso storage',
            file: 'pdf_visor.dart',
            clase: '_PdfVisorState',
            funcion: 'saveFile',
          ),
        );
        return false;
      }
    } catch (e, s) {
      Logger.log(
        dataLog: DataLog(
          msg: 'Catch saveFile',
          file: 'pdf_visor.dart',
          clase: '_PdfVisorState',
          funcion: 'saveFile',
          error: e,
          stackTrace: s,
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  void _showMsg({required String msg, Color? color}) {
    CustomDialog customDialog = const CustomDialog();
    customDialog.generateDialog(context: context, msg: msg, color: color);
  }
}
