import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'
    show
        SfPdfViewer,
        SfPdfViewerState,
        PdfDocumentLoadedDetails,
        PdfDocumentLoadFailedDetails;

import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/info_dialog.dart';
import 'file_util.dart';
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
  bool isDocumentLoaded = false;

  Future<void> saveFile() async {
    //if (pdfBytes.isEmpty || isDocumentLoaded == false) return;
    var resultSave = await FileUtil.savePdf(widget.fileName, pdfBytes);
    if (resultSave.status == Status.ok) {
      _showMsg(msg: 'Archivo guardado en ${resultSave.msg}');
    } else if (resultSave.status == Status.error) {
      _showMsg(
          msg: 'Error al guardar el archivo. Inténtalo en el '
              'almacenamiento interno de tu dispositivo',
          color: red900);
    } else if (resultSave.status == Status.abortado) {
      _showMsg(msg: 'Proceso abortado', color: red900);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            onPressed: () async {
              if (pdfBytes.isEmpty || isDocumentLoaded == false) {
                _showMsg(msg: 'Archivo no disponible', color: red900);
              } else {
                await saveFile();
              }
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
          setState(() => isDocumentLoaded = true);
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) async {
          await InfoDialog(
            context: context,
            title: details.error,
            content: Text(details.description),
          ).generateDialog();
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}
