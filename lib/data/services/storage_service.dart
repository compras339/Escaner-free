import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/document_model.dart';

/// Servicio de persistencia local y gestión de almacenamiento interno (Scoped Storage)
class StorageService {
  static const String _documentsBoxName = 'scanned_documents_box';
  Box<Map>? _box;

  /// Inicializa Hive y los directorios locales requeridos
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_documentsBoxName);

    // Asegurar estructura de carpetas internas
    await getImagesDirectory();
    await getPdfsDirectory();
  }

  /// Retorna el directorio raíz interno de la aplicación
  Future<Directory> getAppRootDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Carpeta interna privada para imágenes escaneadas
  Future<Directory> getImagesDirectory() async {
    final root = await getAppRootDirectory();
    final dir = Directory(p.join(root.path, 'scanned_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Carpeta interna privada para archivos PDF generados
  Future<Directory> getPdfsDirectory() async {
    final root = await getAppRootDirectory();
    final dir = Directory(p.join(root.path, 'generated_pdfs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Genera una ruta única para una nueva página de imagen
  Future<String> createPageImagePath(String docId, String pageId, {bool isProcessed = false}) async {
    final imagesDir = await getImagesDirectory();
    final suffix = isProcessed ? 'proc' : 'orig';
    return p.join(imagesDir.path, '${docId}_${pageId}_$suffix.jpg');
  }

  /// Genera la ruta para el PDF de un documento
  Future<String> createPdfPath(String docId, String title) async {
    final pdfDir = await getPdfsDirectory();
    // Limpiar caracteres no válidos para nombres de archivo
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final fileName = sanitizedTitle.isEmpty ? 'doc_$docId.pdf' : '$sanitizedTitle.pdf';
    return p.join(pdfDir.path, fileName);
  }

  /// Guarda o actualiza un documento en la base de datos local Hive
  Future<void> saveDocument(DocumentModel document) async {
    final box = _box ?? await Hive.openBox<Map>(_documentsBoxName);
    await box.put(document.id, document.toJson());
  }

  /// Obtiene todos los documentos almacenados ordenados por fecha descendente
  Future<List<DocumentModel>> getAllDocuments() async {
    final box = _box ?? await Hive.openBox<Map>(_documentsBoxName);
    final List<DocumentModel> docs = [];

    for (final key in box.keys) {
      final rawData = box.get(key);
      if (rawData != null) {
        try {
          final doc = DocumentModel.fromJson(Map<String, dynamic>.from(rawData));
          docs.add(doc);
        } catch (e) {
          // Ignorar o registrar error de deserialización
        }
      }
    }

    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  /// Obtiene un documento por su ID
  Future<DocumentModel?> getDocumentById(String id) async {
    final box = _box ?? await Hive.openBox<Map>(_documentsBoxName);
    final rawData = box.get(id);
    if (rawData == null) return null;
    return DocumentModel.fromJson(Map<String, dynamic>.from(rawData));
  }

  /// Elimina un documento y limpia físicamente todos sus archivos de imagen y PDF asociados
  Future<void> deleteDocument(String id) async {
    final doc = await getDocumentById(id);
    if (doc != null) {
      // Eliminar páginas del sistema de archivos
      for (final page in doc.pages) {
        final orig = File(page.originalImagePath);
        if (await orig.exists()) {
          try { await orig.delete(); } catch (_) {}
        }
        final proc = File(page.processedImagePath);
        if (await proc.exists()) {
          try { await proc.delete(); } catch (_) {}
        }
      }

      // Eliminar PDF si existe
      if (doc.pdfPath != null) {
        final pdfFile = File(doc.pdfPath!);
        if (await pdfFile.exists()) {
          try { await pdfFile.delete(); } catch (_) {}
        }
      }
    }

    final box = _box ?? await Hive.openBox<Map>(_documentsBoxName);
    await box.delete(id);
  }
}
