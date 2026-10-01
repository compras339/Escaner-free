import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import '../../../../data/models/document_model.dart';
import '../../../../data/models/filter_type.dart';
import '../../../../data/models/scanned_page_model.dart';
import '../../../../data/repositories/document_repository.dart';

/// ViewModel para la gestión de páginas dentro de un documento: reordenar, rotar, recortar y aplicar filtros
class DocumentEditorViewModel extends ChangeNotifier {
  final DocumentRepository _repository;
  final String documentId;

  DocumentModel? _document;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  String? _errorMessage;

  DocumentEditorViewModel({
    required DocumentRepository repository,
    required this.documentId,
  }) : _repository = repository;

  DocumentModel? get document => _document;
  List<ScannedPageModel> get pages => _document?.pages ?? [];
  bool get isLoading => _isLoading;
  bool get isProcessingAction => _isProcessingAction;
  String? get errorMessage => _errorMessage;

  Future<void> loadDocument() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _document = await _repository.getDocument(documentId);
      if (_document == null) {
        _errorMessage = 'No se encontró el documento solicitado.';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar el documento: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rota una página 90 grados a la derecha
  Future<void> rotatePage(String pageId) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      _document = await _repository.rotatePage(
        documentId: documentId,
        pageId: pageId,
      );
    } catch (e) {
      _errorMessage = 'Error al rotar la página: $e';
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Aplica un filtro de realce a una página
  Future<void> applyFilter(String pageId, FilterType filter) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      _document = await _repository.updatePageFilter(
        documentId: documentId,
        pageId: pageId,
        newFilter: filter,
      );
    } catch (e) {
      _errorMessage = 'Error al aplicar el filtro: $e';
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Recorta una página según las esquinas seleccionadas
  Future<void> cropPage(String pageId, List<Offset> corners) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      _document = await _repository.cropPage(
        documentId: documentId,
        pageId: pageId,
        corners: corners,
      );
    } catch (e) {
      _errorMessage = 'Error al recortar la página: $e';
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Reordena páginas dentro del documento
  Future<void> reorderPages(int oldIndex, int newIndex) async {
    try {
      _document = await _repository.reorderPages(
        documentId: documentId,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al reordenar las páginas: $e';
      notifyListeners();
    }
  }

  /// Elimina una página
  Future<void> deletePage(String pageId) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      _document = await _repository.deletePage(
        documentId: documentId,
        pageId: pageId,
      );
    } catch (e) {
      _errorMessage = 'Error al eliminar la página: $e';
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Agrega nuevas páginas desde fotos capturadas
  Future<void> addPages(List<String> rawImagePaths) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      _document = await _repository.addPagesToDocument(
        documentId: documentId,
        rawImagePaths: rawImagePaths,
      );
    } catch (e) {
      _errorMessage = 'Error al añadir páginas: $e';
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Renombra el documento
  Future<void> renameDocument(String newTitle) async {
    try {
      _document = await _repository.renameDocument(
        documentId: documentId,
        newTitle: newTitle,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al renombrar el documento: $e';
      notifyListeners();
    }
  }

  /// Compila el documento final en PDF
  Future<String?> compilePdf() async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      final pdfPath = await _repository.compileDocumentPdf(documentId);
      await loadDocument();
      return pdfPath;
    } catch (e) {
      _errorMessage = 'Error al compilar el PDF: $e';
      return null;
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }
}
