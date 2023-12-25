import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../services/doc_cnmv.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/loading_progress.dart';

enum PdfDoc { folleto, informe }

class FondoDoc {
  final Fondo fondo;
  final PdfDoc pdfDoc;
  const FondoDoc({required this.fondo, required this.pdfDoc});
}

class PagePdf extends StatefulWidget {
  final FondoDoc fondoDoc;
  const PagePdf({super.key, required this.fondoDoc});

  @override
  State<PagePdf> createState() => _PagePdfState();
}

class _PagePdfState extends State<PagePdf> {
  bool showPdf = true;

  Future<Uint8List?>? getPdfContent() async {
    var docCnmv = DocCnmv(isin: widget.fondoDoc.fondo.isin);
    String? urlPdf;
    if (widget.fondoDoc.pdfDoc == PdfDoc.folleto) {
      urlPdf = await docCnmv.getUrlFolleto();
    } else {
      urlPdf = await docCnmv.getUrlInforme();
    }
    if (urlPdf != null) {
      try {
        http.Response response = await http.get(Uri.parse(urlPdf));
        return response.bodyBytes;
      } catch (e) {
        setState(() => showPdf = false);
        return null;
      }
    } else {
      setState(() => showPdf = false);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => false,
      //onPopInvoked: ((didPop) => context.pop(true)),
      child: Container(
        decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  //context.go(fondoPage);
                  context.pop(showPdf);
                }),
            title: const Text('PDF'),
          ),
          body: showPdf == false
              ? const Center(
                  child: Text('Archivo no encontrado'),
                )
              : FutureBuilder<Uint8List?>(
                  future: getPdfContent(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        width: double.infinity,
                        //aspectRatio: 0.71,
                        child: PdfPreview(
                          allowPrinting: true,
                          allowSharing: true,
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          //dpi: 200,
                          build: (format) => snapshot.data!,
                          onError: (context, error) {
                            showPdf = false;
                            return const Text(
                                'file not in PDF format or corrupted');
                          },
                        ),
                      );
                    }
                    return const SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: LoadingProgress(titulo: 'Cargando documento...'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
