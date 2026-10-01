import 'dart:io';
import 'dart:ui' show Offset;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/filter_type.dart';
import '../models/scanned_page_model.dart';
import '../services/image_processor_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/storage_service.dart';

/// Repositorio principal que centraliza la lógica de negocio y persistencia de documentos
class DocumentRepository {
  final StorageService _storageService;
  final ImageProcessorService _imageProcessorService;
  final PdfGeneratorService _pdfGeneratorService;
  final Uuid _uuid = const Uuid();

  DocumentRepository({
    required StorageService storageService,
    required ImageProcessorService imageProcessorService,
    required PdfGeneratorService pdfGeneratorService,
  })  : _storageService = storageService,
        _imageProcessorService = imageProcessorService,
        _pdfGeneratorService = pdfGeneratorService;

  Future<List<DocumentModel>> getDocuments() async {
    return await _storageService.getAllDocuments();
  }

  Future<DocumentModel?> getDocument(String id) async {
    return await _storageService.getDocumentById(id);
  }

  /// Crea un nuevo documento importando una lista de rutas de imágenes originales capturadas
  Future<DocumentModel> createDocumentFromRawImages({
    required List<String> rawImagePaths,
    String? title,
  }) async {
    final docId = _uuid.v4();
    final now = DateTime.now();
    final defaultTitle = title ?? 'Doc_${DateFormat('yyyyMMdd_HHmm').format(now)}';

    final List<ScannedPageModel> pages = [];

    for (int i = 0; i < rawImagePaths.length; i++) {
      final rawPath = rawImagePaths[i];
      final pageId = _uuid.v4();

      final origDestPath = await _storageService.createPageImagePath(docId, pageId, isProcessed: false);
      final procDestPath = await _storageService.createPageImagePath(docId, pageId, isProcessed: true);

      // Copiar archivo original al almacenamiento seguro interno de la app
      await File(rawPath).copy(origDestPath);

      // Copia inicial procesada (filtro original sin rotación)
      await File(origDestPath).copy(procDestPath);

      pages.add(ScannedPageModel(
        id: pageId,
        originalImagePath: origDestPath,
        processedImagePath: procDestPath,
        filter: FilterType.original,
        rotationAngle: 0,
        pageNumber: i + 1,
        createdAt: now,
      ));
    }

    final newDoc = DocumentModel(
      id: docId,
      title: defaultTitle,
      createdAt: now,
      updatedAt: now,
      pages: pages,
    );

    await _storageService.saveDocument(newDoc);
    return newDoc;
  }

