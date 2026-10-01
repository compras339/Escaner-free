import 'package:flutter/material.dart';
import '../../../../data/models/document_model.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../../data/services/scanner_service.dart';
import '../../../../data/services/share_export_service.dart';

/// ViewModel para la pantalla principal de listado y gestión de documentos
class HomeViewModel extends ChangeNotifier {
  final DocumentRepository _repository;
  final ScannerService _scannerService;
  final ShareExportService _shareExportService;

  List<DocumentModel> _allDocuments = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  HomeViewModel({
    required DocumentRepository repository,
    required ScannerService scannerService,
    required ShareExportService shareExportService,
  })  : _repository = repository,
        _scannerService = scannerService,
        _shareExportService = shareExportService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<DocumentModel> get documents {
    if (_searchQuery.trim().isEmpty) {
      return _allDocuments;
    }
    return _allDocuments.where((doc) {
      return doc.title.toLowerCase().contains(_searchQuery.toLowerCase().trim());
    }).toList();
  }

  /// Carga la lista de documentos locales
  Future<void> loadDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allDocuments = await _repository.getDocuments();
    } catch (e) {
      _errorMessage = 'Error al cargar los documentos locales: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra los documentos por búsqueda de texto
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Escanea usando la API offline de ML Kit y crea un nuevo documento
  Future<DocumentModel?> scanWithMlKit() async {
    _isLoading = true;
    notifyListeners();

    try {
      final imagePaths = await _scannerService.startMlKitScanner();
      if (imagePaths.isNotEmpty) {
        final newDoc = await _repository.createDocumentFromRawImages(
          rawImagePaths: imagePaths,
        );
        await loadDocuments();
        return newDoc;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Error durante el escaneo inteligente: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina un documento seleccionado
  Future<void> deleteDocument(String id) async {
    try {
      await _repository.deleteDocument(id);
      await loadDocuments();
    } catch (e) {
      _errorMessage = 'Error al eliminar el documento: $e';
      notifyListeners();
    }
  }

  /// Comparte el PDF de un documento mediante la hoja de compartir nativa
  Future<void> shareDocument(DocumentModel doc, {Rect? origin}) async {
    try {
      String? pdfPath = doc.pdfPath;
      if (pdfPath == null) {
        pdfPath = await _repository.compileDocumentPdf(doc.id);
      }
      await _shareExportService.sharePdf(
        pdfPath: pdfPath,
        documentTitle: doc.title,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      _errorMessage = 'No se pudo compartir el archivo: $e';
      notifyListeners();
    }
  }
}
