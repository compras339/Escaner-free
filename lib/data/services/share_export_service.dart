import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import '../models/document_model.dart';

/// Servicio para compartir archivos mediante el Share Sheet nativo y exportar a Descargas/Galería local
class ShareExportService {
  /// Abre la hoja de compartir nativa de Android para enviar el PDF a otras aplicaciones
  Future<void> sharePdf({
    required String pdfPath,
    required String documentTitle,
    Rect? sharePositionOrigin,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('El archivo PDF no existe en el almacenamiento local.');
    }

    final xFile = XFile(
      pdfPath,
      mimeType: 'application/pdf',
      name: '$documentTitle.pdf',
    );

    await Share.shareXFiles(
      [xFile],
      text: 'Documento escaneado: $documentTitle',
      subject: documentTitle,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Comparte una lista de imágenes individuales (páginas)
  Future<void> shareImages({
    required List<String> imagePaths,
    String? title,
    Rect? sharePositionOrigin,
  }) async {
    final files = imagePaths
        .where((path) => File(path).existsSync())
        .map((path) => XFile(path, mimeType: 'image/jpeg'))
        .toList();

    if (files.isEmpty) {
      throw Exception('No hay imágenes válidas para compartir.');
    }

    await Share.shareXFiles(
      files,
      text: title != null ? 'Páginas escaneadas de $title' : 'Páginas escaneadas',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Exporta el archivo PDF a la carpeta de descargas pública del usuario
  Future<String> exportPdfToDownloads({
    required String sourcePdfPath,
    required String fileName,
  }) async {
    final source = File(sourcePdfPath);
    if (!await source.exists()) {
      throw Exception('El archivo PDF de origen no existe.');
    }

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      // Ruta estándar de Descargas en Android
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null) {
      throw Exception('No se pudo acceder a la carpeta de descargas del dispositivo.');
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final targetPath = p.join(downloadsDir.path, '$sanitizedName.pdf');
    final targetFile = File(targetPath);

    await source.copy(targetFile.path);
    return targetFile.path;
  }

  /// Envía el PDF al servicio de impresión local del sistema (Android Print Spooler)
  Future<void> printDocument({
    required String pdfPath,
    required String documentTitle,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw Exception('El archivo PDF no existe para impresión.');
    }

    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: documentTitle,
    );
  }
}