  /// Agrega páginas adicionales a un documento ya existente
  Future<DocumentModel> addPagesToDocument({
    required String documentId,
    required List<String> rawImagePaths,
  }) async {
    final existingDoc = await _storageService.getDocumentById(documentId);
    if (existingDoc == null) {
      throw Exception('El documento no fue encontrado.');
    }

    final now = DateTime.now();
    final updatedPages = List<ScannedPageModel>.from(existingDoc.pages);

    for (int i = 0; i < rawImagePaths.length; i++) {
      final rawPath = rawImagePaths[i];
      final pageId = _uuid.v4();

      final origDestPath = await _storageService.createPageImagePath(documentId, pageId, isProcessed: false);
      final procDestPath = await _storageService.createPageImagePath(documentId, pageId, isProcessed: true);

      await File(rawPath).copy(origDestPath);
      await File(origDestPath).copy(procDestPath);

      updatedPages.add(ScannedPageModel(
        id: pageId,
        originalImagePath: origDestPath,
        processedImagePath: procDestPath,
        filter: FilterType.original,
        rotationAngle: 0,
        pageNumber: updatedPages.length + 1,
        createdAt: now,
      ));
    }

    final updatedDoc = existingDoc.copyWith(
      pages: updatedPages,
      updatedAt: now,
      pdfPath: null, // Invalidar PDF anterior al agregar nuevas páginas
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Aplica un filtro de imagen a una página específica
  Future<DocumentModel> updatePageFilter({
    required String documentId,
    required String pageId,
    required FilterType newFilter,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final pageIndex = doc.pages.indexWhere((p) => p.id == pageId);
    if (pageIndex == -1) throw Exception('Página no encontrada.');

    final page = doc.pages[pageIndex];

    // Procesar la imagen desde la versión original con la rotación y filtro actualizados
    await _imageProcessorService.processImage(
      inputPath: page.originalImagePath,
      outputPath: page.processedImagePath,
      filter: newFilter,
      rotationDegrees: page.rotationAngle,
    );

    final updatedPage = page.copyWith(filter: newFilter);
    final updatedPages = List<ScannedPageModel>.from(doc.pages);
    updatedPages[pageIndex] = updatedPage;

    final updatedDoc = doc.copyWith(
      pages: updatedPages,
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Rota una página 90 grados a la derecha
  Future<DocumentModel> rotatePage({
    required String documentId,
    required String pageId,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final pageIndex = doc.pages.indexWhere((p) => p.id == pageId);
    if (pageIndex == -1) throw Exception('Página no encontrada.');

    final page = doc.pages[pageIndex];
    final newAngle = (page.rotationAngle + 90) % 360;

    await _imageProcessorService.processImage(
      inputPath: page.originalImagePath,
      outputPath: page.processedImagePath,
      filter: page.filter,
      rotationDegrees: newAngle,
    );

    final updatedPage = page.copyWith(rotationAngle: newAngle);
    final updatedPages = List<ScannedPageModel>.from(doc.pages);
    updatedPages[pageIndex] = updatedPage;

    final updatedDoc = doc.copyWith(
      pages: updatedPages,
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Recorta una página a partir de los puntos poligonales de esquina seleccionados
  Future<DocumentModel> cropPage({
    required String documentId,
    required String pageId,
    required List<Offset> corners,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final pageIndex = doc.pages.indexWhere((p) => p.id == pageId);
    if (pageIndex == -1) throw Exception('Página no encontrada.');

    final page = doc.pages[pageIndex];

    // Aplicar recorte sobre la imagen original
    await _imageProcessorService.cropPerspective(
      inputPath: page.originalImagePath,
      outputPath: page.originalImagePath, // Reemplazar original con recorte
      normalizedCorners: corners,
    );

    // Re-aplicar el filtro y rotación sobre la imagen recortada
    await _imageProcessorService.processImage(
      inputPath: page.originalImagePath,
      outputPath: page.processedImagePath,
      filter: page.filter,
      rotationDegrees: page.rotationAngle,
    );

    final updatedDoc = doc.copyWith(
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Reordena las páginas del documento
  Future<DocumentModel> reorderPages({
    required String documentId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final updatedPages = List<ScannedPageModel>.from(doc.pages);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedPages.removeAt(oldIndex);
    updatedPages.insert(newIndex, item);

    // Actualizar números de página correlativos
    final renumberedPages = <ScannedPageModel>[];
    for (int i = 0; i < updatedPages.length; i++) {
      renumberedPages.add(updatedPages[i].copyWith(pageNumber: i + 1));
    }

    final updatedDoc = doc.copyWith(
      pages: renumberedPages,
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Elimina una página del documento
  Future<DocumentModel> deletePage({
    required String documentId,
    required String pageId,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final pageIndex = doc.pages.indexWhere((p) => p.id == pageId);
    if (pageIndex == -1) throw Exception('Página no encontrada.');

    final pageToDelete = doc.pages[pageIndex];

    // Limpiar archivos locales de la página
    final orig = File(pageToDelete.originalImagePath);
    if (await orig.exists()) {
      try { await orig.delete(); } catch (_) {}
    }
    final proc = File(pageToDelete.processedImagePath);
    if (await proc.exists()) {
      try { await proc.delete(); } catch (_) {}
    }

    final updatedPages = List<ScannedPageModel>.from(doc.pages)..removeAt(pageIndex);

    // Renumerar
    final renumberedPages = <ScannedPageModel>[];
    for (int i = 0; i < updatedPages.length; i++) {
      renumberedPages.add(updatedPages[i].copyWith(pageNumber: i + 1));
    }

    final updatedDoc = doc.copyWith(
      pages: renumberedPages,
      updatedAt: DateTime.now(),
      pdfPath: null,
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Cambia el título del documento
  Future<DocumentModel> renameDocument({
    required String documentId,
    required String newTitle,
  }) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    final updatedDoc = doc.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );

    await _storageService.saveDocument(updatedDoc);
    return updatedDoc;
  }

  /// Compila el documento en un archivo PDF local y actualiza la ruta en el modelo
  Future<String> compileDocumentPdf(String documentId) async {
    final doc = await _storageService.getDocumentById(documentId);
    if (doc == null) throw Exception('Documento no encontrado.');

    if (doc.pages.isEmpty) {
      throw Exception('No hay páginas para generar el archivo PDF.');
    }

    final targetPdfPath = await _storageService.createPdfPath(doc.id, doc.title);
    final compiledPdfPath = await _pdfGeneratorService.generatePdf(
      document: doc,
      targetPdfPath: targetPdfPath,
    );

    final updatedDoc = doc.copyWith(
      pdfPath: compiledPdfPath,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveDocument(updatedDoc);

    return compiledPdfPath;
  }

  /// Elimina por completo un documento
  Future<void> deleteDocument(String documentId) async {
    await _storageService.deleteDocument(documentId);
  }
}
