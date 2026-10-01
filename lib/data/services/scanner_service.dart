import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Servicio para orquestar el escaneo inteligente usando la API On-Device de ML Kit
class ScannerService {
  /// Ejecuta el escáner de documentos inteligente local de Google ML Kit
  /// Incluye detección automática de bordes, corrección de perspectiva y eliminación de sombras
  Future<List<String>> startMlKitScanner({int pageLimit = 50}) async {
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: pageLimit,
        isGalleryImportAllowed: true,
      );

      final documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await documentScanner.scanDocument();

      await documentScanner.close();

      final List<String> images = result.images ?? [];
      return images;
    } catch (e) {
      debugPrint('Error o cancelación en ML Kit Document Scanner: $e');
      return [];
    }
  }
}
