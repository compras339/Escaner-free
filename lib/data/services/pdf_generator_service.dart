import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/document_model.dart';
import '../models/scanned_page_model.dart';

/// Servicio local para compilar páginas escaneadas en documentos PDF estándar
class PdfGeneratorService {
  /// Genera un archivo PDF unificado a partir de las páginas del documento
  Future<String> generatePdf({
    required DocumentModel document,
    required String targetPdfPath,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    return compute(_compilePdfIsolate, _PdfCompilationParams(
      pages: document.pages,
      documentTitle: document.title,
      targetPdfPath: targetPdfPath,
      pageFormat: pageFormat,
    ));
  }
}

class _PdfCompilationParams {
  final List<ScannedPageModel> pages;
  final String documentTitle;
  final String targetPdfPath;
  final PdfPageFormat pageFormat;

  _PdfCompilationParams({
    required this.pages,
    required this.documentTitle,
    required this.targetPdfPath,
    required this.pageFormat,
  });
}

Future<String> _compilePdfIsolate(_PdfCompilationParams params) async {
  if (params.pages.isEmpty) {
    throw Exception('El documento no contiene páginas para exportar.');
  }

  final pdf = pw.Document(
    title: params.documentTitle,
    author: 'Escáner Local Offline',
    creator: 'DocScanner Engine',
  );

  for (final page in params.pages) {
    final imageFile = File(page.processedImagePath);
    if (!await imageFile.exists()) {
      continue;
    }

    final imageBytes = await imageFile.readAsBytes();
    final pdfImage = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: params.pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  final outputFile = File(params.targetPdfPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(await pdf.save());

  return outputFile.path;
}
