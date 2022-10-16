import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'
    show SfPdfViewer, SfPdfViewerState, PdfDocumentLoadedDetails, PdfDocumentLoadFailedDetails;

import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/dialogs/custom_messenger.dart';
import '../widgets/dialogs/info_dialog.dart';
import 'file_util.dart';

class PdfViewer extends StatefulWidget {
  final String fileName;
  final String url;
  const PdfViewer({Key? key, required this.fileName, required this.url}) : super(key: key);

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
          color: AppColor.rojo900);
    } else if (resultSave.status == Status.abortado) {
      _showMsg(msg: 'Proceso abortado', color: AppColor.rojo900);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    return Container(
      decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          actions: [
            IconButton(
              onPressed: () async {
                if (pdfBytes.isEmpty || isDocumentLoaded == false) {
                  _showMsg(msg: 'Archivo no disponible', color: AppColor.rojo900);
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
      ),
    );
  }

  void _showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color).generateDialog();
}
