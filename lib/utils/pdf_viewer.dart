import 'dart:io' show File, Directory;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'
    show
        SfPdfViewer,
        SfPdfViewerState,
        PdfDocumentLoadedDetails,
        PdfDocumentLoadFailedDetails;

import '../models/logger.dart';
import '../widgets/dialogs/custom_messenger.dart';
import 'styles.dart';

class PdfViewer extends StatefulWidget {
  final String fileName;
  final String url;
  const PdfViewer({Key? key, required this.fileName, required this.url})
      : super(key: key);

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  List<int> pdfBytes = [];

  void showErrorDialog(BuildContext context, String error, String description) {
    showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(error),
            content: Text(description),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        });
  }

  Future<bool> saveFile() async {
    try {
      if (await _requestPermission(Permission.storage)) {
        Directory? directory = await getExternalStorageDirectory();
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
        Directory? folderCarfoin;
        if (newPath.isNotEmpty) {
          folderCarfoin = Directory('$newPath/Doc_Carfoin');
        }
        if (folderCarfoin == null || pdfBytes.isEmpty) {
          throw Exception();
        }
        if (!await folderCarfoin.exists()) {
          await folderCarfoin.create(recursive: true);
        }
        if (await folderCarfoin.exists() && pdfBytes.isNotEmpty) {
          try {
            await File('${folderCarfoin.path}/${widget.fileName}')
                .writeAsBytes(pdfBytes)
                .then((value) => true)
                .onError((e, s) => throw Exception());
          } catch (e, s) {
            Logger.log(
                dataLog: DataLog(
                    msg: 'Catch file write',
                    file: 'pdf_viewer.dart',
                    clase: '_PdfVisorState',
                    funcion: 'saveFile',
                    error: e,
                    stackTrace: s));
          }
        } else {
          throw Exception();
        }
      } else {
        Logger.log(
            dataLog: DataLog(
                msg: 'No permiso storage',
                file: 'pdf_viewer.dart',
                clase: '_PdfViewerState',
                funcion: 'saveFile'));
      }
    } catch (e, s) {
      Logger.log(
          dataLog: DataLog(
              msg: 'Catch saveFile',
              file: 'pdf_viewer.dart',
              clase: '_PdfViewerState',
              funcion: 'saveFile',
              error: e,
              stackTrace: s));
    }
    return false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            onPressed: () async {
              await saveFile()
                  .then((value) =>
                      _showMsg(msg: 'Archivo guardado en Doc_Carfoin'))
                  .onError((e, s) {
                Logger.log(
                    dataLog: DataLog(
                        msg: 'onError saveFile',
                        file: 'pdf_viewer.dart',
                        clase: '_PdfViewerState',
                        funcion: 'build',
                        error: e,
                        stackTrace: s));
                _showMsg(msg: 'Error al guardar el archivo', color: red900);
              });
            },
            icon: const Icon(Icons.download),
          )
        ],
      ),
      body: SfPdfViewer.network(
        widget.url,
        key: _pdfViewerKey,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) async {
          //PdfDocument pdf = details.document;
          pdfBytes = await details.document.save();
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          showErrorDialog(context, details.error, details.description);
        },
      ),
    );
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}
